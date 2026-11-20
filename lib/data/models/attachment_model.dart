import 'package:cloud_firestore/cloud_firestore.dart';

/// Supported storage providers for Naik Notes attachments.
class AttachmentStorageProvider {
  static const String googleDriveAppData = 'google_drive_appdata';
  static const String localOnly = 'local_only';
}

/// Synchronization and upload status lifecycle of an attachment.
class AttachmentUploadStatus {
  static const String pending = 'pending';
  static const String uploading = 'uploading';
  static const String uploaded = 'uploaded';
  static const String downloading = 'downloading';
  static const String availableOffline = 'available_offline';
  static const String failed = 'failed';
  static const String downloadFailed = 'download_failed';
  static const String driveDisconnected = 'drive_disconnected';
  static const String fileUnavailable = 'file_unavailable';
}

/// Domain model representing a note attachment stored in Google Drive's hidden `appDataFolder`
/// and referenced in Cloud Firestore and the local Drift SQLite database.
class NoteAttachment {
  final String attachmentId;
  final String? driveFileId;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String storageProvider;
  final DateTime createdAt;
  final DateTime? uploadedAt;
  final String checksum;
  final String uploadStatus;
  final bool isDeleted;
  final String? localPath;
  final String noteId;
  final String ownerId;
  final int retryCount;
  final String? lastError;

  const NoteAttachment({
    required this.attachmentId,
    this.driveFileId,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    this.storageProvider = AttachmentStorageProvider.googleDriveAppData,
    required this.createdAt,
    this.uploadedAt,
    required this.checksum,
    this.uploadStatus = AttachmentUploadStatus.pending,
    this.isDeleted = false,
    this.localPath,
    required this.noteId,
    required this.ownerId,
    this.retryCount = 0,
    this.lastError,
  });

  bool get isImage =>
      mimeType.startsWith('image/') ||
      fileName.endsWith('.png') ||
      fileName.endsWith('.jpg') ||
      fileName.endsWith('.jpeg') ||
      fileName.endsWith('.webp') ||
      fileName.endsWith('.gif');

  bool get isPdf =>
      mimeType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');

  String get humanReadableSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  NoteAttachment copyWith({
    String? attachmentId,
    String? driveFileId,
    String? fileName,
    String? mimeType,
    int? fileSize,
    String? storageProvider,
    DateTime? createdAt,
    DateTime? uploadedAt,
    String? checksum,
    String? uploadStatus,
    bool? isDeleted,
    String? localPath,
    String? noteId,
    String? ownerId,
    int? retryCount,
    String? lastError,
    bool clearDriveFileId = false,
    bool clearLocalPath = false,
  }) {
    return NoteAttachment(
      attachmentId: attachmentId ?? this.attachmentId,
      driveFileId: clearDriveFileId ? null : (driveFileId ?? this.driveFileId),
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      storageProvider: storageProvider ?? this.storageProvider,
      createdAt: createdAt ?? this.createdAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      checksum: checksum ?? this.checksum,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      localPath: clearLocalPath ? null : (localPath ?? this.localPath),
      noteId: noteId ?? this.noteId,
      ownerId: ownerId ?? this.ownerId,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  /// Converts this attachment to a Firestore-compliant map using native Timestamps.
  Map<String, dynamic> toFirestore() {
    return {
      'attachmentId': attachmentId,
      'driveFileId': driveFileId,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'storageProvider': storageProvider,
      'createdAt': Timestamp.fromDate(createdAt),
      'uploadedAt': uploadedAt != null ? Timestamp.fromDate(uploadedAt!) : null,
      'checksum': checksum,
      'uploadStatus': uploadStatus,
      'isDeleted': isDeleted,
      'schemaVersion': 1,
    };
  }

  /// Deserializes a Firestore map into a [NoteAttachment].
  factory NoteAttachment.fromFirestore(
    Map<String, dynamic> data, {
    required String noteId,
    required String ownerId,
    String? localPath,
  }) {
    DateTime parseTimestamp(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return NoteAttachment(
      attachmentId: data['attachmentId'] as String? ?? '',
      driveFileId: data['driveFileId'] as String?,
      fileName: data['fileName'] as String? ?? 'attachment',
      mimeType: data['mimeType'] as String? ?? 'application/octet-stream',
      fileSize: (data['fileSize'] as num?)?.toInt() ?? 0,
      storageProvider: data['storageProvider'] as String? ??
          AttachmentStorageProvider.googleDriveAppData,
      createdAt: parseTimestamp(data['createdAt']),
      uploadedAt: data['uploadedAt'] != null
          ? parseTimestamp(data['uploadedAt'])
          : null,
      checksum: data['checksum'] as String? ?? '',
      uploadStatus: data['uploadStatus'] as String? ??
          AttachmentUploadStatus.availableOffline,
      isDeleted: data['isDeleted'] as bool? ?? false,
      localPath: localPath,
      noteId: noteId,
      ownerId: ownerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'attachmentId': attachmentId,
      'driveFileId': driveFileId,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'storageProvider': storageProvider,
      'createdAt': createdAt.toIso8601String(),
      'uploadedAt': uploadedAt?.toIso8601String(),
      'checksum': checksum,
      'uploadStatus': uploadStatus,
      'isDeleted': isDeleted,
      'localPath': localPath,
      'noteId': noteId,
      'ownerId': ownerId,
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }

  factory NoteAttachment.fromJson(Map<String, dynamic> json) {
    return NoteAttachment(
      attachmentId: json['attachmentId'] as String,
      driveFileId: json['driveFileId'] as String?,
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      storageProvider: json['storageProvider'] as String? ??
          AttachmentStorageProvider.googleDriveAppData,
      createdAt: DateTime.parse(json['createdAt'] as String),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.parse(json['uploadedAt'] as String)
          : null,
      checksum: json['checksum'] as String,
      uploadStatus: json['uploadStatus'] as String? ?? AttachmentUploadStatus.pending,
      isDeleted: json['isDeleted'] as bool? ?? false,
      localPath: json['localPath'] as String?,
      noteId: json['noteId'] as String,
      ownerId: json['ownerId'] as String,
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }
}
