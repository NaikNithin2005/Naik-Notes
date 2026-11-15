import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/template_store_model.dart';

abstract class TemplateStoreRepository {
  Future<void> saveCustomTemplate(CustomTemplate template);
  Future<List<CustomTemplate>> getInstalledTemplates({String? category});
  Future<List<CustomTemplate>> getAllTemplates({String? category});
  Future<CustomTemplate?> getTemplateById(String id);
  Future<void> deleteCustomTemplate(String id);
  Future<void> setTemplateInstalled(String id, bool installed);
}

class DriftTemplateStoreRepository implements TemplateStoreRepository {
  final AppDatabase db;

  DriftTemplateStoreRepository(this.db);

  @override
  Future<void> saveCustomTemplate(CustomTemplate template) async {
    await db
        .into(db.customTemplatesTable)
        .insertOnConflictUpdate(
          CustomTemplatesTableCompanion(
            id: Value(template.id),
            title: Value(template.title),
            description: Value(template.description),
            category: Value(template.category),
            author: Value(template.author),
            paperPropertiesJson: Value(
              jsonEncode(template.properties.toJson()),
            ),
            thumbnailBase64: Value(template.thumbnailBase64),
            isInstalled: Value(template.isInstalled),
            isBuiltIn: Value(template.isBuiltIn),
            downloadCount: Value(template.downloadCount),
            rating: Value(template.rating),
            createdAt: Value(template.createdAt),
            updatedAt: Value(template.updatedAt),
          ),
        );
  }

  @override
  Future<List<CustomTemplate>> getInstalledTemplates({String? category}) async {
    var statement = db.select(db.customTemplatesTable)
      ..where((t) => t.isInstalled.equals(true));

    if (category != null && category.isNotEmpty && category != 'All') {
      statement = statement..where((t) => t.category.equals(category));
    }

    statement = statement..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);
    final rows = await statement.get();
    return rows.map((r) => _mapRowToTemplate(r)).toList();
  }

  @override
  Future<List<CustomTemplate>> getAllTemplates({String? category}) async {
    var statement = db.select(db.customTemplatesTable);

    if (category != null && category.isNotEmpty && category != 'All') {
      statement = statement..where((t) => t.category.equals(category));
    }

    statement = statement..orderBy([(t) => OrderingTerm.desc(t.downloadCount)]);
    final rows = await statement.get();
    return rows.map((r) => _mapRowToTemplate(r)).toList();
  }

  @override
  Future<CustomTemplate?> getTemplateById(String id) async {
    final row = await (db.select(
      db.customTemplatesTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (row == null) return null;
    return _mapRowToTemplate(row);
  }

  @override
  Future<void> deleteCustomTemplate(String id) async {
    await (db.delete(
      db.customTemplatesTable,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> setTemplateInstalled(String id, bool installed) async {
    await (db.update(
      db.customTemplatesTable,
    )..where((t) => t.id.equals(id))).write(
      CustomTemplatesTableCompanion(
        isInstalled: Value(installed),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  CustomTemplate _mapRowToTemplate(CustomTemplatesTableData r) {
    PaperProperties props;
    try {
      props = PaperProperties.fromJson(
        jsonDecode(r.paperPropertiesJson) as Map<String, dynamic>,
      );
    } catch (_) {
      props = const PaperProperties();
    }

    return CustomTemplate(
      id: r.id,
      title: r.title,
      description: r.description,
      category: r.category,
      author: r.author,
      properties: props,
      thumbnailBase64: r.thumbnailBase64,
      isInstalled: r.isInstalled,
      isBuiltIn: r.isBuiltIn,
      downloadCount: r.downloadCount,
      rating: r.rating,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
