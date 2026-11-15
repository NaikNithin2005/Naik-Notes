import 'package:drift/drift.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/search_index_model.dart';

abstract class PageSearchRepository {
  Future<void> indexPageContent(PageSearchEntry entry);
  Future<List<PageSearchEntry>> searchPages(String query, {String? notebookId});
  Future<List<PageSearchEntry>> getEntriesForPage(String pageId);
  Future<void> deleteEntriesForPage(String pageId, {String? sourceType});
  Future<void> deleteEntriesForNotebook(String notebookId);
}

class DriftPageSearchRepository implements PageSearchRepository {
  final AppDatabase db;

  DriftPageSearchRepository(this.db);

  @override
  Future<void> indexPageContent(PageSearchEntry entry) async {
    // Delete existing entry for this page and source type before re-indexing
    await (db.delete(db.pageSearchIndexTable)..where(
          (t) =>
              t.pageId.equals(entry.pageId) &
              t.sourceType.equals(entry.sourceType),
        ))
        .go();

    if (entry.textContent.trim().isEmpty) return;

    await db
        .into(db.pageSearchIndexTable)
        .insert(
          PageSearchIndexTableCompanion(
            id: Value(entry.id),
            pageId: Value(entry.pageId),
            notebookId: Value(entry.notebookId),
            sourceType: Value(entry.sourceType),
            textContent: Value(entry.textContent),
            boundingBoxesJson: Value(entry.boundingBoxesJson),
            createdAt: Value(entry.createdAt),
            updatedAt: Value(entry.updatedAt),
          ),
        );
  }

  @override
  Future<List<PageSearchEntry>> searchPages(
    String query, {
    String? notebookId,
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    var statement = db.select(db.pageSearchIndexTable);

    if (notebookId != null) {
      statement = statement
        ..where(
          (t) =>
              t.notebookId.equals(notebookId) &
              t.textContent.lower().contains(cleanQuery),
        );
    } else {
      statement = statement
        ..where((t) => t.textContent.lower().contains(cleanQuery));
    }

    final rows = await statement.get();
    return rows
        .map(
          (r) => PageSearchEntry.fromDatabase(
            id: r.id,
            pageId: r.pageId,
            notebookId: r.notebookId,
            sourceType: r.sourceType,
            textContent: r.textContent,
            boundingBoxesJson: r.boundingBoxesJson,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  @override
  Future<List<PageSearchEntry>> getEntriesForPage(String pageId) async {
    final rows = await (db.select(
      db.pageSearchIndexTable,
    )..where((t) => t.pageId.equals(pageId))).get();

    return rows
        .map(
          (r) => PageSearchEntry.fromDatabase(
            id: r.id,
            pageId: r.pageId,
            notebookId: r.notebookId,
            sourceType: r.sourceType,
            textContent: r.textContent,
            boundingBoxesJson: r.boundingBoxesJson,
            createdAt: r.createdAt,
            updatedAt: r.updatedAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> deleteEntriesForPage(String pageId, {String? sourceType}) async {
    var statement = db.delete(db.pageSearchIndexTable);
    if (sourceType != null) {
      await (statement..where(
            (t) => t.pageId.equals(pageId) & t.sourceType.equals(sourceType),
          ))
          .go();
    } else {
      await (statement..where((t) => t.pageId.equals(pageId))).go();
    }
  }

  @override
  Future<void> deleteEntriesForNotebook(String notebookId) async {
    await (db.delete(
      db.pageSearchIndexTable,
    )..where((t) => t.notebookId.equals(notebookId))).go();
  }
}
