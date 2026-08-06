import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../data/temporary_file_manager.dart';
import '../../vault/domain/encryption_use_case.dart';
import '../../../core/providers/session_provider.dart';

final playbackSessionProvider = FutureProvider.family.autoDispose<SecurePlaybackSession, VaultItemEntity>((ref, item) async {
  final tempManager = ref.read(temporaryFileManagerProvider);
  final encUseCase = ref.read(encryptionUseCaseProvider);
  
  // Extension extraction
  String extension = '.tmp';
  if (item.originalName.contains('.')) {
    extension = '.${item.originalName.split('.').last}';
  }

  // Create temporary file
  final tempFile = await tempManager.createTemporaryFile(extension);

  try {
    // 1. Fetch encrypted bytes from local storage.
    final encryptedFile = File(item.encryptedFilePath);
    final encryptedBytes = await encryptedFile.readAsBytes();

    // 2. Fetch Master Key
    final masterKeyBytes = ref.read(sessionProvider);
    if (masterKeyBytes == null) {
      throw Exception("Master key not available in session");
    }
    final masterKey = await encUseCase.importMasterKey(masterKeyBytes);

    // 3. Decrypt the bytes
    final decryptedBytes = await encUseCase.decryptDataWithCek(
      encryptedBytes.toList(),
      item.wrappedContentKey,
      item.iv,
      masterKey,
    );

    // 4. Write to temp file
    await tempManager.writeBytes(tempFile, decryptedBytes);
  } catch (e) {
    // Cleanup if decryption fails
    await tempManager.deleteFile(tempFile);
    rethrow;
  }
  
  final session = SecurePlaybackSession(
    id: item.id.toString(),
    file: tempFile,
    onDispose: () async {
      await tempManager.deleteFile(tempFile);
    },
  );
  
  // Auto-dispose cleanup
  ref.onDispose(() {
    session.dispose();
  });
  
  return session;
});
