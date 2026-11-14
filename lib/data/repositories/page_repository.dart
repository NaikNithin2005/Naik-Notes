import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../local/app_database.dart';
import '../models/page_model.dart';
import '../models/paper_template_model.dart';

/// Repository interface and implementation for local page persistence.
abstract class PageRepository {
  Future<List<NotebookPage>> getPagesForNotebook(String notebookId);
  Stream<List<NotebookPage>> watchPagesForNotebook(String notebookId);
  Future<NotebookPage?> getPageById(String pageId);
  Future<void> savePage(NotebookPage page);
  Future<void> deletePage(String pageId);
  Future<void> updatePageTemplate(
    String pageId,
    String templateId,
    PaperProperties properties,
  );
  Future<List<NotebookPage>> ensurePagesExist(
    String notebookId, {
    String templateId = 'college_ruled',
    String pageSize = 'A4',
    String orientation = 'portrait',
    int count = 1,
  });
}

class DriftPageRepository implements PageRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  DriftPageRepository(this._db);

  NotebookPage _toDomain(PagesTableData row) {
    final type = PaperTemplateType.fromId(row.templateId);
    final props = PaperProperties.fromJsonString(
      row.templatePropertiesJson,
      type,
    );

    return NotebookPage(
      id: row.id,
      notebookId: row.notebookId,
      sectionId: row.sectionId,
      pageNumber: row.pageNumber,
      templateId: row.templateId,
      properties: props,
      width: row.width,
      height: row.height,
      revision: row.revision,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  PagesTableCompanion _toCompanion(NotebookPage domain) {
    return PagesTableCompanion(
      id: Value(domain.id),
      notebookId: Value(domain.notebookId),
      sectionId: Value(domain.sectionId),
      pageNumber: Value(domain.pageNumber),
      templateId: Value(domain.templateId),
      backgroundColor: Value(domain.properties.backgroundColorHex),
      templatePropertiesJson: Value(domain.properties.toJsonString()),
      width: Value(domain.width),
      height: Value(domain.height),
      revision: Value(domain.revision),
      createdAt: Value(domain.createdAt),
      updatedAt: Value(domain.updatedAt),
    );
  }

  @override
  Future<List<NotebookPage>> getPagesForNotebook(String notebookId) async {
    final query = _db.select(_db.pagesTable)
      ..where((tbl) => tbl.notebookId.equals(notebookId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.pageNumber)]);
    final rows = await query.get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<NotebookPage>> watchPagesForNotebook(String notebookId) {
    final query = _db.select(_db.pagesTable)
      ..where((tbl) => tbl.notebookId.equals(notebookId))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.pageNumber)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<NotebookPage?> getPageById(String pageId) async {
    final query = _db.select(_db.pagesTable)
      ..where((tbl) => tbl.id.equals(pageId));
    final row = await query.getSingleOrNull();
    return row != null ? _toDomain(row) : null;
  }

  @override
  Future<void> savePage(NotebookPage page) async {
    await _db.into(_db.pagesTable).insertOnConflictUpdate(_toCompanion(page));
  }

  @override
  Future<void> deletePage(String pageId) async {
    await (_db.delete(
      _db.pagesTable,
    )..where((tbl) => tbl.id.equals(pageId))).go();
  }

  @override
  Future<void> updatePageTemplate(
    String pageId,
    String templateId,
    PaperProperties properties,
  ) async {
    final existing = await getPageById(pageId);
    if (existing != null) {
      final updated = existing.copyWith(
        templateId: templateId,
        properties: properties,
        updatedAt: DateTime.now(),
      );
      await savePage(updated);
    }
  }

  @override
  Future<List<NotebookPage>> ensurePagesExist(
    String notebookId, {
    String templateId = 'college_ruled',
    String pageSize = 'A4',
    String orientation = 'portrait',
    int count = 1,
  }) async {
    final existing = await getPagesForNotebook(notebookId);
    if (existing.isNotEmpty) {
      return existing;
    }

    final dims = PaperProperties.getDimensions(pageSize, orientation);
    final type = PaperTemplateType.fromId(templateId);
    final defaultProps = PaperProperties.defaultFor(
      type,
      pageSize: pageSize,
      orientation: orientation,
    );

    final now = DateTime.now();
    final newPages = <NotebookPage>[];

    for (int i = 1; i <= count; i++) {
      final page = NotebookPage(
        id: _uuid.v4(),
        notebookId: notebookId,
        pageNumber: i,
        templateId: templateId,
        properties: defaultProps,
        width: dims.width,
        height: dims.height,
        createdAt: now,
        updatedAt: now,
      );
      await savePage(page);
      newPages.add(page);
    }

    return newPages;
  }
}
