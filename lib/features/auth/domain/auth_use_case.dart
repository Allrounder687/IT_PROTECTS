import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authUseCaseProvider = Provider<AuthUseCase>((ref) {
  return AuthUseCase();
});

class AuthUseCase {
  final _argon2 = Argon2id(
    memory: 32000, 
    iterations: 2,
    parallelism: 2,
    hashLength: 32, 
  );
  final _aesGcm = AesGcm.with256bits();

  Future<SecretKey> deriveKek(String pin, List<int> salt) async {
    return await compute((Map<String, dynamic> args) async {
      final argon2 = Argon2id(
        memory: 32000, 
        iterations: 2,
        parallelism: 2,
        hashLength: 32, 
      );
      return await argon2.deriveKeyFromPassword(
        password: args['pin'] as String,
        nonce: args['salt'] as List<int>,
      );
    }, {'pin': pin, 'salt': salt});
  }

  Future<List<int>> generateRandomKey() async {
    final key = await _aesGcm.newSecretKey();
    return await key.extractBytes();
  }

  Future<String> wrapMasterKey(List<int> masterKeyBytes, SecretKey kek) async {
    final box = await _aesGcm.encrypt(masterKeyBytes, secretKey: kek);
    return base64Encode(box.concatenation());
  }

  Future<List<int>> unwrapMasterKey(String wrappedKey, SecretKey kek) async {
    final blob = base64Decode(wrappedKey);
    final box = SecretBox.fromConcatenation(
      blob,
      nonceLength: _aesGcm.nonceLength,
      macLength: _aesGcm.macAlgorithm.macLength,
    );
    return await _aesGcm.decrypt(box, secretKey: kek);
  }

  Future<String> hashPin(String pin, List<int> salt) async {
    final key = await deriveKek(pin, salt);
    final bytes = await key.extractBytes();
    return base64Encode(bytes);
  }
}
