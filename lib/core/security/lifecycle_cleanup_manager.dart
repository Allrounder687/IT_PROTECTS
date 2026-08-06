import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/viewer/data/temporary_file_manager.dart';
import '../../features/auth/state/auth_notifier.dart';
import '../../features/settings/state/settings_providers.dart';
import 'sensor_service.dart';

final ignoreLifecycleLockProvider = StateProvider<bool>((ref) => false);

class LifecycleCleanupManager extends ConsumerStatefulWidget {
  final Widget child;

  const LifecycleCleanupManager({super.key, required this.child});

  @override
  ConsumerState<LifecycleCleanupManager> createState() => _LifecycleCleanupManagerState();
}

class _LifecycleCleanupManagerState extends ConsumerState<LifecycleCleanupManager> with WidgetsBindingObserver {
  StreamSubscription<bool>? _faceDownSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    final sensorService = ref.read(sensorServiceProvider);
    sensorService.startListening();
    
    _faceDownSubscription = sensorService.faceDownStream.listen((isFaceDown) {
      if (isFaceDown) {
        final settings = ref.read(securitySettingsProvider);
        if (settings.faceDownLockEnabled) {
          ref.read(authNotifierProvider.notifier).lockVault();
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _faceDownSubscription?.cancel();
    ref.read(sensorServiceProvider).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Always reset the ignore flag when the app resumes
      ref.read(ignoreLifecycleLockProvider.notifier).state = false;
      return;
    }

    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      
      final isIgnored = ref.read(ignoreLifecycleLockProvider);
      if (isIgnored) {
        return; // Don't lock, an intentional system dialog is open
      }
      
      // Aggressively wipe temporary cache when app is backgrounded
      final tempManager = ref.read(temporaryFileManagerProvider);
      tempManager.wipeAll();
      
      // Lock vault when backgrounded
      ref.read(authNotifierProvider.notifier).lockVault();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
