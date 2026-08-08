import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../vault/state/vault_notifier.dart'; // for importPhoto
import '../../vault/state/paginated_vault_notifier.dart';
import '../../vault/presentation/encrypted_grid_widget.dart';
import '../../../core/presentation/responsive_config.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/presentation/components/vault_hero_header.dart';
import '../../../core/presentation/components/vault_card.dart';
import '../../../core/theme/app_theme.dart';
import '../state/albums_notifier.dart';
import '../../vault/presentation/vault_item_context_menu.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumDetailScreen({super.key, required this.albumId});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
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
      ref.read(paginatedVaultProvider(int.parse(widget.albumId)).notifier).loadNextPage();
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
                  subtitle: const Text('Take a photo directly into this album'),
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
                      await ref.read(vaultListProvider.notifier).importPhoto(albumId: int.parse(widget.albumId));
                      ref.read(paginatedVaultProvider(int.parse(widget.albumId)).notifier).refresh();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to import: $e')),
                        );
                      }
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
    final paginatedStateAsync = ref.watch(paginatedVaultProvider(int.parse(widget.albumId)));
    final albums = ref.watch(albumsNotifierProvider).valueOrNull;
    final album = albums?.firstWhere((a) => a.id.toString() == widget.albumId);

    return Scaffold(
      appBar: CustomAppBar(
        title: album?.name ?? 'Album',
        showSearch: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Upload to this album',
            onPressed: _showAddBottomSheet,
          ),
        ],
        onSearchChanged: (value) {
          // TODO: Implement scoped search
        },
      ),
      body: ResponsiveConfig.buildConstrainedBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VaultHeroHeader(
              title: album?.name ?? 'Album',
              subtitle: '${album?.itemCount ?? 0} items secured.',
              onUploadPressed: _showAddBottomSheet,
              uploadButtonLabel: 'Upload to this album',
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
                          const Icon(Icons.folder_open, size: 64, color: Colors.white30),
                          const SizedBox(height: 16),
                          Text(
                            'This album is empty.',
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
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    gridDelegate: ResponsiveConfig.getVaultGridDelegate(),
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
                        onLongPress: () => showVaultItemContextMenu(context, ref, item, currentAlbumId: int.parse(widget.albumId)),
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
        onPressed: _showAddBottomSheet,
        child: const Icon(Icons.add),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}
