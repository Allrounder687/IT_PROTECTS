import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'sync_panel_sheet.dart';

enum SyncState { idle, syncing, error }

final syncStateProvider = StateProvider<SyncState>((ref) => SyncState.idle);

class SyncIndicatorWidget extends ConsumerWidget {
  const SyncIndicatorWidget({super.key});

  void _showSyncPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SyncPanelSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);

    Widget icon;
    switch (syncState) {
      case SyncState.idle:
        icon = const Icon(Icons.cloud_done_outlined, color: Colors.green, size: 24);
        break;
      case SyncState.syncing:
        icon = const Icon(Icons.sync, color: Colors.blueAccent, size: 24)
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 2.seconds);
        break;
      case SyncState.error:
        icon = const Icon(Icons.cloud_off, color: Colors.redAccent, size: 24);
        break;
    }

    return IconButton(
      icon: icon,
      tooltip: 'Sync Status',
      onPressed: () => _showSyncPanel(context),
    );
  }
}
