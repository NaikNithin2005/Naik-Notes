import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';

/// Represents a historical snapshot of a page's content, layout, and annotations.
@immutable
class PageSnapshot {
  final String id;
  final String pageId;
  final String notebookId;
  final int versionNumber;
  final String label;
  final List<Stroke> strokes;
  final List<StickyNote> stickyNotes;
  final String templateId;
  final PaperProperties? templateProperties;
  final String deviceInfo;
  final DateTime createdAt;

  const PageSnapshot({
    required this.id,
    required this.pageId,
    required this.notebookId,
    required this.versionNumber,
    required this.label,
    required this.strokes,
    this.stickyNotes = const [],
    this.templateId = 'college_ruled',
    this.templateProperties,
    this.deviceInfo = 'Local Device',
    required this.createdAt,
  });

  String get formattedDate {
    final y = createdAt.year;
    final m = createdAt.month.toString().padLeft(2, '0');
    final d = createdAt.day.toString().padLeft(2, '0');
    final h = createdAt.hour.toString().padLeft(2, '0');
    final min = createdAt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }

  int get strokeCount => strokes.length;
  int get noteCount => stickyNotes.length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'page_id': pageId,
    'notebook_id': notebookId,
    'version_number': versionNumber,
    'label': label,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'sticky_notes': stickyNotes.map((n) => n.toJson()).toList(),
    'template_id': templateId,
    'template_properties': templateProperties?.toJson(),
    'device_info': deviceInfo,
    'created_at': createdAt.toIso8601String(),
  };

  factory PageSnapshot.fromJson(Map<String, dynamic> json) => PageSnapshot(
    id: json['id'] as String,
    pageId: json['page_id'] as String,
    notebookId: json['notebook_id'] as String,
    versionNumber: json['version_number'] as int? ?? 1,
    label: json['label'] as String? ?? 'Snapshot',
    strokes:
        (json['strokes'] as List<dynamic>?)
            ?.map((e) => Stroke.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    stickyNotes:
        (json['sticky_notes'] as List<dynamic>?)
            ?.map((e) => StickyNote.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    templateId: json['template_id'] as String? ?? 'college_ruled',
    templateProperties: json['template_properties'] != null
        ? PaperProperties.fromJson(
            json['template_properties'] as Map<String, dynamic>,
          )
        : null,
    deviceInfo: json['device_info'] as String? ?? 'Local Device',
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static List<Stroke> parseStrokesJson(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => Stroke.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<StickyNote> parseStickyNotesJson(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((e) => StickyNote.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

/// Difference summary between two revisions of a page.
class PageDiffSummary {
  final int strokesBefore;
  final int strokesAfter;
  final int notesBefore;
  final int notesAfter;

  const PageDiffSummary({
    required this.strokesBefore,
    required this.strokesAfter,
    required this.notesBefore,
    required this.notesAfter,
  });

  int get strokesDelta => strokesAfter - strokesBefore;
  int get notesDelta => notesAfter - notesBefore;

  String get summaryText {
    final strokeStr = strokesDelta >= 0
        ? '+$strokesDelta strokes'
        : '$strokesDelta strokes';
    final noteStr = notesDelta >= 0
        ? '+$notesDelta notes'
        : '$notesDelta notes';
    return '$strokeStr, $noteStr';
  }
}
