import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/album.dart';
import '../data/albums_repository.dart';
import '../../../core/providers/auth_mode_provider.dart';
import '../../providers/state/sync_status_notifier.dart';

final albumsNotifierProvider = AsyncNotifierProvider<AlbumsNotifier, List<Album>>(AlbumsNotifier.new);

class AlbumsNotifier extends AsyncNotifier<List<Album>> {
  @override
  Future<List<Album>> build() async {
    final authMode = ref.watch(authModeProvider);
    final repo = ref.read(albumsRepositoryProvider);
    
    // Refresh albums when sync finishes to update counts/covers
    ref.listen(syncStatusProvider, (previous, next) {
      if ((previous?.value == SyncState.syncingDown || previous?.value == SyncState.syncingUp) && 
          next.value == SyncState.idle) {
        refresh();
      }
    });

    return await repo.loadAlbums(authMode: authMode);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authMode = ref.read(authModeProvider);
      final repo = ref.read(albumsRepositoryProvider);
      return repo.loadAlbums(authMode: authMode);
    });
  }

  Future<void> createAlbum(String name, String? providerId) async {
    final repo = ref.read(albumsRepositoryProvider);
    final authMode = ref.read(authModeProvider);
    final newAlbum = await repo.createAlbum(name, providerId, authMode: authMode);
    state = state.whenData((albums) => [...albums, newAlbum]);
  }

  Future<void> toggleAlbumLock(int albumId, bool locked) async {
    final repo = ref.read(albumsRepositoryProvider);
    final authMode = ref.read(authModeProvider);
    final updated = await repo.setAlbumLock(albumId, locked, authMode: authMode);
    state = state.whenData(
      (albums) => albums.map((a) => a.id == albumId ? updated : a).toList(),
    );
  }

  Future<void> renameAlbum(int albumId, String newName) async {
    final repo = ref.read(albumsRepositoryProvider);
    final authMode = ref.read(authModeProvider);
    final updated = await repo.setAlbumName(albumId, newName, authMode: authMode);
    state = state.whenData(
      (albums) => albums.map((a) => a.id == albumId ? updated : a).toList(),
    );
  }

  Future<void> changeAlbumProvider(int albumId, String? providerId) async {
    final repo = ref.read(albumsRepositoryProvider);
    final authMode = ref.read(authModeProvider);
    final updated = await repo.setAlbumProvider(albumId, providerId, authMode: authMode);
    state = state.whenData(
      (albums) => albums.map((a) => a.id == albumId ? updated : a).toList(),
    );
  }

  Future<void> setAlbumCover(int albumId, int coverItemId) async {
    final repo = ref.read(albumsRepositoryProvider);
    final authMode = ref.read(authModeProvider);
    final updated = await repo.setAlbumCover(albumId, coverItemId, authMode: authMode);
    state = state.whenData(
      (albums) => albums.map((a) => a.id == albumId ? updated : a).toList(),
    );
  }
}
