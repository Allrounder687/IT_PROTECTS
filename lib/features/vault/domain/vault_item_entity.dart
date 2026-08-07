class VaultItemEntity {
  final int id;
  final int albumId;
  final String originalName;
  final String encryptedFilePath;
  final String type;
  final int size;
  final String wrappedContentKey;
  final String iv;
  final bool isTrashed;
  final int? deletedAt;
  final bool isFavourite;

  VaultItemEntity({
    required this.id,
    required this.albumId,
    required this.originalName,
    required this.encryptedFilePath,
    required this.type,
    required this.size,
    required this.wrappedContentKey,
    required this.iv,
    this.isTrashed = false,
    this.deletedAt,
    this.isFavourite = false,
  });

  factory VaultItemEntity.fromMap(Map<String, dynamic> map) {
    return VaultItemEntity(
      id: map['id'],
      albumId: map['album_id'],
      originalName: map['original_name'],
      encryptedFilePath: map['encrypted_file_path'],
      type: map['type'],
      size: map['size'],
      wrappedContentKey: map['wrapped_content_key'],
      iv: map['iv'],
      isTrashed: map['is_trashed'] == 1,
      deletedAt: map['deleted_at'],
      isFavourite: map['is_favourite'] == 1,
    );
  }
}
