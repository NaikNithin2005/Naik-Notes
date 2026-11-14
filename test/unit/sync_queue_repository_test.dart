import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/sync_operation_model.dart';
import 'package:naik_notes/data/repositories/sync_queue_repository.dart';

void main() {
  group('DriftSyncQueueRepository Tests', () {
    late AppDatabase db;
    late DriftSyncQueueRepository queueRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queueRepo = DriftSyncQueueRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'enqueue operations and fetch pending operations in FIFO order',
      () async {
        final now = DateTime.now();

        final op1 = SyncOperation(
          id: 'op-1',
          entityType: SyncEntityType.notebook,
          entityId: 'nb-101',
          operationType: SyncOperationType.insert,
          payload: {'title': 'Math Notebook'},
          revision: 1,
          createdAt: now.subtract(const Duration(minutes: 5)),
        );

        final op2 = SyncOperation(
          id: 'op-2',
          entityType: SyncEntityType.stroke,
          entityId: 'stroke-202',
          operationType: SyncOperationType.insert,
          payload: {'color': 4278190080},
          revision: 1,
          createdAt: now.subtract(const Duration(minutes: 2)),
        );

        await queueRepo.enqueue(op1);
        await queueRepo.enqueue(op2);

        final count = await queueRepo.getPendingCount();
        expect(count, equals(2));

        final pending = await queueRepo.getPendingOperations();
        expect(pending.length, equals(2));
        expect(pending[0].id, equals('op-1'));
        expect(pending[1].id, equals('op-2'));
        expect(pending[0].entityType, equals(SyncEntityType.notebook));
        expect(pending[0].payload['title'], equals('Math Notebook'));
      },
    );

    test(
      'markAsSyncing and markAsSynced transitions status correctly',
      () async {
        final op = SyncOperation(
          id: 'op-transition',
          entityType: SyncEntityType.folder,
          entityId: 'folder-1',
          operationType: SyncOperationType.insert,
          payload: {'name': 'College'},
          revision: 1,
          createdAt: DateTime.now(),
        );

        await queueRepo.enqueue(op);

        // Transition to syncing
        await queueRepo.markAsSyncing(['op-transition']);
        var pending = await queueRepo.getPendingOperations();
        // 'syncing' status is excluded from pending queue query (only 'pending' and 'failed')
        expect(pending.isEmpty, isTrue);

        // Transition to synced
        await queueRepo.markAsSynced(['op-transition']);
        expect(await queueRepo.getPendingCount(), equals(0));

        // Clear synced
        await queueRepo.clearSynced();
        final allRows = await db.select(db.syncQueueTable).get();
        expect(allRows.isEmpty, isTrue);
      },
    );

    test('markAsFailed increments retryCount and records lastError', () async {
      final op = SyncOperation(
        id: 'op-fail-test',
        entityType: SyncEntityType.stickyNote,
        entityId: 'note-1',
        operationType: SyncOperationType.update,
        payload: {'content': 'Exam at 9am'},
        revision: 2,
        createdAt: DateTime.now(),
      );

      await queueRepo.enqueue(op);

      await queueRepo.markAsFailed('op-fail-test', 'Network timeout 504');

      final pending = await queueRepo.getPendingOperations();
      expect(pending.length, equals(1));
      expect(pending.first.status, equals(SyncQueueStatus.failed));
      expect(pending.first.retryCount, equals(1));
      expect(pending.first.lastError, contains('504'));

      // Fail again
      await queueRepo.markAsFailed('op-fail-test', 'Connection refused');
      final updated = await queueRepo.getPendingOperations();
      expect(updated.first.retryCount, equals(2));
      expect(updated.first.lastError, equals('Connection refused'));
    });

    test('watchPendingCount emits updates reactively', () async {
      final stream = queueRepo.watchPendingCount();
      expectLater(stream, emitsInOrder([0, 1, 2]));

      await Future.delayed(const Duration(milliseconds: 10));

      await queueRepo.enqueue(
        SyncOperation(
          id: 'op-stream-1',
          entityType: SyncEntityType.notebook,
          entityId: 'nb-stream-1',
          operationType: SyncOperationType.insert,
          payload: {},
          revision: 1,
          createdAt: DateTime.now(),
        ),
      );

      await queueRepo.enqueue(
        SyncOperation(
          id: 'op-stream-2',
          entityType: SyncEntityType.notebook,
          entityId: 'nb-stream-2',
          operationType: SyncOperationType.insert,
          payload: {},
          revision: 1,
          createdAt: DateTime.now(),
        ),
      );
    });
  });
}
