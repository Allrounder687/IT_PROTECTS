import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../state/vault_notifier.dart';
import '../../providers/state/sync_status_notifier.dart';
import 'encrypted_grid_widget.dart';
import 'vault_item_context_menu.dart';

class VaultDashboardScreen extends ConsumerWidget {
  const VaultDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaItemsState = ref.watch(vaultListProvider);
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search your vault...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {},
                ),
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
            child: mediaItemsState.when(
              data: (items) {
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
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await ref.read(vaultListProvider.notifier).importPhoto();
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
