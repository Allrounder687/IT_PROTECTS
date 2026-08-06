import 'package:cryptography/cryptography.dart';

void main() async {
  final aesGcm = AesGcm.with256bits();
  final contentKey = await aesGcm.newSecretKey();
  
  final data = [1, 2, 3, 4, 5];
  final dataBox = await aesGcm.encrypt(
    data,
    secretKey: contentKey,
  );
  
  final encryptedBlob = dataBox.concatenation();
  
  print('Encrypted blob length: ${encryptedBlob.length}');
  print('Nonce length: ${dataBox.nonce.length}');
  print('Cipher length: ${dataBox.cipherText.length}');
  print('Mac length: ${dataBox.mac.bytes.length}');
  
  final macLength = aesGcm.macAlgorithm.macLength;
  print('Expected mac length: $macLength');
  
  try {
    final reconstructedBox = SecretBox.fromConcatenation(
      encryptedBlob,
      nonceLength: aesGcm.nonceLength,
      macLength: macLength,
    );
    
    final decrypted = await aesGcm.decrypt(
      reconstructedBox,
      secretKey: contentKey,
    );
    print('Decrypted: $decrypted');
  } catch (e) {
    print('Error: $e');
  }
}
