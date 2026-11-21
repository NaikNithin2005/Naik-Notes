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
  TextColumn get coverImageUrl => text().nullable()();
  TextColumn get paperTemplateId =>
      text().withDefault(const Constant('college_ruled'))();
  TextColumn get orientation =>
      text().withDefault(const Constant('portrait'))();
  TextColumn get pageSize => text().withDefault(const Constant('A4'))();
  IntColumn get pageCount => integer().withDefault(const Constant(1))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isPdf => boolean().withDefault(const Constant(false))();
  TextColumn get pdfPath => text().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  TextColumn get deletionId => text().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

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
  BoolColumn get isBookmarked => boolean().withDefault(const Constant(false))();
  IntColumn get pdfPageIndex => integer().nullable()();
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
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get revision => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing sticky note and text annotations on notebook/PDF pages.
class StickyNotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get pageId =>
      text().references(PagesTable, #id, onDelete: KeyAction.cascade)();
  RealColumn get x => real()();
  RealColumn get y => real()();
  RealColumn get width => real().withDefault(const Constant(160.0))();
  RealColumn get height => real().withDefault(const Constant(140.0))();
  TextColumn get content => text()();
  TextColumn get colorHex => text().withDefault(
    const Constant('#FEF08A'),
  )(); // Classic soft canary yellow
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing local offline sync queue operations awaiting push to backend.
class SyncQueueTable extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().withDefault(const Constant('local_user'))();
  TextColumn get entityType =>
      text()(); // notebook, folder, page, stroke, sticky_note
  TextColumn get entityId => text()();
  TextColumn get parentId => text().nullable()(); // notebookId or pageId
  TextColumn get operationType => text()(); // insert, update, delete
  TextColumn get payloadJson => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(
    const Constant('pending'),
  )(); // pending, syncing, synced, failed
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing indexed text on notebook pages (from OCR, handwriting, sticky notes, or PDF text).
class PageSearchIndexTable extends Table {
  TextColumn get id => text()();
  TextColumn get pageId =>
      text().references(PagesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get notebookId =>
      text().references(NotebooksTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get sourceType => text()(); // handwriting, pdf, sticky_note
  TextColumn get textContent => text()();
  TextColumn get boundingBoxesJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing audio recordings attached to a notebook or page.
class AudioRecordingsTable extends Table {
  TextColumn get id => text()();
  TextColumn get notebookId =>
      text().references(NotebooksTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get pageId => text().nullable().references(
    PagesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get title => text().withDefault(const Constant('Lecture Audio'))();
  TextColumn get filePath => text()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing timestamped bookmarks within an audio recording synchronized with handwriting.
class AudioBookmarksTable extends Table {
  TextColumn get id => text()();
  TextColumn get recordingId => text().references(
    AudioRecordingsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get pageId => text().nullable()();
  TextColumn get strokeId => text().nullable()();
  IntColumn get timestampMs => integer()();
  TextColumn get label => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing historical snapshots of notebook pages for version history and restore.
class PageSnapshotsTable extends Table {
  TextColumn get id => text()();
  TextColumn get pageId =>
      text().references(PagesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get notebookId =>
      text().references(NotebooksTable, #id, onDelete: KeyAction.cascade)();
  IntColumn get versionNumber => integer().withDefault(const Constant(1))();
  TextColumn get label => text().withDefault(const Constant('Snapshot'))();
  TextColumn get strokesJson => text()();
  TextColumn get stickyNotesJson => text().withDefault(const Constant('[]'))();
  TextColumn get templateId =>
      text().withDefault(const Constant('college_ruled'))();
  TextColumn get templatePropertiesJson => text().nullable()();
  TextColumn get deviceInfo =>
      text().withDefault(const Constant('Local Device'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing custom user-created and downloaded community paper templates.
class CustomTemplatesTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get author => text().withDefault(const Constant('Community'))();
  TextColumn get paperPropertiesJson => text()();
  TextColumn get thumbnailBase64 => text().nullable()();
  BoolColumn get isInstalled => boolean().withDefault(const Constant(true))();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  IntColumn get downloadCount => integer().withDefault(const Constant(0))();
  RealColumn get rating => real().withDefault(const Constant(5.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing note attachments stored in Google Drive appDataFolder and cached locally.
class AttachmentsTable extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().withDefault(const Constant('local_user'))();
  TextColumn get noteId => text()();
  TextColumn get driveFileId => text().nullable()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  TextColumn get localPath => text().nullable()();
  TextColumn get checksum => text()();
  TextColumn get storageProvider => text().withDefault(
    const Constant('google_drive_appdata'),
  )();
  TextColumn get uploadStatus => text().withDefault(
    const Constant('pending'),
  )();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get uploadedAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing rich-text notes with Quill Delta JSON persistence.
class NotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text().withDefault(const Constant('local_user'))();
  TextColumn get notebookId => text()();
  TextColumn get title => text().withDefault(const Constant('Untitled Note'))();
  TextColumn get contentDelta =>
      text().withDefault(const Constant('[{"insert":"\\n"}]'))();
  TextColumn get plainText => text().withDefault(const Constant(''))();
  TextColumn get preview => text().withDefault(const Constant(''))();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get deletionId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get localVersion => integer().withDefault(const Constant(1))();
  IntColumn get serverVersion => integer().withDefault(const Constant(1))();
  TextColumn get deviceId => text().nullable()();
  TextColumn get lastModifiedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table representing permanent deletion tombstones.
/// Prevents permanently deleted notebooks and notes from resurrecting through cloud sync.
class TombstonesTable extends Table {
  TextColumn get id => text()(); // Original notebookId or noteId
  TextColumn get ownerId => text().withDefault(const Constant('local_user'))();
  TextColumn get entityType => text()(); // 'notebook' | 'note'
  TextColumn get deletionId => text()();
  DateTimeColumn get deletedAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table mapping local entity IDs to Google Drive file/folder IDs.
/// Guarantees that sync updates existing Drive files/folders instead of creating duplicates.
class DriveFileMappingsTable extends Table {
  TextColumn get entityId => text()(); // notebookId, noteId, pageId, folderId
  TextColumn get ownerId => text().withDefault(const Constant('local_user'))();
  TextColumn get entityType => text()();
  TextColumn get driveFileId => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entityId};
}

@DriftDatabase(
  tables: [
    FoldersTable,
    NotebooksTable,
    SectionsTable,
    PagesTable,
    StrokesTable,
    StickyNotesTable,
    SyncQueueTable,
    PageSearchIndexTable,
    AudioRecordingsTable,
    AudioBookmarksTable,
    PageSnapshotsTable,
    CustomTemplatesTable,
    AttachmentsTable,
    NotesTable,
    TombstonesTable,
    DriveFileMappingsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnectionForUser('local_user'));

  static final Map<String, AppDatabase> _userDatabases = {};

  factory AppDatabase.forUser(String userId, [QueryExecutor? e]) {
    if (e != null) {
      return AppDatabase(e);
    }
    final sanitized = sanitizeUid(userId);
    final existing = _userDatabases[sanitized];
    if (existing != null) {
      return existing;
    }
    final instance = AppDatabase(_openConnectionForUser(userId));
    _userDatabases[sanitized] = instance;
    return instance;
  }

  @override
  Future<void> close() async {
    _userDatabases.removeWhere((key, value) => identical(value, this));
    await super.close();
  }

  static void resetInstances() {
    _userDatabases.clear();
  }

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 10) {
        await m.addColumn(notebooksTable, notebooksTable.coverImageUrl);
      }
      if (from < 11) {
        await m.addColumn(syncQueueTable, syncQueueTable.ownerId);
        await m.addColumn(syncQueueTable, syncQueueTable.parentId);
      }
      if (from < 12) {
        await m.createTable(attachmentsTable);
      }
      if (from < 13) {
        await m.createTable(notesTable);
      }
      if (from < 14) {
        await m.addColumn(notebooksTable, notebooksTable.deletionId);
        await m.addColumn(notebooksTable, notebooksTable.lastSyncedAt);
        await m.addColumn(notesTable, notesTable.deletionId);
        await m.addColumn(notesTable, notesTable.syncStatus);
        await m.createTable(tombstonesTable);
        await m.createTable(driveFileMappingsTable);
      }
      if (from < 15) {
        await m.addColumn(notesTable, notesTable.localVersion);
        await m.addColumn(notesTable, notesTable.serverVersion);
        await m.addColumn(notesTable, notesTable.deviceId);
        await m.addColumn(notesTable, notesTable.lastModifiedBy);
      }
    },
  );

  static String sanitizeUid(String userId) {
    final sanitized = userId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final cleaned = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'anonymous' : cleaned;
  }

  static QueryExecutor _openConnectionForUser(String userId) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final sanitized = sanitizeUid(userId);
    return driftDatabase(name: 'naik_notes_user_$sanitized');
  }
}
