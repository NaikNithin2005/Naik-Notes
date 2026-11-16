import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/folder_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sync_operation_model.dart';
import 'package:naik_notes/data/repositories/folder_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/data/repositories/sync_queue_repository.dart';
import 'package:naik_notes/services/sync/sync_service.dart';

void main() {
  group('SyncService Tests', () {
    late AppDatabase db;
    late DriftSyncQueueRepository queueRepo;
    late DriftNotebookRepository notebookRepo;
    late DriftFolderRepository folderRepo;
    late DriftPageRepository pageRepo;
    late DriftStrokeRepository strokeRepo;
    late DriftStickyNoteRepository stickyNoteRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queueRepo = DriftSyncQueueRepository(db);
      notebookRepo = DriftNotebookRepository(db);
      folderRepo = DriftFolderRepository(db);
      pageRepo = DriftPageRepository(db);
      strokeRepo = DriftStrokeRepository(db);
      stickyNoteRepo = DriftStickyNoteRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('checkServerHealth returns true on 200 and false on error', () async {
      final healthyClient = MockClient((request) async {
        return http.Response(jsonEncode({'status': 'healthy'}), 200);
      });

      final healthyService = SyncService(
        queueRepo: queueRepo,
        notebookRepo: notebookRepo,
        folderRepo: folderRepo,
        pageRepo: pageRepo,
        strokeRepo: strokeRepo,
        stickyNoteRepo: stickyNoteRepo,
        client: healthyClient,
        baseUrl: 'http://test-server/v1',
      );

      expect(await healthyService.checkServerHealth(), isTrue);

      final failingClient = MockClient((request) async {
        return http.Response('Internal Error', 500);
      });

      final failingService = SyncService(
        queueRepo: queueRepo,
        notebookRepo: notebookRepo,
        folderRepo: folderRepo,
        pageRepo: pageRepo,
        strokeRepo: strokeRepo,
        stickyNoteRepo: stickyNoteRepo,
        client: failingClient,
        baseUrl: 'http://test-server/v1',
      );

      expect(await failingService.checkServerHealth(), isFalse);
    });

    test(
      'syncAll pushes pending operations to remote backend and updates watermark',
      () async {
        // 1. Enqueue local notebook
        final now = DateTime.now();
        final localNotebook = Notebook(
          id: 'nb-local-1',
          ownerId: 'local_user',
          title: 'Local Research Notes',
          coverId: 'dark_academia_leather',
          createdAt: now,
          updatedAt: now,
        );

        final op = SyncOperation(
          id: 'op-push-1',
          entityType: SyncEntityType.notebook,
          entityId: localNotebook.id,
          operationType: SyncOperationType.insert,
          payload: localNotebook.toJson(),
          revision: 1,
          createdAt: now,
        );

        await queueRepo.enqueue(op);
        expect(await queueRepo.getPendingCount(), equals(1));

        // Mock backend response
        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/sync/status')) {
            return http.Response(jsonEncode({'status': 'healthy'}), 200);
          }
          if (request.url.path.endsWith('/sync/push')) {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final ops = body['operations'] as List<dynamic>;
            expect(ops.length, equals(1));

            return http.Response(
              jsonEncode({
                'synced_ids': ['op-push-1'],
                'conflicts': [],
                'latest_watermark': 105,
              }),
              200,
            );
          }
          if (request.url.path.endsWith('/sync/pull')) {
            return http.Response(
              jsonEncode({'operations': [], 'latest_watermark': 105}),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final service = SyncService(
          queueRepo: queueRepo,
          notebookRepo: notebookRepo,
          folderRepo: folderRepo,
          pageRepo: pageRepo,
          strokeRepo: strokeRepo,
          stickyNoteRepo: stickyNoteRepo,
          client: mockClient,
          baseUrl: 'http://test-server/v1',
        );

        final result = await service.syncAll();
        expect(result.isSuccess, isTrue);
        expect(result.pushedCount, equals(1));
        expect(service.lastWatermark, equals(105));

        // Synced operations should be cleared from queue
        expect(await queueRepo.getPendingCount(), equals(0));
      },
    );

    test(
      'syncAll pulls remote operations and reconciles into local database',
      () async {
        final now = DateTime.now();

        // Remote entities to be pulled
        final remoteNotebook = Notebook(
          id: 'nb-remote-2',
          ownerId: 'local_user',
          title: 'Remote Cloud Architecture',
          coverId: 'minimal_sand',
          createdAt: now,
          updatedAt: now,
        );

        final remoteFolder = Folder(
          id: 'folder-remote-1',
          ownerId: 'local_user',
          name: 'Backend Architecture',
          createdAt: now,
          updatedAt: now,
        );

        final remotePage = NotebookPage(
          id: 'page-remote-1',
          notebookId: 'nb-remote-2',
          pageNumber: 1,
          templateId: 'square_grid',
          properties: PaperProperties.defaultFor(PaperTemplateType.squareGrid),
          createdAt: now,
          updatedAt: now,
        );

        final mockClient = MockClient((request) async {
          if (request.url.path.endsWith('/sync/status')) {
            return http.Response(jsonEncode({'status': 'healthy'}), 200);
          }
          if (request.url.path.endsWith('/sync/pull')) {
            return http.Response(
              jsonEncode({
                'operations': [
                  {
                    'entity_type': 'folder',
                    'entity_id': 'folder-remote-1',
                    'operation_type': 'insert',
                    'payload': remoteFolder.toJson(),
                  },
                  {
                    'entity_type': 'notebook',
                    'entity_id': 'nb-remote-2',
                    'operation_type': 'insert',
                    'payload': remoteNotebook.toJson(),
                  },
                  {
                    'entity_type': 'page',
                    'entity_id': 'page-remote-1',
                    'operation_type': 'insert',
                    'payload': remotePage.toJson(),
                  },
                ],
                'latest_watermark': 120,
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        });

        final service = SyncService(
          queueRepo: queueRepo,
          notebookRepo: notebookRepo,
          folderRepo: folderRepo,
          pageRepo: pageRepo,
          strokeRepo: strokeRepo,
          stickyNoteRepo: stickyNoteRepo,
          client: mockClient,
          baseUrl: 'http://test-server/v1',
        );

        final result = await service.syncAll();
        expect(result.isSuccess, isTrue);
        expect(result.pulledCount, equals(3));
        expect(service.lastWatermark, equals(120));

        // Verify records are inserted in local Drift SQLite!
        final savedNotebook = await notebookRepo.getNotebookById('nb-remote-2');
        expect(savedNotebook, isNotNull);
        expect(savedNotebook!.title, equals('Remote Cloud Architecture'));

        final savedFolder = await folderRepo.getFolderById('folder-remote-1');
        expect(savedFolder, isNotNull);
        expect(savedFolder!.name, equals('Backend Architecture'));

        final savedPage = await pageRepo.getPageById('page-remote-1');
        expect(savedPage, isNotNull);
        expect(savedPage!.templateId, equals('square_grid'));
      },
    );
  });
}
