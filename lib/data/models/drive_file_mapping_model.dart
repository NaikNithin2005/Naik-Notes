/// Domain model mapping local entity IDs to Google Drive file/folder IDs.
/// Prevents creating duplicate files or folders in Google Drive during sync retries.
class DriveFileMapping {
  final String entityId;
  final String ownerId;
  final String entityType; // 'notebook_folder', 'notebook_file', 'page_file', 'note_file'
  final String driveFileId;
  final DateTime updatedAt;

  const DriveFileMapping({
    required this.entityId,
    required this.ownerId,
    required this.entityType,
    required this.driveFileId,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'entityId': entityId,
    'ownerId': ownerId,
    'entityType': entityType,
    'driveFileId': driveFileId,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory DriveFileMapping.fromJson(Map<String, dynamic> json) => DriveFileMapping(
    entityId: json['entityId'] as String,
    ownerId: json['ownerId'] as String? ?? 'local_user',
    entityType: json['entityType'] as String,
    driveFileId: json['driveFileId'] as String,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

