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

  Future<void> deleteNote(String id, {String? deletionId});

  Future<void> restoreNote(String id);

  Future<void> permanentlyDeleteNote(String id, {String? deletionId, String? ownerId});

  Future<void> bulkDelete(Iterable<String> noteIds, {String? deletionId});

  Future<void> bulkRestore(Iterable<String> noteIds);

  Future<void> bulkPermanentDelete(Iterable<String> noteIds, {String? ownerId});

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
  Stream<List<Note>> watchTrashNotes({String? ownerId});

  Future<void> emptyTrash({String? ownerId});

  Future<List<String>> cleanupExpiredTrash({int retentionDays = 30, String? ownerId});
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
      deletionId: row.deletionId,
      syncStatus: row.syncStatus,
      lastSyncedAt: row.lastSyncedAt,
      localVersion: row.localVersion,
      serverVersion: row.serverVersion,
      deviceId: row.deviceId,
      lastModifiedBy: row.lastModifiedBy,
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
      deletionId: Value(domain.deletionId),
      syncStatus: Value(domain.syncStatus),
      lastSyncedAt: Value(domain.lastSyncedAt),
      localVersion: Value(domain.localVersion),
      serverVersion: Value(domain.serverVersion),
      deviceId: Value(domain.deviceId),
      lastModifiedBy: Value(domain.lastModifiedBy),
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
    // If tombstoned, refuse to resurrect!
    final isTomb = await (_db.select(_db.tombstonesTable)..where((t) => t.id.equals(note.id))).getSingleOrNull();
    if (isTomb != null) return;

    await _db.into(_db.notesTable).insertOnConflictUpdate(_toCompanion(note));
  }

  @override
  Future<void> deleteNote(String id, {String? deletionId}) async {
    final now = DateTime.now();
    final delId = deletionId ?? _uuid.v4();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(id))).write(
      NotesTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        deletionId: Value(delId),
        syncStatus: const Value('pending'),
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
        deletionId: const Value(null),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> permanentlyDeleteNote(String id, {String? deletionId, String? ownerId}) async {
    final now = DateTime.now();
    final delId = deletionId ?? _uuid.v4();
    final existing = await getNoteById(id);
    final user = ownerId ?? existing?.ownerId ?? 'local_user';

    await _db.transaction(() async {
      // 1. Record Tombstone in local ledger
      await _db.into(_db.tombstonesTable).insertOnConflictUpdate(
        TombstonesTableCompanion(
          id: Value(id),
          ownerId: Value(user),
          entityType: const Value('note'),
          deletionId: Value(delId),
          deletedAt: Value(now),
          syncedAt: const Value(null),
        ),
      );

      // 2. Delete Note
      await (_db.delete(_db.notesTable)..where((t) => t.id.equals(id))).go();
    });
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
          syncStatus: const Value('pending'),
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
          syncStatus: const Value('pending'),
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
        syncStatus: const Value('pending'),
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
        syncStatus: const Value('pending'),
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
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<Note?> duplicateNote(String noteId) async {
    final original = await getNoteById(noteId);
    if (original == null) return null;

    final now = DateTime.now();
    final newId = _uuid.v4();
    final duplicate = original.copyWith(
      id: newId,
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      isPinned: false,
      syncStatus: 'pending',
    );
    await saveNote(duplicate);
    return duplicate;
  }

  @override
  Future<void> addTag(String noteId, String tag) async {
    final note = await getNoteById(noteId);
    if (note == null) return;
    final cleanTag = tag.trim();
    if (cleanTag.isEmpty || note.tags.contains(cleanTag)) return;

    final updatedTags = [...note.tags, cleanTag];
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(noteId))).write(
      NotesTableCompanion(
        tagsJson: Value(jsonEncode(updatedTags)),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> removeTag(String noteId, String tag) async {
    final note = await getNoteById(noteId);
    if (note == null) return;
    final cleanTag = tag.trim();
    if (!note.tags.contains(cleanTag)) return;

    final updatedTags = note.tags.where((t) => t != cleanTag).toList();
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.equals(noteId))).write(
      NotesTableCompanion(
        tagsJson: Value(jsonEncode(updatedTags)),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
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
    final all = await getAllNotes(ownerId: ownerId, notebookId: notebookId);
    if (cleanQuery.isEmpty) return all;

    return all.where((n) {
      final inTitle = n.title.toLowerCase().contains(cleanQuery);
      final inText = n.plainText.toLowerCase().contains(cleanQuery);
      final inTags = n.tags.any((t) => t.toLowerCase().contains(cleanQuery));
      return inTitle || inText || inTags;
    }).toList();
  }

  @override
  Future<List<Note>> getTrashNotes({String? ownerId}) async {
    final query = _db.select(_db.notesTable)
      ..where((t) {
        final isDeleted = t.isDeleted.equals(true);
        if (ownerId != null) {
          return isDeleted & t.ownerId.equals(ownerId);
        }
        return isDeleted;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]);

    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Note>> watchTrashNotes({String? ownerId}) {
    final query = _db.select(_db.notesTable)
      ..where((t) {
        final isDeleted = t.isDeleted.equals(true);
        if (ownerId != null) {
          return isDeleted & t.ownerId.equals(ownerId);
        }
        return isDeleted;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.deletedAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> emptyTrash({String? ownerId}) async {
    final trashNotes = await getTrashNotes(ownerId: ownerId);
    for (final note in trashNotes) {
      await permanentlyDeleteNote(note.id, ownerId: ownerId);
    }
  }

  @override
  Future<void> bulkDelete(Iterable<String> noteIds, {String? deletionId}) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    final delId = deletionId ?? _uuid.v4();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(now),
        deletionId: Value(delId),
        syncStatus: const Value('pending'),
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
        deletionId: const Value(null),
        syncStatus: const Value('pending'),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> bulkPermanentDelete(Iterable<String> noteIds, {String? ownerId}) async {
    for (final id in noteIds) {
      await permanentlyDeleteNote(id, ownerId: ownerId);
    }
  }

  @override
  Future<void> bulkTogglePin(Iterable<String> noteIds, bool pin) async {
    if (noteIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notesTable)..where((t) => t.id.isIn(noteIds))).write(
      NotesTableCompanion(
        isPinned: Value(pin),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
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
        syncStatus: const Value('pending'),
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
        syncStatus: const Value('pending'),
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
        syncStatus: const Value('pending'),
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

  @override
  Future<List<String>> cleanupExpiredTrash({int retentionDays = 30, String? ownerId}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final query = _db.select(_db.notesTable)
      ..where((t) {
        final expired = t.isDeleted.equals(true) & t.deletedAt.isNotNull() & t.deletedAt.isSmallerOrEqualValue(cutoff);
        if (ownerId != null) return expired & t.ownerId.equals(ownerId);
        return expired;
      });
    final rows = await query.get();
    final expiredIds = rows.map((r) => r.id).toList();
    for (final id in expiredIds) {
      await permanentlyDeleteNote(id, ownerId: ownerId);
    }
    return expiredIds;
  }
}
