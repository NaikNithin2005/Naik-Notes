/// Domain model representing a permanent deletion tombstone.
/// Ensures permanently deleted notebooks and notes never resurrect through cloud sync,
/// even when stale offline devices reconnect later.
class Tombstone {
  final String id; // Original notebookId or noteId
  final String ownerId;
  final String entityType; // 'notebook' or 'note'
  final String deletionId;
  final DateTime deletedAt;
  final DateTime? syncedAt;

  const Tombstone({
    required this.id,
    required this.ownerId,
    required this.entityType,
    required this.deletionId,
    required this.deletedAt,
    this.syncedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'entityType': entityType,
    'deletionId': deletionId,
    'deletedAt': deletedAt.toIso8601String(),
    'syncedAt': syncedAt?.toIso8601String(),
  };

  factory Tombstone.fromJson(Map<String, dynamic> json) => Tombstone(
    id: json['id'] as String,
    ownerId: json['ownerId'] as String? ?? 'local_user',
    entityType: json['entityType'] as String,
    deletionId: json['deletionId'] as String,
    deletedAt: DateTime.parse(json['deletedAt'] as String),
    syncedAt: json['syncedAt'] != null
        ? DateTime.parse(json['syncedAt'] as String)
        : null,
  );
}

