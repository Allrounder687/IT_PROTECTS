import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/security/lifecycle_cleanup_manager.dart';
import '../data/local_vault_repository.dart';
import '../domain/encryption_use_case.dart';
import '../domain/vault_item_entity.dart';
import '../../providers/domain/sync_job.dart';
import '../../settings/state/settings_providers.dart';
import '../../providers/state/sync_status_notifier.dart';
import '../../../core/providers/session_provider.dart';
import '../../documents/domain/document_template.dart';

import '../domain/migration_use_case.dart';
import '../../../core/providers/auth_mode_provider.dart';

final vaultListProvider = AsyncNotifierProvider.autoDispose<VaultAsyncNotifier, List<VaultItemEntity>>(VaultAsyncNotifier.new);

final coverItemProvider = FutureProvider.family<VaultItemEntity?, int>((ref, coverItemId) async {
  final repo = ref.read(localVaultRepositoryProvider);
  final authMode = ref.watch(authModeProvider);
  return await repo.getMediaItem(coverItemId, authMode: authMode);
});

class VaultAsyncNotifier extends AutoDisposeAsyncNotifier<List<VaultItemEntity>> {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<VaultItemEntity>> build() async {
    final migration = ref.read(migrationUseCaseProvider);
    try {
      await migration.migrateOldImages();
    } catch (e) {
      // Ignore migration errors so they don't break the whole vault
      debugPrint('Vault migration error: $e');
    }

    final authMode = ref.watch(authModeProvider);
    final localRepo = ref.read(localVaultRepositoryProvider);
    return await localRepo.getMediaItems(authMode: authMode);
  }

  Future<void> importPhoto({int? albumId}) async {
    ref.read(ignoreLifecycleLockProvider.notifier).state = true;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      ref.read(ignoreLifecycleLockProvider.notifier).state = false;
      return;
    }

    final bytes = await image.readAsBytes();
    final encUseCase = ref.read(encryptionUseCaseProvider);
    final localRepo = ref.read(localVaultRepositoryProvider);

    final masterKeyBytes = ref.read(sessionProvider);
    if (masterKeyBytes == null) throw Exception("Master key not found in session");
    final masterKey = await encUseCase.importMasterKey(masterKeyBytes);

    final encryptionResult = await encUseCase.encryptDataWithCek(bytes.toList(), masterKey);
    final fileName = '${_uuid.v4()}.enc';
    final savedPath = await localRepo.saveEncryptedFile(encryptionResult.encryptedDataBlob, fileName);
    
    final authMode = ref.read(authModeProvider);
    final id = await localRepo.insertMediaItem(
      image.name, 
      savedPath, 
      'image', 
      bytes.length,
      encryptionResult.wrappedContentKey,
      encryptionResult.iv,
      albumId: albumId,
      authMode: authMode,
    );
    
    final cloudSettings = ref.read(cloudSyncSettingsProvider);
    if (cloudSettings.defaultProviderId != null && cloudSettings.defaultProviderId!.isNotEmpty) {
      final job = SyncJob(
        itemId: id,
        operation: SyncOperation.upload,
        targetProviderId: cloudSettings.defaultProviderId!,
        createdAt: DateTime.now(),
      );
      await localRepo.enqueueSyncJob(job, authMode: authMode);
      ref.read(syncStatusProvider.notifier).markAsQueued();
    }

    ref.invalidateSelf();
  }

  Future<void> importDocument({
    int? albumId,
    required DocumentTemplate template,
    String? filePath,
  }) async {
    final encUseCase = ref.read(encryptionUseCaseProvider);
    final localRepo = ref.read(localVaultRepositoryProvider);
    final masterKeyBytes = ref.read(sessionProvider);
    if (masterKeyBytes == null) throw Exception("Master key not found in session");
    final masterKey = await encUseCase.importMasterKey(masterKeyBytes);

    List<int> fileBytes = [];
    String originalName = template.title;
    String type = 'document';

    if (filePath != null) {
      final file = XFile(filePath);
      fileBytes = await file.readAsBytes();
      originalName = file.name;
    }

    // Encrypt file if attached, otherwise just create an empty CEK encryption
    final encryptionResult = await encUseCase.encryptDataWithCek(fileBytes, masterKey);
    
    String savedPath = '';
    if (fileBytes.isNotEmpty) {
      final fileName = '${_uuid.v4()}.enc';
      savedPath = await localRepo.saveEncryptedFile(encryptionResult.encryptedDataBlob, fileName);
    }

    final jsonStr = template.toJsonString();
    final encryptedMetadata = await encUseCase.encryptMetadata(jsonStr, masterKey);
    
    final authMode = ref.read(authModeProvider);
    final id = await localRepo.insertMediaItem(
      originalName, 
      savedPath, 
      type, 
      fileBytes.length,
      encryptionResult.wrappedContentKey,
      encryptionResult.iv,
      albumId: albumId,
      authMode: authMode,
      encryptedMetadata: encryptedMetadata,
    );
    
    final cloudSettings = ref.read(cloudSyncSettingsProvider);
    if (cloudSettings.defaultProviderId != null && cloudSettings.defaultProviderId!.isNotEmpty) {
      final job = SyncJob(
        itemId: id,
        operation: SyncOperation.upload,
        targetProviderId: cloudSettings.defaultProviderId!,
        createdAt: DateTime.now(),
      );
      await localRepo.enqueueSyncJob(job, authMode: authMode);
      ref.read(syncStatusProvider.notifier).markAsQueued();
    }

    ref.invalidateSelf();
  }
}
