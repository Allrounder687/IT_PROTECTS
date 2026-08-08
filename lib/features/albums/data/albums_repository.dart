import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/data/local_vault_repository.dart';
import '../domain/album.dart';

import '../../../core/providers/auth_mode_provider.dart';

final albumsRepositoryProvider = Provider<AlbumsRepository>((ref) {
  return AlbumsRepositoryImpl(ref);
});

abstract class AlbumsRepository {
  Future<List<Album>> loadAlbums({AuthMode authMode = AuthMode.real});
  Future<Album> createAlbum(String name, String? providerId, {required AuthMode authMode});
  Future<Album> setAlbumLock(int albumId, bool locked, {required AuthMode authMode});
  Future<Album> setAlbumName(int albumId, String newName, {required AuthMode authMode});
  Future<Album> setAlbumProvider(int albumId, String? providerId, {required AuthMode authMode});
  Future<Album> setAlbumCover(int albumId, int coverItemId, {required AuthMode authMode});
}

class AlbumsRepositoryImpl implements AlbumsRepository {
  final Ref _ref;
  AlbumsRepositoryImpl(this._ref);

  @override
  Future<List<Album>> loadAlbums({AuthMode authMode = AuthMode.real}) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.loadAlbums(authMode: authMode);
  }

  @override
  Future<Album> createAlbum(String name, String? providerId, {required AuthMode authMode}) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.createAlbum(name, providerId, authMode: authMode);
  }

  @override
  Future<Album> setAlbumLock(int albumId, bool locked, {required AuthMode authMode}) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.updateAlbumLock(albumId, locked, authMode: authMode);
  }

  @override
  Future<Album> setAlbumName(int albumId, String newName, {required AuthMode authMode}) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.updateAlbumName(albumId, newName, authMode: authMode);
  }

  @override
  Future<Album> setAlbumProvider(int albumId, String? providerId, {required AuthMode authMode}) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.updateAlbumProvider(albumId, providerId, authMode: authMode);
  }

  @override
  Future<Album> setAlbumCover(int albumId, int coverItemId, {required AuthMode authMode}) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.updateAlbumCover(albumId, coverItemId, authMode: authMode);
  }
}
