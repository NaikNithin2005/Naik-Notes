import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:uuid/uuid.dart';

/// Domain model representing a rich-text note in Naik Notes.
class Note {
  final String id;
  final String ownerId;
  final String notebookId;
  final String title;
  final String contentDelta; // JSON string of Quill Delta
  final String plainText; // Extracted plain text for fast zero-cost search
  final String preview; // Short plain text snippet for note cards
  final List<String> tags;
  final bool isPinned;
  final bool isFavorite;
  final bool isArchived;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? deletionId;
  final String syncStatus;
  final DateTime? lastSyncedAt;
  final int localVersion;
  final int serverVersion;
  final String? deviceId;
  final String? lastModifiedBy;

  const Note({
    required this.id,
    required this.ownerId,
    required this.notebookId,
    required this.title,
    required this.contentDelta,
    required this.plainText,
    required this.preview,
    this.tags = const [],
    this.isPinned = false,
    this.isFavorite = false,
    this.isArchived = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.deletionId,
    this.syncStatus = 'synced',
    this.lastSyncedAt,
    this.localVersion = 1,
    this.serverVersion = 1,
    this.deviceId,
    this.lastModifiedBy,
  });

  /// Creates a blank note with empty Quill Delta JSON.
  factory Note.createBlank({
    required String ownerId,
    required String notebookId,
    String title = 'Untitled Note',
    List<String> tags = const [],
    String? deviceId,
    String? lastModifiedBy,
  }) {
    final now = DateTime.now();
    const defaultDeltaJson = '[{"insert":"\\n"}]';
    return Note(
      id: const Uuid().v4(),
      ownerId: ownerId,
      notebookId: notebookId,
      title: title,
      contentDelta: defaultDeltaJson,
      plainText: '',
      preview: '',
      tags: tags,
      isPinned: false,
      isFavorite: false,
      isArchived: false,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'synced',
      localVersion: 1,
      serverVersion: 1,
      deviceId: deviceId,
      lastModifiedBy: lastModifiedBy,
    );
  }

  /// Extracts plain text from a Quill Delta JSON string.
  static String extractPlainText(String deltaJson) {
    if (deltaJson.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(deltaJson);
      final doc = Document.fromJson(decoded);
      return doc.toPlainText().trim();
    } catch (_) {
      return '';
    }
  }

  /// Generates a preview snippet from plain text (up to maxChars).
  static String generatePreview(String plainText, {int maxChars = 140}) {
    final cleaned = plainText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxChars) return cleaned;
    return '${cleaned.substring(0, maxChars)}...';
  }

  /// Creates a copy of this note with updated fields.
  Note copyWith({
    String? id,
    String? ownerId,
    String? notebookId,
    String? title,
    String? contentDelta,
    String? plainText,
    String? preview,
    List<String>? tags,
    bool? isPinned,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? deletionId,
    String? syncStatus,
    DateTime? lastSyncedAt,
    int? localVersion,
    int? serverVersion,
    String? deviceId,
    String? lastModifiedBy,
    bool clearDeletedAt = false,
    bool clearDeletionId = false,
  }) {
    final newDelta = contentDelta ?? this.contentDelta;
    final newPlainText = plainText ??
        (contentDelta != null ? extractPlainText(newDelta) : this.plainText);
    final newPreview = preview ??
        (contentDelta != null ? generatePreview(newPlainText) : this.preview);

    return Note(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      notebookId: notebookId ?? this.notebookId,
      title: title ?? this.title,
      contentDelta: newDelta,
      plainText: newPlainText,
      preview: newPreview,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      deletionId: clearDeletionId ? null : (deletionId ?? this.deletionId),
      syncStatus: syncStatus ?? this.syncStatus,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      localVersion: localVersion ?? this.localVersion,
      serverVersion: serverVersion ?? this.serverVersion,
      deviceId: deviceId ?? this.deviceId,
      lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'notebookId': notebookId,
      'title': title,
      'contentDelta': contentDelta,
      'plainText': plainText,
      'preview': preview,
      'tags': tags,
      'isPinned': isPinned,
      'isFavorite': isFavorite,
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'deletionId': deletionId,
      'syncStatus': syncStatus,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'localVersion': localVersion,
      'serverVersion': serverVersion,
      'deviceId': deviceId,
      'lastModifiedBy': lastModifiedBy,
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    final rawDelta = json['contentDelta'] as String? ?? '[{"insert":"\\n"}]';
    final rawText = json['plainText'] as String? ?? Note.extractPlainText(rawDelta);
    final rawPreview = json['preview'] as String? ?? Note.generatePreview(rawText);

    return Note(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? 'local_user',
      notebookId: json['notebookId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Note',
      contentDelta: rawDelta,
      plainText: rawText,
      preview: rawPreview,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isPinned: json['isPinned'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
      deletionId: json['deletionId'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'synced',
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      localVersion: json['localVersion'] as int? ?? 1,
      serverVersion: json['serverVersion'] as int? ?? 1,
      deviceId: json['deviceId'] as String?,
      lastModifiedBy: json['lastModifiedBy'] as String?,
    );
  }
}
