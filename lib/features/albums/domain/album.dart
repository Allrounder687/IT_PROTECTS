enum AlbumType { mainVault, documents, privatePhotos, custom }

class Album {
  final int id; // SQLite ID
  final String name;
  final AlbumType type;
  final bool isLocked;
  final String? storageProviderId;
  final int itemCount;
  final bool isDecoyVisible;

  Album({
    required this.id,
    required this.name,
    required this.type,
    this.isLocked = false,
    this.storageProviderId,
    this.itemCount = 0,
    this.isDecoyVisible = false,
  });

  Album copyWith({
    int? id,
    String? name,
    AlbumType? type,
    bool? isLocked,
    String? storageProviderId,
    int? itemCount,
    bool? isDecoyVisible,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      isLocked: isLocked ?? this.isLocked,
      storageProviderId: storageProviderId ?? this.storageProviderId,
      itemCount: itemCount ?? this.itemCount,
      isDecoyVisible: isDecoyVisible ?? this.isDecoyVisible,
    );
  }

  factory Album.fromMap(Map<String, dynamic> map, int itemCount) {
    return Album(
      id: map['id'] as int,
      name: map['name'] as String,
      type: AlbumType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlbumType.custom,
      ),
      isLocked: (map['is_locked'] as int? ?? 0) == 1,
      storageProviderId: map['storage_provider_id'] as String?,
      itemCount: itemCount,
      isDecoyVisible: (map['is_decoy_visible'] as int? ?? 0) == 1,
    );
  }
}
