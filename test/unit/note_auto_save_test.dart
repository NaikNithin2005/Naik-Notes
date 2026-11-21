import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/repositories/note_repository.dart';
import 'package:naik_notes/features/notes/services/note_auto_save_coordinator.dart';

class _FakeNoteRepository implements NoteRepository {
  final Map<String, Note> _store = {};
  int saveCount = 0;

  @override
  Future<void> saveNote(Note note) async {
    saveCount++;
    _store[note.id] = note;
  }

  @override
  Future<Note?> getNoteById(String id, {String? ownerId}) async => _store[id];

  @override
  Future<List<Note>> getAllNotes({
    String? ownerId,
    String? notebookId,
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async =>
      _store.values.toList();

  @override
  Stream<List<Note>> watchAllNotes({
    String? ownerId,
    String? notebookId,
    bool includeArchived = false,
    bool includeDeleted = false,
  }) =>
      Stream.value(_store.values.toList());

  @override
  Future<void> deleteNote(String id) async {
    final n = _store[id];
    if (n != null) {
      _store[id] = n.copyWith(isDeleted: true, deletedAt: DateTime.now());
    }
  }

  @override
  Future<void> restoreNote(String id) async {
    final n = _store[id];
    if (n != null) {
      _store[id] = n.copyWith(isDeleted: false, clearDeletedAt: true);
    }
  }

  @override
  Future<void> permanentlyDeleteNote(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> togglePin(String id) async {
    final n = _store[id];
    if (n != null) _store[id] = n.copyWith(isPinned: !n.isPinned);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final n = _store[id];
    if (n != null) _store[id] = n.copyWith(isFavorite: !n.isFavorite);
  }

  @override
  Future<void> archiveNote(String id) async {
    final n = _store[id];
    if (n != null) _store[id] = n.copyWith(isArchived: true);
  }

  @override
  Future<void> unarchiveNote(String id) async {
    final n = _store[id];
    if (n != null) _store[id] = n.copyWith(isArchived: false);
  }

  @override
  Future<void> moveNoteToNotebook(String noteId, String targetNotebookId) async {
    final n = _store[noteId];
    if (n != null) _store[noteId] = n.copyWith(notebookId: targetNotebookId);
  }

  @override
  Future<Note?> duplicateNote(String noteId) async {
    final n = _store[noteId];
    if (n == null) return null;
    final copy = n.copyWith(id: 'copy_${n.id}', title: '${n.title} (Copy)');
    _store[copy.id] = copy;
    return copy;
  }

  @override
  Future<void> addTag(String noteId, String tag) async {
    final n = _store[noteId];
    if (n != null && !n.tags.contains(tag)) {
      _store[noteId] = n.copyWith(tags: [...n.tags, tag]);
    }
  }

  @override
  Future<void> removeTag(String noteId, String tag) async {
    final n = _store[noteId];
    if (n != null) {
      _store[noteId] = n.copyWith(tags: n.tags.where((t) => t != tag).toList());
    }
  }

  @override
  Future<List<Note>> searchNotes(
    String query, {
    String? ownerId,
    String? notebookId,
  }) async =>
      [];

  @override
  Future<List<Note>> getTrashNotes({String? ownerId}) async => [];

  @override
  Future<void> emptyTrash({String? ownerId}) async {
    _store.removeWhere((k, v) => v.isDeleted);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NoteAutoSaveCoordinator Unit Tests', () {
    late _FakeNoteRepository fakeRepo;
    late ProviderContainer container;
    late Note testNote;

    setUp(() {
      fakeRepo = _FakeNoteRepository();
      container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      testNote = Note.createBlank(
        ownerId: 'user_1',
        notebookId: 'nb_1',
        title: 'Original Title',
      );
      fakeRepo.saveNote(testNote);
      fakeRepo.saveCount = 0; // reset
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial coordinator status is idle', () {
      final state = container.read(noteAutoSaveCoordinatorProvider);
      expect(state.status, SaveStatus.idle);
    });

    test('flushPendingSave flushes edits immediately to repository', () async {
      final coordinator =
          container.read(noteAutoSaveCoordinatorProvider.notifier);

      final newDelta = jsonEncode([
        {'insert': 'New content written in editor\n'}
      ]);

      // Schedule debounce save
      coordinator.onNoteChanged(
        note: testNote,
        deltaJson: newDelta,
      );

      // Verify that before 1500ms, it hasn't written to repo yet
      expect(fakeRepo.saveCount, 0);

      // Flush explicitly (simulating note switch or route exit)
      await coordinator.flushPendingSave(noteId: testNote.id);

      expect(fakeRepo.saveCount, 1);
      final savedNote = await fakeRepo.getNoteById(testNote.id);
      expect(savedNote, isNotNull);
      expect(savedNote!.contentDelta, newDelta);
      expect(savedNote.plainText.trim(), 'New content written in editor');
      expect(container.read(noteAutoSaveCoordinatorProvider).status,
          SaveStatus.saved);
    });

    test('Rapid consecutive edits debounce into a single write on flush', () async {
      final coordinator =
          container.read(noteAutoSaveCoordinatorProvider.notifier);

      for (int i = 1; i <= 5; i++) {
        coordinator.onNoteChanged(
          note: testNote,
          deltaJson: jsonEncode([
            {'insert': 'Keystroke $i\n'}
          ]),
        );
      }

      // No writes yet while user is actively typing
      expect(fakeRepo.saveCount, 0);

      // Explicit flush
      await coordinator.flushPendingSave(noteId: testNote.id);

      // Only 1 consolidated write occurred!
      expect(fakeRepo.saveCount, 1);
      final savedNote = await fakeRepo.getNoteById(testNote.id);
      expect(savedNote!.plainText.trim(), 'Keystroke 5');
    });

    test('Title change triggers coordinator debounce and saves updated title', () async {
      final coordinator =
          container.read(noteAutoSaveCoordinatorProvider.notifier);

      coordinator.onNoteChanged(
        note: testNote,
        deltaJson: testNote.contentDelta,
        title: 'Renamed Title',
      );

      expect(fakeRepo.saveCount, 0);

      await coordinator.flushPendingSave();

      expect(fakeRepo.saveCount, 1);
      final savedNote = await fakeRepo.getNoteById(testNote.id);
      expect(savedNote!.title, 'Renamed Title');
    });
  });
}
