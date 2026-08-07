import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/data/google_drive_repository.dart';
import '../../providers/data/dropbox_repository.dart';
import '../../providers/data/onedrive_repository.dart';
import '../../providers/domain/storage_provider.dart';
import '../../providers/state/active_provider_notifier.dart';
import '../../../core/security/lifecycle_cleanup_manager.dart';
import '../state/settings_providers.dart';
import '../../../core/presentation/responsive_config.dart';

final googleDriveRepoProvider = Provider((ref) => GoogleDriveRepository());
final dropboxRepoProvider = Provider((ref) => DropboxRepository());
final oneDriveRepoProvider = Provider((ref) => OneDriveRepository());

class StorageProvidersScreen extends ConsumerStatefulWidget {
  const StorageProvidersScreen({super.key});

  @override
  ConsumerState<StorageProvidersScreen> createState() => _StorageProvidersScreenState();
}

class _StorageProvidersScreenState extends ConsumerState<StorageProvidersScreen> {
  bool _isLoading = false;
  String? _error;
  
  final Map<String, bool> _connectedState = {};
  final Map<String, double> _usedBytes = {};
  final Map<String, double> _totalBytes = {};

  @override
  void initState() {
    super.initState();
    _loadAllStates();
  }

  Future<void> _loadAllStates() async {
    await Future.wait([
      _loadState(ref.read(googleDriveRepoProvider), 'google_drive'),
      _loadState(ref.read(dropboxRepoProvider), 'dropbox'),
      _loadState(ref.read(oneDriveRepoProvider), 'onedrive'),
    ]);
  }

  Future<void> _loadState(StorageProvider repo, String id) async {
    try {
      final isAuth = await repo.isAuthenticated();
      if (isAuth && mounted) {
        setState(() {
          _connectedState[id] = true;
        });
        
        try {
          final quota = await repo.getQuota();
          if (mounted) {
            setState(() {
              _usedBytes[id] = quota['used']?.toDouble() ?? 0.0;
              _totalBytes[id] = quota['total']?.toDouble() ?? 0.0;
            });
          }
        } catch (e) {
          // Ignore quota errors (OneDrive AppFolder scope might block drive root access)
        }
      }
    } catch (_) {}
  }

  Future<void> _connectProvider(String providerId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = providerId == 'google_drive' 
          ? ref.read(googleDriveRepoProvider) 
          : providerId == 'dropbox'
              ? ref.read(dropboxRepoProvider)
              : ref.read(oneDriveRepoProvider);
          
      bool dialogShown = false;
      
      ref.read(ignoreLifecycleLockProvider.notifier).state = true;
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
      ref.read(cloudSyncSettingsProvider.notifier).setDefaultProvider(providerId);
      
      if (mounted) {
        await _loadState(repo, providerId); // Load real state after connect
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully connected to ${providerId == "google_drive" ? "Google Drive" : providerId == "dropbox" ? "Dropbox" : "OneDrive"}')),
          );
        }
      }
    } catch (e) {
      ref.read(ignoreLifecycleLockProvider.notifier).state = false;
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
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
                isConnected: _connectedState['google_drive'] == true,
                usedBytes: _usedBytes['google_drive'] ?? 0,
                totalBytes: _totalBytes['google_drive'] ?? 0,
                onConnect: () => _connectProvider('google_drive'),
                onDisconnect: _disconnectProvider,
              ),
              const SizedBox(height: 16),
              _buildProviderCard(
                id: 'dropbox',
                name: 'Dropbox',
                icon: Icons.cloud,
                color: Colors.blue,
                activeProviderId: activeProviderId,
                isConnected: _connectedState['dropbox'] == true,
                usedBytes: _usedBytes['dropbox'] ?? 0,
                totalBytes: _totalBytes['dropbox'] ?? 0,
                onConnect: () => _connectProvider('dropbox'),
                onDisconnect: _disconnectProvider,
              ),
              const SizedBox(height: 16),
              _buildProviderCard(
                id: 'onedrive',
                name: 'Microsoft OneDrive',
                icon: Icons.window,
                color: Colors.lightBlue,
                activeProviderId: activeProviderId,
                isConnected: _connectedState['onedrive'] == true,
                usedBytes: _usedBytes['onedrive'] ?? 0,
                totalBytes: _totalBytes['onedrive'] ?? 0,
                onConnect: () => _connectProvider('onedrive'),
                onDisconnect: _disconnectProvider,
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
                    Text(totalBytes < 0 ? '$usedGB GB Used' : '$usedGB GB / $totalGB GB', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                if (totalBytes >= 0) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: usagePercent,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usagePercent > 0.9 ? Colors.redAccent : color,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
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
                      onPressed: _isLoading ? null : onConnect,
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
