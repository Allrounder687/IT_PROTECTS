import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/vault_item_entity.dart';
import '../data/local_vault_repository.dart';
import 'pagination_state.dart';
import '../../../core/providers/auth_mode_provider.dart';

final searchNotifierProvider = AsyncNotifierProvider<SearchNotifier, PaginationState<VaultItemEntity>>(SearchNotifier.new);

class SearchNotifier extends AsyncNotifier<PaginationState<VaultItemEntity>> {
  static const int _pageSize = 50;
  Timer? _debounceTimer;
  String _currentQuery = '';

  @override
  Future<PaginationState<VaultItemEntity>> build() async {
    // Initial state is empty since no search is active
    return const PaginationState<VaultItemEntity>();
  }

  void onSearchChanged(String query) {
    _currentQuery = query;

    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
    }

    if (query.trim().isEmpty) {
      state = const AsyncData(PaginationState<VaultItemEntity>());
      return;
    }

    state = const AsyncLoading();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final authMode = ref.read(authModeProvider);
      final repo = ref.read(localVaultRepositoryProvider);
      try {
        final items = await repo.searchMediaItems(query, limit: _pageSize, offset: 0, authMode: authMode);
        state = AsyncData(PaginationState<VaultItemEntity>(
          items: items,
          page: 1,
          hasMore: items.length == _pageSize,
        ));
      } catch (e, st) {
        state = AsyncError(e, st);
      }
    });
  }

  Future<void> loadNextPage() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore || currentState.isLoadingNext || _currentQuery.trim().isEmpty) {
      return;
    }

    state = AsyncData(currentState.copyWith(isLoadingNext: true));

    try {
      final authMode = ref.read(authModeProvider);
      final repo = ref.read(localVaultRepositoryProvider);
      final nextItems = await repo.searchMediaItems(
        _currentQuery,
        limit: _pageSize,
        offset: currentState.page * _pageSize,
        authMode: authMode,
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
}
