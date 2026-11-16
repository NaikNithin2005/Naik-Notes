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

  const Notebook({
    required this.id,
    required this.ownerId,
    this.folderId,
    required this.title,
    this.description = '',
    required this.coverId,
    this.coverColorHex = '#8B4513',
    this.coverImageUrl,
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
    bool clearFolderId = false,
    bool clearCoverImageUrl = false,
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
      deletedAt: deletedAt ?? this.deletedAt,
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
    );
  }
}
