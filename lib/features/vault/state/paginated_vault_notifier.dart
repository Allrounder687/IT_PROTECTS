import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vault_item_entity.dart';
import '../data/local_vault_repository.dart';
import 'pagination_state.dart';
import '../../../core/providers/auth_mode_provider.dart';

final paginatedVaultProvider = AsyncNotifierProvider.family<PaginatedVaultNotifier, PaginationState<VaultItemEntity>, int?>(PaginatedVaultNotifier.new);

class PaginatedVaultNotifier extends FamilyAsyncNotifier<PaginationState<VaultItemEntity>, int?> {
  static const int _pageSize = 50;

  @override
  Future<PaginationState<VaultItemEntity>> build(int? arg) async {
    final authMode = ref.watch(authModeProvider);
    final repo = ref.read(localVaultRepositoryProvider);
    final items = await repo.getMediaItems(limit: _pageSize, offset: 0, authMode: authMode, albumId: arg);
    return PaginationState<VaultItemEntity>(
      items: items,
      page: 1,
      hasMore: items.length == _pageSize,
    );
  }

  Future<void> loadNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore || currentState.isLoadingNext) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingNext: true));

    try {
      final authMode = ref.read(authModeProvider);
      final repo = ref.read(localVaultRepositoryProvider);
      final nextItems = await repo.getMediaItems(
        limit: _pageSize, 
        offset: currentState.page * _pageSize,
        authMode: authMode,
        albumId: arg,
      );

      state = AsyncData(PaginationState<VaultItemEntity>(
        items: [...currentState.items, ...nextItems],
        page: currentState.page + 1,
        hasMore: nextItems.length == _pageSize,
        isLoadingNext: false,
      ));
    } catch (e) {
      state = AsyncData(currentState.copyWith(isLoadingNext: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final authMode = ref.read(authModeProvider);
    final repo = ref.read(localVaultRepositoryProvider);
    try {
      final items = await repo.getMediaItems(limit: _pageSize, offset: 0, authMode: authMode, albumId: arg);
      state = AsyncData(PaginationState<VaultItemEntity>(
        items: items,
        page: 1,
        hasMore: items.length == _pageSize,
      ));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
