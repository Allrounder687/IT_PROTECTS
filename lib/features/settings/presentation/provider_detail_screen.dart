import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../sync/presentation/sync_indicator_widget.dart';

class ProviderDetailScreen extends ConsumerStatefulWidget {
  final String providerId;

  const ProviderDetailScreen({super.key, required this.providerId});

  @override
  ConsumerState<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends ConsumerState<ProviderDetailScreen> {
  void _triggerManualSync() {
    ref.read(syncStateProvider.notifier).state = SyncState.syncing;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manual sync triggered')),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(syncStateProvider.notifier).state = SyncState.idle;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // In a real app we'd fetch the provider details and mapped albums by ID.
    // For now, we use mock UI representation.
    final name = widget.providerId == 'google_drive' ? 'Google Drive' : 'Dropbox';
    final icon = widget.providerId == 'google_drive' ? Icons.add_to_drive : Icons.cloud;
    final color = widget.providerId == 'google_drive' ? Colors.blueAccent : Colors.blue;

    return Scaffold(
      appBar: CustomAppBar(
        title: '$name Details',
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 64, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  'Connected to $name',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('user@example.com', style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.sync),
                  label: const Text('Trigger Manual Sync'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _triggerManualSync,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Mapped Albums',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Mock Mapped Albums
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.photo_album, color: AppTheme.primary),
              title: Text('Camera Roll'),
              subtitle: Text('342 items synced'),
              trailing: Icon(Icons.cloud_done, color: Colors.green),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.folder_special, color: AppTheme.primary),
              title: Text('Favorites'),
              subtitle: Text('42 items synced'),
              trailing: Icon(Icons.cloud_done, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
