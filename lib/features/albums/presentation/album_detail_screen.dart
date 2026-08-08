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
import '../../documents/presentation/document_edit_screen.dart';
import '../../documents/domain/document_template.dart';
import '../domain/album.dart';
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

  void _showAddBottomSheet(Album? album) {
    if (album?.type == AlbumType.documents) {
      _showDocumentTypeBottomSheet();
      return;
    }

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

  void _showDocumentTypeBottomSheet() {
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text('Select Document Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card, color: AppTheme.primary),
                  title: const Text('Credit Card'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/document/edit/${widget.albumId}/${DocumentTemplateType.creditCard.name}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: AppTheme.primary),
                  title: const Text('Bank Account'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/document/edit/${widget.albumId}/${DocumentTemplateType.bankAccount.name}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.badge, color: AppTheme.primary),
                  title: const Text('Government ID'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/document/edit/${widget.albumId}/${DocumentTemplateType.governmentId.name}');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description, color: AppTheme.primary),
                  title: const Text('Other Secure Document'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/document/edit/${widget.albumId}/${DocumentTemplateType.custom.name}');
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
            onPressed: () => _showAddBottomSheet(album),
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
              onUploadPressed: () => _showAddBottomSheet(album),
              uploadButtonLabel: album?.type == AlbumType.documents ? 'Add Document' : 'Upload to this album',
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

                  if (album?.type == AlbumType.documents) {
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      itemCount: items.length + (paginatedState.isLoadingNext ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
                        }
                        final item = items[index];
                        return Card(
                          color: AppTheme.surfaceVariant.withValues(alpha: 0.3),
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.description, color: AppTheme.primary),
                            ),
                            title: Text(item.originalName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Secure Document'),
                            onTap: () => context.push('/document/viewer/${item.id}'),
                            onLongPress: () => showVaultItemContextMenu(context, ref, item, currentAlbumId: int.parse(widget.albumId)),
                          ),
                        ).animate().fade(delay: ((index % 10) * 50).ms, duration: 300.ms).slideY(begin: 0.1, end: 0);
                      },
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
        onPressed: () => _showAddBottomSheet(album),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}
