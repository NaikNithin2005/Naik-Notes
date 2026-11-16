import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../models/notebook_model.dart';

/// Repository interface for local notebook persistence and operations.
abstract class NotebookRepository {
  Future<List<Notebook>> getAllNotebooks({bool includeArchived = false});
  Stream<List<Notebook>> watchAllNotebooks({bool includeArchived = false});
  Future<Notebook?> getNotebookById(String id);
  Future<List<Notebook>> getNotebooksByFolder(String? folderId);
  Future<void> saveNotebook(Notebook notebook);
  Future<void> renameNotebook(
    String id,
    String newTitle, {
    String? newDescription,
  });
  Future<Notebook?> duplicateNotebook(String id);
  Future<void> moveNotebookToFolder(String notebookId, String? folderId);
  Future<void> archiveNotebook(String id);
  Future<void> unarchiveNotebook(String id);
  Future<void> deleteNotebook(String id);
  Future<void> toggleFavorite(String id);
  Future<void> populateDefaultSamplesIfEmpty();
}

class DriftNotebookRepository implements NotebookRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DriftNotebookRepository(this._db);

  Notebook _toDomain(NotebooksTableData row) {
    return Notebook(
      id: row.id,
      ownerId: row.ownerId,
      folderId: row.folderId,
      title: row.title,
      description: row.description,
      coverId: row.coverId,
      coverColorHex: row.coverColorHex,
      coverImageUrl: row.coverImageUrl,
      paperTemplateId: row.paperTemplateId,
      orientation: row.orientation,
      pageSize: row.pageSize,
      pageCount: row.pageCount,
      isFavorite: row.isFavorite,
      isArchived: row.isArchived,
      isPdf: row.isPdf,
      pdfPath: row.pdfPath,
      revision: row.revision,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  NotebooksTableCompanion _toCompanion(Notebook domain) {
    return NotebooksTableCompanion(
      id: Value(domain.id),
      ownerId: Value(domain.ownerId),
      folderId: Value(domain.folderId),
      title: Value(domain.title),
      description: Value(domain.description),
      coverId: Value(domain.coverId),
      coverColorHex: Value(domain.coverColorHex),
      coverImageUrl: Value(domain.coverImageUrl),
      paperTemplateId: Value(domain.paperTemplateId),
      orientation: Value(domain.orientation),
      pageSize: Value(domain.pageSize),
      pageCount: Value(domain.pageCount),
      isFavorite: Value(domain.isFavorite),
      isArchived: Value(domain.isArchived),
      isPdf: Value(domain.isPdf),
      pdfPath: Value(domain.pdfPath),
      revision: Value(domain.revision),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
      deletedAt: Value(domain.deletedAt),
      syncStatus: const Value('synced'),
    );
  }

  @override
  Future<List<Notebook>> getAllNotebooks({bool includeArchived = false}) async {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final notDeleted = tbl.deletedAt.isNull();
        if (includeArchived) return notDeleted;
        return notDeleted & tbl.isArchived.equals(false);
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Notebook>> watchAllNotebooks({bool includeArchived = false}) {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final notDeleted = tbl.deletedAt.isNull();
        if (includeArchived) return notDeleted;
        return notDeleted & tbl.isArchived.equals(false);
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Notebook?> getNotebookById(String id) async {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) => tbl.id.equals(id) & tbl.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<List<Notebook>> getNotebooksByFolder(String? folderId) async {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final notDeleted =
            tbl.deletedAt.isNull() & tbl.isArchived.equals(false);
        if (folderId == null) {
          return notDeleted;
        }
        return notDeleted & tbl.folderId.equals(folderId);
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> saveNotebook(Notebook notebook) async {
    await _db
        .into(_db.notebooksTable)
        .insertOnConflictUpdate(_toCompanion(notebook));
  }

  @override
  Future<void> renameNotebook(
    String id,
    String newTitle, {
    String? newDescription,
  }) async {
    final existing = await getNotebookById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        title: newTitle,
        description: newDescription ?? existing.description,
        updatedAt: DateTime.now(),
      );
      await saveNotebook(updated);
    }
  }

  @override
  Future<Notebook?> duplicateNotebook(String id) async {
    final existing = await getNotebookById(id);
    if (existing == null) return null;

    final now = DateTime.now();
    final newId = _uuid.v4();
    final duplicate = existing.copyWith(
      id: newId,
      title: '${existing.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      revision: 1,
    );
    await saveNotebook(duplicate);
    return duplicate;
  }

  @override
  Future<void> moveNotebookToFolder(String notebookId, String? folderId) async {
    final now = DateTime.now();
    await (_db.update(
      _db.notebooksTable,
    )..where((tbl) => tbl.id.equals(notebookId))).write(
      NotebooksTableCompanion(folderId: Value(folderId), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> archiveNotebook(String id) async {
    final now = DateTime.now();
    await (_db.update(
      _db.notebooksTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      NotebooksTableCompanion(
        isArchived: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> unarchiveNotebook(String id) async {
    final now = DateTime.now();
    await (_db.update(
      _db.notebooksTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      NotebooksTableCompanion(
        isArchived: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> deleteNotebook(String id) async {
    // Soft delete with timestamp
    final now = DateTime.now();
    await (_db.update(
      _db.notebooksTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      NotebooksTableCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final existing = await getNotebookById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        isFavorite: !existing.isFavorite,
        updatedAt: DateTime.now(),
      );
      await saveNotebook(updated);
    }
  }

  @override
  Future<void> populateDefaultSamplesIfEmpty() async {
    // Production requirement: No hardcoded demo notebooks are populated.
    // The notebook library starts clean and empty.
  }
}
