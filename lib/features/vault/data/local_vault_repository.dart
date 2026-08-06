import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/vault_item_entity.dart';

final localVaultRepositoryProvider = Provider<LocalVaultRepository>((ref) {
  return LocalVaultRepository(ref);
});

class LocalVaultRepository {
  final Ref _ref;
  Database? _database;

  LocalVaultRepository(this._ref);

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final authRepo = _ref.read(authRepositoryProvider);
    final dbPassword = await authRepo.getOrGenerateDatabaseKey();
    
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'vault.db');

    return await openDatabase(
      path,
      version: 1,
      password: dbPassword,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE albums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE media_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            album_id INTEGER NOT NULL,
            original_name TEXT NOT NULL,
            encrypted_file_path TEXT NOT NULL,
            type TEXT NOT NULL,
            size INTEGER NOT NULL,
            wrapped_content_key TEXT NOT NULL,
            iv TEXT NOT NULL,
            FOREIGN KEY (album_id) REFERENCES albums (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE intrusion_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            photo_path TEXT,
            successful INTEGER NOT NULL
          )
        ''');
        
        await db.insert('albums', {
          'name': 'Main Vault',
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      },
    );
  }

  Future<int> getOrCreateMainAlbum() async {
    final db = await database;
    final albums = await db.query('albums', limit: 1);
    if (albums.isEmpty) {
      return await db.insert('albums', {
        'name': 'Main Vault',
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    }
    return albums.first['id'] as int;
  }

  Future<void> insertMediaItem(String name, String encryptedFilePath, String type, int size, String wrappedKey, String iv) async {
    final db = await database;
    final albumId = await getOrCreateMainAlbum();
    await db.insert('media_items', {
      'album_id': albumId,
      'original_name': name,
      'encrypted_file_path': encryptedFilePath,
      'type': type,
      'size': size,
      'wrapped_content_key': wrappedKey,
      'iv': iv,
    });
  }

  Future<List<VaultItemEntity>> getMediaItems({int limit = 50, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_items', 
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => VaultItemEntity.fromMap(e)).toList();
  }

  Future<List<VaultItemEntity>> searchMediaItems(String query, {int limit = 50, int offset = 0}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: 'original_name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => VaultItemEntity.fromMap(e)).toList();
  }

  Future<String> saveEncryptedFile(List<int> bytes, String fileName) async {
    final docDir = await getApplicationDocumentsDirectory();
    final filePath = p.join(docDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }
}
