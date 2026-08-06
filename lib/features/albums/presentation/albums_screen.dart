import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/albums_notifier.dart';
import '../domain/album.dart';
import '../../../core/presentation/responsive_config.dart';

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
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create New Album', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Album Name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isNotEmpty) {
                    ref.read(albumsNotifierProvider.notifier).createAlbum(nameController.text.trim(), null);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
              const SizedBox(height: 16),
            ],
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
        title: const Text('Rename Album'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
      appBar: AppBar(
        title: const Text('Albums'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateAlbumDialog,
          )
        ],
      ),
      body: ResponsiveConfig.buildConstrainedBody(
        child: albumsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('Error: $error')),
          data: (albums) => GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: ResponsiveConfig.getAlbumGridDelegate(),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              IconData icon;
              Color color;
              switch (album.type) {
                case AlbumType.mainVault:
                  icon = Icons.security;
                  color = Colors.blueAccent;
                  break;
                case AlbumType.documents:
                  icon = Icons.description;
                  color = Colors.orangeAccent;
                  break;
                case AlbumType.privatePhotos:
                  icon = Icons.photo_library;
                  color = Colors.purpleAccent;
                  break;
                case AlbumType.custom:
                  icon = Icons.folder;
                  color = Colors.greenAccent;
                  break;
              }
              return _buildAlbumCard(context, ref, album, icon, color);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, WidgetRef ref, Album album, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Opened ${album.name}')),
          );
        },
        onLongPress: () {
          if (album.type == AlbumType.custom) {
            _showAlbumContextMenu(context, album, ref);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, size: 40, color: color),
                  if (album.isLocked)
                    IconButton(
                      icon: const Icon(Icons.lock, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        // Normally prompt for PIN before unlocking
                        ref.read(albumsNotifierProvider.notifier).toggleAlbumLock(album.id, false);
                      },
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.lock_open, color: Colors.grey, size: 20),
                      onPressed: () {
                        ref.read(albumsNotifierProvider.notifier).toggleAlbumLock(album.id, true);
                      },
                    ),
                ],
              ),
              const Spacer(),
              Text(
                album.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${album.itemCount} items',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlbumContextMenu(BuildContext context, Album album, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameAlbumDialog(album);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: const Text('Change Storage Provider'),
                onTap: () {
                  Navigator.pop(context);
                  // Not fully fleshed out, could show a list of linked providers
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change provider coming soon')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
