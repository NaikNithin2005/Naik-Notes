import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/repositories/note_repository.dart';

void main() {
  group('DriftNoteRepository SQLite Unit Tests', () {
    late AppDatabase db;
    late DriftNoteRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftNoteRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saveNote and getNoteById correctly persists and retrieves', () async {
      final now = DateTime(2026, 11, 21, 12, 0);
      final note = Note(
        id: 'test_note_1',
        ownerId: 'user_a',
        notebookId: 'nb_a',
        title: 'Deep Learning Lecture 1',
        contentDelta: jsonEncode([
          {'insert': 'Backpropagation equations\n'}
        ]),
        plainText: 'Backpropagation equations\n',
        preview: 'Backpropagation equations',
        tags: ['ai', 'math'],
        isPinned: false,
        isFavorite: true,
        isArchived: false,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveNote(note);

      final fetched = await repo.getNoteById('test_note_1');
      expect(fetched, isNotNull);
      expect(fetched!.id, 'test_note_1');
      expect(fetched.ownerId, 'user_a');
      expect(fetched.notebookId, 'nb_a');
      expect(fetched.title, 'Deep Learning Lecture 1');
      expect(fetched.plainText, 'Backpropagation equations\n');
      expect(fetched.preview, 'Backpropagation equations');
      expect(fetched.tags, ['ai', 'math']);
      expect(fetched.isFavorite, isTrue);
    });

    test('getAllNotes filters out deleted and archived by default', () async {
      final note1 = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'Active');
      final note2 = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'Archived')
          .copyWith(isArchived: true);
      final note3 = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'Deleted')
          .copyWith(isDeleted: true, deletedAt: DateTime.now());

      await repo.saveNote(note1);
      await repo.saveNote(note2);
      await repo.saveNote(note3);

      final activeOnly = await repo.getAllNotes(ownerId: 'user_a');
      expect(activeOnly.length, 1);
      expect(activeOnly.first.title, 'Active');

      final withArchived = await repo.getAllNotes(
        ownerId: 'user_a',
        includeArchived: true,
      );
      expect(withArchived.length, 2);

      final allIncludingTrash = await repo.getAllNotes(
        ownerId: 'user_a',
        includeArchived: true,
        includeDeleted: true,
      );
      expect(allIncludingTrash.length, 3);
    });

    test('soft delete and restore flow', () async {
      final note = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'To Soft Delete');
      await repo.saveNote(note);

      // Soft delete
      await repo.deleteNote(note.id);
      var fetched = await repo.getNoteById(note.id);
      expect(fetched!.isDeleted, isTrue);
      expect(fetched.deletedAt, isNotNull);

      // Restore from trash
      await repo.restoreNote(note.id);
      fetched = await repo.getNoteById(note.id);
      expect(fetched!.isDeleted, isFalse);
      expect(fetched.deletedAt, isNull);
    });

    test('permanentlyDeleteNote purges note completely from database', () async {
      final note = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'To Purge');
      await repo.saveNote(note);

      await repo.permanentlyDeleteNote(note.id);
      final fetched = await repo.getNoteById(note.id);
      expect(fetched, isNull);
    });

    test('togglePin and toggleFavorite', () async {
      final note = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1');
      await repo.saveNote(note);

      expect(note.isPinned, isFalse);
      await repo.togglePin(note.id);
      var fetched = await repo.getNoteById(note.id);
      expect(fetched!.isPinned, isTrue);

      await repo.togglePin(note.id);
      fetched = await repo.getNoteById(note.id);
      expect(fetched!.isPinned, isFalse);

      expect(note.isFavorite, isFalse);
      await repo.toggleFavorite(note.id);
      fetched = await repo.getNoteById(note.id);
      expect(fetched!.isFavorite, isTrue);
    });

    test('archiveNote and unarchiveNote', () async {
      final note = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1');
      await repo.saveNote(note);

      await repo.archiveNote(note.id);
      var fetched = await repo.getNoteById(note.id);
      expect(fetched!.isArchived, isTrue);

      await repo.unarchiveNote(note.id);
      fetched = await repo.getNoteById(note.id);
      expect(fetched!.isArchived, isFalse);
    });

    test('moveNoteToNotebook updates notebookId', () async {
      final note = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1');
      await repo.saveNote(note);

      await repo.moveNoteToNotebook(note.id, 'nb_2');
      final fetched = await repo.getNoteById(note.id);
      expect(fetched!.notebookId, 'nb_2');
    });

    test('duplicateNote duplicates note with new ID and (Copy) title', () async {
      final note = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'Master Note');
      await repo.saveNote(note);

      final copy = await repo.duplicateNote(note.id);
      expect(copy, isNotNull);
      expect(copy!.id, isNot(note.id));
      expect(copy.title, 'Master Note (Copy)');
      expect(copy.notebookId, 'nb_1');

      final fetchedCopy = await repo.getNoteById(copy.id);
      expect(fetchedCopy, isNotNull);
    });

    test('addTag and removeTag mutate tag list correctly', () async {
      final note = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', tags: ['init']);
      await repo.saveNote(note);

      await repo.addTag(note.id, 'flutter');
      var fetched = await repo.getNoteById(note.id);
      expect(fetched!.tags, ['init', 'flutter']);

      // Adding duplicate should not duplicate tag
      await repo.addTag(note.id, 'flutter');
      fetched = await repo.getNoteById(note.id);
      expect(fetched!.tags, ['init', 'flutter']);

      // Remove tag
      await repo.removeTag(note.id, 'init');
      fetched = await repo.getNoteById(note.id);
      expect(fetched!.tags, ['flutter']);
    });

    test('emptyTrash deletes only soft-deleted notes belonging to user', () async {
      final noteActive = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'Keep Me');
      final noteTrash = Note.createBlank(ownerId: 'user_a', notebookId: 'nb_1', title: 'Trash Me')
          .copyWith(isDeleted: true, deletedAt: DateTime.now());
      final otherUserTrash = Note.createBlank(ownerId: 'user_b', notebookId: 'nb_2', title: 'Other Trash')
          .copyWith(isDeleted: true, deletedAt: DateTime.now());

      await repo.saveNote(noteActive);
      await repo.saveNote(noteTrash);
      await repo.saveNote(otherUserTrash);

      await repo.emptyTrash(ownerId: 'user_a');

      final active = await repo.getNoteById(noteActive.id);
      expect(active, isNotNull);

      final purged = await repo.getNoteById(noteTrash.id);
      expect(purged, isNull);

      final otherStillExists = await repo.getNoteById(otherUserTrash.id);
      expect(otherStillExists, isNotNull);
    });
  });
}

