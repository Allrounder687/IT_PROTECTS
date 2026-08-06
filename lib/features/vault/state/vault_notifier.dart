import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/security/lifecycle_cleanup_manager.dart';
import '../data/local_vault_repository.dart';
import '../domain/encryption_use_case.dart';
import '../domain/vault_item_entity.dart';
import '../../providers/domain/sync_job.dart';
import '../../settings/state/settings_providers.dart';
import '../../providers/state/sync_status_notifier.dart';
import '../../../core/providers/session_provider.dart';

import '../domain/migration_use_case.dart';

final vaultListProvider = AsyncNotifierProvider.autoDispose<VaultAsyncNotifier, List<VaultItemEntity>>(VaultAsyncNotifier.new);

class VaultAsyncNotifier extends AutoDisposeAsyncNotifier<List<VaultItemEntity>> {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<VaultItemEntity>> build() async {
    final migration = ref.read(migrationUseCaseProvider);
    await migration.migrateOldImages();

    final localRepo = ref.read(localVaultRepositoryProvider);
    return await localRepo.getMediaItems();
  }

  Future<void> importPhoto() async {
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
    
    final id = await localRepo.insertMediaItem(
      image.name, 
      savedPath, 
      'image', 
      bytes.length,
      encryptionResult.wrappedContentKey,
      encryptionResult.iv,
    );
    
    final cloudSettings = ref.read(cloudSyncSettingsProvider);
    if (cloudSettings.defaultProviderId != null && cloudSettings.defaultProviderId!.isNotEmpty) {
      final job = SyncJob(
        itemId: id,
        operation: SyncOperation.upload,
        targetProviderId: cloudSettings.defaultProviderId!,
        createdAt: DateTime.now(),
      );
      await localRepo.enqueueSyncJob(job);
      ref.read(syncStatusProvider.notifier).markAsQueued();
    }

    ref.invalidateSelf();
  }
}
