import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/folder_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/repositories/folder_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';

void main() {
  group('Folder Model Tests', () {
    test('serializes and deserializes Folder to and from JSON', () {
      final now = DateTime(2026, 11, 14, 18, 0);
      final folder = Folder(
        id: 'f-101',
        ownerId: 'user-abc',
        parentId: 'f-parent',
        name: 'Quantum Optics',
        colorHex: '#1E2A38',
        createdAt: now,
        updatedAt: now,
      );

      final json = folder.toJson();
      expect(json['id'], 'f-101');
      expect(json['ownerId'], 'user-abc');
      expect(json['parentId'], 'f-parent');
      expect(json['name'], 'Quantum Optics');
      expect(json['colorHex'], '#1E2A38');

      final deserialized = Folder.fromJson(json);
      expect(deserialized.id, folder.id);
      expect(deserialized.name, folder.name);
      expect(deserialized.parentId, 'f-parent');
      expect(deserialized.colorHex, '#1E2A38');
    });

    test('copyWith updates specified fields', () {
      final now = DateTime(2026, 11, 14, 18, 0);
      final folder = Folder(
        id: 'f-102',
        name: 'Drafts',
        createdAt: now,
        updatedAt: now,
      );

      final updated = folder.copyWith(
        name: 'Published Notes',
        colorHex: '#4A6B53',
      );
      expect(updated.id, 'f-102');
      expect(updated.name, 'Published Notes');
      expect(updated.colorHex, '#4A6B53');
    });
  });

  group('DriftFolderRepository SQLite Tests', () {
    late AppDatabase db;
    late DriftFolderRepository folderRepo;
    late DriftNotebookRepository notebookRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      folderRepo = DriftFolderRepository(db);
      notebookRepo = DriftNotebookRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('saves and retrieves folders', () async {
      final now = DateTime.now();
      final folder = Folder(
        id: 'f-test-1',
        name: 'Mathematics',
        colorHex: '#1E2A38',
        createdAt: now,
        updatedAt: now,
      );

      await folderRepo.saveFolder(folder);

      final retrieved = await folderRepo.getFolderById('f-test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Mathematics');
      expect(retrieved.colorHex, '#1E2A38');

      final all = await folderRepo.getAllFolders();
      expect(all.length, 1);
      expect(all.first.id, 'f-test-1');
    });

    test('renames an existing folder', () async {
      final now = DateTime.now();
      final folder = Folder(
        id: 'f-rename-1',
        name: 'Old Name',
        colorHex: '#8B4513',
        createdAt: now,
        updatedAt: now,
      );
      await folderRepo.saveFolder(folder);

      await folderRepo.renameFolder(
        'f-rename-1',
        'New Advanced Name',
        newColorHex: '#4A1521',
      );

      final updated = await folderRepo.getFolderById('f-rename-1');
      expect(updated, isNotNull);
      expect(updated!.name, 'New Advanced Name');
      expect(updated.colorHex, '#4A1521');
    });

    test('deleting folder unassigns notebooks in that folder', () async {
      final now = DateTime.now();
      final folder = Folder(
        id: 'f-del-1',
        name: 'Physics',
        createdAt: now,
        updatedAt: now,
      );
      await folderRepo.saveFolder(folder);

      final notebook = Notebook(
        id: 'nb-in-folder',
        ownerId: 'user-default',
        folderId: 'f-del-1',
        title: 'Thermodynamics Notes',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );
      await notebookRepo.saveNotebook(notebook);

      // Verify notebook is in folder
      final preDelete = await notebookRepo.getNotebookById('nb-in-folder');
      expect(preDelete?.folderId, 'f-del-1');

      // Delete the folder
      await folderRepo.deleteFolder('f-del-1');

      // Folder should not appear in active folders
      final folderAfter = await folderRepo.getFolderById('f-del-1');
      expect(folderAfter, isNull);

      // Notebook should still exist but folderId is now unfiled (null)
      final postDelete = await notebookRepo.getNotebookById('nb-in-folder');
      expect(postDelete, isNotNull);
      expect(postDelete!.folderId, isNull);
    });

    test('does not populate demo folders in production when empty', () async {
      await folderRepo.populateDefaultSampleFoldersIfEmpty();
      final folders = await folderRepo.getAllFolders();
      expect(folders.isEmpty, true);
    });
  });
}
