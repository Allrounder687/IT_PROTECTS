import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../data/temporary_file_manager.dart';

final playbackSessionProvider = FutureProvider.family.autoDispose<SecurePlaybackSession, VaultItemEntity>((ref, item) async {
  final tempManager = ref.read(temporaryFileManagerProvider);
  
  // Extension extraction
  String extension = '.tmp';
  if (item.originalName.contains('.')) {
    extension = '.${item.originalName.split('.').last}';
  }

  // Create temporary file
  final tempFile = await tempManager.createTemporaryFile(extension);

  // Mock Decryption Process
  // 1. Fetch encrypted bytes from local storage.
  // 2. Fetch the CEK for this file from the database.
  // 3. Decrypt the bytes in an isolate.
  await Future.delayed(const Duration(milliseconds: 500)); // Mocking crypto delay
  
  // Here we just write empty bytes to satisfy the type.
  final decryptedBytes = <int>[]; 
  await tempManager.writeBytes(tempFile, decryptedBytes);
  
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
