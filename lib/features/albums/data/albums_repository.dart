import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/data/local_vault_repository.dart';
import '../domain/album.dart';

import '../../../core/providers/auth_mode_provider.dart';

final albumsRepositoryProvider = Provider<AlbumsRepository>((ref) {
  return AlbumsRepositoryImpl(ref);
});

abstract class AlbumsRepository {
  Future<List<Album>> loadAlbums({AuthMode authMode = AuthMode.real});
  Future<Album> createAlbum(String name, String? providerId);
  Future<Album> setAlbumLock(int albumId, bool locked);
  Future<Album> setAlbumName(int albumId, String newName);
  Future<Album> setAlbumProvider(int albumId, String? providerId);
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
  Future<Album> createAlbum(String name, String? providerId) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.createAlbum(name, providerId);
  }

  @override
  Future<Album> setAlbumLock(int albumId, bool locked) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.updateAlbumLock(albumId, locked);
  }

  @override
  Future<Album> setAlbumName(int albumId, String newName) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.updateAlbumName(albumId, newName);
  }

  @override
  Future<Album> setAlbumProvider(int albumId, String? providerId) async {
    final vaultRepo = _ref.read(localVaultRepositoryProvider);
    return await vaultRepo.updateAlbumProvider(albumId, providerId);
  }
}
