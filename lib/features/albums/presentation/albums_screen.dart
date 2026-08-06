import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/albums_notifier.dart';
import '../domain/album.dart';
import '../../../core/presentation/responsive_config.dart';
import '../../../core/presentation/components/vault_hero_header.dart';
import '../../../core/presentation/components/album_card.dart';
import '../../../core/presentation/components/skeleton_grid.dart';
import '../../../core/theme/app_theme.dart';

class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {

  void _showCreateAlbumDialog() {
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Create New Album', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Album Name',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isNotEmpty) {
                      ref.read(albumsNotifierProvider.notifier).createAlbum(nameController.text.trim(), null);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Create'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRenameAlbumDialog(Album album) {
    final nameController = TextEditingController(text: album.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Rename Album'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(albumsNotifierProvider.notifier).renameAlbum(album.id, nameController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(albumsNotifierProvider);
    return Scaffold(
      body: ResponsiveConfig.buildFluidBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VaultHeroHeader(
              title: 'Albums',
              subtitle: 'Organize your memories securely.',
              onUploadPressed: _showCreateAlbumDialog,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: albumsAsync.when(
          loading: () => const SkeletonGrid(isAlbum: true),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
          data: (albums) => GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return _buildAlbumCard(context, ref, album);
            },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, WidgetRef ref, Album album) {
    return GestureDetector(
      onLongPress: () {
        if (album.type == AlbumType.custom) {
          _showAlbumContextMenu(context, album, ref);
        }
      },
      child: AlbumCard(
        title: album.name,
        itemCount: album.itemCount,
        isLocked: album.isLocked,
        onTap: () {
          // Route to Album Detail Screen
          context.push('/albums/${album.id}');
        },
      ),
    );
  }

  void _showAlbumContextMenu(BuildContext context, Album album, WidgetRef ref) {
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
                leading: const Icon(Icons.edit, color: AppTheme.primary),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameAlbumDialog(album);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_outlined, color: AppTheme.primary),
                title: const Text('Change Storage Provider'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change provider coming soon')),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
