import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/folder_model.dart';

/// Repository interface and implementation for local folder persistence.
abstract class FolderRepository {
  Future<List<Folder>> getAllFolders({String? ownerId});
  Stream<List<Folder>> watchAllFolders({String? ownerId});
  Future<Folder?> getFolderById(String id, {String? ownerId});
  Future<void> saveFolder(Folder folder);
  Future<void> renameFolder(String id, String newName, {String? newColorHex});
  Future<void> deleteFolder(String id);
  Future<void> populateDefaultSampleFoldersIfEmpty();
}

class DriftFolderRepository implements FolderRepository {
  final AppDatabase _db;

  DriftFolderRepository(this._db);

  Folder _toDomain(FoldersTableData row) {
    return Folder(
      id: row.id,
      ownerId: row.ownerId,
      parentId: row.parentId,
      name: row.name,
      colorHex: row.colorHex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    );
  }

  FoldersTableCompanion _toCompanion(Folder domain) {
    return FoldersTableCompanion(
      id: Value(domain.id),
      ownerId: Value(domain.ownerId),
      parentId: Value(domain.parentId),
      name: Value(domain.name),
      colorHex: Value(domain.colorHex),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
      deletedAt: Value(domain.deletedAt),
    );
  }

  @override
  Future<List<Folder>> getAllFolders({String? ownerId}) async {
    final query = _db.select(_db.foldersTable)
      ..where((tbl) {
        final notDeleted = tbl.deletedAt.isNull();
        if (ownerId != null) return notDeleted & tbl.ownerId.equals(ownerId);
        return notDeleted;
      })
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Folder>> watchAllFolders({String? ownerId}) {
    final query = _db.select(_db.foldersTable)
      ..where((tbl) {
        final notDeleted = tbl.deletedAt.isNull();
        if (ownerId != null) return notDeleted & tbl.ownerId.equals(ownerId);
        return notDeleted;
      })
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<Folder?> getFolderById(String id, {String? ownerId}) async {
    final query = _db.select(_db.foldersTable)
      ..where((tbl) {
        final matches = tbl.id.equals(id) & tbl.deletedAt.isNull();
        if (ownerId != null) return matches & tbl.ownerId.equals(ownerId);
        return matches;
      });
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<void> saveFolder(Folder folder) async {
    await _db
        .into(_db.foldersTable)
        .insertOnConflictUpdate(_toCompanion(folder));
  }

  @override
  Future<void> renameFolder(
    String id,
    String newName, {
    String? newColorHex,
  }) async {
    final existing = await getFolderById(id);
    if (existing != null) {
      final updated = existing.copyWith(
        name: newName,
        colorHex: newColorHex ?? existing.colorHex,
        updatedAt: DateTime.now(),
      );
      await saveFolder(updated);
    }
  }

  @override
  Future<void> deleteFolder(String id) async {
    final now = DateTime.now();
    // Soft delete the folder
    await (_db.update(
      _db.foldersTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      FoldersTableCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );

    // Unassign notebooks that were in this folder
    await (_db.update(
      _db.notebooksTable,
    )..where((tbl) => tbl.folderId.equals(id))).write(
      NotebooksTableCompanion(
        folderId: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> populateDefaultSampleFoldersIfEmpty() async {
    // Production clean slate: no hardcoded demo folders.
  }
}
