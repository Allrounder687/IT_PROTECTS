class PaginationState<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoadingNext;

  const PaginationState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingNext = false,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingNext,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingNext: isLoadingNext ?? this.isLoadingNext,
    );
  }
}
