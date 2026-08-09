import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cryptography/cryptography.dart';

void main() async {
  final salt = List<int>.generate(32, (i) => i);
  try {
    final key = await compute((Map<String, dynamic> args) async {
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
    }, {'pin': '123', 'salt': salt});
    
    final bytes = await key.extractBytes();
    print("SUCCESS: " + base64Encode(bytes));
  } catch (e) {
    print("ERROR: $e");
  }
}
