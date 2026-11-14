import 'dart:ui';

/// A single entry in the hierarchical Table of Contents (outline) of a PDF.
class PdfOutlineItem {
  final String title;
  final int pageIndex; // 0-based
  final List<PdfOutlineItem> children;

  const PdfOutlineItem({
    required this.title,
    required this.pageIndex,
    this.children = const [],
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'pageIndex': pageIndex,
    'children': children.map((c) => c.toJson()).toList(),
  };

  factory PdfOutlineItem.fromJson(Map<String, dynamic> json) => PdfOutlineItem(
    title: json['title'] as String,
    pageIndex: json['pageIndex'] as int,
    children:
        (json['children'] as List<dynamic>?)
            ?.map((c) => PdfOutlineItem.fromJson(c as Map<String, dynamic>))
            .toList() ??
        const [],
  );
}

/// Metadata extracted from an imported PDF document.
class PdfDocumentMetadata {
  final String title;
  final String? author;
  final int pageCount;
  final int fileSizeBytes;
  final List<PdfOutlineItem> tableOfContents;
  final DateTime? creationDate;

  const PdfDocumentMetadata({
    required this.title,
    this.author,
    required this.pageCount,
    required this.fileSizeBytes,
    this.tableOfContents = const [],
    this.creationDate,
  });

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// A searchable text block extracted from a PDF page for text search and highlighting.
class PdfTextBlock {
  final String text;
  final Rect boundingBox;
  final int pageIndex;

  const PdfTextBlock({
    required this.text,
    required this.boundingBox,
    required this.pageIndex,
  });
}
