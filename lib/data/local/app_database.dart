import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Table representing notebook folders.
class FoldersTable extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().withDefault(const Constant('local_user'))();
  TextColumn get parentId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get colorHex => text().withDefault(const Constant('#8B4513'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing stored notebooks.
class NotebooksTable extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().withDefault(const Constant('local_user'))();
  TextColumn get folderId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get coverId =>
      text().withDefault(const Constant('classic_leather'))();
  TextColumn get coverColorHex =>
      text().withDefault(const Constant('#8B4513'))();
  TextColumn get paperTemplateId =>
      text().withDefault(const Constant('college_ruled'))();
  TextColumn get orientation =>
      text().withDefault(const Constant('portrait'))();
  TextColumn get pageSize => text().withDefault(const Constant('A4'))();
  IntColumn get pageCount => integer().withDefault(const Constant(1))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing notebook sections (tabbed dividers).
class SectionsTable extends Table {
  TextColumn get id => text()();
  TextColumn get notebookId =>
      text().references(NotebooksTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get colorHex => text().withDefault(const Constant('#1E2A38'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing notebook pages.
class PagesTable extends Table {
  TextColumn get id => text()();
  TextColumn get notebookId =>
      text().references(NotebooksTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get sectionId => text().nullable()();
  IntColumn get pageNumber => integer()();
  TextColumn get templateId =>
      text().withDefault(const Constant('college_ruled'))();
  TextColumn get backgroundColor => text().nullable()();
  TextColumn get templatePropertiesJson => text().nullable()();
  RealColumn get width => real().withDefault(const Constant(595.28))();
  RealColumn get height => real().withDefault(const Constant(841.89))();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing vector handwriting strokes.
class StrokesTable extends Table {
  TextColumn get id => text()();
  TextColumn get pageId =>
      text().references(PagesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get toolType => text()();
  IntColumn get colorValue => integer()();
  RealColumn get width => real()();
  RealColumn get opacity => real()();
  TextColumn get pointsJson => text()();
  TextColumn get boundingBoxJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get revision => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    FoldersTable,
    NotebooksTable,
    SectionsTable,
    PagesTable,
    StrokesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 3;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'naik_notes_local');
  }
}
