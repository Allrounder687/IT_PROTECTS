import 'dart:convert';
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

  Future<SecretKey> deriveMasterKey(String pin, List<int> salt) async {
    return await _argon2.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
  }

  Future<String> hashPin(String pin, List<int> salt) async {
    final key = await deriveMasterKey(pin, salt);
    final bytes = await key.extractBytes();
    return base64Encode(bytes);
  }
}
