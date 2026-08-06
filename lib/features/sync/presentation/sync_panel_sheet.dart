import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_indicator_widget.dart';

class SyncPanelSheet extends ConsumerWidget {
  const SyncPanelSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 40),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(100),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Text('Sync Status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          
          _buildStatusBanner(syncState),
          const SizedBox(height: 24),
          
          const Text('Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: const Text('Last synced'),
            trailing: const Text('2 mins ago', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.pending_actions),
            title: const Text('Items queued'),
            trailing: const Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          if (syncState == SyncState.error) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.error_outline, color: Colors.redAccent),
              title: const Text('Last error'),
              subtitle: const Text('Network timeout while uploading "IMG_2026.jpg"'),
            ),
          ],
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync),
              label: const Text('Force Sync Now'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(syncStateProvider.notifier).state = SyncState.syncing;
                Navigator.pop(context);
                
                // Mock ending sync after a few seconds
                Future.delayed(const Duration(seconds: 3), () {
                  ref.read(syncStateProvider.notifier).state = SyncState.idle;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(SyncState state) {
    Color color;
    IconData icon;
    String text;

    switch (state) {
      case SyncState.idle:
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'All files are up to date';
        break;
      case SyncState.syncing:
        color = Colors.blue;
        icon = Icons.sync;
        text = 'Syncing 4 items...';
        break;
      case SyncState.error:
        color = Colors.redAccent;
        icon = Icons.error;
        text = 'Sync failed. Tap to retry.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        border: Border.all(color: color.withAlpha(100)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
