import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vault/domain/vault_item_entity.dart';
import '../../vault/data/local_vault_repository.dart';
import '../../../core/providers/auth_mode_provider.dart';

final trashNotifierProvider = AsyncNotifierProvider<TrashNotifier, List<VaultItemEntity>>(TrashNotifier.new);

class TrashNotifier extends AsyncNotifier<List<VaultItemEntity>> {
  @override
  Future<List<VaultItemEntity>> build() async {
    final authMode = ref.watch(authModeProvider);
    final repo = ref.read(localVaultRepositoryProvider);
    return await repo.getTrashedItems(limit: 100, offset: 0, authMode: authMode);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authMode = ref.read(authModeProvider);
      final repo = ref.read(localVaultRepositoryProvider);
      return repo.getTrashedItems(limit: 100, offset: 0, authMode: authMode);
    });
  }

  Future<void> restoreItem(int itemId) async {
    final repo = ref.read(localVaultRepositoryProvider);
    await repo.restoreFromTrash(itemId);
    await refresh();
  }

  Future<void> deleteItemPermanently(int itemId) async {
    final repo = ref.read(localVaultRepositoryProvider);
    await repo.deleteItemPermanently(itemId);
    await refresh();
  }

  Future<void> emptyTrash() async {
    final items = state.valueOrNull ?? [];
    final repo = ref.read(localVaultRepositoryProvider);
    for (final item in items) {
      await repo.deleteItemPermanently(item.id);
    }
    await refresh();
  }
}
