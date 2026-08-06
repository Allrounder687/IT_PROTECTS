class VaultItemEntity {
  final int id;
  final int albumId;
  final String originalName;
  final String encryptedFilePath;
  final String type;
  final int size;
  final String wrappedContentKey;
  final String iv;

  VaultItemEntity({
    required this.id,
    required this.albumId,
    required this.originalName,
    required this.encryptedFilePath,
    required this.type,
    required this.size,
    required this.wrappedContentKey,
    required this.iv,
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
    );
  }
}
