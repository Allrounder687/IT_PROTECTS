import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'active_provider_notifier.dart';
import '../domain/sync_job.dart';
import '../../vault/data/local_vault_repository.dart';
import '../../settings/state/settings_providers.dart';

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
  bool _isProcessing = false;
  @override
  Future<SyncState> build() async {
    // Optionally check if there are pending jobs on startup.
    return SyncState.idle;
  }

  void markAsQueued() {
    if (state.valueOrNull != SyncState.syncingUp) {
      state = const AsyncData(SyncState.queued);
    }
    _attemptSync();
  }

  Future<void> _attemptSync() async {
    if (_isProcessing) return;

    final cloudSettings = ref.read(cloudSyncSettingsProvider);
    if (!cloudSettings.autoSyncEnabled) {
      return;
    }

    final provider = ref.read(activeCloudProvider);
    if (provider == null) {
      state = const AsyncData(SyncState.idle);
      return;
    }

    try {
      final isAuthed = await provider.isAuthenticated();
      if (!isAuthed) {
        state = const AsyncData(SyncState.error);
        return;
      }

      _isProcessing = true;
      state = const AsyncData(SyncState.syncingUp);
      
      final repo = ref.read(localVaultRepositoryProvider);
      
      while (true) {
        final jobs = await repo.getPendingSyncJobs(limit: 5);
        if (jobs.isEmpty) break;

        for (final job in jobs) {
          try {
            if (job.operation == SyncOperation.upload) {
              // We need the file bytes. Let's mock the byte reading for the real structure
              // In a real app we query media_items, read the file, and upload.
              // For IT_PROTECTS architecture demo, we will simulate the file upload call
              // to the provider.
              
              // Simulate API call to upload blob
              await Future.delayed(const Duration(milliseconds: 800)); 
              // await provider.uploadBlob(bytes, "enc_file_${job.itemId}");
              
              await repo.deleteSyncJob(job.id!);
            } else {
              // Handle delete/update
              await repo.deleteSyncJob(job.id!);
            }
          } catch (e) {
            await repo.updateSyncJobError(job.id!, job.retryCount + 1, e.toString());
          }
        }
      }
      
      state = const AsyncData(SyncState.idle);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    } finally {
      _isProcessing = false;
    }
  }
}
