import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../state/trash_notifier.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Set<int> _selectedIds = {};

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _restoreSelected() {
    for (final id in _selectedIds) {
      ref.read(trashNotifierProvider.notifier).restoreItem(id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored ${_selectedIds.length} items.')),
    );
    setState(() {
      _selectedIds.clear();
    });
  }

  void _deletePermanently() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete Permanently?'),
        content: Text('Are you sure you want to permanently delete ${_selectedIds.length} items? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
              for (final id in _selectedIds) {
                ref.read(trashNotifierProvider.notifier).deleteItemPermanently(id);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Permanently deleted ${_selectedIds.length} items.')),
              );
              setState(() {
                _selectedIds.clear();
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashStateAsync = ref.watch(trashNotifierProvider);
    final isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      appBar: CustomAppBar(
        title: isSelectionMode ? '${_selectedIds.length} Selected' : 'Trash',
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: _restoreSelected,
              tooltip: 'Restore',
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
              onPressed: _deletePermanently,
              tooltip: 'Delete Permanently',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () {
                ref.read(trashNotifierProvider.notifier).emptyTrash();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trash emptied')));
              },
              tooltip: 'Empty Trash',
            ),
          ]
        ],
      ),
      body: trashStateAsync.when(
        data: (trashItems) => trashItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete_outline, size: 64, color: AppTheme.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Trash is empty',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: trashItems.length,
                itemBuilder: (context, index) {
                  final item = trashItems[index];
                  final isSelected = _selectedIds.contains(item.id);

                  return ListTile(
                    leading: const Icon(Icons.broken_image, color: AppTheme.primary),
                    title: Text(item.originalName),
                    subtitle: Text(item.deletedAt != null 
                        ? 'Deleted ${DateTime.fromMillisecondsSinceEpoch(item.deletedAt!).toString().split('.')[0]}'
                        : 'Deleted recently'),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primary) : const Icon(Icons.circle_outlined),
                    selected: isSelected,
                    onTap: () {
                      if (isSelectionMode) {
                        _toggleSelection(item.id);
                      }
                    },
                    onLongPress: () {
                      _toggleSelection(item.id);
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
