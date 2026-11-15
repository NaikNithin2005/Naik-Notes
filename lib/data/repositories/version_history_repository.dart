import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/version_history_model.dart';

abstract class VersionHistoryRepository {
  Future<void> saveSnapshot(PageSnapshot snapshot);
  Future<List<PageSnapshot>> getSnapshotsForPage(String pageId);
  Future<PageSnapshot?> getSnapshotById(String id);
  Future<void> deleteSnapshot(String id);
  Future<void> deleteSnapshotsForPage(String pageId);
  Future<void> restoreSnapshot(String snapshotId);
}

class DriftVersionHistoryRepository implements VersionHistoryRepository {
  final AppDatabase db;

  DriftVersionHistoryRepository(this.db);

  @override
  Future<void> saveSnapshot(PageSnapshot snapshot) async {
    await db
        .into(db.pageSnapshotsTable)
        .insertOnConflictUpdate(
          PageSnapshotsTableCompanion(
            id: Value(snapshot.id),
            pageId: Value(snapshot.pageId),
            notebookId: Value(snapshot.notebookId),
            versionNumber: Value(snapshot.versionNumber),
            label: Value(snapshot.label),
            strokesJson: Value(
              jsonEncode(snapshot.strokes.map((s) => s.toJson()).toList()),
            ),
            stickyNotesJson: Value(
              jsonEncode(snapshot.stickyNotes.map((n) => n.toJson()).toList()),
            ),
            templateId: Value(snapshot.templateId),
            templatePropertiesJson: Value(
              snapshot.templateProperties != null
                  ? jsonEncode(snapshot.templateProperties!.toJson())
                  : null,
            ),
            deviceInfo: Value(snapshot.deviceInfo),
            createdAt: Value(snapshot.createdAt),
          ),
        );
  }

  @override
  Future<List<PageSnapshot>> getSnapshotsForPage(String pageId) async {
    final rows =
        await (db.select(db.pageSnapshotsTable)
              ..where((t) => t.pageId.equals(pageId))
              ..orderBy([
                (t) => OrderingTerm.desc(t.versionNumber),
                (t) => OrderingTerm.desc(t.createdAt),
              ]))
            .get();

    return rows.map((r) => _mapRowToSnapshot(r)).toList();
  }

  @override
  Future<PageSnapshot?> getSnapshotById(String id) async {
    final row = await (db.select(
      db.pageSnapshotsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (row == null) return null;
    return _mapRowToSnapshot(row);
  }

  @override
  Future<void> deleteSnapshot(String id) async {
    await (db.delete(
      db.pageSnapshotsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> deleteSnapshotsForPage(String pageId) async {
    await (db.delete(
      db.pageSnapshotsTable,
    )..where((t) => t.pageId.equals(pageId))).go();
  }

  @override
  Future<void> restoreSnapshot(String snapshotId) async {
    final snapshot = await getSnapshotById(snapshotId);
    if (snapshot == null) return;

    await db.transaction(() async {
      // 1. Update page template and properties
      await (db.update(
        db.pagesTable,
      )..where((t) => t.id.equals(snapshot.pageId))).write(
        PagesTableCompanion(
          templateId: Value(snapshot.templateId),
          templatePropertiesJson: Value(
            snapshot.templateProperties != null
                ? jsonEncode(snapshot.templateProperties!.toJson())
                : null,
          ),
          updatedAt: Value(DateTime.now()),
        ),
      );

      // 2. Delete current strokes on this page
      await (db.delete(
        db.strokesTable,
      )..where((t) => t.pageId.equals(snapshot.pageId))).go();

      // 3. Insert snapshot strokes
      for (final s in snapshot.strokes) {
        await db
            .into(db.strokesTable)
            .insert(
              StrokesTableCompanion(
                id: Value(s.id),
                pageId: Value(snapshot.pageId),
                toolType: Value(s.tool.id),
                colorValue: Value(s.colorValue),
                width: Value(s.width),
                opacity: Value(s.opacity),
                pointsJson: Value(s.pointsToJsonString()),
                boundingBoxJson: Value(s.boundingBoxToJsonString()),
                createdAt: Value(s.createdAt),
                deletedAt: Value(s.deletedAt),
                revision: Value(s.revision),
              ),
            );
      }

      // 4. Delete and restore sticky notes
      await (db.delete(
        db.stickyNotesTable,
      )..where((t) => t.pageId.equals(snapshot.pageId))).go();

      for (final n in snapshot.stickyNotes) {
        await db
            .into(db.stickyNotesTable)
            .insert(
              StickyNotesTableCompanion(
                id: Value(n.id),
                pageId: Value(snapshot.pageId),
                x: Value(n.x),
                y: Value(n.y),
                width: Value(n.width),
                height: Value(n.height),
                content: Value(n.content),
                colorHex: Value(n.colorHex),
                createdAt: Value(n.createdAt),
                updatedAt: Value(n.updatedAt),
              ),
            );
      }
    });
  }

  PageSnapshot _mapRowToSnapshot(PageSnapshotsTableData r) {
    final strokes = PageSnapshot.parseStrokesJson(r.strokesJson);
    final stickyNotes = PageSnapshot.parseStickyNotesJson(r.stickyNotesJson);

    PaperProperties? props;
    if (r.templatePropertiesJson != null) {
      try {
        props = PaperProperties.fromJson(
          jsonDecode(r.templatePropertiesJson!) as Map<String, dynamic>,
        );
      } catch (_) {}
    }

    return PageSnapshot(
      id: r.id,
      pageId: r.pageId,
      notebookId: r.notebookId,
      versionNumber: r.versionNumber,
      label: r.label,
      strokes: strokes,
      stickyNotes: stickyNotes,
      templateId: r.templateId,
      templateProperties: props,
      deviceInfo: r.deviceInfo,
      createdAt: r.createdAt,
    );
  }
}
