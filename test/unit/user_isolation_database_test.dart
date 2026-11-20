import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/folder_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sync_operation_model.dart';
import 'package:naik_notes/data/repositories/folder_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/sync_queue_repository.dart';

void main() {
  group('Strict Multi-User Database Isolation Tests', () {
    late AppDatabase dbUserA;
    late AppDatabase dbUserB;
    late DriftNotebookRepository notebookRepoA;
    late DriftNotebookRepository notebookRepoB;
    late DriftFolderRepository folderRepoA;
    late DriftFolderRepository folderRepoB;
    late DriftPageRepository pageRepoA;
    late DriftPageRepository pageRepoB;
    late DriftSyncQueueRepository syncQueueRepoA;
    late DriftSyncQueueRepository syncQueueRepoB;

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    setUp(() {
      // Simulate two completely separate database instances partitioned per UID
      dbUserA = AppDatabase(NativeDatabase.memory());
      dbUserB = AppDatabase(NativeDatabase.memory());

      notebookRepoA = DriftNotebookRepository(dbUserA);
      notebookRepoB = DriftNotebookRepository(dbUserB);
      folderRepoA = DriftFolderRepository(dbUserA);
      folderRepoB = DriftFolderRepository(dbUserB);
      pageRepoA = DriftPageRepository(dbUserA);
      pageRepoB = DriftPageRepository(dbUserB);
      syncQueueRepoA = DriftSyncQueueRepository(dbUserA);
      syncQueueRepoB = DriftSyncQueueRepository(dbUserB);
    });

    tearDown(() async {
      await dbUserA.close();
      await dbUserB.close();
    });

    test('User A data is completely invisible and isolated from User B', () async {
      const userA = 'user_alpha_uid_111';
      const userB = 'user_beta_uid_222';
      final now = DateTime.now();

      // 1. User A creates a notebook and folder
      final folderA = Folder(
        id: 'folder-a-private',
        ownerId: userA,
        name: "User A's Confidential Folder",
        createdAt: now,
        updatedAt: now,
      );
      await folderRepoA.saveFolder(folderA);

      final notebookA = Notebook(
        id: 'nb-a-confidential',
        ownerId: userA,
        folderId: folderA.id,
        title: 'Secret Notes User A',
        description: 'Contains private user A research',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
        pageCount: 1,
        createdAt: now,
        updatedAt: now,
      );
      await notebookRepoA.saveNotebook(notebookA);

      final pageA = NotebookPage(
        id: 'page-a-1',
        notebookId: notebookA.id,
        pageNumber: 1,
        templateId: 'college_ruled',
        properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
        createdAt: now,
        updatedAt: now,
      );
      await pageRepoA.savePage(pageA);

      // 2. User A verifies own data exists
      final userANotebooks = await notebookRepoA.getAllNotebooks(ownerId: userA);
      expect(userANotebooks.length, equals(1));
      expect(userANotebooks.first.id, equals('nb-a-confidential'));

      final userAFolders = await folderRepoA.getAllFolders(ownerId: userA);
      expect(userAFolders.length, equals(1));
      expect(userAFolders.first.id, equals('folder-a-private'));

      final userAPages = await pageRepoA.getPagesForNotebook(notebookA.id);
      expect(userAPages.length, equals(1));
      expect(userAPages.first.id, equals('page-a-1'));

      // 3. User B queries database — MUST BE STRICTLY EMPTY
      final userBNotebooks = await notebookRepoB.getAllNotebooks(ownerId: userB);
      expect(userBNotebooks, isEmpty);

      final userBFolders = await folderRepoB.getAllFolders(ownerId: userB);
      expect(userBFolders, isEmpty);

      // User B querying User A's notebook directly returns null
      final leakedNotebook = await notebookRepoB.getNotebookById('nb-a-confidential', ownerId: userB);
      expect(leakedNotebook, isNull);

      final leakedPages = await pageRepoB.getPagesForNotebook('nb-a-confidential');
      expect(leakedPages, isEmpty);
    });

    test('Sync queue operations enforce ownerId and partition isolation', () async {
      const userA = 'user_alpha_uid_111';

      // 1. User A enqueues an offline update
      final opA = SyncOperation(
        id: 'op-a-1',
        entityId: 'nb-a-confidential',
        entityType: SyncEntityType.notebook,
        operationType: SyncOperationType.insert,
        ownerId: userA,
        payload: {'title': 'Offline Notebook A'},
        revision: 1,
        createdAt: DateTime.now(),
      );
      await syncQueueRepoA.enqueue(opA);

      // 2. User A queue has 1 pending operation
      final pendingA = await syncQueueRepoA.getPendingOperations();
      expect(pendingA.length, equals(1));
      expect(pendingA.first.ownerId, equals(userA));
      expect(pendingA.first.entityId, equals('nb-a-confidential'));

      // 3. User B queue has 0 pending operations
      final pendingB = await syncQueueRepoB.getPendingOperations();
      expect(pendingB, isEmpty);

      // 4. User A marks operation as synced and clears synced
      await syncQueueRepoA.markAsSynced([opA.id]);
      await syncQueueRepoA.clearSynced();
      final remainingA = await syncQueueRepoA.getPendingOperations();
      expect(remainingA, isEmpty);
    });

    test('Sanitizes UID properly to avoid path traversal or invalid characters', () {
      final sanitizedValid = AppDatabase.sanitizeUid('user_123_abc-XYZ');
      expect(sanitizedValid, equals('user_123_abc-XYZ'));

      // Slashes and dots must be stripped
      final sanitizedMalicious = AppDatabase.sanitizeUid('../../etc/passwd..//');
      expect(sanitizedMalicious.contains('/'), isFalse);
      expect(sanitizedMalicious.contains(r'\'), isFalse);
      expect(sanitizedMalicious.contains('.'), isFalse);
      expect(sanitizedMalicious, equals('etc_passwd'));

      // Empty fallback
      final sanitizedEmpty = AppDatabase.sanitizeUid('???***:::');
      expect(sanitizedEmpty, equals('anonymous'));
    });
  });
}
