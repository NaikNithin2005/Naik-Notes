import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/note_model.dart';

void main() {
  group('Note Model Unit Tests', () {
    test('Note.createBlank creates valid initial state with Quill delta', () {
      final note = Note.createBlank(
        ownerId: 'user_123',
        notebookId: 'nb_abc',
        title: 'Meeting Notes',
        tags: ['work', 'meeting'],
      );

      expect(note.id, isNotEmpty);
      expect(note.ownerId, 'user_123');
      expect(note.notebookId, 'nb_abc');
      expect(note.title, 'Meeting Notes');
      expect(note.tags, ['work', 'meeting']);
      expect(note.isPinned, isFalse);
      expect(note.isFavorite, isFalse);
      expect(note.isArchived, isFalse);
      expect(note.isDeleted, isFalse);
      expect(note.deletedAt, isNull);

      // Verify Delta JSON
      final delta = jsonDecode(note.contentDelta) as List;
      expect(delta, isNotEmpty);
      expect(delta.first['insert'], '\n');
    });

    test('extractPlainText extracts clean text from Delta JSON', () {
      const deltaJson =
          r'[{"insert":"Hello World!\n"},{"insert":"Second line\n"}]';
      final text = Note.extractPlainText(deltaJson);

      expect(text, 'Hello World!\nSecond line');
    });

    test('generatePreview produces clean single-line preview snippet', () {
      const plain = '  First sentence of note.\n\nSecond sentence.  ';
      final preview = Note.generatePreview(plain);

      expect(preview, 'First sentence of note. Second sentence.');
    });

    test('Serialization to/from JSON map preserves all fields', () {
      final now = DateTime(2026, 11, 21, 14, 0);
      final note = Note(
        id: 'note_1',
        ownerId: 'user_1',
        notebookId: 'nb_1',
        title: 'Project Architecture',
        contentDelta: jsonEncode([
          {'insert': 'Design System\n'}
        ]),
        plainText: 'Design System\n',
        preview: 'Design System',
        tags: ['architecture', 'flutter'],
        isPinned: true,
        isFavorite: true,
        isArchived: false,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      );

      final jsonMap = note.toJson();
      final reconstituted = Note.fromJson(jsonMap);

      expect(reconstituted.id, note.id);
      expect(reconstituted.ownerId, note.ownerId);
      expect(reconstituted.notebookId, note.notebookId);
      expect(reconstituted.title, note.title);
      expect(reconstituted.contentDelta, note.contentDelta);
      expect(reconstituted.plainText, note.plainText);
      expect(reconstituted.preview, note.preview);
      expect(reconstituted.tags, note.tags);
      expect(reconstituted.isPinned, isTrue);
      expect(reconstituted.isFavorite, isTrue);
      expect(reconstituted.isArchived, isFalse);
      expect(reconstituted.isDeleted, isFalse);
      expect(reconstituted.createdAt, now);
      expect(reconstituted.updatedAt, now);
    });

    test('copyWith modifies specified fields while maintaining immutability', () {
      final note = Note.createBlank(
        ownerId: 'user_1',
        notebookId: 'nb_1',
        title: 'Initial',
      );

      final updated = note.copyWith(
        title: 'Updated Title',
        isPinned: true,
        isFavorite: true,
      );

      expect(note.title, 'Initial');
      expect(note.isPinned, isFalse);
      expect(updated.title, 'Updated Title');
      expect(updated.isPinned, isTrue);
      expect(updated.isFavorite, isTrue);
    });

    test('soft delete sets isDeleted and deletedAt', () {
      final note = Note.createBlank(
        ownerId: 'user_1',
        notebookId: 'nb_1',
      );

      final deleteTime = DateTime.now();
      final deleted = note.copyWith(
        isDeleted: true,
        deletedAt: deleteTime,
      );

      expect(deleted.isDeleted, isTrue);
      expect(deleted.deletedAt, deleteTime);

      final restored = deleted.copyWith(
        isDeleted: false,
        clearDeletedAt: true,
      );

      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);
    });
  });
}
