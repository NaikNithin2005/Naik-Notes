import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/sync_operation_model.dart';

abstract class SyncQueueRepository {
  Future<void> enqueue(SyncOperation operation);
  Future<List<SyncOperation>> getPendingOperations({int limit = 50});
  Future<int> getPendingCount();
  Stream<int> watchPendingCount();
  Future<void> markAsSyncing(List<String> ids);
  Future<void> markAsSynced(List<String> ids);
  Future<void> markAsFailed(String id, String error);
  Future<void> clearSynced();
  Future<void> clearAll();
}

class DriftSyncQueueRepository implements SyncQueueRepository {
  final AppDatabase _db;

  DriftSyncQueueRepository(this._db);

  @override
  Future<void> enqueue(SyncOperation operation) async {
    await _db
        .into(_db.syncQueueTable)
        .insertOnConflictUpdate(
          SyncQueueTableCompanion(
            id: Value(operation.id),
            entityType: Value(operation.entityType.value),
            entityId: Value(operation.entityId),
            operationType: Value(operation.operationType.value),
            payloadJson: Value(jsonEncode(operation.payload)),
            revision: Value(operation.revision),
            createdAt: Value(operation.createdAt),
            status: Value(operation.status.value),
            retryCount: Value(operation.retryCount),
            lastError: Value(operation.lastError),
          ),
        );
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({int limit = 50}) async {
    final query = _db.select(_db.syncQueueTable)
      ..where(
        (tbl) => tbl.status.equals('pending') | tbl.status.equals('failed'),
      )
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_rowToOperation).toList();
  }

  @override
  Future<int> getPendingCount() async {
    final countExp = _db.syncQueueTable.id.count();
    final query = _db.selectOnly(_db.syncQueueTable)
      ..addColumns([countExp])
      ..where(
        _db.syncQueueTable.status.equals('pending') |
            _db.syncQueueTable.status.equals('failed'),
      );

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  @override
  Stream<int> watchPendingCount() {
    final countExp = _db.syncQueueTable.id.count();
    final query = _db.selectOnly(_db.syncQueueTable)
      ..addColumns([countExp])
      ..where(
        _db.syncQueueTable.status.equals('pending') |
            _db.syncQueueTable.status.equals('failed'),
      );

    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  @override
  Future<void> markAsSyncing(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.syncQueueTable)..where((tbl) => tbl.id.isIn(ids)))
        .write(const SyncQueueTableCompanion(status: Value('syncing')));
  }

  @override
  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.syncQueueTable)..where((tbl) => tbl.id.isIn(ids)))
        .write(const SyncQueueTableCompanion(status: Value('synced')));
  }

  @override
  Future<void> markAsFailed(String id, String error) async {
    final existing = await (_db.select(
      _db.syncQueueTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    final currentRetries = existing?.retryCount ?? 0;

    await (_db.update(
      _db.syncQueueTable,
    )..where((tbl) => tbl.id.equals(id))).write(
      SyncQueueTableCompanion(
        status: const Value('failed'),
        retryCount: Value(currentRetries + 1),
        lastError: Value(error),
      ),
    );
  }

  @override
  Future<void> clearSynced() async {
    await (_db.delete(
      _db.syncQueueTable,
    )..where((tbl) => tbl.status.equals('synced'))).go();
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.syncQueueTable).go();
  }

  SyncOperation _rowToOperation(SyncQueueTableData row) {
    Map<String, dynamic> payloadMap = {};
    try {
      payloadMap = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    } catch (_) {
      payloadMap = {};
    }

    return SyncOperation(
      id: row.id,
      entityType: SyncEntityType.fromValue(row.entityType),
      entityId: row.entityId,
      operationType: SyncOperationType.fromValue(row.operationType),
      payload: payloadMap,
      revision: row.revision,
      createdAt: row.createdAt,
      status: SyncQueueStatus.fromValue(row.status),
      retryCount: row.retryCount,
      lastError: row.lastError,
    );
  }
}
