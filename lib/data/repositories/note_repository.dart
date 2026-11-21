import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../models/note_model.dart';

/// Repository interface for rich-text note persistence and management.
abstract class NoteRepository {
  Future<List<Note>> getAllNotes({
    String? ownerId,
    String? notebookId,
    bool includeArchived = false,
    bool includeDeleted = false,
  });

  Stream<List<Note>> watchAllNotes({
    String? ownerId,
    String? notebookId,
    bool includeArchived = false,
    bool includeDeleted = false,
  });

  Future<Note?> getNoteById(String id, {String? ownerId});

  Future<void> saveNote(Note note);

  Future<void> deleteNote(String id);

  Future<void> restoreNote(String id);

  Future<void> permanentlyDeleteNote(String id);

  Future<void> bulkDelete(Iterable<String> noteIds);

  Future<void> bulkRestore(Iterable<String> noteIds);

  Future<void> bulkPermanentDelete(Iterable<String> noteIds);

  Future<void> bulkTogglePin(Iterable<String> noteIds, bool pin);

  Future<void> bulkToggleFavorite(Iterable<String> noteIds, bool favorite);

  Future<void> bulkArchive(Iterable<String> noteIds, bool archive);

  Future<void> bulkMoveToNotebook(Iterable<String> noteIds, String targetNotebookId);

  Future<void> bulkAddTag(Iterable<String> noteIds, String tag);

  Future<void> bulkRemoveTag(Iterable<String> noteIds, String tag);

  Future<void> togglePin(String id);

  Future<void> toggleFavorite(String id);

  Future<void> archiveNote(String id);

  Future<void> unarchiveNote(String id);

  Future<void> moveNoteToNotebook(String noteId, String targetNotebookId);

  Future<Note?> duplicateNote(String noteId);

  Future<void> addTag(String noteId, String tag);

  Future<void> removeTag(String noteId, String tag);

  Future<List<Note>> searchNotes(
    String query, {
    String? ownerId,
    String? notebookId,
  });

  Future<List<Note>> getTrashNotes({String? ownerId});

  Future<void> emptyTrash({String? ownerId});
}

/// Drift SQLite implementation of [NoteRepository].
class DriftNoteRepository implements NoteRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DriftNoteRepository(this._db);

  Note _toDomain(NotesTableData row) {
    List<String> tags = [];
    try {
      final decoded = jsonDecode(row.tagsJson) as List<dynamic>;
      tags = decoded.map((e) => e.toString()).toList();
    } catch (_) {}

    return Note(
      id: row.id,
      ownerId: row.ownerId,
      notebookId: row.notebookId,
      title: row.title,
      contentDelta: row.contentDelta,
      plainText: row.plainText,
      preview: row.preview,
      tags: tags,
      isPinned: row.isPinned,
      isFavorite: row.isFavorite,
      isArchived: row.isArchived,
      isDeleted: row.isDeleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
      lastSyncedAt: row.lastSyncedAt,
    );
  }

  NotesTableCompanion _toCompanion(Note domain) {
    return NotesTableCompanion(
      id: Value(domain.id),
      ownerId: Value(domain.ownerId),
      notebookId: Value(domain.notebookId),
      title: Value(domain.title),
      contentDelta: Value(domain.contentDelta),
      plainText: Value(domain.plainText),
      preview: Value(domain.preview),
      tagsJson: Value(jsonEncode(domain.tags)),
      isPinned: Value(domain.isPinned),
      isFavorite: Value(domain.isFavorite),
      isArchived: Value(domain.isArchived),
      isDeleted: Value(domain.isDeleted),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
      deletedAt: Value(domain.deletedAt),
      lastSyncedAt: Value(domain.lastSyncedAt),
    );
  }

  @override
  Future<List<Note>> getAllNotes({
    String? ownerId,
    String? notebookId,
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    final query = _db.select(_db.notesTable);

    if (ownerId != null) {
      query.where((t) => t.ownerId.equals(ownerId));
    }
    if (notebookId != null) {
      query.where((t) => t.notebookId.equals(notebookId));
    }
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    if (!includeDeleted) {
      query.where((t) => t.isDeleted.equals(false));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);

    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Note>> watchAllNotes({
    String? ownerId,
    String? notebookId,
    bool includeArchived = false,
    bool includeDeleted = false,
  }) {
    final query = _db.select(_db.notesTable);

    if (ownerId != null) {
      query.where((t) => t.ownerId.equals(ownerId));
    }
    if (notebookId != null) {
      query.where((t) => t.notebookId.equals(notebookId));
    }
    if (!includeArchived) {
      query.where((t) => t.isArchived.equals(false));
    }
    if (!includeDeleted) {
      query.where((t) => t.isDeleted.equals(false));
    }

    query.orderBy([
      (t) => OrderingTerm(expression: t.isPinned, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Note?> getNoteById(String id, {String? ownerId}) async {
    final query = _db.select(_db.notesTable)..where((t) => t.id.equals(id));
    if (ownerId != null) {
      query.where((t) => t.ownerId.equals(ownerId));
    }
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<void> saveNote(Note note) async {
    await _db.into(_db.notesTable).insertOnConflictUpdate(_toCompanion(note));
  }

  @override
  Future<void> deleteNote(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> restoreNote(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(
        isDeleted: const Value(false),
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> permanentlyDeleteNote(String id) async {
    await (_db.delete(_db.notesTable)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> togglePin(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final now = DateTime.now();
      await (_db.update(_db.notesTable)..where((t) => t.id.equals(id))).write(
        NotesTableCompanion(
          isPinned: Value(!note.isPinned),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      final now = DateTime.now();
      await (_db.update(_db.notesTable)..where((t) => t.id.equals(id))).write(
        NotesTableCompanion(
          isFavorite: Value(!note.isFavorite),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<void> archiveNote(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(
        isArchived: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> unarchiveNote(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(
        isArchived: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> moveNoteToNotebook(String noteId, String targetNotebookId) async {
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(noteId))).write(
      NotesTableCompanion(
        notebookId: Value(targetNotebookId),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<Note?> duplicateNote(String noteId) async {
    final original = await getNoteById(noteId);
    if (original == null) return null;

    final now = DateTime.now();
    final copy = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      isDeleted: false,
      clearDeletedAt: true,
    );

    await saveNote(copy);
    return copy;
  }

  @override
  Future<void> addTag(String noteId, String tag) async {
    final note = await getNoteById(noteId);
    if (note == null) return;
    final trimmed = tag.trim();
    if (trimmed.isEmpty || note.tags.contains(trimmed)) return;

    final updatedTags = [...note.tags, trimmed];
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(noteId))).write(
      NotesTableCompanion(
        tagsJson: Value(jsonEncode(updatedTags)),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> removeTag(String noteId, String tag) async {
    final note = await getNoteById(noteId);
    if (note == null) return;
    final updatedTags = note.tags.where((t) => t != tag).toList();
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(noteId))).write(
      NotesTableCompanion(
        tagsJson: Value(jsonEncode(updatedTags)),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<List<Note>> searchNotes(
    String query, {
    String? ownerId,
    String? notebookId,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return getAllNotes(ownerId: ownerId, notebookId: notebookId);
    }

    final all = await getAllNotes(ownerId: ownerId, notebookId: notebookId);
    return all.where((n) {
      final titleMatch = n.title.toLowerCase().contains(cleanQuery);
      final textMatch = n.plainText.toLowerCase().contains(cleanQuery);
      final tagMatch = n.tags.any((t) => t.toLowerCase().contains(cleanQuery));
      return titleMatch || textMatch || tagMatch;
    }).toList();
  }

  @override
  Future<List<Note>> getTrashNotes({String? ownerId}) async {
    final query = _db.select(_db.notesTable)
      ..where((t) => t.isDeleted.equals(true));
    if (ownerId != null) {
      query.where((t) => t.ownerId.equals(ownerId));
    }
    query.orderBy([
      (t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc),
    ]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> emptyTrash({String? ownerId}) async {
    final query = _db.delete(_db.notesTable)
      ..where((t) => t.isDeleted.equals(true));
    if (ownerId != null) {
      query.where((t) => t.ownerId.equals(ownerId));
    }
    await query.go();
  }

  @override
  Future<void> bulkDelete(Iterable<String> noteIds) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> bulkRestore(Iterable<String> noteIds) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        isDeleted: const Value(false),
        deletedAt: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> bulkPermanentDelete(Iterable<String> noteIds) async {
    if (noteIds.isEmpty) return;
    await (_db.delete(_db.notesTable)..where((t) => t.id.isIn(noteIds))).go();
  }

  @override
  Future<void> bulkTogglePin(Iterable<String> noteIds, bool pin) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        isPinned: Value(pin),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> bulkToggleFavorite(Iterable<String> noteIds, bool favorite) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        isFavorite: Value(favorite),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> bulkArchive(Iterable<String> noteIds, bool archive) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        isArchived: Value(archive),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> bulkMoveToNotebook(Iterable<String> noteIds, String targetNotebookId) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        notebookId: Value(targetNotebookId),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> bulkAddTag(Iterable<String> noteIds, String tag) async {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty || noteIds.isEmpty) return;
    for (final id in noteIds) {
      await addTag(id, cleanTag);
    }
  }

  @override
  Future<void> bulkRemoveTag(Iterable<String> noteIds, String tag) async {
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty || noteIds.isEmpty) return;
    for (final id in noteIds) {
      await removeTag(id, cleanTag);
    }
  }
}

