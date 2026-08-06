import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/domain/encryption_use_case.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../../../core/providers/session_provider.dart';

final decryptedItemProvider = AsyncNotifierProvider.family.autoDispose<ViewerAsyncNotifier, Uint8List, VaultItemEntity>(ViewerAsyncNotifier.new);

class ViewerAsyncNotifier extends AutoDisposeFamilyAsyncNotifier<Uint8List, VaultItemEntity> {
  @override
  Future<Uint8List> build(VaultItemEntity arg) async {
    final file = File(arg.encryptedFilePath);
    if (!await file.exists()) throw Exception('File not found');

    final encryptedBytes = await file.readAsBytes();
    
    final encUseCase = ref.read(encryptionUseCaseProvider);

    final masterKeyBytes = ref.read(sessionProvider);
    if (masterKeyBytes == null) throw Exception("Master key not found");
    
    final masterKey = await encUseCase.importMasterKey(masterKeyBytes);
    final decryptedBytes = await encUseCase.decryptDataWithCek(
      encryptedBytes.toList(), 
      arg.wrappedContentKey, 
      arg.iv, 
      masterKey
    );
    
    return Uint8List.fromList(decryptedBytes);
  }
}
