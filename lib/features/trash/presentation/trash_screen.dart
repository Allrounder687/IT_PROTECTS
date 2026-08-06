import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../vault/domain/vault_item_entity.dart';

// Mock Trash Provider for UI
final trashProvider = Provider<List<VaultItemEntity>>((ref) {
  // In a real implementation, we'd query items where isDeleted = true
  return [];
});

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
        title: const Text('Delete Permanently?'),
        content: Text('Are you sure you want to permanently delete ${_selectedIds.length} items? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context);
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
    final trashItems = ref.watch(trashProvider);
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
          ]
        ],
      ),
      body: trashItems.isEmpty
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
                  leading: const Icon(Icons.broken_image),
                  title: Text(item.originalName),
                  subtitle: const Text('Deleted 2 days ago'),
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
    );
  }
}
