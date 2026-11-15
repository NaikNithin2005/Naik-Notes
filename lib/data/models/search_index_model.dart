import 'dart:convert';

import 'package:flutter/material.dart';

/// Bounding box and metadata for an individual recognized word or text fragment.
@immutable
class WordBoundingBox {
  final String word;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;
  final List<String> strokeIds;

  const WordBoundingBox({
    required this.word,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    this.confidence = 1.0,
    this.strokeIds = const [],
  });

  Rect get rect => Rect.fromLTRB(left, top, right, bottom);
  double get width => (right - left).abs();
  double get height => (bottom - top).abs();

  Map<String, dynamic> toJson() => {
    'word': word,
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
    'confidence': confidence,
    'strokeIds': strokeIds,
  };

  factory WordBoundingBox.fromJson(Map<String, dynamic> json) {
    return WordBoundingBox(
      word: json['word'] as String? ?? '',
      left: (json['left'] as num?)?.toDouble() ?? 0.0,
      top: (json['top'] as num?)?.toDouble() ?? 0.0,
      right: (json['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (json['bottom'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      strokeIds:
          (json['strokeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  WordBoundingBox copyWith({
    String? word,
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? confidence,
    List<String>? strokeIds,
  }) {
    return WordBoundingBox(
      word: word ?? this.word,
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      confidence: confidence ?? this.confidence,
      strokeIds: strokeIds ?? this.strokeIds,
    );
  }
}

/// An indexed text entry for a document page in SQLite.
@immutable
class PageSearchEntry {
  final String id;
  final String pageId;
  final String notebookId;
  final String sourceType; // 'handwriting', 'pdf', 'sticky_note'
  final String textContent;
  final List<WordBoundingBox> boundingBoxes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PageSearchEntry({
    required this.id,
    required this.pageId,
    required this.notebookId,
    required this.sourceType,
    required this.textContent,
    this.boundingBoxes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get boundingBoxesJson =>
      jsonEncode(boundingBoxes.map((b) => b.toJson()).toList());

  factory PageSearchEntry.fromDatabase({
    required String id,
    required String pageId,
    required String notebookId,
    required String sourceType,
    required String textContent,
    String? boundingBoxesJson,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    List<WordBoundingBox> boxes = [];
    if (boundingBoxesJson != null && boundingBoxesJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(boundingBoxesJson) as List;
        boxes = decoded
            .map((b) => WordBoundingBox.fromJson(Map<String, dynamic>.from(b)))
            .toList();
      } catch (_) {}
    }

    return PageSearchEntry(
      id: id,
      pageId: pageId,
      notebookId: notebookId,
      sourceType: sourceType,
      textContent: textContent,
      boundingBoxes: boxes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Structured search result item returned across global or in-document searches.
@immutable
class SearchResultItem {
  final String notebookId;
  final String notebookTitle;
  final String? pageId;
  final int? pageNumber;
  final String snippet;
  final String matchedTerm;
  final String
  sourceType; // 'notebookTitle', 'handwriting', 'stickyNote', 'pdf'
  final List<WordBoundingBox> matchingBoxes;

  const SearchResultItem({
    required this.notebookId,
    required this.notebookTitle,
    this.pageId,
    this.pageNumber,
    required this.snippet,
    required this.matchedTerm,
    required this.sourceType,
    this.matchingBoxes = const [],
  });

  @override
  String toString() =>
      'SearchResultItem(nb: $notebookTitle, page: $pageNumber, snippet: "$snippet", type: $sourceType)';
}
