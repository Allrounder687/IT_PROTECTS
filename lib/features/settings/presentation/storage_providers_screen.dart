import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      bool dialogShown = false;
      
      await repo.authenticate(
        onDeviceCodePrompt: (url, code) {
          dialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Center(child: Text('Device Pairing')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Please visit this URL on your phone or computer:', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  SelectableText(url, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  const SizedBox(height: 24),
                  const Text('And enter the following code:', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SelectableText(
                      code,
                      style: TextStyle(
                        fontSize: 32,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Waiting for authorization...'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Just hides UI; the background poll might eventually timeout
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }
      );
      
      if (dialogShown && mounted) {
        Navigator.of(context).pop(); // Dismiss the pairing dialog
      }
      
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
              _buildProviderCard(
                id: 'google_drive',
                name: 'Google Drive',
                icon: Icons.add_to_drive,
                color: Colors.blueAccent,
                activeProviderId: activeProviderId,
                isConnected: true, // Mocking connected state for UI visualization
                usedBytes: 12.5 * 1024 * 1024 * 1024,
                totalBytes: 15.0 * 1024 * 1024 * 1024,
                onConnect: _connectGoogleDrive,
                onDisconnect: _disconnectProvider,
              ),
              const SizedBox(height: 16),
              _buildProviderCard(
                id: 'dropbox',
                name: 'Dropbox',
                icon: Icons.cloud,
                color: Colors.blue,
                activeProviderId: activeProviderId,
                isConnected: false,
                usedBytes: 0,
                totalBytes: 2.0 * 1024 * 1024 * 1024,
                onConnect: null,
                onDisconnect: null,
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildProviderCard({
    required String id,
    required String name,
    required IconData icon,
    required Color color,
    required String? activeProviderId,
    required bool isConnected,
    required double usedBytes,
    required double totalBytes,
    required VoidCallback? onConnect,
    required VoidCallback? onDisconnect,
  }) {
    final isDefault = activeProviderId == id;
    final usagePercent = totalBytes > 0 ? usedBytes / totalBytes : 0.0;
    final usedGB = (usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
    final totalGB = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

    return Card(
      elevation: isDefault ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isDefault ? BorderSide(color: color, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isConnected ? () {
          context.push('/settings/providers/$id');
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          isConnected ? 'Linked' : 'Not Linked',
                          style: TextStyle(
                            color: isConnected ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isConnected && isDefault)
                    const Icon(Icons.star, color: Colors.amber),
                ],
              ),
              const SizedBox(height: 24),
              if (isConnected) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Storage Usage', style: Theme.of(context).textTheme.bodySmall),
                    Text('$usedGB GB / $totalGB GB', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: usagePercent,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    usagePercent > 0.9 ? Colors.redAccent : color,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isConnected) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.link_off, color: Colors.redAccent),
                      label: const Text('Unlink', style: TextStyle(color: Colors.redAccent)),
                      onPressed: onDisconnect,
                    ),
                    if (!isDefault)
                      ElevatedButton(
                        onPressed: () {
                           ref.read(cloudSyncSettingsProvider.notifier).setDefaultProvider(id);
                        },
                        child: const Text('Set Default'),
                      ),
                  ] else ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Connect'),
                      onPressed: onConnect,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
