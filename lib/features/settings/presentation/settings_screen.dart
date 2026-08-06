import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/settings_providers.dart';
import '../domain/settings_models.dart';
import '../../../core/presentation/responsive_config.dart';
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/presentation/components/settings_group_header.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final security = ref.watch(securitySettingsProvider);
    final cloud = ref.watch(cloudSyncSettingsProvider);
    final playback = ref.watch(playbackPrivacySettingsProvider);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ResponsiveConfig.buildConstrainedBody(
        child: ListView(
          children: [
            const SettingsGroupHeader(title: 'Storage & Management'),
            ListTile(
              leading: const Icon(Icons.storage, color: AppTheme.primary),
              title: const Text('Space Saver'),
              subtitle: const Text('Manage local vs cloud storage'),
              onTap: () => context.push('/settings/space-saver'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.primary),
              title: const Text('Trash'),
              subtitle: const Text('Recently deleted items'),
              onTap: () => context.push('/settings/trash'),
            ),
            const Divider(),
            const SettingsGroupHeader(title: 'Security'),
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
              onTap: () => context.push('/settings/change-pin'),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.screen_lock_portrait),
              title: const Text('Face-down auto lock'),
              subtitle: const Text('Instantly lock vault when phone is face down'),
              value: security.faceDownLockEnabled,
              onChanged: (v) => ref.read(securitySettingsProvider.notifier).toggleFaceDownLock(v),
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
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined, color: Colors.redAccent),
              title: const Text('Intruder Alerts & Logs'),
              subtitle: const Text('View failed unlock attempts'),
              onTap: () => context.push('/settings/intruder-logs'),
            ),
            const Divider(),
            const SettingsGroupHeader(title: 'Cloud Sync'),
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
            const SettingsGroupHeader(title: 'Playback & Privacy'),
            ListTile(
              leading: const Icon(Icons.ondemand_video),
              title: const Text('Playback Mode'),
              subtitle: Text(playback.playbackMode.name.toUpperCase()),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Playback Mode'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Immersive'),
                            subtitle: const Text('Full screen, no metadata overlays.'),
                            trailing: playback.playbackMode == PlaybackMode.immersive ? const Icon(Icons.check, color: AppTheme.primary) : null,
                            onTap: () {
                              ref.read(playbackPrivacySettingsProvider.notifier).setPlaybackMode(PlaybackMode.immersive);
                              context.pop();
                            },
                          ),
                          ListTile(
                            title: const Text('Safe'),
                            subtitle: const Text('Time-limited sharing and badges enabled.'),
                            trailing: playback.playbackMode == PlaybackMode.safe ? const Icon(Icons.check, color: AppTheme.primary) : null,
                            onTap: () {
                              ref.read(playbackPrivacySettingsProvider.notifier).setPlaybackMode(PlaybackMode.safe);
                              context.pop();
                            },
                          ),
                          ListTile(
                            title: const Text('Minimal'),
                            subtitle: const Text('Basic controls, high performance.'),
                            trailing: playback.playbackMode == PlaybackMode.minimal ? const Icon(Icons.check, color: AppTheme.primary) : null,
                            onTap: () {
                              ref.read(playbackPrivacySettingsProvider.notifier).setPlaybackMode(PlaybackMode.minimal);
                              context.pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
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
