enum SyncOperation {
  upload,
  update,
  delete,
}

class SyncJob {
  final int? id;
  final int itemId;
  final int albumId; // If 0, assume main vault
  final SyncOperation operation;
  final String targetProviderId;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;

  const SyncJob({
    this.id,
    required this.itemId,
    this.albumId = 0,
    required this.operation,
    required this.targetProviderId,
    this.retryCount = 0,
    this.lastError,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'album_id': albumId,
      'operation': operation.name,
      'target_provider_id': targetProviderId,
      'retry_count': retryCount,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SyncJob.fromMap(Map<String, dynamic> map) {
    return SyncJob(
      id: map['id'] as int?,
      itemId: map['item_id'] as int,
      albumId: map['album_id'] as int? ?? 0,
      operation: SyncOperation.values.firstWhere((e) => e.name == map['operation']),
      targetProviderId: map['target_provider_id'] as String,
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SyncJob copyWith({
    int? id,
    int? itemId,
    int? albumId,
    SyncOperation? operation,
    String? targetProviderId,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
  }) {
    return SyncJob(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      albumId: albumId ?? this.albumId,
      operation: operation ?? this.operation,
      targetProviderId: targetProviderId ?? this.targetProviderId,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
