import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/vault_notifier.dart';
import '../../providers/state/sync_status_notifier.dart';
import 'encrypted_grid_widget.dart';
import 'vault_item_context_menu.dart';

import 'dart:async';
import '../../../core/providers/auth_mode_provider.dart';
import '../data/local_vault_repository.dart';
import '../../vault/domain/vault_item_entity.dart';

class VaultDashboardScreen extends ConsumerStatefulWidget {
  const VaultDashboardScreen({super.key});

  @override
  ConsumerState<VaultDashboardScreen> createState() => _VaultDashboardScreenState();
}

class _VaultDashboardScreenState extends ConsumerState<VaultDashboardScreen> {
  Timer? _debounce;
  List<VaultItemEntity>? _searchResults;
  bool _isSearching = false;
  final _searchController = TextEditingController();

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() {
        _isSearching = true;
      });
      final repo = ref.read(localVaultRepositoryProvider);
      final authMode = ref.read(authModeProvider);
      final results = await repo.searchMediaItems(query, authMode: authMode);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaItemsState = ref.watch(vaultListProvider);
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: syncStatus.when(
                data: (status) {
                  switch (status.state) {
                    case SyncState.syncingUp:
                    case SyncState.syncingDown:
                      return const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ).animate(onPlay: (controller) => controller.repeat()).rotate(duration: 2.seconds);
                    case SyncState.queued:
                      return const Icon(Icons.cloud_upload_outlined, color: Colors.amber);
                    case SyncState.error:
                      return const Icon(Icons.cloud_off, color: Colors.red);
                    case SyncState.idle:
                    default:
                      return const Icon(Icons.cloud_done_outlined, color: Colors.grey);
                  }
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const Icon(Icons.cloud_off, color: Colors.red),
              ),
              onPressed: () {
                _showSyncStatusSheet(context, ref);
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Search your vault...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Recents',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults != null
                    ? _buildGrid(context, _searchResults!)
                    : mediaItemsState.when(
                        data: (items) => _buildGrid(context, items),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => Center(child: Text('Error: $error')),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo),
                      title: const Text('Import Photo/Video'),
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await ref.read(vaultListProvider.notifier).importPhoto();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import: $e')));
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Add Document'),
                      onTap: () {
                        Navigator.pop(context);
                        // Using go_router
                        context.push('/document/new');
                      },
                    ),
                  ],
                ),
              );
            }
          );
        },
        child: const Icon(Icons.add),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildGrid(BuildContext context, List<VaultItemEntity> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_special, size: 64, color: Colors.white30),
            const SizedBox(height: 16),
            Text(
              _searchResults != null ? 'No results found.' : 'Your vault is empty.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ],
        ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => context.push('/viewer/$index'),
          onLongPress: () => showVaultItemContextMenu(context, ref, item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: EncryptedGridWidget(
              item: item,
            ),
          ),
        ).animate().fade(delay: (index * 50).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
      },
    );
  }

  void _showSyncStatusSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final syncStatus = ref.watch(syncStatusProvider);
            final statusData = syncStatus.valueOrNull ?? const SyncStatus();
            
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cloud Sync Status', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_queue, color: Colors.blue),
                    title: const Text('Pending Uploads/Deletions'),
                    trailing: Text('${statusData.pendingCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: const Text('Errors'),
                    trailing: Text('${statusData.errorCount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: Colors.grey),
                    title: const Text('Last Sync'),
                    subtitle: Text(statusData.lastSyncTime != null 
                        ? '${statusData.lastSyncTime!.hour}:${statusData.lastSyncTime!.minute.toString().padLeft(2, '0')}'
                        : 'Never'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(syncStatusProvider.notifier).markAsQueued();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sync Now'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
