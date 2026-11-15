import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../data/models/folder_model.dart';
import '../../data/models/notebook_model.dart';
import '../../data/models/page_model.dart';
import '../../data/models/sticky_note_model.dart';
import '../../data/models/stroke_model.dart';
import '../../data/models/sync_operation_model.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../data/repositories/page_repository.dart';
import '../../data/repositories/sticky_note_repository.dart';
import '../../data/repositories/stroke_repository.dart';
import '../../data/repositories/sync_queue_repository.dart';

/// Result summary of a push/pull synchronization pass.
class SyncResult {
  final bool isSuccess;
  final int pushedCount;
  final int pulledCount;
  final int conflictCount;
  final String? errorMessage;
  final DateTime timestamp;

  const SyncResult({
    required this.isSuccess,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.conflictCount = 0,
    this.errorMessage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SyncResult(isSuccess: $isSuccess, pushed: $pushedCount, pulled: $pulledCount, conflicts: $conflictCount, error: $errorMessage)';
  }
}

/// Core offline-first sync coordinator. Orchestrates delta pushes, pulls,
/// and local SQLite reconciliation with the FastAPI backend.
class SyncService {
  final SyncQueueRepository queueRepo;
  final NotebookRepository notebookRepo;
  final FolderRepository folderRepo;
  final PageRepository pageRepo;
  final StrokeRepository strokeRepo;
  final StickyNoteRepository stickyNoteRepo;
  final http.Client _client;
  final String _baseUrl;
  final Uuid _uuid = const Uuid();

  int lastWatermark;

  SyncService({
    required this.queueRepo,
    required this.notebookRepo,
    required this.folderRepo,
    required this.pageRepo,
    required this.strokeRepo,
    required this.stickyNoteRepo,
    http.Client? client,
    String? baseUrl,
    this.lastWatermark = 0,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.devApiBaseUrl;

  /// Verifies connectivity with the remote backend.
  Future<bool> checkServerHealth() async {
    try {
      final res = await _client
          .get(Uri.parse('$_baseUrl/sync/status'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Executes a full synchronization cycle: push pending local changes,
  /// then pull remote updates and apply them locally.
  Future<SyncResult> syncAll({String ownerId = 'local_user'}) async {
    final now = DateTime.now();

    final isHealthy = await checkServerHealth();
    if (!isHealthy) {
      return SyncResult(
        isSuccess: false,
        errorMessage: 'Backend service offline or unreachable',
        timestamp: now,
      );
    }

    int pushedCount = 0;
    int conflictCount = 0;
    int pulledCount = 0;

    // --- STEP 1: PUSH LOCAL CHANGES ---
    try {
      final pending = await queueRepo.getPendingOperations(limit: 100);
      if (pending.isNotEmpty) {
        final pendingIds = pending.map((e) => e.id).toList();
        await queueRepo.markAsSyncing(pendingIds);

        final pushPayload = {
          'client_id': 'naik_flutter_client',
          'owner_id': ownerId,
          'operations': pending.map((e) => e.toJson()).toList(),
        };

        final pushRes = await _client.post(
          Uri.parse('$_baseUrl/sync/push'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(pushPayload),
        );

        if (pushRes.statusCode == 200) {
          final data = jsonDecode(pushRes.body) as Map<String, dynamic>;
          final syncedIds =
              (data['synced_ids'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          final conflicts = (data['conflicts'] as List<dynamic>?) ?? [];
          final newWatermark =
              data['latest_watermark'] as int? ?? lastWatermark;

          await queueRepo.markAsSynced(syncedIds);
          pushedCount = syncedIds.length;
          conflictCount = conflicts.length;
          if (newWatermark > lastWatermark) {
            lastWatermark = newWatermark;
          }
        } else {
          for (final op in pending) {
            await queueRepo.markAsFailed(
              op.id,
              'Push HTTP ${pushRes.statusCode}: ${pushRes.body}',
            );
          }
          return SyncResult(
            isSuccess: false,
            errorMessage: 'Push failed with HTTP ${pushRes.statusCode}',
            timestamp: now,
          );
        }
      }
    } catch (e) {
      return SyncResult(
        isSuccess: false,
        errorMessage: 'Push exception: $e',
        timestamp: now,
      );
    }

    // --- STEP 2: PULL REMOTE CHANGES ---
    try {
      final pullUrl = Uri.parse(
        '$_baseUrl/sync/pull?since_revision=$lastWatermark&owner_id=$ownerId',
      );
      final pullRes = await _client.get(pullUrl);

      if (pullRes.statusCode == 200) {
        final data = jsonDecode(pullRes.body) as Map<String, dynamic>;
        final ops = (data['operations'] as List<dynamic>?) ?? [];
        final watermark = data['latest_watermark'] as int? ?? lastWatermark;

        for (final rawOp in ops) {
          final opMap = rawOp as Map<String, dynamic>;
          final entityType = opMap['entity_type'] as String;
          final entityId = opMap['entity_id'] as String;
          final opType = (opMap['operation_type'] as String).toLowerCase();
          final payload = opMap['payload'] is Map<String, dynamic>
              ? opMap['payload'] as Map<String, dynamic>
              : jsonDecode(opMap['payload'] as String);

          await _applyRemoteOperation(
            entityType: entityType,
            entityId: entityId,
            operationType: opType,
            payload: payload as Map<String, dynamic>,
          );
          pulledCount++;
        }

        if (watermark > lastWatermark) {
          lastWatermark = watermark;
        }
      } else {
        return SyncResult(
          isSuccess: false,
          pushedCount: pushedCount,
          conflictCount: conflictCount,
          errorMessage: 'Pull failed with HTTP ${pullRes.statusCode}',
          timestamp: now,
        );
      }
    } catch (e) {
      return SyncResult(
        isSuccess: false,
        pushedCount: pushedCount,
        conflictCount: conflictCount,
        errorMessage: 'Pull exception: $e',
        timestamp: now,
      );
    }

    // Clean up synced operations in queue
    await queueRepo.clearSynced();

    return SyncResult(
      isSuccess: true,
      pushedCount: pushedCount,
      pulledCount: pulledCount,
      conflictCount: conflictCount,
      timestamp: now,
    );
  }

  /// Dispatches remote mutations to appropriate local Drift repository.
  Future<void> _applyRemoteOperation({
    required String entityType,
    required String entityId,
    required String operationType,
    required Map<String, dynamic> payload,
  }) async {
    switch (entityType) {
      case 'notebook':
        if (operationType == 'delete') {
          await notebookRepo.deleteNotebook(entityId);
        } else {
          try {
            final nb = Notebook.fromJson(payload);
            await notebookRepo.saveNotebook(nb);
          } catch (_) {}
        }
        break;

      case 'folder':
        if (operationType == 'delete') {
          await folderRepo.deleteFolder(entityId);
        } else {
          try {
            final folder = Folder.fromJson(payload);
            await folderRepo.saveFolder(folder);
          } catch (_) {}
        }
        break;

      case 'page':
        if (operationType == 'delete') {
          await pageRepo.deletePage(entityId);
        } else {
          try {
            final page = NotebookPage.fromJson(payload);
            await pageRepo.savePage(page);
          } catch (_) {}
        }
        break;

      case 'stroke':
        if (operationType == 'delete') {
          await strokeRepo.softDeleteStroke(entityId);
        } else {
          try {
            final stroke = Stroke.fromJson(payload);
            await strokeRepo.saveStroke(stroke);
          } catch (_) {}
        }
        break;

      case 'sticky_note':
        if (operationType == 'delete') {
          await stickyNoteRepo.deleteStickyNote(entityId);
        } else {
          try {
            final note = StickyNote.fromJson(payload);
            await stickyNoteRepo.saveStickyNote(note);
          } catch (_) {}
        }
        break;
    }
  }

  // --- LOCAL MUTATION ENQUEUE HELPERS ---

  Future<void> enqueueNotebookMutation(
    Notebook notebook,
    SyncOperationType type,
  ) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      entityType: SyncEntityType.notebook,
      entityId: notebook.id,
      operationType: type,
      payload: notebook.toJson(),
      revision: notebook.revision,
      createdAt: DateTime.now(),
    );
    await queueRepo.enqueue(op);
  }

  Future<void> enqueueFolderMutation(
    Folder folder,
    SyncOperationType type,
  ) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      entityType: SyncEntityType.folder,
      entityId: folder.id,
      operationType: type,
      payload: folder.toJson(),
      revision: 1,
      createdAt: DateTime.now(),
    );
    await queueRepo.enqueue(op);
  }

  Future<void> enqueueStrokeMutation(
    Stroke stroke,
    SyncOperationType type,
  ) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      entityType: SyncEntityType.stroke,
      entityId: stroke.id,
      operationType: type,
      payload: stroke.toJson(),
      revision: stroke.revision,
      createdAt: DateTime.now(),
    );
    await queueRepo.enqueue(op);
  }

  Future<void> enqueueStickyNoteMutation(
    StickyNote note,
    SyncOperationType type,
  ) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      entityType: SyncEntityType.stickyNote,
      entityId: note.id,
      operationType: type,
      payload: note.toJson(),
      revision: 1,
      createdAt: DateTime.now(),
    );
    await queueRepo.enqueue(op);
  }

  Future<void> enqueuePageMutation(
    NotebookPage page,
    SyncOperationType type,
  ) async {
    final op = SyncOperation(
      id: _uuid.v4(),
      entityType: SyncEntityType.page,
      entityId: page.id,
      operationType: type,
      payload: page.toJson(),
      revision: page.revision,
      createdAt: DateTime.now(),
    );
    await queueRepo.enqueue(op);
  }
}
