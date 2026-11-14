import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/sticky_note_model.dart';

/// Repository interface for persisting sticky note annotations.
abstract class StickyNoteRepository {
  Future<List<StickyNote>> getStickyNotesForPage(String pageId);
  Stream<List<StickyNote>> watchStickyNotesForPage(String pageId);
  Future<void> saveStickyNote(StickyNote note);
  Future<void> deleteStickyNote(String id);
  Future<void> updatePosition(String id, double x, double y);
  Future<void> updateContent(String id, String content);
  Future<void> updateColor(String id, String colorHex);
}

/// Drift SQLite implementation of [StickyNoteRepository].
class DriftStickyNoteRepository implements StickyNoteRepository {
  final AppDatabase _db;

  DriftStickyNoteRepository(this._db);

  StickyNote _toDomain(StickyNotesTableData row) {
    return StickyNote(
      id: row.id,
      pageId: row.pageId,
      x: row.x,
      y: row.y,
      width: row.width,
      height: row.height,
      content: row.content,
      colorHex: row.colorHex,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  StickyNotesTableCompanion _toCompanion(StickyNote domain) {
    return StickyNotesTableCompanion(
      id: Value(domain.id),
      pageId: Value(domain.pageId),
      x: Value(domain.x),
      y: Value(domain.y),
      width: Value(domain.width),
      height: Value(domain.height),
      content: Value(domain.content),
      colorHex: Value(domain.colorHex),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
    );
  }

  @override
  Future<List<StickyNote>> getStickyNotesForPage(String pageId) async {
    final query = _db.select(_db.stickyNotesTable)
      ..where((tbl) => tbl.pageId.equals(pageId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<StickyNote>> watchStickyNotesForPage(String pageId) {
    final query = _db.select(_db.stickyNotesTable)
      ..where((tbl) => tbl.pageId.equals(pageId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> saveStickyNote(StickyNote note) async {
    await _db
        .into(_db.stickyNotesTable)
        .insertOnConflictUpdate(_toCompanion(note));
  }

  @override
  Future<void> deleteStickyNote(String id) async {
    await (_db.delete(
      _db.stickyNotesTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> updatePosition(String id, double x, double y) async {
    await (_db.update(
      _db.stickyNotesTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      StickyNotesTableCompanion(
        x: Value(x),
        y: Value(y),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateContent(String id, String content) async {
    await (_db.update(
      _db.stickyNotesTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      StickyNotesTableCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateColor(String id, String colorHex) async {
    await (_db.update(
      _db.stickyNotesTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      StickyNotesTableCompanion(
        colorHex: Value(colorHex),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
