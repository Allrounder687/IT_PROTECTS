import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/viewer/data/temporary_file_manager.dart';

class LifecycleCleanupManager extends ConsumerStatefulWidget {
  final Widget child;

  const LifecycleCleanupManager({super.key, required this.child});

  @override
  ConsumerState<LifecycleCleanupManager> createState() => _LifecycleCleanupManagerState();
}

class _LifecycleCleanupManagerState extends ConsumerState<LifecycleCleanupManager> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      
      // Aggressively wipe temporary cache when app is backgrounded or locked
      final tempManager = ref.read(temporaryFileManagerProvider);
      tempManager.wipeAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
