import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'active_provider_notifier.dart';

enum SyncState {
  idle,
  queued,
  syncingUp,
  syncingDown,
  conflictResolution,
  error,
}

final syncStatusProvider = AsyncNotifierProvider<SyncStatusNotifier, SyncState>(SyncStatusNotifier.new);

class SyncStatusNotifier extends AsyncNotifier<SyncState> {
  @override
  Future<SyncState> build() async {
    return SyncState.idle;
  }

  /// Triggered when the local vault makes a change (importing a photo).
  void markAsQueued() {
    state = const AsyncData(SyncState.queued);
    _attemptSync();
  }

  Future<void> _attemptSync() async {
    final provider = ref.read(activeCloudProvider);
    if (provider == null) {
      // No provider linked, remain queued or go idle
      state = const AsyncData(SyncState.idle);
      return;
    }

    try {
      final isAuthed = await provider.isAuthenticated();
      if (!isAuthed) {
        state = const AsyncData(SyncState.error);
        return;
      }

      state = const AsyncData(SyncState.syncingUp);
      
      // In a full implementation, we would query the local SQLite DB 
      // for the `sync_queue` table and process the blobs.
      await Future.delayed(const Duration(seconds: 2)); // Mocking upload time
      
      state = const AsyncData(SyncState.idle);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
