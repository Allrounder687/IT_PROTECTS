import 'dart:convert';
import 'package:cryptography/cryptography.dart';

void main() async {
  final aesGcm = AesGcm.with256bits();
  
  final masterKey = await aesGcm.newSecretKey();
  final contentKey = await aesGcm.newSecretKey();
  
  // Wrap
  final cekBytes = await contentKey.extractBytes();
  final cekBox = await aesGcm.encrypt(
    cekBytes,
    secretKey: masterKey,
  );
  
  final wrappedKeyBase64 = base64Encode(cekBox.cipherText + cekBox.mac.bytes);
  final ivBase64 = base64Encode(cekBox.nonce);
  
  // Unwrap
  final nonce = base64Decode(ivBase64);
  final wrappedKeyData = base64Decode(wrappedKeyBase64);
  final macLength = aesGcm.macAlgorithm.macLength;
  final cipherText = wrappedKeyData.sublist(0, wrappedKeyData.length - macLength);
  final macBytes = wrappedKeyData.sublist(wrappedKeyData.length - macLength);
  
  final cekBox2 = SecretBox(
    cipherText,
    nonce: nonce,
    mac: Mac(macBytes),
  );
  
  try {
    final unwrappedCekBytes = await aesGcm.decrypt(
      cekBox2,
      secretKey: masterKey,
    );
    print('Unwrapped successfully!');
  } catch (e) {
    print('Error unwrapping CEK: $e');
  }
}
