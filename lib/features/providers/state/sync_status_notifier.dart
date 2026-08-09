import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'active_provider_notifier.dart';
import '../domain/sync_job.dart';
import '../../albums/data/albums_repository.dart';
import '../../../core/providers/auth_mode_provider.dart';
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

class SyncStatus {
  final SyncState state;
  final int pendingCount;
  final int errorCount;
  final int uploadedCount;
  final DateTime? lastSyncTime;

  const SyncStatus({
    this.state = SyncState.idle,
    this.pendingCount = 0,
    this.errorCount = 0,
    this.uploadedCount = 0,
    this.lastSyncTime,
  });

  SyncStatus copyWith({
    SyncState? state,
    int? pendingCount,
    int? errorCount,
    int? uploadedCount,
    DateTime? lastSyncTime,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      pendingCount: pendingCount ?? this.pendingCount,
      errorCount: errorCount ?? this.errorCount,
      uploadedCount: uploadedCount ?? this.uploadedCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

final syncStatusProvider = AsyncNotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);

class SyncStatusNotifier extends AsyncNotifier<SyncStatus> {
  bool _isProcessing = false;
  
  @override
  Future<SyncStatus> build() async {
    return await _fetchCounts(const SyncStatus());
  }

  Future<SyncStatus> _fetchCounts(SyncStatus currentStatus) async {
    try {
      final repo = ref.read(localVaultRepositoryProvider);
      final authMode = ref.read(authModeProvider);
      // Fast count query
      final db = await repo.getDatabase(authMode);
      final pendingRes = await db.rawQuery('SELECT COUNT(*) FROM sync_queue WHERE retry_count = 0');
      final errorRes = await db.rawQuery('SELECT COUNT(*) FROM sync_queue WHERE retry_count > 0');
      final uploadedRes = await db.rawQuery('SELECT COUNT(*) FROM media_items WHERE remote_id IS NOT NULL');
      final pendingCount = (pendingRes.isNotEmpty && pendingRes.first.values.first != null) ? pendingRes.first.values.first as int : 0;
      final errorCount = (errorRes.isNotEmpty && errorRes.first.values.first != null) ? errorRes.first.values.first as int : 0;
      final uploadedCount = (uploadedRes.isNotEmpty && uploadedRes.first.values.first != null) ? uploadedRes.first.values.first as int : 0;
      return currentStatus.copyWith(pendingCount: pendingCount, errorCount: errorCount, uploadedCount: uploadedCount);
    } catch (e) {
      return currentStatus;
    }
  }

  void markAsQueued() async {
    if (state.valueOrNull?.state != SyncState.syncingUp) {
      final updatedStatus = await _fetchCounts(state.valueOrNull ?? const SyncStatus());
      state = AsyncData(updatedStatus.copyWith(state: SyncState.queued));
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
      final status = await _fetchCounts(state.valueOrNull ?? const SyncStatus());
      state = AsyncData(status.copyWith(state: SyncState.idle));
      return;
    }

    try {
      final isAuthed = await provider.isAuthenticated();
      if (!isAuthed) {
        final status = await _fetchCounts(state.valueOrNull ?? const SyncStatus());
        state = AsyncData(status.copyWith(state: SyncState.error));
        return;
      }

      _isProcessing = true;
      final status = await _fetchCounts(state.valueOrNull ?? const SyncStatus());
      state = AsyncData(status.copyWith(state: SyncState.syncingUp));
      
      final repo = ref.read(localVaultRepositoryProvider);
      final authMode = ref.read(authModeProvider);
      
      while (true) {
        final jobs = await repo.getPendingSyncJobs(limit: 5, authMode: authMode);
        if (jobs.isEmpty) break;

        for (final job in jobs) {
          try {
            if (job.operation == SyncOperation.upload) {
              // Simulate API call to upload blob
              await Future.delayed(const Duration(milliseconds: 800)); 
              await repo.deleteSyncJob(job.id!, authMode: authMode);
            } else {
              // Handle delete/update
              await repo.deleteSyncJob(job.id!, authMode: authMode);
            }
          } catch (e) {
            await repo.updateSyncJobError(job.id!, job.retryCount + 1, e.toString(), authMode: authMode);
          }
        }
        
        // Update counts visually during batch processing
        final updatedStatus = await _fetchCounts(state.valueOrNull ?? const SyncStatus());
        state = AsyncData(updatedStatus.copyWith(state: SyncState.syncingUp));
      }
      
      final finalStatus = await _fetchCounts(state.valueOrNull ?? const SyncStatus());
      state = AsyncData(finalStatus.copyWith(state: SyncState.idle, lastSyncTime: DateTime.now()));
    } catch (e, stack) {
      state = AsyncError(e, stack);
    } finally {
      _isProcessing = false;
    }
  }
}
