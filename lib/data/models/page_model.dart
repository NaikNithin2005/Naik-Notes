import 'paper_template_model.dart';

/// Domain model representing a notebook page with vector paper template properties.
class NotebookPage {
  final String id;
  final String notebookId;
  final String? sectionId;
  final int pageNumber;
  final String templateId;
  final PaperProperties properties;
  final double width;
  final double height;
  final bool isBookmarked;
  final int? pdfPageIndex;
  final int revision;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotebookPage({
    required this.id,
    required this.notebookId,
    this.sectionId,
    required this.pageNumber,
    required this.templateId,
    required this.properties,
    this.width = 595.28,
    this.height = 841.89,
    this.isBookmarked = false,
    this.pdfPageIndex,
    this.revision = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  PaperTemplateType get templateType => PaperTemplateType.fromId(templateId);

  NotebookPage copyWith({
    String? id,
    String? notebookId,
    String? sectionId,
    int? pageNumber,
    String? templateId,
    PaperProperties? properties,
    double? width,
    double? height,
    bool? isBookmarked,
    int? pdfPageIndex,
    int? revision,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearSectionId = false,
  }) {
    return NotebookPage(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      sectionId: clearSectionId ? null : (sectionId ?? this.sectionId),
      pageNumber: pageNumber ?? this.pageNumber,
      templateId: templateId ?? this.templateId,
      properties: properties ?? this.properties,
      width: width ?? this.width,
      height: height ?? this.height,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      pdfPageIndex: pdfPageIndex ?? this.pdfPageIndex,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notebookId': notebookId,
      'sectionId': sectionId,
      'pageNumber': pageNumber,
      'templateId': templateId,
      'properties': properties.toJson(),
      'width': width,
      'height': height,
      'isBookmarked': isBookmarked,
      'pdfPageIndex': pdfPageIndex,
      'revision': revision,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NotebookPage.fromJson(Map<String, dynamic> json) {
    final templateId = json['templateId'] as String? ?? 'college_ruled';
    final type = PaperTemplateType.fromId(templateId);
    final propsMap = json['properties'] as Map<String, dynamic>?;

    return NotebookPage(
      id: json['id'] as String,
      notebookId: json['notebookId'] as String,
      sectionId: json['sectionId'] as String?,
      pageNumber: json['pageNumber'] as int? ?? 1,
      templateId: templateId,
      properties: propsMap != null
          ? PaperProperties.fromJson(propsMap)
          : PaperProperties.defaultFor(type),
      width: (json['width'] as num?)?.toDouble() ?? 595.28,
      height: (json['height'] as num?)?.toDouble() ?? 841.89,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      pdfPageIndex: json['pdfPageIndex'] as int?,
      revision: json['revision'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
