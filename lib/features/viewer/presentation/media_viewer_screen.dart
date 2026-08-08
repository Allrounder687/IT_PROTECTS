import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../vault/state/vault_notifier.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../../vault/data/local_vault_repository.dart';
import '../../vault/state/paginated_vault_notifier.dart';
import '../../vault/presentation/vault_item_context_menu.dart';
import 'image_item_viewer.dart';
import 'video_item_viewer.dart';
import 'doc_item_viewer.dart';

import '../../vault/presentation/decoy_auth_dialog.dart';
import '../../../core/providers/auth_mode_provider.dart';

class MediaViewerScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const MediaViewerScreen({super.key, required this.initialIndex});

  @override
  ConsumerState<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends ConsumerState<MediaViewerScreen> {
  late PageController _pageController;
  bool _showHud = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleHud() {
    setState(() {
      _showHud = !_showHud;
    });
  }

  void _showInfoOverlay(VaultItemEntity item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('File Info', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Name'),
                subtitle: Text(item.originalName),
              ),
              ListTile(
                leading: const Icon(Icons.sd_storage),
                title: const Text('Size'),
                subtitle: Text('${(item.size / 1024).toStringAsFixed(2)} KB'),
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Encryption Status'),
                subtitle: const Text('Encrypted (AES-256-GCM)'),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_done),
                title: const Text('Provider'),
                subtitle: const Text('Local (Encrypted)'),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final mediaItemsState = ref.watch(vaultListProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Immersive viewer
      body: mediaItemsState.when(
        data: (items) {
          if (items.isEmpty) return const Center(child: Text('No items', style: TextStyle(color: Colors.white)));
          
          final currentItem = items[_currentIndex];

          return Stack(
            children: [
              GestureDetector(
                onTap: _toggleHud,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final item = items[index];
                    
                    if (item.originalName.endsWith('.mp4') || item.originalName.endsWith('.mov')) {
                      return VideoItemViewer(item: item, showHud: _showHud);
                    } else if (item.originalName.endsWith('.pdf')) {
                      return DocItemViewer(item: item);
                    } else {
                      return ImageItemViewer(item: item);
                    }
                  },
                ),
              ),

              // HUD Overlay - Top Bar
              if (_showHud)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black87, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () => context.pop(),
                          ),
                          Expanded(
                            child: Text(
                              currentItem.originalName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.security, color: Colors.white),
                            onPressed: () async {
                              final success = await showDialog<bool>(
                                context: context,
                                builder: (context) => DecoyAuthDialog(item: currentItem),
                              );
                              if (success == true) {
                                ref.invalidate(vaultListProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Moved to Decoy Vault')),
                                  );
                                  Navigator.pop(context); // Close viewer as it's moved
                                }
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.white),
                            onPressed: () => _showInfoOverlay(currentItem),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 200.ms).slideY(begin: -1, end: 0),
                ),
                
              // HUD Overlay - Bottom Bar
              if (_showHud && !currentItem.originalName.endsWith('.mp4') && !currentItem.originalName.endsWith('.mov'))
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black87],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: Icon(currentItem.isFavourite ? Icons.favorite : Icons.favorite_border, color: currentItem.isFavourite ? Colors.redAccent : Colors.white),
                            onPressed: () async {
                              final repo = ref.read(localVaultRepositoryProvider);
                              final authMode = ref.read(authModeProvider);
                              await repo.toggleFavourite(currentItem.id, !currentItem.isFavourite, authMode: authMode);
                              ref.invalidate(vaultListProvider);
                              ref.read(paginatedVaultProvider(null).notifier).refresh();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(currentItem.isFavourite ? 'Removed from Favourites' : 'Added to Favourites')));
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.folder_open, color: Colors.white),
                            onPressed: () {
                              showMoveToAlbumDialog(context, ref, currentItem, null);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility_off, color: Colors.white),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marked as Decoy')));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.send_time_extension, color: Colors.white),
                            onPressed: () => executeSafeSend(context, ref, currentItem),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () async {
                              final repo = ref.read(localVaultRepositoryProvider);
                              final authMode = ref.read(authModeProvider);
                              await repo.moveToTrash(currentItem.id, authMode: authMode);
                              ref.invalidate(vaultListProvider);
                              ref.read(paginatedVaultProvider(null).notifier).refresh();
                              if (context.mounted) {
                                context.pop(); // Close viewer since item is gone
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moved to Trash')));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(duration: 200.ms).slideY(begin: 1, end: 0),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}
