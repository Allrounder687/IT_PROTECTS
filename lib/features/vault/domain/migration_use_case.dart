import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cryptography/cryptography.dart';
import '../../auth/data/auth_repository.dart';
import 'encryption_use_case.dart';
import '../data/local_vault_repository.dart';
import '../../../core/providers/session_provider.dart';

final migrationUseCaseProvider = Provider<MigrationUseCase>((ref) {
  return MigrationUseCase(ref);
});

class MigrationUseCase {
  final Ref _ref;

  MigrationUseCase(this._ref);

  Future<void> migrateOldImages() async {
    final authRepo = _ref.read(authRepositoryProvider);
    final encUseCase = _ref.read(encryptionUseCaseProvider);
    final localRepo = _ref.read(localVaultRepositoryProvider);
    
    // Get the old master key
    final oldMasterKeyBytes = await authRepo.getOldMasterKey();
    if (oldMasterKeyBytes == null) {
      return;
    }
    final oldMasterKey = await encUseCase.importMasterKey(oldMasterKeyBytes);

    // Get the new master key (current session)
    final currentMasterKeyBytes = _ref.read(sessionProvider);
    if (currentMasterKeyBytes == null) {
      return; // Vault is locked
    }
    final currentMasterKey = await encUseCase.importMasterKey(currentMasterKeyBytes);

    // Fetch all media items
    final items = await localRepo.getMediaItems(limit: 1000);

    for (final item in items) {
      final file = File(item.encryptedFilePath);
      if (!await file.exists()) continue;

      final encryptedBytes = await file.readAsBytes();

      try {
        // Test if it decrypts with the new key.
        await encUseCase.decryptDataWithCek(
          encryptedBytes.toList(),
          item.wrappedContentKey,
          item.iv,
          currentMasterKey,
        );
        // If it succeeds, it's already using the new key.
        continue;
      } catch (e) {
        if (e is SecretBoxAuthenticationError) {
          try {
            // Decrypt with OLD key
            final decryptedBytes = await encUseCase.decryptDataWithCek(
              encryptedBytes.toList(),
              item.wrappedContentKey,
              item.iv,
              oldMasterKey,
            );

            // Re-encrypt with NEW key
            final encryptionResult = await encUseCase.encryptDataWithCek(
              decryptedBytes,
              currentMasterKey,
            );

            // Overwrite the file with new encrypted blob
            await file.writeAsBytes(encryptionResult.encryptedDataBlob);

            // Update database with new wrapped content key and IV
            await localRepo.updateMediaItemKeys(
              item.id,
              encryptionResult.wrappedContentKey,
              encryptionResult.iv,
            );
          } catch (oldE) {
            // Couldn't decrypt with old key either, ignore
          }
        }
      }
    }
  }
}
