import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../data/local_vault_repository.dart';
import '../domain/encryption_use_case.dart';
import '../domain/vault_item_entity.dart';
import '../../auth/data/auth_repository.dart';

final vaultListProvider = AsyncNotifierProvider.autoDispose<VaultAsyncNotifier, List<VaultItemEntity>>(VaultAsyncNotifier.new);

class VaultAsyncNotifier extends AutoDisposeAsyncNotifier<List<VaultItemEntity>> {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  @override
  Future<List<VaultItemEntity>> build() async {
    final localRepo = ref.read(localVaultRepositoryProvider);
    return await localRepo.getMediaItems();
  }

  Future<void> importPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final encUseCase = ref.read(encryptionUseCaseProvider);
    final authRepo = ref.read(authRepositoryProvider);
    final localRepo = ref.read(localVaultRepositoryProvider);

    final masterKeyBytes = await authRepo.getMasterKey();
    if (masterKeyBytes == null) throw Exception("Master key not found in storage");
    final masterKey = await encUseCase.importMasterKey(masterKeyBytes);

    final encryptionResult = await encUseCase.encryptDataWithCek(bytes.toList(), masterKey);
    final fileName = '${_uuid.v4()}.enc';
    final savedPath = await localRepo.saveEncryptedFile(encryptionResult.encryptedDataBlob, fileName);
    
    await localRepo.insertMediaItem(
      image.name, 
      savedPath, 
      'image', 
      bytes.length,
      encryptionResult.wrappedContentKey,
      encryptionResult.iv,
    );

    ref.invalidateSelf();
  }
}
