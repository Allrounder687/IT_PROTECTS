import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data/google_drive_repository.dart';
import '../../providers/state/active_provider_notifier.dart';
import '../../settings/state/settings_providers.dart';

final googleDriveRepoProvider = Provider((ref) => GoogleDriveRepository());

class CloudProviderSetupScreen extends ConsumerStatefulWidget {
  const CloudProviderSetupScreen({super.key});

  @override
  ConsumerState<CloudProviderSetupScreen> createState() => _CloudProviderSetupScreenState();
}

class _CloudProviderSetupScreenState extends ConsumerState<CloudProviderSetupScreen> {
  bool _isLoading = false;

  Future<void> _connectGoogleDrive() async {
    setState(() => _isLoading = true);

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
        // Onboarding complete, go to vault
        context.go('/vault');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup'),
        actions: [
          TextButton(
            onPressed: () => context.go('/vault'),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.cloud_sync,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 32),
              Text(
                'Never Lose Your Vault',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Link a cloud provider to securely back up your encrypted vault. (You can also do this later in Settings)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Google Drive Option
              ListTile(
                leading: const Icon(Icons.add_to_drive, color: Colors.blueAccent, size: 36),
                title: const Text('Google Drive', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Uses hidden app data folder'),
                trailing: _isLoading 
                  ? const CircularProgressIndicator() 
                  : ElevatedButton(
                      onPressed: _connectGoogleDrive,
                      child: const Text('Connect'),
                    ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              
              const SizedBox(height: 16),
              
              // Dropbox Option
              ListTile(
                leading: const Icon(Icons.cloud, color: Colors.blue, size: 36),
                title: const Text('Dropbox', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Coming soon'),
                trailing: const ElevatedButton(
                  onPressed: null,
                  child: Text('Connect'),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),

              const Spacer(),
              SizedBox(
                height: 56,
                child: TextButton(
                  onPressed: () => context.go('/vault'),
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
