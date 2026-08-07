import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/presentation/components/vault_card.dart';
import '../../../core/presentation/responsive_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../vault/presentation/encrypted_grid_widget.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../state/trash_notifier.dart';
import '../../vault/state/paginated_vault_notifier.dart';
import '../../vault/state/vault_notifier.dart';

class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  void _showTrashItemContextMenu(BuildContext context, WidgetRef ref, VaultItemEntity item) {
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
                leading: const Icon(Icons.restore, color: Colors.green),
                title: const Text('Restore'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(trashNotifierProvider.notifier).restoreItem(item.id);
                  ref.invalidate(vaultListProvider);
                  ref.read(paginatedVaultProvider(null).notifier).refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item restored to Vault')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('Delete Permanently', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.surface,
                      title: const Text('Permanently Delete?'),
                      content: const Text('This action cannot be undone. The file will be permanently removed from your device.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ref.read(trashNotifierProvider.notifier).deleteItemPermanently(item.id);
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
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

  void _showEmptyTrashDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Empty Trash?'),
        content: const Text('All items in the trash will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(trashNotifierProvider.notifier).emptyTrash();
            },
            child: const Text('Empty Trash', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashStateAsync = ref.watch(trashNotifierProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Recycle Bin',
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: 'Empty Trash',
            onPressed: () => _showEmptyTrashDialog(context, ref),
          ),
        ],
      ),
      body: ResponsiveConfig.buildConstrainedBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Tap any item to restore or permanently delete it.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
            Expanded(
              child: trashStateAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.delete_outline, size: 64, color: Colors.white30),
                          const SizedBox(height: 16),
                          Text(
                            'Trash is empty.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white54,
                                ),
                          ),
                        ],
                      ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    gridDelegate: ResponsiveConfig.getVaultGridDelegate(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return VaultCard(
                        item: item,
                        thumbnail: EncryptedGridWidget(item: item),
                        onTap: () {
                          // View not allowed in trash, show context menu
                          _showTrashItemContextMenu(context, ref, item);
                        },
                        onLongPress: () => _showTrashItemContextMenu(context, ref, item),
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
    );
  }
}
