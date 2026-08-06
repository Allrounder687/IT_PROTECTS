import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/settings_providers.dart';
import '../../../core/presentation/responsive_config.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securitySettingsProvider);
    final cloud = ref.watch(cloudSyncSettingsProvider);
    final playback = ref.watch(playbackPrivacySettingsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ResponsiveConfig.buildConstrainedBody(
        child: ListView(
          children: [
            const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Security', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Biometric unlock'),
            value: security.biometricEnabled,
            onChanged: (v) => ref.read(securitySettingsProvider.notifier).toggleBiometric(v),
          ),
          ListTile(
            leading: const Icon(Icons.password),
            title: const Text('Change Master PIN'),
            subtitle: const Text('Update your primary unlock code'),
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.security),
            title: const Text('Decoy Vault'),
            subtitle: const Text('Configure fake PIN and decoy storage'),
            value: security.decoyVaultEnabled,
            onChanged: (v) {
              if (v) {
                context.push('/settings/setup-decoy');
              } else {
                ref.read(securitySettingsProvider.notifier).toggleDecoyVault(false);
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Cloud Sync', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('Auto sync'),
            value: cloud.autoSyncEnabled,
            onChanged: (v) => ref.read(cloudSyncSettingsProvider.notifier).toggleAutoSync(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: const Text('Wi-Fi only sync'),
            value: cloud.wifiOnlySync,
            onChanged: (v) => ref.read(cloudSyncSettingsProvider.notifier).toggleWifiOnly(v),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Storage Providers'),
            subtitle: Text(cloud.defaultProviderId?.isNotEmpty == true ? cloud.defaultProviderId! : 'None'),
            onTap: () {
              context.push('/settings/providers');
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Playback & Privacy', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.ondemand_video),
            title: const Text('Playback Mode'),
            subtitle: Text(playback.playbackMode.name),
            onTap: () {},
          ),
          SwitchListTile(
            secondary: const Icon(Icons.title),
            title: const Text('Show filenames'),
            value: playback.showFilenames,
            onChanged: (v) => ref.read(playbackPrivacySettingsProvider.notifier).toggleShowFilenames(v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.info_outline),
            title: const Text('Show metadata'),
            value: playback.showMetadata,
            onChanged: (v) => ref.read(playbackPrivacySettingsProvider.notifier).toggleShowMetadata(v),
          ),
        ],
      ),
    ));
  }
}
