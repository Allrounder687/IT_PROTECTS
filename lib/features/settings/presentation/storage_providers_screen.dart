import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/data/google_drive_repository.dart';
import '../../providers/state/active_provider_notifier.dart';
import '../state/settings_providers.dart';
import '../../../core/presentation/responsive_config.dart';

final googleDriveRepoProvider = Provider((ref) => GoogleDriveRepository());

class StorageProvidersScreen extends ConsumerStatefulWidget {
  const StorageProvidersScreen({super.key});

  @override
  ConsumerState<StorageProvidersScreen> createState() => _StorageProvidersScreenState();
}

class _StorageProvidersScreenState extends ConsumerState<StorageProvidersScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _connectGoogleDrive() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(googleDriveRepoProvider);
      await repo.authenticate();
      
      // Update global active provider
      ref.read(activeCloudProvider.notifier).setProvider(repo);
      
      // Update settings to persist the choice
      ref.read(cloudSyncSettingsProvider.notifier).setDefaultProvider('google_drive');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully connected to Google Drive')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _disconnectProvider() {
    ref.read(activeCloudProvider.notifier).clearProvider();
    ref.read(cloudSyncSettingsProvider.notifier).setDefaultProvider(null);
  }

  @override
  Widget build(BuildContext context) {
    final cloudSettings = ref.watch(cloudSyncSettingsProvider);
    final activeProviderId = cloudSettings.defaultProviderId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Providers'),
      ),
      body: ResponsiveConfig.buildConstrainedBody(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.add_to_drive, color: Colors.blueAccent),
                title: const Text('Google Drive'),
                subtitle: const Text('App Data folder (hidden from user)'),
                trailing: activeProviderId == 'google_drive'
                  ? TextButton(
                      onPressed: _disconnectProvider,
                      child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
                    )
                  : ElevatedButton(
                      onPressed: _connectGoogleDrive,
                      child: const Text('Connect'),
                    ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: activeProviderId == 'google_drive' ? Colors.blue.withValues(alpha: 0.1) : null,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.blue),
                title: const Text('Dropbox'),
                subtitle: const Text('Coming soon'),
                trailing: const ElevatedButton(
                  onPressed: null,
                  child: Text('Connect'),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ],
          ),
      ),
    );
  }
}
