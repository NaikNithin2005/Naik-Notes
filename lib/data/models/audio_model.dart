import 'package:flutter/foundation.dart';

/// Speed presets for audio playback.
enum AudioSpeed {
  speed1x(1.0, '1.0x'),
  speed125x(1.25, '1.25x'),
  speed15x(1.5, '1.5x'),
  speed2x(2.0, '2.0x');

  final double multiplier;
  final String label;
  const AudioSpeed(this.multiplier, this.label);

  AudioSpeed next() {
    const values = AudioSpeed.values;
    final nextIdx = (values.indexOf(this) + 1) % values.length;
    return values[nextIdx];
  }
}

/// A timestamped bookmark within an audio recording, synchronized with a page or stroke.
@immutable
class AudioBookmark {
  final String id;
  final String recordingId;
  final String? pageId;
  final String? strokeId;
  final int timestampMs;
  final String label;
  final DateTime createdAt;

  const AudioBookmark({
    required this.id,
    required this.recordingId,
    this.pageId,
    this.strokeId,
    required this.timestampMs,
    required this.label,
    required this.createdAt,
  });

  String get formattedTimestamp {
    final totalSeconds = (timestampMs / 1000).floor();
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recordingId': recordingId,
    'pageId': pageId,
    'strokeId': strokeId,
    'timestampMs': timestampMs,
    'label': label,
    'createdAt': createdAt.toIso8601String(),
  };

  factory AudioBookmark.fromJson(Map<String, dynamic> json) => AudioBookmark(
    id: json['id'] as String,
    recordingId: json['recordingId'] as String,
    pageId: json['pageId'] as String?,
    strokeId: json['strokeId'] as String?,
    timestampMs: json['timestampMs'] as int? ?? 0,
    label: json['label'] as String? ?? 'Bookmark',
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  AudioBookmark copyWith({
    String? id,
    String? recordingId,
    String? pageId,
    String? strokeId,
    int? timestampMs,
    String? label,
    DateTime? createdAt,
  }) {
    return AudioBookmark(
      id: id ?? this.id,
      recordingId: recordingId ?? this.recordingId,
      pageId: pageId ?? this.pageId,
      strokeId: strokeId ?? this.strokeId,
      timestampMs: timestampMs ?? this.timestampMs,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// An audio recording attached to a notebook or document.
@immutable
class AudioRecording {
  final String id;
  final String notebookId;
  final String? pageId;
  final String title;
  final String filePath;
  final int durationMs;
  final List<AudioBookmark> bookmarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AudioRecording({
    required this.id,
    required this.notebookId,
    this.pageId,
    this.title = 'Lecture Audio',
    required this.filePath,
    this.durationMs = 0,
    this.bookmarks = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedDuration {
    final totalSeconds = (durationMs / 1000).floor();
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'notebookId': notebookId,
    'pageId': pageId,
    'title': title,
    'filePath': filePath,
    'durationMs': durationMs,
    'bookmarks': bookmarks.map((b) => b.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory AudioRecording.fromJson(Map<String, dynamic> json) => AudioRecording(
    id: json['id'] as String,
    notebookId: json['notebookId'] as String,
    pageId: json['pageId'] as String?,
    title: json['title'] as String? ?? 'Lecture Audio',
    filePath: json['filePath'] as String? ?? '',
    durationMs: json['durationMs'] as int? ?? 0,
    bookmarks:
        (json['bookmarks'] as List<dynamic>?)
            ?.map((b) => AudioBookmark.fromJson(Map<String, dynamic>.from(b)))
            .toList() ??
        const [],
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    updatedAt:
        DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
  );

  AudioRecording copyWith({
    String? id,
    String? notebookId,
    String? pageId,
    String? title,
    String? filePath,
    int? durationMs,
    List<AudioBookmark>? bookmarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AudioRecording(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationMs: durationMs ?? this.durationMs,
      bookmarks: bookmarks ?? this.bookmarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
