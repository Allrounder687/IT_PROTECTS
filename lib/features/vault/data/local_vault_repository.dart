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
  Database? _realDb;
  Database? _decoyDb;

  LocalVaultRepository(this._ref);

  Future<Database> getDatabase(AuthMode mode) async {
    if (mode == AuthMode.real) {
      if (_realDb != null) return _realDb!;
      _realDb = await _initDB(mode);
      return _realDb!;
    } else {
      if (_decoyDb != null) return _decoyDb!;
      _decoyDb = await _initDB(mode);
      return _decoyDb!;
    }
  }

  Future<Database> _initDB(AuthMode mode) async {
    final authRepo = _ref.read(authRepositoryProvider);
    final dbPassword = mode == AuthMode.real
        ? await authRepo.getOrGenerateDatabaseKey()
        : await authRepo.getOrGenerateDecoyDatabaseKey();

    final isDesktop =
        (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    final factory = isDesktop ? databaseFactoryFfi : sqlcipher.databaseFactory;

    final dbPath = await factory.getDatabasesPath();
    final path = p.join(
      dbPath,
      mode == AuthMode.real ? 'vault.db' : 'decoy_vault.db',
    );

    Future<void> onCreate(db, version) async {
      await db.execute('''
            CREATE TABLE albums (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            type TEXT NOT NULL,
            is_locked INTEGER NOT NULL,
            storage_provider_id TEXT,
            is_decoy_visible INTEGER NOT NULL,
            cover_item_id INTEGER
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
            encrypted_metadata TEXT,
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
        await db.execute(
          'ALTER TABLE albums ADD COLUMN type TEXT NOT NULL DEFAULT "custom"',
        );
        await db.execute(
          'ALTER TABLE albums ADD COLUMN is_locked INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE albums ADD COLUMN storage_provider_id TEXT',
        );
        await db.execute(
          'ALTER TABLE albums ADD COLUMN is_decoy_visible INTEGER NOT NULL DEFAULT 0',
        );

        await db.update(
          'albums',
          {'type': AlbumType.mainVault.name, 'is_decoy_visible': 1},
          where: 'name = ?',
          whereArgs: ['Main Vault'],
        );
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
        await db.update(
          'albums',
          {'is_decoy_visible': 0},
          where: 'name IN (?, ?)',
          whereArgs: ['Main Vault', 'Documents'],
        );
        final maps = await db.query(
          'albums',
          where: 'name = ?',
          whereArgs: ['Decoy Vault'],
        );
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
        await db.execute(
          'ALTER TABLE media_items ADD COLUMN is_trashed INTEGER NOT NULL DEFAULT 0',
        );
        await db.execute(
          'ALTER TABLE media_items ADD COLUMN deleted_at INTEGER',
        );
        await db.execute(
          'ALTER TABLE media_items ADD COLUMN is_favourite INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (oldVersion < 6) {
        await db.execute(
          'ALTER TABLE media_items ADD COLUMN encrypted_metadata TEXT',
        );
      }
      if (oldVersion < 7) {
        await db.execute(
          'ALTER TABLE albums ADD COLUMN cover_item_id INTEGER',
        );
      }
    }

    final options = isDesktop
        ? OpenDatabaseOptions(
            version: 7,
            onConfigure: (db) async {
              await db.execute("PRAGMA key = '';");
            },
            onCreate: onCreate,
            onUpgrade: onUpgrade,
          )
        : sqlcipher.SqlCipherOpenDatabaseOptions(
            version: 7,
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
    final db = await getDatabase(authMode);
    final isDecoy = authMode == AuthMode.decoy ? 1 : 0;
    final albums = await db.query(
      'albums',
      where: 'is_decoy_visible = ?',
      whereArgs: [isDecoy],
      limit: 1,
    );
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

  Future<int> getOrCreateDecoyAlbum({required AuthMode authMode}) async {
    final db = await getDatabase(authMode);
    final albums = await db.query(
      'albums',
      where: 'name = ? AND is_decoy_visible = 1',
      whereArgs: ['Decoy Vault'],
      limit: 1,
    );
    if (albums.isNotEmpty) {
      return albums.first['id'] as int;
    }

    // Create one if it doesn't exist
    return await db.insert('albums', {
      'name': 'Decoy Vault',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'type': 'local',
      'is_locked': 0,
      'storage_provider_id': 'local',
      'is_decoy_visible': 1,
    });
  }

  Future<int> getOrCreateDocumentsAlbum(AuthMode authMode) async {
    final db = await getDatabase(authMode);
    final maps = await db.query(
      'albums',
      where: 'type = ?',
      whereArgs: [AlbumType.documents.name],
    );
    if (maps.isNotEmpty) {
      return maps.first['id'] as int;
    }
    return await db.insert('albums', {
      'name': 'Documents',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'type': AlbumType.documents.name,
      'is_locked': 0,
      'is_decoy_visible': 0,
    });
  }

  Future<int> insertMediaItem(
    String name,
    String encryptedFilePath,
    String type,
    int size,
    String wrappedKey,
    String iv, {
    int? albumId,
    required AuthMode authMode,
    String? encryptedMetadata,
  }) async {
    final db = await getDatabase(authMode);
    final targetAlbumId = albumId ?? await getOrCreateMainAlbum(authMode);
    final id = await db.insert('media_items', {
      'album_id': targetAlbumId,
      'original_name': name,
      'encrypted_file_path': encryptedFilePath,
      'type': type,
      'size': size,
      'wrapped_content_key': wrappedKey,
      'iv': iv,
      'encrypted_metadata': encryptedMetadata,
    });
    return id;
  }

  Future<void> updateMediaItemKeys(
    int id,
    String wrappedKey,
    String iv, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'media_items',
      {'wrapped_content_key': wrappedKey, 'iv': iv},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<VaultItemEntity?> getMediaItem(int id, {required AuthMode authMode}) async {
    final db = await getDatabase(authMode);
    final List<Map<String, dynamic>> maps = await db.query(
      'media_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return VaultItemEntity.fromMap(maps.first);
  }

  Future<List<VaultItemEntity>> getMediaItems({
    int limit = 50,
    int offset = 0,
    AuthMode authMode = AuthMode.real,
    int? albumId,
  }) async {
    final db = await getDatabase(authMode);
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

  Future<List<VaultItemEntity>> searchMediaItems(
    String query, {
    int limit = 50,
    int offset = 0,
    AuthMode authMode = AuthMode.real,
  }) async {
    final db = await getDatabase(authMode);
    String whereString = 'original_name LIKE ?';
    if (authMode == AuthMode.decoy) {
      whereString +=
          ' AND album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 1)';
    } else {
      whereString +=
          ' AND album_id IN (SELECT id FROM albums WHERE is_decoy_visible = 0)';
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

  Future<List<VaultItemEntity>> getTrashedItems({
    int limit = 50,
    int offset = 0,
    AuthMode authMode = AuthMode.real,
  }) async {
    final db = await getDatabase(authMode);
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

  Future<void> moveToTrash(int itemId, {required AuthMode authMode}) async {
    final db = await getDatabase(authMode);
    await db.update(
      'media_items',
      {'is_trashed': 1, 'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> restoreFromTrash(
    int itemId, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'media_items',
      {'is_trashed': 0, 'deleted_at': null},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteItemPermanently(
    int itemId, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);

    // First, delete the file
    final maps = await db.query(
      'media_items',
      where: 'id = ?',
      whereArgs: [itemId],
    );
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

  Future<void> moveItemToAlbum(
    int itemId,
    int newAlbumId, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'media_items',
      {'album_id': newAlbumId},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> transferItemToVault({
    required VaultItemEntity item,
    required String newWrappedKey,
    required String newIv,
    required int newAlbumId,
    required AuthMode fromMode,
    required AuthMode toMode,
  }) async {
    final fromDb = await getDatabase(fromMode);
    final toDb = await getDatabase(toMode);

    await toDb.insert('media_items', {
      'album_id': newAlbumId,
      'original_name': item.originalName,
      'file_path': item.filePath,
      'wrapped_content_key': newWrappedKey,
      'iv': newIv,
      'size': item.size,
      'mime_type': item.mimeType,
      'created_at': item.createdAt.millisecondsSinceEpoch,
      'is_favourite': item.isFavourite ? 1 : 0,
      'is_trashed': item.isTrashed ? 1 : 0,
      'deleted_at': item.deletedAt?.millisecondsSinceEpoch,
    });

    await fromDb.delete('media_items', where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> toggleFavourite(
    int itemId,
    bool isFavourite, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
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

  Future<Album?> getAlbum(int id, {required AuthMode authMode}) async {
    final db = await getDatabase(authMode);
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT a.*, 
        (SELECT COUNT(*) FROM media_items m WHERE m.album_id = a.id AND m.is_trashed = 0) as itemCount,
        COALESCE(a.cover_item_id, (SELECT m.id FROM media_items m WHERE m.album_id = a.id AND m.is_trashed = 0 ORDER BY m.id DESC LIMIT 1)) as derivedCoverItemId
      FROM albums a
      WHERE a.id = ?
    ''',
      [id],
    );
    if (maps.isEmpty) return null;
    return Album.fromMap(
      maps.first,
      maps.first['itemCount'] as int,
      maps.first['derivedCoverItemId'] as int?,
    );
  }

  Future<List<Album>> loadAlbums({AuthMode authMode = AuthMode.real}) async {
    final db = await getDatabase(authMode);
    final String whereClause = authMode == AuthMode.decoy
        ? 'WHERE a.is_decoy_visible = 1'
        : 'WHERE a.is_decoy_visible = 0';

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, 
        (SELECT COUNT(*) FROM media_items m WHERE m.album_id = a.id AND m.is_trashed = 0) as itemCount,
        COALESCE(a.cover_item_id, (SELECT m.id FROM media_items m WHERE m.album_id = a.id AND m.is_trashed = 0 ORDER BY m.id DESC LIMIT 1)) as derivedCoverItemId 
      FROM albums a
      $whereClause
      ORDER BY a.created_at ASC
    ''');

    return maps
        .map(
          (e) => Album.fromMap(
            e,
            e['itemCount'] as int,
            e['derivedCoverItemId'] as int?,
          ),
        )
        .toList();
  }

  Future<Album> createAlbum(
    String name,
    String? providerId, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    final id = await db.insert('albums', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'type': AlbumType.custom.name,
      'is_locked': 0,
      'storage_provider_id': providerId,
      'is_decoy_visible': 0,
    });

    return (await getAlbum(id, authMode: authMode))!;
  }

  Future<Album> updateAlbumLock(
    int id,
    bool locked, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'albums',
      {'is_locked': locked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    return (await getAlbum(id, authMode: authMode))!;
  }

  Future<Album> updateAlbumName(
    int id,
    String newName, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'albums',
      {'name': newName},
      where: 'id = ?',
      whereArgs: [id],
    );

    return (await getAlbum(id, authMode: authMode))!;
  }

  Future<Album> updateAlbumCover(
    int id,
    int coverItemId, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'albums',
      {'cover_item_id': coverItemId},
      where: 'id = ?',
      whereArgs: [id],
    );
    return (await getAlbum(id, authMode: authMode))!;
  }

  Future<Album> updateAlbumProvider(
    int id,
    String? providerId, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'albums',
      {'storage_provider_id': providerId},
      where: 'id = ?',
      whereArgs: [id],
    );

    return (await getAlbum(id, authMode: authMode))!;
  }

  // --- Sync Queue Methods ---
  Future<void> enqueueSyncJob(SyncJob job, {required AuthMode authMode}) async {
    final db = await getDatabase(authMode);
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

  Future<List<SyncJob>> getPendingSyncJobs({
    required AuthMode authMode,
    int limit = 20,
  }) async {
    final db = await getDatabase(authMode);
    final maps = await db.query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: limit,
    );
    return maps.map((m) => SyncJob.fromMap(m)).toList();
  }

  Future<void> updateSyncJobError(
    int jobId,
    int retryCount,
    String? lastError, {
    required AuthMode authMode,
  }) async {
    final db = await getDatabase(authMode);
    await db.update(
      'sync_queue',
      {'retry_count': retryCount, 'last_error': lastError},
      where: 'id = ?',
      whereArgs: [jobId],
    );
  }

  Future<void> deleteSyncJob(int jobId, {required AuthMode authMode}) async {
    final db = await getDatabase(authMode);
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [jobId]);
  }

  Future<void> migrateDecoyDatabase() async {
    final realDb = await getDatabase(AuthMode.real);
    final decoyDb = await getDatabase(AuthMode.decoy);

    final decoyAlbums = await realDb.query(
      'albums',
      where: 'is_decoy_visible = 1',
    );
    if (decoyAlbums.isEmpty) return;

    for (final album in decoyAlbums) {
      final existing = await decoyDb.query(
        'albums',
        where: 'id = ?',
        whereArgs: [album['id']],
      );
      if (existing.isEmpty) {
        await decoyDb.insert('albums', album);
      }

      final mediaItems = await realDb.query(
        'media_items',
        where: 'album_id = ?',
        whereArgs: [album['id']],
      );
      for (final item in mediaItems) {
        final existingItem = await decoyDb.query(
          'media_items',
          where: 'id = ?',
          whereArgs: [item['id']],
        );
        if (existingItem.isEmpty) {
          await decoyDb.insert('media_items', item);
        }
      }

      // Remove from real db
      await realDb.delete(
        'media_items',
        where: 'album_id = ?',
        whereArgs: [album['id']],
      );
      await realDb.delete('albums', where: 'id = ?', whereArgs: [album['id']]);
    }
  }

  Future<Map<String, int>> getStorageStats(AuthMode authMode) async {
    final db = await getDatabase(authMode);
    final res = await db.rawQuery('SELECT SUM(size) as total FROM media_items');
    final totalOriginal = Sqflite.firstIntValue(res) ?? 0;
    
    // In a real app we'd query the file system. For this demo, we estimate:
    // If Space Saver is toggled on, local size is ~20% of original. 
    // Otherwise, local size is exactly original + 28 bytes (encryption overhead) per item.
    final countRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM media_items');
    final count = Sqflite.firstIntValue(countRes) ?? 0;
    
    return {
      'totalOriginal': totalOriginal,
      'itemCount': count,
    };
  }

  Future<void> deleteVault({required AuthMode authMode}) async {
    final db = await getDatabase(authMode);

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
    final factory =
        (kIsWeb || Platform.isWindows || Platform.isLinux || Platform.isMacOS)
        ? databaseFactoryFfi
        : sqlcipher.databaseFactory;
    final dbPath = await factory.getDatabasesPath();
    final path = p.join(
      dbPath,
      authMode == AuthMode.real ? 'vault.db' : 'decoy_vault.db',
    );

    // Close the database before deleting
    await db.close();
    if (authMode == AuthMode.real)
      _realDb = null;
    else
      _decoyDb = null;

    try {
      await factory.deleteDatabase(path);
      // Fallback for Windows file lock issues in sqflite_ffi
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
  }
}
