import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';

class SpaceSaverScreen extends ConsumerStatefulWidget {
  const SpaceSaverScreen({super.key});

  @override
  ConsumerState<SpaceSaverScreen> createState() => _SpaceSaverScreenState();
}

class _SpaceSaverScreenState extends ConsumerState<SpaceSaverScreen> {
  bool _spaceSaverEnabled = false;

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
          ListTile(
            leading: const Icon(Icons.cloud_done, color: AppTheme.primary),
            title: const Text('Backed up originals'),
            trailing: const Text('12.4 GB', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.phone_android, color: Colors.green),
            title: const Text('Local compressed copies'),
            trailing: const Text('1.1 GB', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
                      const SnackBar(content: Text('Compressing 45 eligible items...')),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
