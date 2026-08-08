import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyMasterKey = 'wrapped_master_key';
  static const _keyDecoyMasterKey = 'wrapped_decoy_master_key';
  static const _keyDbKey = 'db_key';
  static const _keyDecoyDbKey = 'decoy_db_key';
  static const _keySalt = 'crypto_salt';
  static const _keyDecoySalt = 'crypto_decoy_salt';

  Future<void> saveWrappedMasterKey(String wrappedKey) async {
    await _storage.write(key: _keyMasterKey, value: wrappedKey);
  }

  Future<String?> getWrappedMasterKey() async {
    return await _storage.read(key: _keyMasterKey);
  }

  Future<List<int>?> getOldMasterKey() async {
    final base64Key = await _storage.read(key: 'master_key');
    if (base64Key == null) return null;
    return base64Decode(base64Key);
  }

  Future<void> saveWrappedDecoyMasterKey(String wrappedKey) async {
    await _storage.write(key: _keyDecoyMasterKey, value: wrappedKey);
  }

  Future<String?> getWrappedDecoyMasterKey() async {
    return await _storage.read(key: _keyDecoyMasterKey);
  }

  Future<String> getOrGenerateDatabaseKey() async {
    var dbKey = await _storage.read(key: _keyDbKey);
    if (dbKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      dbKey = base64Encode(keyBytes);
      await _storage.write(key: _keyDbKey, value: dbKey);
    }
    return dbKey;
  }

  Future<String> getOrGenerateDecoyDatabaseKey() async {
    var dbKey = await _storage.read(key: _keyDecoyDbKey);
    if (dbKey == null) {
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (i) => random.nextInt(256));
      dbKey = base64Encode(keyBytes);
      await _storage.write(key: _keyDecoyDbKey, value: dbKey);
    }
    return dbKey;
  }

  Future<List<int>> getOrGenerateSalt() async {
    var saltBase64 = await _storage.read(key: _keySalt);
    if (saltBase64 == null) {
      final random = Random.secure();
      final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
      saltBase64 = base64Encode(saltBytes);
      await _storage.write(key: _keySalt, value: saltBase64);
    }
    return base64Decode(saltBase64);
  }

  Future<List<int>> getOrGenerateDecoySalt() async {
    var saltBase64 = await _storage.read(key: _keyDecoySalt);
    if (saltBase64 == null) {
      final random = Random.secure();
      final saltBytes = List<int>.generate(32, (i) => random.nextInt(256));
      saltBase64 = base64Encode(saltBytes);
      await _storage.write(key: _keyDecoySalt, value: saltBase64);
    }
    return base64Decode(saltBase64);
  }

  // --- PIN Hashes ---
  static const _keyPinHash = 'pin_hash';
  static const _keyDecoyPinHash = 'decoy_pin_hash';

  Future<void> savePinHash(String hash) async {
    await _storage.write(key: _keyPinHash, value: hash);
  }

  Future<String?> getPinHash() async {
    return await _storage.read(key: _keyPinHash);
  }

  Future<void> saveDecoyPinHash(String hash) async {
    await _storage.write(key: _keyDecoyPinHash, value: hash);
  }

  Future<String?> getDecoyPinHash() async {
    return await _storage.read(key: _keyDecoyPinHash);
  }

  Future<void> clearAll() async {
    final keys = [
      _keyPinHash, _keyDecoyPinHash, _keyMasterKey, 
      _keyDecoyMasterKey, _keyDbKey, _keyDecoyDbKey, _keySalt, _keyDecoySalt
    ];
    for (final key in keys) {
      try {
        await _storage.delete(key: key);
      } catch (_) {}
    }
  }
}
