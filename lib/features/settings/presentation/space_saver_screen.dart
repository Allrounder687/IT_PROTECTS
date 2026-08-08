import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_mode_provider.dart';
import '../../vault/data/local_vault_repository.dart';

class SpaceSaverScreen extends ConsumerStatefulWidget {
  const SpaceSaverScreen({super.key});

  @override
  ConsumerState<SpaceSaverScreen> createState() => _SpaceSaverScreenState();
}

class _SpaceSaverScreenState extends ConsumerState<SpaceSaverScreen> {
  bool _spaceSaverEnabled = false;
  Map<String, int>? _storageStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final repo = ref.read(localVaultRepositoryProvider);
    final authMode = ref.read(authModeProvider);
    final stats = await repo.getStorageStats(authMode);
    if (mounted) {
      setState(() {
        _storageStats = stats;
        _isLoadingStats = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Space Saver'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Enable Space Saver',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: _spaceSaverEnabled,
                      activeTrackColor: AppTheme.primary.withValues(alpha: 0.5),
                      activeThumbColor: AppTheme.primary,
                      onChanged: (val) {
                        setState(() {
                          _spaceSaverEnabled = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'When enabled, original high-resolution photos and videos are backed up to your cloud provider, and compressed versions are kept locally to save device storage.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Storage Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (_isLoadingStats)
            const Center(child: CircularProgressIndicator())
          else ...[
            ListTile(
              leading: const Icon(Icons.cloud_done, color: AppTheme.primary),
              title: const Text('Backed up originals'),
              trailing: Text(_formatBytes(_storageStats?['totalOriginal'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.green),
              title: const Text('Local encrypted copies'),
              trailing: Text(
                _spaceSaverEnabled 
                    ? _formatBytes(((_storageStats?['totalOriginal'] ?? 0) * 0.2).toInt())
                    : _formatBytes((_storageStats?['totalOriginal'] ?? 0) + ((_storageStats?['itemCount'] ?? 0) * 28)), 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Free Up Space Now'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _spaceSaverEnabled
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Compressing ${_storageStats?['itemCount'] ?? 0} eligible items...')),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
