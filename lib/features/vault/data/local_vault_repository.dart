import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:flutter/foundation.dart';
import '../../../core/providers/auth_mode_provider.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/vault_item_entity.dart';
import '../../albums/domain/album.dart';
import '../../providers/domain/sync_job.dart';

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
    
    final isDesktop = (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final factory = isDesktop ? databaseFactoryFfi : sqlcipher.databaseFactory;

    final dbPath = await factory.getDatabasesPath();
    final path = p.join(dbPath, 'vault.db');

    Future<void> onCreate(db, version) async {
          await db.execute('''
            CREATE TABLE albums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            type TEXT NOT NULL,
            is_locked INTEGER NOT NULL,
            storage_provider_id TEXT,
            is_decoy_visible INTEGER NOT NULL
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
            is_trashed INTEGER NOT NULL DEFAULT 0,
            deleted_at INTEGER,
            is_favourite INTEGER NOT NULL DEFAULT 0,
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

        await db.execute('''
          CREATE TABLE sync_queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            item_id INTEGER NOT NULL,
            album_id INTEGER NOT NULL,
            operation TEXT NOT NULL,
            target_provider_id TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        
        final now = DateTime.now().millisecondsSinceEpoch;
        await db.insert('albums', {
          'name': 'Main Vault',
          'created_at': now,
          'type': AlbumType.mainVault.name,
          'is_locked': 0,
          'is_decoy_visible': 0,
        });
        await db.insert('albums', {
          'name': 'Documents',
          'created_at': now,
          'type': AlbumType.documents.name,
          'is_locked': 0,
          'is_decoy_visible': 0,
        });
        await db.insert('albums', {
          'name': 'Private Photos',
          'created_at': now,
          'type': AlbumType.privatePhotos.name,
          'is_locked': 1,
          'is_decoy_visible': 0,
        });
      }

    Future<void> onUpgrade(db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE albums ADD COLUMN type TEXT NOT NULL DEFAULT "custom"');
          await db.execute('ALTER TABLE albums ADD COLUMN is_locked INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE albums ADD COLUMN storage_provider_id TEXT');
          await db.execute('ALTER TABLE albums ADD COLUMN is_decoy_visible INTEGER NOT NULL DEFAULT 0');
          
          await db.update('albums', {'type': AlbumType.mainVault.name, 'is_decoy_visible': 1}, where: 'name = ?', whereArgs: ['Main Vault']);
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE sync_queue (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              item_id INTEGER NOT NULL,
              album_id INTEGER NOT NULL,
              operation TEXT NOT NULL,
              target_provider_id TEXT NOT NULL,
              retry_count INTEGER NOT NULL DEFAULT 0,
              last_error TEXT,
              created_at TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 4) {
          await db.update('albums', {'is_decoy_visible': 0}, where: 'name IN (?, ?)', whereArgs: ['Main Vault', 'Documents']);
          final maps = await db.query('albums', where: 'name = ?', whereArgs: ['Decoy Vault']);
          if (maps.isEmpty) {
            await db.insert('albums', {
              'name': 'Decoy Vault',
              'created_at': DateTime.now().millisecondsSinceEpoch,
              'type': AlbumType.mainVault.name,
              'is_locked': 0,
              'is_decoy_visible': 1,
            });
          }
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE media_items ADD COLUMN is_trashed INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE media_items ADD COLUMN deleted_at INTEGER');
          await db.execute('ALTER TABLE media_items ADD COLUMN is_favourite INTEGER NOT NULL DEFAULT 0');
        }
      }

    final options = isDesktop
        ? OpenDatabaseOptions(
            version: 5,
            onConfigure: (db) async {
              await db.execute("PRAGMA key = '';");
            },
            onCreate: onCreate,
            onUpgrade: onUpgrade,
          )
        : sqlcipher.SqlCipherOpenDatabaseOptions(
            version: 5,
            password: dbPassword,
            onCreate: onCreate,
            onUpgrade: onUpgrade,
          );

        try {
      return await factory.openDatabase(path, options: options);
    } catch (e) {
      // If it fails to open (e.g. corrupted due to previous PRAGMA crash), delete and recreate
      await factory.deleteDatabase(path);
      return await factory.openDatabase(path, options: options);
    }
  }

  Future<int> getOrCreateMainAlbum(AuthMode authMode) async {
    final db = await database;
    final isDecoy = authMode == AuthMode.decoy ? 1 : 0;
    final albums = await db.query('albums', where: 'is_decoy_visible = ?', whereArgs: [isDecoy], limit: 1);
    if (albums.isEmpty) {
      return await db.insert('albums', {
        'name': authMode == AuthMode.decoy ? 'Decoy Vault' : 'Main Vault',
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'type': AlbumType.mainVault.name,
        'is_locked': 0,
        'is_decoy_visible': isDecoy,
      });
    }
    return albums.first['id'] as int;
  }

  Future<int> insertMediaItem(String name, String encryptedFilePath, String type, int size, String wrappedKey, String iv, {int? albumId}) async {
    final db = await database;
    final authMode = _ref.read(authModeProvider);
    final targetAlbumId = albumId ?? await getOrCreateMainAlbum(authMode);
    final id = await db.insert('media_items', {
      'album_id': targetAlbumId,
      'original_name': name,
      'encrypted_file_path': encryptedFilePath,
      'type': type,
      'size': size,
      'wrapped_content_key': wrappedKey,
      'iv': iv,
    });
    return id;
  }

  Future<void> updateMediaItemKeys(int id, String wrappedKey, String iv) async {
    final db = await database;
    await db.update(
      'media_items',
      {
        'wrapped_content_key': wrappedKey,
        'iv': iv,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<VaultItemEntity>> getMediaItems({int limit = 50, int offset = 0, AuthMode authMode = AuthMode.real, int? albumId}) async {
    final db = await database;
    String whereString = authMode == AuthMode.decoy 
        ? 'album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 1)'
        : 'album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 0)';
    
    whereString += ' AND is_trashed = 0';
    List<Object?> whereArgs = [];

    if (albumId != null) {
      whereString += ' AND album_id = ?';
      whereArgs.add(albumId);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => VaultItemEntity.fromMap(e)).toList();
  }

  Future<List<VaultItemEntity>> searchMediaItems(String query, {int limit = 50, int offset = 0, AuthMode authMode = AuthMode.real}) async {
    final db = await database;
    String whereString = 'original_name LIKE ?';
    if (authMode == AuthMode.decoy) {
      whereString += ' AND album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 1)';
    } else {
      whereString += ' AND album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 0)';
    }
    
    whereString += ' AND is_trashed = 0';

    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: whereString,
      whereArgs: ['%$query%'],
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => VaultItemEntity.fromMap(e)).toList();
  }

  Future<List<VaultItemEntity>> getTrashedItems({int limit = 50, int offset = 0, AuthMode authMode = AuthMode.real}) async {
    final db = await database;
    String whereString = authMode == AuthMode.decoy 
        ? 'album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 1)'
        : 'album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 0)';
    whereString += ' AND is_trashed = 1';

    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: whereString,
      orderBy: 'deleted_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((e) => VaultItemEntity.fromMap(e)).toList();
  }

  Future<void> moveToTrash(int itemId) async {
    final db = await database;
    await db.update(
      'media_items',
      {
        'is_trashed': 1,
        'deleted_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> restoreFromTrash(int itemId) async {
    final db = await database;
    await db.update(
      'media_items',
      {
        'is_trashed': 0,
        'deleted_at': null,
      },
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteItemPermanently(int itemId) async {
    final db = await database;
    
    // First, delete the file
    final maps = await db.query('media_items', where: 'id = ?', whereArgs: [itemId]);
    if (maps.isNotEmpty) {
      final path = maps.first['encrypted_file_path'] as String?;
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }

    // Then delete the row
    await db.delete('media_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<void> moveItemToAlbum(int itemId, int newAlbumId) async {
    final db = await database;
    await db.update(
      'media_items',
      {'album_id': newAlbumId},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> toggleFavourite(int itemId, bool isFavourite) async {
    final db = await database;
    await db.update(
      'media_items',
      {'is_favourite': isFavourite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<String> saveEncryptedFile(List<int> bytes, String fileName) async {
    final docDir = await getApplicationDocumentsDirectory();
    final filePath = p.join(docDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  // --- Album Methods ---
  Future<List<Album>> loadAlbums({AuthMode authMode = AuthMode.real}) async {
    final db = await database;
    final String whereClause = authMode == AuthMode.decoy 
        ? 'WHERE a.is_decoy_visible = 1' 
        : 'WHERE a.is_decoy_visible = 0';
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, 
        (SELECT COUNT(*) FROM media_items m WHERE m.album_id = a.id) as itemCount 
      FROM albums a
      $whereClause
      ORDER BY a.created_at ASC
    ''');
    
    return maps.map((e) => Album.fromMap(e, e['itemCount'] as int)).toList();
  }

  Future<Album> createAlbum(String name, String? providerId) async {
    final db = await database;
    final id = await db.insert('albums', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'type': AlbumType.custom.name,
      'is_locked': 0,
      'storage_provider_id': providerId,
      'is_decoy_visible': 0,
    });
    
    final maps = await db.query('albums', where: 'id = ?', whereArgs: [id]);
    return Album.fromMap(maps.first, 0);
  }

  Future<Album> updateAlbumLock(int id, bool locked) async {
    final db = await database;
    await db.update('albums', {'is_locked': locked ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, 
        (SELECT COUNT(*) FROM media_items m WHERE m.album_id = a.id) as itemCount 
      FROM albums a
      WHERE a.id = ?
    ''', [id]);
    
    return Album.fromMap(maps.first, maps.first['itemCount'] as int);
  }

  Future<Album> updateAlbumName(int id, String newName) async {
    final db = await database;
    await db.update('albums', {'name': newName}, where: 'id = ?', whereArgs: [id]);
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, 
        (SELECT COUNT(*) FROM media_items m WHERE m.album_id = a.id) as itemCount 
      FROM albums a
      WHERE a.id = ?
    ''', [id]);
    
    return Album.fromMap(maps.first, maps.first['itemCount'] as int);
  }

  Future<Album> updateAlbumProvider(int id, String? providerId) async {
    final db = await database;
    await db.update('albums', {'storage_provider_id': providerId}, where: 'id = ?', whereArgs: [id]);
    
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, 
        (SELECT COUNT(*) FROM media_items m WHERE m.album_id = a.id) as itemCount 
      FROM albums a
      WHERE a.id = ?
    ''', [id]);
    
    return Album.fromMap(maps.first, maps.first['itemCount'] as int);
  }

  // --- Sync Queue Methods ---
  Future<void> enqueueSyncJob(SyncJob job) async {
    final db = await database;
    await db.insert('sync_queue', {
      'item_id': job.itemId,
      'album_id': job.albumId,
      'operation': job.operation.name,
      'target_provider_id': job.targetProviderId,
      'retry_count': job.retryCount,
      'last_error': job.lastError,
      'created_at': job.createdAt.toIso8601String(),
    });
  }

  Future<List<SyncJob>> getPendingSyncJobs({int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return maps.map((m) => SyncJob.fromMap(m)).toList();
  }

  Future<void> updateSyncJobError(int jobId, int retryCount, String? lastError) async {
    final db = await database;
    await db.update(
      'sync_queue',
      {
        'retry_count': retryCount,
        'last_error': lastError,
      },
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  Future<void> deleteSyncJob(int jobId) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [jobId]);
  }

  Future<void> deleteVault() async {
    final db = await database;
    
    // 1. Delete all encrypted files
    try {
      final mediaItems = await db.query('media_items');
      for (final item in mediaItems) {
        final path = item['encrypted_file_path'] as String?;
        if (path != null) {
          try {
            final file = File(path);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
        }
      }
    } catch (_) {}
    
    // 2. Delete database file
    final factory = (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS) 
        ? databaseFactoryFfi 
        : sqlcipher.databaseFactory;
    final dbPath = await factory.getDatabasesPath();
    final path = p.join(dbPath, 'vault.db');
    
    // Close the database before deleting
    await db.close();
    _database = null;
    
    try {
      await factory.deleteDatabase(path);
    } catch (_) {}
  }
}
