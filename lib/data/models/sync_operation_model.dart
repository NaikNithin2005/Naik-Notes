import 'dart:convert';

/// Supported entity types in the sync engine.
enum SyncEntityType {
  notebook('notebook'),
  folder('folder'),
  page('page'),
  stroke('stroke'),
  stickyNote('sticky_note');

  final String value;
  const SyncEntityType(this.value);

  static SyncEntityType fromValue(String value) {
    return SyncEntityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncEntityType.notebook,
    );
  }
}

/// Operation types recorded in the sync queue.
enum SyncOperationType {
  insert('insert'),
  update('update'),
  delete('delete');

  final String value;
  const SyncOperationType(this.value);

  static SyncOperationType fromValue(String value) {
    return SyncOperationType.values.firstWhere(
      (e) => e.value.toLowerCase() == value.toLowerCase(),
      orElse: () => SyncOperationType.update,
    );
  }
}

/// Current queue processing status.
enum SyncQueueStatus {
  pending('pending'),
  syncing('syncing'),
  synced('synced'),
  failed('failed');

  final String value;
  const SyncQueueStatus(this.value);

  static SyncQueueStatus fromValue(String value) {
    return SyncQueueStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SyncQueueStatus.pending,
    );
  }
}

/// A queued local mutation to be synchronized with the remote backend.
class SyncOperation {
  final String id;
  final String ownerId;
  final SyncEntityType entityType;
  final String entityId;
  final String? parentId;
  final SyncOperationType operationType;
  final Map<String, dynamic> payload;
  final int revision;
  final DateTime createdAt;
  final SyncQueueStatus status;
  final int retryCount;
  final String? lastError;

  const SyncOperation({
    required this.id,
    this.ownerId = 'local_user',
    required this.entityType,
    required this.entityId,
    this.parentId,
    required this.operationType,
    required this.payload,
    required this.revision,
    required this.createdAt,
    this.status = SyncQueueStatus.pending,
    this.retryCount = 0,
    this.lastError,
  });

  SyncOperation copyWith({
    String? id,
    String? ownerId,
    SyncEntityType? entityType,
    String? entityId,
    String? parentId,
    SyncOperationType? operationType,
    Map<String, dynamic>? payload,
    int? revision,
    DateTime? createdAt,
    SyncQueueStatus? status,
    int? retryCount,
    String? lastError,
    bool clearParentId = false,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      operationType: operationType ?? this.operationType,
      payload: payload ?? this.payload,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'entity_type': entityType.value,
      'entity_id': entityId,
      'parent_id': parentId,
      'operation_type': operationType.value,
      'payload': payload,
      'revision': revision,
      'created_at': createdAt.millisecondsSinceEpoch,
      'status': status.value,
      'retry_count': retryCount,
      'last_error': lastError,
    };
  }

  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? 'local_user',
      entityType: SyncEntityType.fromValue(json['entity_type'] as String),
      entityId: json['entity_id'] as String,
      parentId: json['parent_id'] as String?,
      operationType: SyncOperationType.fromValue(
        json['operation_type'] as String,
      ),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : (json['payload'] is String
                ? jsonDecode(json['payload'] as String)
                : {}),
      revision: json['revision'] as int? ?? 1,
      createdAt: json['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int)
          : DateTime.parse(json['created_at'] as String),
      status: json['status'] != null
          ? SyncQueueStatus.fromValue(json['status'] as String)
          : SyncQueueStatus.pending,
      retryCount: json['retry_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }
}
