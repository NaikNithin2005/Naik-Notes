/// Domain model representing a Naik Notes notebook.
class Notebook {
  final String id;
  final String ownerId;
  final String? folderId;
  final String title;
  final String description;
  final String coverId;
  final String coverColorHex;
  final String? coverImageUrl;
  final String? coverDriveId;
  final String? coverFileName;
  final DateTime? coverUpdatedAt;
  final String? coverImageBase64;
  final String paperTemplateId;
  final String orientation; // 'portrait' | 'landscape'
  final String pageSize; // 'A4' | 'Letter' | 'Custom'
  final int pageCount;
  final bool isFavorite;
  final bool isArchived;
  final bool isPdf;
  final String? pdfPath;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletionId;
  final String syncStatus;
  final DateTime? lastSyncedAt;

  bool get isDeleted => deletedAt != null;

  const Notebook({
    required this.id,
    required this.ownerId,
    this.folderId,
    required this.title,
    this.description = '',
    required this.coverId,
    this.coverColorHex = '#8B4513',
    this.coverImageUrl,
    this.coverDriveId,
    this.coverFileName,
    this.coverUpdatedAt,
    this.coverImageBase64,
    this.paperTemplateId = 'college_ruled',
    this.orientation = 'portrait',
    this.pageSize = 'A4',
    this.pageCount = 1,
    this.isFavorite = false,
    this.isArchived = false,
    this.isPdf = false,
    this.pdfPath,
    this.revision = 1,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.deletionId,
    this.syncStatus = 'synced',
    this.lastSyncedAt,
  });

  Notebook copyWith({
    String? id,
    String? ownerId,
    String? folderId,
    String? title,
    String? description,
    String? coverId,
    String? coverColorHex,
    String? coverImageUrl,
    String? coverDriveId,
    String? coverFileName,
    DateTime? coverUpdatedAt,
    String? coverImageBase64,
    String? paperTemplateId,
    String? orientation,
    String? pageSize,
    int? pageCount,
    bool? isFavorite,
    bool? isArchived,
    bool? isPdf,
    String? pdfPath,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletionId,
    String? syncStatus,
    DateTime? lastSyncedAt,
    bool clearFolderId = false,
    bool clearCoverImageUrl = false,
    bool clearCoverDriveId = false,
    bool clearCoverImageBase64 = false,
    bool clearDeletedAt = false,
    bool clearDeletionId = false,
  }) {
    return Notebook(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      title: title ?? this.title,
      description: description ?? this.description,
      coverId: coverId ?? this.coverId,
      coverColorHex: coverColorHex ?? this.coverColorHex,
      coverImageUrl: clearCoverImageUrl
          ? null
          : (coverImageUrl ?? this.coverImageUrl),
      coverDriveId: clearCoverDriveId
          ? null
          : (coverDriveId ?? this.coverDriveId),
      coverFileName: clearCoverDriveId
          ? null
          : (coverFileName ?? this.coverFileName),
      coverUpdatedAt: clearCoverDriveId
          ? null
          : (coverUpdatedAt ?? this.coverUpdatedAt),
      coverImageBase64: clearCoverImageBase64
          ? null
          : (coverImageBase64 ?? this.coverImageBase64),
      paperTemplateId: paperTemplateId ?? this.paperTemplateId,
      orientation: orientation ?? this.orientation,
      pageSize: pageSize ?? this.pageSize,
      pageCount: pageCount ?? this.pageCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isPdf: isPdf ?? this.isPdf,
      pdfPath: pdfPath ?? this.pdfPath,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      deletionId: clearDeletionId ? null : (deletionId ?? this.deletionId),
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'folderId': folderId,
      'title': title,
      'description': description,
      'coverId': coverId,
      'coverColorHex': coverColorHex,
      'coverImageUrl': coverImageUrl,
      'coverDriveId': coverDriveId,
      'coverFileName': coverFileName,
      'coverUpdatedAt': coverUpdatedAt?.toIso8601String(),
      'coverImageBase64': coverImageBase64,
      'paperTemplateId': paperTemplateId,
      'orientation': orientation,
      'pageSize': pageSize,
      'pageCount': pageCount,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'isPdf': isPdf,
      'pdfPath': pdfPath,
      'revision': revision,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletionId': deletionId,
      'syncStatus': syncStatus,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? 'local_user',
      folderId: json['folderId'] as String?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      coverId: json['coverId'] as String? ?? 'classic_leather',
      coverColorHex: json['coverColorHex'] as String? ?? '#8B4513',
      coverImageUrl: json['coverImageUrl'] as String?,
      coverDriveId: json['coverDriveId'] as String?,
      coverFileName: json['coverFileName'] as String?,
      coverUpdatedAt: json['coverUpdatedAt'] != null
          ? DateTime.tryParse(json['coverUpdatedAt'] as String)
          : null,
      coverImageBase64: json['coverImageBase64'] as String?,
      paperTemplateId: json['paperTemplateId'] as String? ?? 'college_ruled',
      orientation: json['orientation'] as String? ?? 'portrait',
      pageSize: json['pageSize'] as String? ?? 'A4',
      pageCount: json['pageCount'] as int? ?? 1,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isPdf: json['isPdf'] as bool? ?? false,
      pdfPath: json['pdfPath'] as String?,
      revision: json['revision'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      deletionId: json['deletionId'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'synced',
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
    );
  }
}
