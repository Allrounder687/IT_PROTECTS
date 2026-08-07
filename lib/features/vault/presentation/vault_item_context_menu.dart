import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/vault_item_entity.dart';
import '../data/local_vault_repository.dart';
import '../state/paginated_vault_notifier.dart';
import '../../albums/state/albums_notifier.dart';

void showVaultItemContextMenu(BuildContext context, WidgetRef ref, VaultItemEntity item, {int? currentAlbumId}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                item.isFavourite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavourite ? Colors.redAccent : AppTheme.primary,
              ),
              title: Text(item.isFavourite ? 'Remove from Favourites' : 'Add to Favourites'),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(localVaultRepositoryProvider);
                await repo.toggleFavourite(item.id, !item.isFavourite);
                ref.read(paginatedVaultProvider(currentAlbumId).notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(item.isFavourite ? 'Removed from Favourites' : 'Added to Favourites')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open, color: AppTheme.primary),
              title: const Text('Move to Album'),
              onTap: () {
                Navigator.pop(context);
                showMoveToAlbumDialog(context, ref, item, currentAlbumId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.send_outlined, color: AppTheme.primary),
              title: const Text('Safe Send'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Safe Send coming soon...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Move to Trash', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(localVaultRepositoryProvider);
                await repo.moveToTrash(item.id);
                ref.read(paginatedVaultProvider(currentAlbumId).notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Moved to Trash')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

void showMoveToAlbumDialog(BuildContext context, WidgetRef ref, VaultItemEntity item, int? currentAlbumId) {
  showDialog(
    context: context,
    builder: (context) {
      return Consumer(
        builder: (context, ref, child) {
          final albumsAsync = ref.watch(albumsNotifierProvider);
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            title: const Text('Move to Album'),
            content: SizedBox(
              width: double.maxFinite,
              child: albumsAsync.when(
                data: (albums) {
                  if (albums.isEmpty) return const Text('No albums available.');
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return ListTile(
                        title: Text(album.name),
                        onTap: () async {
                          Navigator.pop(context);
                          final repo = ref.read(localVaultRepositoryProvider);
                          await repo.moveItemToAlbum(item.id, album.id);
                          ref.read(paginatedVaultProvider(currentAlbumId).notifier).refresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Moved to ${album.name}')),
                            );
                          }
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Error: $e'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            ],
          );
        },
      );
    },
  );
}
