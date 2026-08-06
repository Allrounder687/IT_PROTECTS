import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/vault_notifier.dart'; // for importPhoto
import '../state/paginated_vault_notifier.dart';
import '../state/search_notifier.dart';
import '../../providers/state/sync_status_notifier.dart';
import '../../../core/presentation/responsive_config.dart';
import 'encrypted_grid_widget.dart';

class VaultDashboardScreen extends ConsumerStatefulWidget {
  const VaultDashboardScreen({super.key});

  @override
  ConsumerState<VaultDashboardScreen> createState() => _VaultDashboardScreenState();
}

class _VaultDashboardScreenState extends ConsumerState<VaultDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (_searchController.text.trim().isNotEmpty) {
        ref.read(searchNotifierProvider.notifier).loadNextPage();
      } else {
        ref.read(paginatedVaultProvider.notifier).loadNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.trim().isNotEmpty;
    final paginatedStateAsync = isSearching ? ref.watch(searchNotifierProvider) : ref.watch(paginatedVaultProvider);
    
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: syncStatus.when(
              data: (status) {
                switch (status) {
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
          ),
        ],
      ),
      body: ResponsiveConfig.buildConstrainedBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {}); // Rebuild to toggle between providers
                  ref.read(searchNotifierProvider.notifier).onSearchChanged(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search your vault...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic),
                    onPressed: () {
                      // TODO: Voice search entry point
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Voice search coming soon')),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                isSearching ? 'Search Results' : 'Recents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: paginatedStateAsync.when(
                data: (paginatedState) {
                  final items = paginatedState.items;
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.folder_special, size: 64, color: Colors.white30),
                          const SizedBox(height: 16),
                          Text(
                            'Your vault is empty.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white54,
                                ),
                          ),
                        ],
                      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                    );
                  }

                  return GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    gridDelegate: ResponsiveConfig.getVaultGridDelegate(),
                    itemCount: items.length + (paginatedState.isLoadingNext ? 3 : 0),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final item = items[index];
                      return GestureDetector(
                        onTap: () => context.push('/viewer/$index'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: EncryptedGridWidget(
                            item: item,
                          ),
                        ),
                      ).animate().fade(delay: ((index % 10) * 50).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await ref.read(vaultListProvider.notifier).importPhoto();
            // Refresh pagination to show new item
            ref.read(paginatedVaultProvider.notifier).refresh();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to import: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}
