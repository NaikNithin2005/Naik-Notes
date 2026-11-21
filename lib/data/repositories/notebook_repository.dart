import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../models/drive_file_mapping_model.dart';
import '../models/notebook_model.dart';
import '../models/tombstone_model.dart';

abstract class NotebookRepository {
  Future<List<Notebook>> getAllNotebooks({
    String? ownerId,
    bool includeArchived = false,
  });
  Stream<List<Notebook>> watchAllNotebooks({
    String? ownerId,
    bool includeArchived = false,
  });
  Future<Notebook?> getNotebookById(
    String id, {
    String? ownerId,
    bool includeDeleted = false,
  });
  Future<Notebook?> getAnyNotebookById(String id, {String? ownerId});
  Future<List<Notebook>> getNotebooksByFolder(
    String? folderId, {
    String? ownerId,
  });
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
  Future<void> deleteNotebook(String id, {String? deletionId});
  Future<void> restoreNotebook(String id);
  Future<void> permanentlyDeleteNotebook(String id, {String? deletionId, String? ownerId});
  Future<void> bulkDelete(Iterable<String> notebookIds, {String? deletionId});
  Future<void> bulkRestore(Iterable<String> notebookIds);
  Future<void> bulkPermanentDelete(Iterable<String> notebookIds, {String? ownerId});
  Future<void> bulkArchive(Iterable<String> notebookIds, bool archive);
  Future<void> bulkToggleFavorite(Iterable<String> notebookIds, bool favorite);
  Future<void> bulkMoveToFolder(Iterable<String> notebookIds, String? folderId);
  Future<void> bulkUpdateCoverColor(Iterable<String> notebookIds, String colorHex);
  Future<List<Notebook>> getDeletedNotebooks({String? ownerId});
  Stream<List<Notebook>> watchDeletedNotebooks({String? ownerId});
  Future<void> purgeNotebook(String id);
  Future<void> toggleFavorite(String id);
  Future<void> populateDefaultSamplesIfEmpty();

  // Tombstones & Permanent Deletion Ledger
  Future<bool> isTombstoned(String id);
  Future<List<Tombstone>> getAllTombstones({String? ownerId});
  Future<void> saveTombstone(Tombstone tombstone);

  // Google Drive File Mapping
  Future<void> saveDriveMapping({
    required String entityId,
    required String driveFileId,
    required String entityType,
    required String ownerId,
  });
  Future<DriveFileMapping?> getDriveMapping(String entityId);
  Future<void> removeDriveMapping(String entityId);

  // Auto-Retention
  Future<List<String>> cleanupExpiredTrash({int retentionDays = 30, String? ownerId});
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
      deletionId: row.deletionId,
      syncStatus: row.syncStatus,
      lastSyncedAt: row.lastSyncedAt,
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
      deletionId: Value(domain.deletionId),
      syncStatus: Value(domain.syncStatus),
      lastSyncedAt: Value(domain.lastSyncedAt),
    );
  }

  @override
  Future<List<Notebook>> getAllNotebooks({
    String? ownerId,
    bool includeArchived = false,
  }) async {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final notDeleted = tbl.deletedAt.isNull();
        final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
        if (includeArchived) return notDeleted & ownerFilter;
        return notDeleted & tbl.isArchived.equals(false) & ownerFilter;
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Notebook>> watchAllNotebooks({
    String? ownerId,
    bool includeArchived = false,
  }) {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final notDeleted = tbl.deletedAt.isNull();
        final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
        if (includeArchived) return notDeleted & ownerFilter;
        return notDeleted & tbl.isArchived.equals(false) & ownerFilter;
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Notebook?> getNotebookById(
    String id, {
    String? ownerId,
    bool includeDeleted = false,
  }) async {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final matches = tbl.id.equals(id);
        final notDeleted = includeDeleted ? const Constant(true) : tbl.deletedAt.isNull();
        final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
        return matches & notDeleted & ownerFilter;
      });
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<Notebook?> getAnyNotebookById(String id, {String? ownerId}) =>
      getNotebookById(id, ownerId: ownerId, includeDeleted: true);

  @override
  Future<List<Notebook>> getNotebooksByFolder(
    String? folderId, {
    String? ownerId,
  }) async {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final notDeleted =
            tbl.deletedAt.isNull() & tbl.isArchived.equals(false);
        final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
        if (folderId == null) {
          return notDeleted & ownerFilter;
        }
        return notDeleted & tbl.folderId.equals(folderId) & ownerFilter;
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<void> saveNotebook(Notebook notebook) async {
    // If the item is permanently tombstoned, never resurrect it!
    if (await isTombstoned(notebook.id)) {
      return;
    }
    await _db.into(_db.notebooksTable).insertOnConflictUpdate(_toCompanion(notebook));
  }

  @override
  Future<void> renameNotebook(
    String id,
    String newTitle, {
    String? newDescription,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.equals(id))).write(
      NotebooksTableCompanion(
        title: Value(newTitle),
        description: newDescription != null ? Value(newDescription) : const Value.absent(),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<Notebook?> duplicateNotebook(String id) async {
    final original = await getNotebookById(id);
    if (original == null) return null;

    final now = DateTime.now();
    final newId = _uuid.v4();
    final duplicate = original.copyWith(
      id: newId,
      title: '${original.title} (Copy)',
      createdAt: now,
      updatedAt: now,
      revision: 1,
      syncStatus: 'pending',
    );
    await saveNotebook(duplicate);
    return duplicate;
  }

  @override
  Future<void> moveNotebookToFolder(String notebookId, String? folderId) async {
    final now = DateTime.now();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.equals(notebookId))).write(
      NotebooksTableCompanion(
        folderId: Value(folderId),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
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
        syncStatus: const Value('pending'),
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
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> deleteNotebook(String id, {String? deletionId}) async {
    // Soft delete: moves to Trash, preserves 30-day recovery
    final now = DateTime.now();
    final delId = deletionId ?? _uuid.v4();
    await (_db.update(
      _db.notebooksTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      NotebooksTableCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        deletionId: Value(delId),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> restoreNotebook(String id) async {
    final now = DateTime.now();
    final existing = await getAnyNotebookById(id);
    final nextRev = (existing?.revision ?? 1) + 1;
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.equals(id))).write(
      NotebooksTableCompanion(
        deletedAt: const Value(null),
        deletionId: const Value(null),
        updatedAt: Value(now),
        revision: Value(nextRev),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> permanentlyDeleteNotebook(
    String id, {
    String? deletionId,
    String? ownerId,
  }) async {
    final now = DateTime.now();
    final delId = deletionId ?? _uuid.v4();
    final existing = await getAnyNotebookById(id);
    final user = ownerId ?? existing?.ownerId ?? 'local_user';

    await _db.transaction(() async {
      // 1. Record Tombstone in local ledger to prevent future cloud resurrection
      await _db.into(_db.tombstonesTable).insertOnConflictUpdate(
        TombstonesTableCompanion(
          id: Value(id),
          ownerId: Value(user),
          entityType: const Value('notebook'),
          deletionId: Value(delId),
          deletedAt: Value(now),
          syncedAt: const Value(null),
        ),
      );

      // 2. Cascade delete notebook and all associated local pages & strokes
      await (_db.delete(_db.notebooksTable)..where((tbl) => tbl.id.equals(id))).go();

      // 3. Purge Drive file mapping
      await (_db.delete(_db.driveFileMappingsTable)
            ..where((tbl) => tbl.entityId.equals(id)))
          .go();
    });
  }

  @override
  Future<void> bulkDelete(Iterable<String> notebookIds, {String? deletionId}) async {
    if (notebookIds.isEmpty) return;
    final now = DateTime.now();
    final delId = deletionId ?? _uuid.v4();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.isIn(notebookIds))).write(
      NotebooksTableCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        deletionId: Value(delId),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> bulkRestore(Iterable<String> notebookIds) async {
    if (notebookIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.isIn(notebookIds))).write(
      NotebooksTableCompanion(
        deletedAt: const Value(null),
        deletionId: const Value(null),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> bulkPermanentDelete(Iterable<String> notebookIds, {String? ownerId}) async {
    for (final id in notebookIds) {
      await permanentlyDeleteNotebook(id, ownerId: ownerId);
    }
  }

  @override
  Future<List<Notebook>> getDeletedNotebooks({String? ownerId}) async {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final isDeleted = tbl.deletedAt.isNotNull();
        final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
        return isDeleted & ownerFilter;
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Notebook>> watchDeletedNotebooks({String? ownerId}) {
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final isDeleted = tbl.deletedAt.isNotNull();
        final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
        return isDeleted & ownerFilter;
      })
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.deletedAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> purgeNotebook(String id) async {
    await permanentlyDeleteNotebook(id);
  }

  @override
  Future<void> toggleFavorite(String id) async {
    final existing = await getNotebookById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        isFavorite: !existing.isFavorite,
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );
      await saveNotebook(updated);
    }
  }

  @override
  Future<void> bulkArchive(Iterable<String> notebookIds, bool archive) async {
    if (notebookIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.isIn(notebookIds))).write(
      NotebooksTableCompanion(
        isArchived: Value(archive),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> bulkToggleFavorite(Iterable<String> notebookIds, bool favorite) async {
    if (notebookIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.isIn(notebookIds))).write(
      NotebooksTableCompanion(
        isFavorite: Value(favorite),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> bulkMoveToFolder(Iterable<String> notebookIds, String? folderId) async {
    if (notebookIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.isIn(notebookIds))).write(
      NotebooksTableCompanion(
        folderId: Value(folderId),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> bulkUpdateCoverColor(Iterable<String> notebookIds, String colorHex) async {
    if (notebookIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.notebooksTable)..where((tbl) => tbl.id.isIn(notebookIds))).write(
      NotebooksTableCompanion(
        coverColorHex: Value(colorHex),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<bool> isTombstoned(String id) async {
    final query = _db.select(_db.tombstonesTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null;
  }

  @override
  Future<List<Tombstone>> getAllTombstones({String? ownerId}) async {
    final query = _db.select(_db.tombstonesTable);
    if (ownerId != null) {
      query.where((tbl) => tbl.ownerId.equals(ownerId));
    }
    final rows = await query.get();
    return rows
        .map(
          (r) => Tombstone(
            id: r.id,
            ownerId: r.ownerId,
            entityType: r.entityType,
            deletionId: r.deletionId,
            deletedAt: r.deletedAt,
            syncedAt: r.syncedAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveTombstone(Tombstone tombstone) async {
    await _db.into(_db.tombstonesTable).insertOnConflictUpdate(
      TombstonesTableCompanion(
        id: Value(tombstone.id),
        ownerId: Value(tombstone.ownerId),
        entityType: Value(tombstone.entityType),
        deletionId: Value(tombstone.deletionId),
        deletedAt: Value(tombstone.deletedAt),
        syncedAt: Value(tombstone.syncedAt),
      ),
    );
    // If the local database has an active or deleted notebook with this ID, purge it immediately
    await (_db.delete(_db.notebooksTable)..where((tbl) => tbl.id.equals(tombstone.id))).go();
  }

  @override
  Future<void> saveDriveMapping({
    required String entityId,
    required String driveFileId,
    required String entityType,
    required String ownerId,
  }) async {
    await _db.into(_db.driveFileMappingsTable).insertOnConflictUpdate(
      DriveFileMappingsTableCompanion(
        entityId: Value(entityId),
        driveFileId: Value(driveFileId),
        entityType: Value(entityType),
        ownerId: Value(ownerId),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<DriveFileMapping?> getDriveMapping(String entityId) async {
    final query = _db.select(_db.driveFileMappingsTable)
      ..where((tbl) => tbl.entityId.equals(entityId));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return DriveFileMapping(
      entityId: row.entityId,
      ownerId: row.ownerId,
      entityType: row.entityType,
      driveFileId: row.driveFileId,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> removeDriveMapping(String entityId) async {
    await (_db.delete(_db.driveFileMappingsTable)
          ..where((tbl) => tbl.entityId.equals(entityId)))
        .go();
  }

  @override
  Future<List<String>> cleanupExpiredTrash({int retentionDays = 30, String? ownerId}) async {
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    final query = _db.select(_db.notebooksTable)
      ..where((tbl) {
        final expired = tbl.deletedAt.isNotNull() & tbl.deletedAt.isSmallerOrEqualValue(cutoff);
        final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
        return expired & ownerFilter;
      });
    final rows = await query.get();
    final expiredIds = rows.map((r) => r.id).toList();
    for (final id in expiredIds) {
      await permanentlyDeleteNotebook(id, ownerId: ownerId);
    }
    return expiredIds;
  }

  @override
  Future<void> populateDefaultSamplesIfEmpty() async {
    // Production requirement: No hardcoded demo notebooks are populated.
  }
}
