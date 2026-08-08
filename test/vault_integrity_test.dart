import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:it_protects/core/providers/auth_mode_provider.dart';
import 'package:it_protects/features/vault/data/local_vault_repository.dart';
import 'package:it_protects/features/auth/data/auth_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});
  
  late ProviderContainer container;
  late LocalVaultRepository vaultRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = Directory.systemTemp.createTempSync('vault_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);

    container = ProviderContainer();
    vaultRepo = container.read(localVaultRepositoryProvider);
    // Clear databases
    final authRepo = container.read(authRepositoryProvider);
    await authRepo.clearAll();
    
    // Attempt delete to start clean
    try {
      await vaultRepo.deleteVault(authMode: AuthMode.real);
    } catch (_) {}
    try {
      await vaultRepo.deleteVault(authMode: AuthMode.decoy);
    } catch (_) {}
  });

  tearDown(() async {
    try {
      await vaultRepo.deleteVault(authMode: AuthMode.real);
    } catch (_) {}
    try {
      await vaultRepo.deleteVault(authMode: AuthMode.decoy);
    } catch (_) {}
    container.dispose();
  });

  test('Real -> Decoy -> Real keeps all real items and isolates decoy', () async {
    // 1. Create real items in Real Mode
    final realAlbumId = await vaultRepo.getOrCreateMainAlbum(AuthMode.real);
    final item1Id = await vaultRepo.insertMediaItem(
      'real_photo_1.jpg', 'path1', 'image', 100, 'key1', 'iv1', 
      albumId: realAlbumId, authMode: AuthMode.real
    );

    var realItems = await vaultRepo.getMediaItems(authMode: AuthMode.real);
    expect(realItems.length, 1);
    expect(realItems.first.id, item1Id);

    // 2. Switch to Decoy Mode and create decoy items
    final decoyAlbumId = await vaultRepo.getOrCreateDecoyAlbum(authMode: AuthMode.decoy);
    final item2Id = await vaultRepo.insertMediaItem(
      'decoy_photo_1.jpg', 'path2', 'image', 200, 'key2', 'iv2', 
      albumId: decoyAlbumId, authMode: AuthMode.decoy
    );

    var decoyItems = await vaultRepo.getMediaItems(authMode: AuthMode.decoy);
    expect(decoyItems.length, 1);
    expect(decoyItems.first.id, item2Id);

    // 3. Asserts Decoy items don't appear in Real Mode
    var realItemsCheck = await vaultRepo.getMediaItems(authMode: AuthMode.real);
    expect(realItemsCheck.length, 1);
    expect(realItemsCheck.first.id, item1Id); // Only real item is present

    // 4. Asserts Real items don't appear in Decoy Mode
    var decoyItemsCheck = await vaultRepo.getMediaItems(authMode: AuthMode.decoy);
    expect(decoyItemsCheck.length, 1);
    expect(decoyItemsCheck.first.id, item2Id); // Only decoy item is present
  });

  test('Trash restore returns the item to its original album', () async {
    final realAlbumId = await vaultRepo.getOrCreateMainAlbum(AuthMode.real);
    final itemId = await vaultRepo.insertMediaItem(
      'trash_test.jpg', 'path', 'image', 100, 'key', 'iv', 
      albumId: realAlbumId, authMode: AuthMode.real
    );

    // Verify it is in main list
    var items = await vaultRepo.getMediaItems(authMode: AuthMode.real);
    expect(items.length, 1);

    // Move to trash
    await vaultRepo.moveToTrash(itemId, authMode: AuthMode.real);
    
    items = await vaultRepo.getMediaItems(authMode: AuthMode.real);
    expect(items.length, 0); // Not in main list

    var trashedItems = await vaultRepo.getTrashedItems(authMode: AuthMode.real);
    expect(trashedItems.length, 1);
    expect(trashedItems.first.id, itemId);

    // Restore from trash
    await vaultRepo.restoreFromTrash(itemId, authMode: AuthMode.real);
    
    trashedItems = await vaultRepo.getTrashedItems(authMode: AuthMode.real);
    expect(trashedItems.length, 0);

    items = await vaultRepo.getMediaItems(authMode: AuthMode.real);
    expect(items.length, 1);
    expect(items.first.albumId, realAlbumId); // Returned to original album
  });
}
