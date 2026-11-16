import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/app_database.dart';
import '../../data/local/database_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return BackupService(db);
});

/// Service for exporting and restoring full app backups (notebooks, folders, pages, strokes)
/// as compressed ZIP archives (.naiknotes or .zip).
class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  /// Creates a ZIP archive containing all notebooks, folders, pages, strokes, and sticky notes.
  Future<Uint8List> createBackupArchive() async {
    final archive = Archive();

    // 1. Fetch all local database rows
    final notebooks = await _db.select(_db.notebooksTable).get();
    final folders = await _db.select(_db.foldersTable).get();
    final pages = await _db.select(_db.pagesTable).get();
    final strokes = await _db.select(_db.strokesTable).get();
    final stickyNotes = await _db.select(_db.stickyNotesTable).get();

    final manifest = {
      'app': 'Naik Notes',
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'notebookCount': notebooks.length,
      'folderCount': folders.length,
      'pageCount': pages.length,
      'strokeCount': strokes.length,
      'stickyNoteCount': stickyNotes.length,
    };

    // Add manifest
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );

    // Add notebooks.json
    final notebooksData = notebooks.map((n) {
      return {
        'id': n.id,
        'title': n.title,
        'description': n.description,
        'folderId': n.folderId,
        'coverColorHex': n.coverColorHex,
        'coverImageUrl': n.coverImageUrl,
        'paperTemplateId': n.paperTemplateId,
        'pageSize': n.pageSize,
        'orientation': n.orientation,
        'pageCount': n.pageCount,
        'isFavorite': n.isFavorite,
        'isArchived': n.isArchived,
        'createdAt': n.createdAt.toIso8601String(),
        'updatedAt': n.updatedAt.toIso8601String(),
      };
    }).toList();
    final notebooksBytes = utf8.encode(jsonEncode(notebooksData));
    archive.addFile(
      ArchiveFile('notebooks.json', notebooksBytes.length, notebooksBytes),
    );

    // Add folders.json
    final foldersData = folders.map((f) {
      return {
        'id': f.id,
        'name': f.name,
        'colorHex': f.colorHex,
        'createdAt': f.createdAt.toIso8601String(),
        'updatedAt': f.updatedAt.toIso8601String(),
      };
    }).toList();
    final foldersBytes = utf8.encode(jsonEncode(foldersData));
    archive.addFile(
      ArchiveFile('folders.json', foldersBytes.length, foldersBytes),
    );

    // Add pages.json
    final pagesData = pages.map((p) {
      return {
        'id': p.id,
        'notebookId': p.notebookId,
        'pageNumber': p.pageNumber,
        'templateId': p.templateId,
        'templatePropertiesJson': p.templatePropertiesJson,
        'width': p.width,
        'height': p.height,
        'isBookmarked': p.isBookmarked,
        'createdAt': p.createdAt.toIso8601String(),
        'updatedAt': p.updatedAt.toIso8601String(),
      };
    }).toList();
    final pagesBytes = utf8.encode(jsonEncode(pagesData));
    archive.addFile(ArchiveFile('pages.json', pagesBytes.length, pagesBytes));

    // Add strokes.json
    final strokesData = strokes.map((s) {
      return {
        'id': s.id,
        'pageId': s.pageId,
        'toolType': s.toolType,
        'colorValue': s.colorValue,
        'width': s.width,
        'opacity': s.opacity,
        'pointsJson': s.pointsJson,
        'boundingBoxJson': s.boundingBoxJson,
        'createdAt': s.createdAt.toIso8601String(),
      };
    }).toList();
    final strokesBytes = utf8.encode(jsonEncode(strokesData));
    archive.addFile(
      ArchiveFile('strokes.json', strokesBytes.length, strokesBytes),
    );

    // Add sticky_notes.json
    final stickyNotesData = stickyNotes.map((sn) {
      return {
        'id': sn.id,
        'pageId': sn.pageId,
        'x': sn.x,
        'y': sn.y,
        'width': sn.width,
        'height': sn.height,
        'content': sn.content,
        'colorHex': sn.colorHex,
        'createdAt': sn.createdAt.toIso8601String(),
        'updatedAt': sn.updatedAt.toIso8601String(),
      };
    }).toList();
    final stickyNotesBytes = utf8.encode(jsonEncode(stickyNotesData));
    archive.addFile(
      ArchiveFile(
        'sticky_notes.json',
        stickyNotesBytes.length,
        stickyNotesBytes,
      ),
    );

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData);
  }

  /// Restores database content from a ZIP archive.
  Future<({int notebooksRestored, int pagesRestored, int strokesRestored})>
  restoreFromZip(Uint8List zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    int nbCount = 0;
    int pageCount = 0;
    int strokeCount = 0;

    // 1. Restore folders
    final foldersFile = archive.findFile('folders.json');
    if (foldersFile != null) {
      final jsonStr = utf8.decode(foldersFile.content as List<int>);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        await _db
            .into(_db.foldersTable)
            .insertOnConflictUpdate(
              FoldersTableCompanion(
                id: Value(m['id'] as String),
                name: Value(m['name'] as String),
                colorHex: Value(m['colorHex'] as String? ?? '#8B4513'),
                createdAt: Value(DateTime.parse(m['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
              ),
            );
      }
    }

    // 2. Restore notebooks
    final notebooksFile = archive.findFile('notebooks.json');
    if (notebooksFile != null) {
      final jsonStr = utf8.decode(notebooksFile.content as List<int>);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        await _db
            .into(_db.notebooksTable)
            .insertOnConflictUpdate(
              NotebooksTableCompanion(
                id: Value(m['id'] as String),
                title: Value(m['title'] as String),
                description: Value(m['description'] as String? ?? ''),
                folderId: Value(m['folderId'] as String?),
                coverColorHex: Value(
                  m['coverColorHex'] as String? ?? '#8B4513',
                ),
                coverImageUrl: Value(m['coverImageUrl'] as String?),
                paperTemplateId: Value(
                  m['paperTemplateId'] as String? ?? 'college_ruled',
                ),
                pageSize: Value(m['pageSize'] as String? ?? 'A4'),
                orientation: Value(m['orientation'] as String? ?? 'portrait'),
                pageCount: Value(m['pageCount'] as int? ?? 1),
                isFavorite: Value(m['isFavorite'] as bool? ?? false),
                isArchived: Value(m['isArchived'] as bool? ?? false),
                createdAt: Value(DateTime.parse(m['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
              ),
            );
        nbCount++;
      }
    }

    // 3. Restore pages
    final pagesFile = archive.findFile('pages.json');
    if (pagesFile != null) {
      final jsonStr = utf8.decode(pagesFile.content as List<int>);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        await _db
            .into(_db.pagesTable)
            .insertOnConflictUpdate(
              PagesTableCompanion(
                id: Value(m['id'] as String),
                notebookId: Value(m['notebookId'] as String),
                pageNumber: Value(m['pageNumber'] as int),
                templateId: Value(
                  m['templateId'] as String? ?? 'college_ruled',
                ),
                templatePropertiesJson: Value(
                  m['templatePropertiesJson'] as String?,
                ),
                width: Value((m['width'] as num?)?.toDouble() ?? 595.28),
                height: Value((m['height'] as num?)?.toDouble() ?? 841.89),
                isBookmarked: Value(m['isBookmarked'] as bool? ?? false),
                createdAt: Value(DateTime.parse(m['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
              ),
            );
        pageCount++;
      }
    }

    // 4. Restore strokes
    final strokesFile = archive.findFile('strokes.json');
    if (strokesFile != null) {
      final jsonStr = utf8.decode(strokesFile.content as List<int>);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        await _db
            .into(_db.strokesTable)
            .insertOnConflictUpdate(
              StrokesTableCompanion(
                id: Value(m['id'] as String),
                pageId: Value(m['pageId'] as String),
                toolType: Value(m['toolType'] as String? ?? 'pen'),
                colorValue: Value(m['colorValue'] as int? ?? 0xFF000000),
                width: Value((m['width'] as num?)?.toDouble() ?? 2.0),
                opacity: Value((m['opacity'] as num?)?.toDouble() ?? 1.0),
                pointsJson: Value(m['pointsJson'] as String? ?? '[]'),
                boundingBoxJson: Value(m['boundingBoxJson'] as String? ?? '{}'),
                createdAt: Value(DateTime.parse(m['createdAt'] as String)),
              ),
            );
        strokeCount++;
      }
    }

    // 5. Restore sticky notes
    final stickyNotesFile = archive.findFile('sticky_notes.json');
    if (stickyNotesFile != null) {
      final jsonStr = utf8.decode(stickyNotesFile.content as List<int>);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        await _db
            .into(_db.stickyNotesTable)
            .insertOnConflictUpdate(
              StickyNotesTableCompanion(
                id: Value(m['id'] as String),
                pageId: Value(m['pageId'] as String),
                x: Value((m['x'] as num).toDouble()),
                y: Value((m['y'] as num).toDouble()),
                width: Value((m['width'] as num?)?.toDouble() ?? 160.0),
                height: Value((m['height'] as num?)?.toDouble() ?? 140.0),
                content: Value(m['content'] as String? ?? ''),
                colorHex: Value(m['colorHex'] as String? ?? '#FEF08A'),
                createdAt: Value(DateTime.parse(m['createdAt'] as String)),
                updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
              ),
            );
      }
    }

    return (
      notebooksRestored: nbCount,
      pagesRestored: pageCount,
      strokesRestored: strokeCount,
    );
  }
}
