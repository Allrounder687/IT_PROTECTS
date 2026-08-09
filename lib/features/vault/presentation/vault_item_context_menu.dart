import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/vault_item_entity.dart';
import '../data/local_vault_repository.dart';
import '../state/paginated_vault_notifier.dart';
import '../../albums/state/albums_notifier.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import '../domain/encryption_use_case.dart';
import '../../auth/state/auth_notifier.dart';
import '../../../core/providers/session_provider.dart';
import 'decoy_auth_dialog.dart';
import '../../../core/providers/auth_mode_provider.dart';
import 'package:file_picker/file_picker.dart';

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
                final authMode = ref.read(authModeProvider);
                await repo.toggleFavourite(item.id, !item.isFavourite, authMode: authMode);
                ref.read(paginatedVaultProvider(currentAlbumId).notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(item.isFavourite ? 'Removed from Favourites' : 'Added to Favourites')),
                  );
                }
              },
            ),
            if (item.albumId != null)
              ListTile(
                leading: const Icon(Icons.image, color: AppTheme.primary),
                title: const Text('Set as album cover'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref.read(albumsNotifierProvider.notifier).setAlbumCover(item.albumId!, item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Album cover updated')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to set cover: $e')),
                      );
                    }
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
                executeSafeSend(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: AppTheme.primary),
              title: const Text('Mark as Decoy'),
              onTap: () async {
                Navigator.pop(context);
                final success = await showDialog<bool>(
                  context: context,
                  builder: (context) => DecoyAuthDialog(item: item),
                );
                if (success == true) {
                  ref.read(paginatedVaultProvider(currentAlbumId).notifier).refresh();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moved to Decoy Vault')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Move to Trash', style: TextStyle(color: Colors.redAccent)),
              onTap: () async {
                Navigator.pop(context);
                final repo = ref.read(localVaultRepositoryProvider);
                final authMode = ref.read(authModeProvider);
                await repo.moveToTrash(item.id, authMode: authMode);
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
                          final authMode = ref.read(authModeProvider);
                          await repo.moveItemToAlbum(item.id, album.id, authMode: authMode);
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
Future<void> executeSafeSend(BuildContext context, WidgetRef ref, VaultItemEntity item) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preparing Safe Send...')));
    
    // 1. Read encrypted file
    final file = File(item.encryptedFilePath);
    final encryptedBytes = await file.readAsBytes();
    
    // 2. Decrypt
    final encUseCase = ref.read(encryptionUseCaseProvider);
    final masterKeyBytes = ref.read(sessionProvider);
    if (masterKeyBytes == null) throw Exception('No session key');
    final masterKey = SecretKey(masterKeyBytes);
    
    final decryptedBytes = await encUseCase.decryptDataWithCek(
      encryptedBytes,
      item.wrappedContentKey,
      item.iv,
      masterKey,
    );
    
    // 3. Check Platform
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop doesn't support share_plus very well for files, use Save As fallback
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save decrypted file',
        fileName: item.originalName,
      );

      if (outputFile != null) {
        final out = File(outputFile);
        await out.writeAsBytes(decryptedBytes);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved securely to ${out.path}')));
        }
      }
    } else {
      // 4. Mobile Share
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${item.originalName}');
      await tempFile.writeAsBytes(decryptedBytes);
      
      final result = await Share.shareXFiles([XFile(tempFile.path)]);
      
      // 5. Cleanup
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      
      if (context.mounted && result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sent securely! (File deleted from cache)')));
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Re-import this item from device gallery; current file handle is invalid.'),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}
