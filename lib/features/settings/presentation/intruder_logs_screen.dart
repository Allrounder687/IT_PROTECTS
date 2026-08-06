import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/presentation/components/custom_app_bar.dart';
import '../../../core/theme/app_theme.dart';
import '../state/intruder_log_provider.dart';
import '../state/settings_providers.dart';

class IntruderLogsScreen extends ConsumerWidget {
  const IntruderLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(intruderLogProvider);
    final securitySettings = ref.watch(securitySettingsProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Intruder Alerts',
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Logs',
              onPressed: () {
                ref.read(intruderLogProvider.notifier).clearLogs();
              },
            ),
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Export Logs',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logs exported')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.camera_front),
            title: const Text('Intruder Photos'),
            subtitle: const Text('Silently capture photo on failed unlock'),
            value: securitySettings.intruderPhotosEnabled,
            onChanged: (val) {
              ref.read(securitySettingsProvider.notifier).toggleIntruderPhotos(val);
            },
          ),
          const Divider(),
          if (logs.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No intrusion attempts recorded.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: log.photoPath != null
                          ? const Icon(Icons.face, color: Colors.grey) // Mock image loading
                          : const Icon(Icons.no_photography, color: Colors.grey),
                    ),
                    title: Text(
                      'Failed Attempt',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(timeago.format(log.timestamp)),
                        Text('${log.deviceOs} • ${log.location ?? 'Unknown location'}'),
                      ],
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
