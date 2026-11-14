import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/stroke_model.dart';

/// Repository interface for local persistence of vector strokes.
abstract class StrokeRepository {
  Future<List<Stroke>> getStrokesForPage(String pageId);
  Stream<List<Stroke>> watchStrokesForPage(String pageId);
  Future<void> saveStroke(Stroke stroke);
  Future<void> saveStrokes(List<Stroke> strokes);
  Future<void> softDeleteStroke(String strokeId);
  Future<void> softDeleteStrokes(List<String> strokeIds);
  Future<void> restoreStroke(String strokeId);
  Future<void> permanentlyDeleteStroke(String strokeId);
  Future<void> clearPage(String pageId);
}

/// Drift implementation of [StrokeRepository].
class DriftStrokeRepository implements StrokeRepository {
  final AppDatabase _db;

  DriftStrokeRepository(this._db);

  Stroke _toDomain(StrokesTableData row) {
    final rawPoints = jsonDecode(row.pointsJson) as List<dynamic>;
    final pts = rawPoints
        .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
        .toList();

    final b = jsonDecode(row.boundingBoxJson) as Map<String, dynamic>;
    final bbox = Rect.fromLTRB(
      (b['left'] as num).toDouble(),
      (b['top'] as num).toDouble(),
      (b['right'] as num).toDouble(),
      (b['bottom'] as num).toDouble(),
    );

    return Stroke(
      id: row.id,
      pageId: row.pageId,
      tool: ToolType.fromId(row.toolType),
      colorValue: row.colorValue,
      width: row.width,
      opacity: row.opacity,
      points: pts,
      boundingBox: bbox,
      revision: row.revision,
      createdAt: row.createdAt,
      deletedAt: row.deletedAt,
    );
  }

  StrokesTableCompanion _toCompanion(Stroke domain) {
    return StrokesTableCompanion(
      id: Value(domain.id),
      pageId: Value(domain.pageId),
      toolType: Value(domain.tool.id),
      colorValue: Value(domain.colorValue),
      width: Value(domain.width),
      opacity: Value(domain.opacity),
      pointsJson: Value(domain.pointsToJsonString()),
      boundingBoxJson: Value(domain.boundingBoxToJsonString()),
      createdAt: Value(domain.createdAt),
      deletedAt: Value(domain.deletedAt),
      revision: Value(domain.revision),
    );
  }

  @override
  Future<List<Stroke>> getStrokesForPage(String pageId) async {
    final query = _db.select(_db.strokesTable)
      ..where((tbl) => tbl.pageId.equals(pageId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<Stroke>> watchStrokesForPage(String pageId) {
    final query = _db.select(_db.strokesTable)
      ..where((tbl) => tbl.pageId.equals(pageId) & tbl.deletedAt.isNull())
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<void> saveStroke(Stroke stroke) async {
    await _db
        .into(_db.strokesTable)
        .insertOnConflictUpdate(_toCompanion(stroke));
  }

  @override
  Future<void> saveStrokes(List<Stroke> strokes) async {
    await _db.batch((batch) {
      for (final stroke in strokes) {
        batch.insert(
          _db.strokesTable,
          _toCompanion(stroke),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<void> softDeleteStroke(String strokeId) async {
    final now = DateTime.now();
    await (_db.update(_db.strokesTable)
          ..where((tbl) => tbl.id.equals(strokeId)))
        .write(StrokesTableCompanion(deletedAt: Value(now)));
  }

  @override
  Future<void> softDeleteStrokes(List<String> strokeIds) async {
    if (strokeIds.isEmpty) return;
    final now = DateTime.now();
    await (_db.update(_db.strokesTable)..where((tbl) => tbl.id.isIn(strokeIds)))
        .write(StrokesTableCompanion(deletedAt: Value(now)));
  }

  @override
  Future<void> restoreStroke(String strokeId) async {
    await (_db.update(_db.strokesTable)
          ..where((tbl) => tbl.id.equals(strokeId)))
        .write(const StrokesTableCompanion(deletedAt: Value(null)));
  }

  @override
  Future<void> permanentlyDeleteStroke(String strokeId) async {
    await (_db.delete(
      _db.strokesTable,
    )..where((tbl) => tbl.id.equals(strokeId))).go();
  }

  @override
  Future<void> clearPage(String pageId) async {
    final now = DateTime.now();
    await (_db.update(_db.strokesTable)
          ..where((tbl) => tbl.pageId.equals(pageId) & tbl.deletedAt.isNull()))
        .write(StrokesTableCompanion(deletedAt: Value(now)));
  }
}
