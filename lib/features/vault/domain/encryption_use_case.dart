import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EncryptionResult {
  final List<int> encryptedDataBlob;
  final String wrappedContentKey;
  final String iv;

  EncryptionResult({
    required this.encryptedDataBlob,
    required this.wrappedContentKey,
    required this.iv,
  });
}

final encryptionUseCaseProvider = Provider<EncryptionUseCase>((ref) {
  return EncryptionUseCase();
});

class EncryptionUseCase {
  final _aesGcm = AesGcm.with256bits();

  Future<SecretKey> importMasterKey(List<int> bytes) async {
    return SecretKey(bytes);
  }

  /// Encrypts data using a newly generated per-file CEK.
  /// The CEK is then encrypted using the provided [masterKey].
  Future<EncryptionResult> encryptDataWithCek(List<int> data, SecretKey masterKey) async {
    // 1. Generate a Content Encryption Key (CEK)
    final contentKey = await _aesGcm.newSecretKey();
    
    // 2. Encrypt the file using the CEK
    final dataBox = await _aesGcm.encrypt(
      data,
      secretKey: contentKey,
    );
    final encryptedBlob = dataBox.concatenation();
    
    // 3. Wrap (Encrypt) the CEK using the Master Key
    final cekBytes = await contentKey.extractBytes();
    final cekBox = await _aesGcm.encrypt(
      cekBytes,
      secretKey: masterKey,
    );
    
    // Store the ciphertext and MAC together, and IV separate if needed, 
    // or just concatenate everything. Here we split it for the DB schema.
    final wrappedKeyBase64 = base64Encode(cekBox.cipherText + cekBox.mac.bytes);
    final ivBase64 = base64Encode(cekBox.nonce);

    return EncryptionResult(
      encryptedDataBlob: encryptedBlob,
      wrappedContentKey: wrappedKeyBase64,
      iv: ivBase64,
    );
  }

  /// Decrypts a file using the wrapped CEK.
  Future<List<int>> decryptDataWithCek(List<int> encryptedBlob, String wrappedKeyBase64, String ivBase64, SecretKey masterKey) async {
    // 1. Reconstruct the SecretBox for the CEK
    final nonce = base64Decode(ivBase64);
    final wrappedKeyData = base64Decode(wrappedKeyBase64);
    final macLength = _aesGcm.macAlgorithm.macLength;
    final cipherText = wrappedKeyData.sublist(0, wrappedKeyData.length - macLength);
    final macBytes = wrappedKeyData.sublist(wrappedKeyData.length - macLength);
    
    final cekBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );
    
    // 2. Unwrap the CEK
    final cekBytes = await _aesGcm.decrypt(
      cekBox,
      secretKey: masterKey,
    );
    final contentKey = SecretKey(cekBytes);
    
    // 3. Decrypt the file data
    final dataBox = SecretBox.fromConcatenation(
      encryptedBlob,
      nonceLength: _aesGcm.nonceLength,
      macLength: macLength,
    );
    
    return await _aesGcm.decrypt(
      dataBox,
      secretKey: contentKey,
    );
  }
}
