import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';

void main() {
  group('Notebook CRUD & Folder Integration Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftNotebookRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('renames notebook and updates description', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-crud-1',
        ownerId: 'user-default',
        title: 'Original Title',
        description: 'Old description',
        coverId: 'dark_academia_leather',
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveNotebook(nb);

      await repo.renameNotebook(
        'nb-crud-1',
        'Updated Title',
        newDescription: 'New description',
      );

      final updated = await repo.getNotebookById('nb-crud-1');
      expect(updated, isNotNull);
      expect(updated!.title, 'Updated Title');
      expect(updated.description, 'New description');
    });

    test('duplicates notebook with copy suffix and new unique ID', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-source-1',
        ownerId: 'user-default',
        folderId: 'folder-sci',
        title: 'Calculus III',
        description: 'Multivariable calculus notes',
        coverId: 'dark_academia_leather',
        coverColorHex: '#1E2A38',
        paperTemplateId: 'square_grid',
        orientation: 'portrait',
        pageSize: 'A4',
        pageCount: 15,
        isFavorite: true,
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveNotebook(nb);

      final duplicated = await repo.duplicateNotebook('nb-source-1');
      expect(duplicated, isNotNull);
      expect(duplicated!.id, isNot(equals('nb-source-1')));
      expect(duplicated.title, 'Calculus III (Copy)');
      expect(duplicated.description, 'Multivariable calculus notes');
      expect(duplicated.folderId, 'folder-sci');
      expect(duplicated.coverId, 'dark_academia_leather');
      expect(duplicated.pageCount, 15);

      // Verify both exist in repository
      final all = await repo.getAllNotebooks();
      expect(all.length, 2);
    });

    test('moves notebook between folders and unfiles', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-move-1',
        ownerId: 'user-default',
        folderId: null,
        title: 'Draft Notes',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveNotebook(nb);

      // Move to folder A
      await repo.moveNotebookToFolder('nb-move-1', 'folder-a');
      var item = await repo.getNotebookById('nb-move-1');
      expect(item?.folderId, 'folder-a');

      // Move to folder B
      await repo.moveNotebookToFolder('nb-move-1', 'folder-b');
      item = await repo.getNotebookById('nb-move-1');
      expect(item?.folderId, 'folder-b');

      // Unfile (null)
      await repo.moveNotebookToFolder('nb-move-1', null);
      item = await repo.getNotebookById('nb-move-1');
      expect(item?.folderId, isNull);
    });

    test('archives and unarchives notebook', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-archive-1',
        ownerId: 'user-default',
        title: 'Semester 1 Archives',
        coverId: 'classic_leather',
        isArchived: false,
        createdAt: now,
        updatedAt: now,
      );
      await repo.saveNotebook(nb);

      // Archive
      await repo.archiveNotebook('nb-archive-1');

      // Should not be in regular getAllNotebooks()
      final activeNotebooks = await repo.getAllNotebooks(
        includeArchived: false,
      );
      expect(activeNotebooks.any((n) => n.id == 'nb-archive-1'), false);

      // Should be in getAllNotebooks(includeArchived: true)
      final allNotebooks = await repo.getAllNotebooks(includeArchived: true);
      expect(allNotebooks.any((n) => n.id == 'nb-archive-1'), true);

      final archivedItem = await repo.getNotebookById('nb-archive-1');
      expect(archivedItem?.isArchived, true);

      // Unarchive
      await repo.unarchiveNotebook('nb-archive-1');
      final unarchivedItem = await repo.getNotebookById('nb-archive-1');
      expect(unarchivedItem?.isArchived, false);
      final activeAgain = await repo.getAllNotebooks(includeArchived: false);
      expect(activeAgain.any((n) => n.id == 'nb-archive-1'), true);
    });

    test('filters notebooks by folder', () async {
      final now = DateTime.now();
      final nb1 = Notebook(
        id: 'nb-f1',
        ownerId: 'user-default',
        folderId: 'folder-math',
        title: 'Algebra',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );
      final nb2 = Notebook(
        id: 'nb-f2',
        ownerId: 'user-default',
        folderId: 'folder-math',
        title: 'Geometry',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );
      final nb3 = Notebook(
        id: 'nb-f3',
        ownerId: 'user-default',
        folderId: 'folder-art',
        title: 'Drawings',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );
      final nb4 = Notebook(
        id: 'nb-f4',
        ownerId: 'user-default',
        folderId: null,
        title: 'Unfiled Idea',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );

      await repo.saveNotebook(nb1);
      await repo.saveNotebook(nb2);
      await repo.saveNotebook(nb3);
      await repo.saveNotebook(nb4);

      final mathNotes = await repo.getNotebooksByFolder('folder-math');
      expect(mathNotes.length, 2);
      expect(
        mathNotes.map((n) => n.title),
        containsAll(['Algebra', 'Geometry']),
      );

      final artNotes = await repo.getNotebooksByFolder('folder-art');
      expect(artNotes.length, 1);
      expect(artNotes.first.title, 'Drawings');
    });
  });
}
