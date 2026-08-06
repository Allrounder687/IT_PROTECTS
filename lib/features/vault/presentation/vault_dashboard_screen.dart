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
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/presentation/components/vault_card.dart';
import '../../../core/presentation/components/skeleton_grid.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/security/lifecycle_cleanup_manager.dart';

class VaultDashboardScreen extends ConsumerStatefulWidget {
  const VaultDashboardScreen({super.key});

  @override
  ConsumerState<VaultDashboardScreen> createState() => _VaultDashboardScreenState();
}

class _VaultDashboardScreenState extends ConsumerState<VaultDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['All', 'Photos', 'Videos', 'Docs', 'Favorites'];

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

  void _showAddBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
                  title: const Text('Secure Camera'),
                  subtitle: const Text('Take a photo directly into the vault'),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Secure Camera coming soon')),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
                  title: const Text('Add from Gallery / File'),
                  subtitle: const Text('Import existing media'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      // Prevent the app from locking when the system file picker opens
                      ref.read(ignoreLifecycleLockProvider.notifier).state = true;
                      await ref.read(vaultListProvider.notifier).importPhoto();
                      ref.read(paginatedVaultProvider.notifier).refresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to import: $e')),
                        );
                      }
                    } finally {
                      // In case it wasn't reset by resuming (e.g. error before picker opened)
                      ref.read(ignoreLifecycleLockProvider.notifier).state = false;
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.trim().isNotEmpty;
    final paginatedStateAsync = isSearching ? ref.watch(searchNotifierProvider) : ref.watch(paginatedVaultProvider);
    
    final syncStatus = ref.watch(syncStatusProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Private Vault',
        showSearch: true,
        onSearchChanged: (value) {
          setState(() {
            // Update search state
            if (_searchController.text != value) {
              _searchController.text = value;
            }
          });
          ref.read(searchNotifierProvider.notifier).onSearchChanged(value);
        },
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
                    );
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
            // Filter Chips
            SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return ChoiceChip(
                    label: Text(_filters[index]),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilterIndex = index);
                        // TODO: Implement actual filtering logic via provider
                      }
                    },
                    selectedColor: AppTheme.primary.withAlpha(50),
                    backgroundColor: AppTheme.surfaceVariant,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                },
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
                    cacheExtent: 2000.0,
                    itemCount: items.length + (paginatedState.isLoadingNext ? 3 : 0),
                    itemBuilder: (context, index) {
                      if (index >= items.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final item = items[index];
                      return VaultCard(
                        item: item,
                        thumbnail: EncryptedGridWidget(item: item),
                        onTap: () => context.push('/viewer/$index'),
                      ).animate().fade(delay: ((index % 10) * 50).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
                    },
                  );
                },
                loading: () => const SkeletonGrid(),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBottomSheet,
        child: const Icon(Icons.add),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}
