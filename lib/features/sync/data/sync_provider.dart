import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/notebook_model.dart';
import '../../../data/models/page_model.dart';
import '../../../data/models/sticky_note_model.dart';
import '../../../data/models/stroke_model.dart';
import '../../../data/models/sync_operation_model.dart';
import '../../../services/storage/firebase_storage_service.dart';
import '../../../services/sync/firebase_sync_service.dart';
import '../../../services/sync/sync_service.dart';
import '../../authentication/data/auth_provider.dart';
import '../../notebooks/data/notebook_provider.dart';

enum SyncUiStatus { synced, syncing, offline, error, pending }

class SyncState {
  final SyncUiStatus status;
  final DateTime? lastSyncedAt;
  final int pendingCount;
  final String? lastError;
  final bool autoSyncEnabled;
  final int lastPushed;
  final int lastPulled;
  final int lastConflicts;

  const SyncState({
    this.status = SyncUiStatus.synced,
    this.lastSyncedAt,
    this.pendingCount = 0,
    this.lastError,
    this.autoSyncEnabled = true,
    this.lastPushed = 0,
    this.lastPulled = 0,
    this.lastConflicts = 0,
  });

  SyncState copyWith({
    SyncUiStatus? status,
    DateTime? lastSyncedAt,
    int? pendingCount,
    String? lastError,
    bool? autoSyncEnabled,
    int? lastPushed,
    int? lastPulled,
    int? lastConflicts,
    bool clearError = false,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      pendingCount: pendingCount ?? this.pendingCount,
      lastError: clearError ? null : (lastError ?? this.lastError),
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
      lastPushed: lastPushed ?? this.lastPushed,
      lastPulled: lastPulled ?? this.lastPulled,
      lastConflicts: lastConflicts ?? this.lastConflicts,
    );
  }
}

/// Global provider for [FirebaseSyncService].
final firebaseSyncServiceProvider = Provider<FirebaseSyncService>((ref) {
  final service = FirebaseSyncService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Global provider for [FirebaseStorageService].
final firebaseStorageServiceProvider = Provider<FirebaseStorageService>((ref) {
  return FirebaseStorageService();
});

/// Global provider for [SyncService].
final syncServiceProvider = Provider<SyncService>((ref) {
  final queueRepo = ref.watch(syncQueueRepositoryProvider);
  final notebookRepo = ref.watch(notebookRepositoryProvider);
  final folderRepo = ref.watch(folderRepositoryProvider);
  final pageRepo = ref.watch(pageRepositoryProvider);
  final strokeRepo = ref.watch(strokeRepositoryProvider);
  final stickyNoteRepo = ref.watch(stickyNoteRepositoryProvider);

  return SyncService(
    queueRepo: queueRepo,
    notebookRepo: notebookRepo,
    folderRepo: folderRepo,
    pageRepo: pageRepo,
    strokeRepo: strokeRepo,
    stickyNoteRepo: stickyNoteRepo,
  );
});

/// Riverpod notifier managing synchronization state, triggers, auto-sync,
/// and live Firestore stream subscription.
class SyncNotifier extends Notifier<SyncState> {
  Timer? _autoSyncTimer;
  String? _listeningUid;

  @override
  SyncState build() {
    final fbSync = ref.read(firebaseSyncServiceProvider);
    ref.onDispose(() {
      _autoSyncTimer?.cancel();
      fbSync.dispose();
    });

    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user != null && user.id != _listeningUid) {
      _listeningUid = user.id;
      _setupRealTimeSync(user.id);
    } else if (user == null) {
      _listeningUid = null;
      fbSync.dispose();
    }

    _startPeriodicSync();

    return const SyncState();
  }

  void _setupRealTimeSync(String uid) {
    final fbSync = ref.read(firebaseSyncServiceProvider);
    fbSync.listenToNotebooks(uid, (remoteNotebooks) async {
      if (!ref.mounted) return;
      try {
        final notebookRepo = ref.read(notebookRepositoryProvider);
        bool hasChanges = false;

        for (final rNb in remoteNotebooks) {
          if (rNb.deletedAt != null) {
            await notebookRepo.deleteNotebook(rNb.id);
            hasChanges = true;
          } else {
            final local = await notebookRepo.getNotebookById(rNb.id, ownerId: uid);
            if (local == null || rNb.revision >= local.revision) {
              await notebookRepo.saveNotebook(rNb);
              hasChanges = true;
            }
          }
        }

        if (hasChanges && ref.mounted) {
          await ref.read(notebooksProvider.notifier).loadFromDatabase();
          state = state.copyWith(
            lastSyncedAt: DateTime.now(),
            status: SyncUiStatus.synced,
            clearError: true,
          );
        }
      } catch (e) {
        debugPrint('[SyncNotifier] Real-time merge error: $e');
      }
    });
  }

  void _startPeriodicSync() {
    _autoSyncTimer?.cancel();
    if (!AppConfig.enablePeriodicSync) return;
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (state.autoSyncEnabled && state.status != SyncUiStatus.syncing) {
        syncNow();
      }
    });
  }

  void toggleAutoSync(bool enabled) {
    state = state.copyWith(autoSyncEnabled: enabled);
    if (enabled) {
      if (AppConfig.enablePeriodicSync) {
        _startPeriodicSync();
      }
    } else {
      _autoSyncTimer?.cancel();
    }
  }

  Future<void> updatePendingCount() async {
    try {
      final queueRepo = ref.read(syncQueueRepositoryProvider);
      final count = await queueRepo.getPendingCount();
      state = state.copyWith(pendingCount: count);
    } catch (_) {}
  }

  Future<SyncResult> syncNow({String ownerId = 'local_user'}) async {
    if (state.status == SyncUiStatus.syncing) {
      return SyncResult(
        isSuccess: false,
        errorMessage: 'Sync already in progress',
        timestamp: DateTime.now(),
      );
    }

    state = state.copyWith(status: SyncUiStatus.syncing, clearError: true);

    final authState = ref.read(authProvider);
    final isAuth = authState.isAuthenticated;
    final uid = isAuth ? authState.user!.id : ownerId;

    try {
      if (isAuth) {
        final fbSync = ref.read(firebaseSyncServiceProvider);
        final notebookRepo = ref.read(notebookRepositoryProvider);
        final folderRepo = ref.read(folderRepositoryProvider);
        final queueRepo = ref.read(syncQueueRepositoryProvider);

        int pushedCount = 0;

        // 1. Process local offline queue
        final pendingOps = await queueRepo.getPendingOperations(limit: 50);
        for (final op in pendingOps) {
          if (op.ownerId != uid && op.ownerId != 'local_user') continue;

          bool success = false;
          try {
            switch (op.entityType) {
              case SyncEntityType.notebook:
                if (op.operationType == SyncOperationType.delete) {
                  success = await fbSync.deleteNotebook(uid, op.entityId);
                } else {
                  final nb = Notebook.fromJson(op.payload);
                  success = await fbSync.pushNotebook(uid, nb);
                }
                break;
              case SyncEntityType.folder:
                if (op.operationType == SyncOperationType.delete) {
                  success = await fbSync.deleteFolder(uid, op.entityId);
                } else {
                  final folder = Folder.fromJson(op.payload);
                  success = await fbSync.pushFolder(uid, folder);
                }
                break;
              case SyncEntityType.page:
                final notebookId = op.parentId ?? op.payload['notebookId'] as String?;
                if (notebookId != null) {
                  if (op.operationType == SyncOperationType.delete) {
                    success = await fbSync.deletePage(uid, notebookId, op.entityId);
                  } else {
                    final page = NotebookPage.fromJson(op.payload);
                    success = await fbSync.pushPage(uid, notebookId, page);
                  }
                }
                break;
              case SyncEntityType.stroke:
                final notebookId = op.payload['notebookId'] as String?;
                final pageId = op.parentId ?? op.payload['pageId'] as String?;
                if (notebookId != null && pageId != null) {
                  final stroke = Stroke.fromJson(op.payload);
                  await fbSync.pushStrokes(uid, notebookId, pageId, [stroke]);
                  success = true;
                }
                break;
              case SyncEntityType.stickyNote:
                final notebookId = op.payload['notebookId'] as String?;
                final pageId = op.parentId ?? op.payload['pageId'] as String?;
                if (notebookId != null && pageId != null) {
                  if (op.operationType == SyncOperationType.delete) {
                    success = await fbSync.deleteStickyNote(uid, notebookId, pageId, op.entityId);
                  } else {
                    final note = StickyNote.fromJson(op.payload);
                    success = await fbSync.pushStickyNote(uid, notebookId, pageId, note);
                  }
                }
                break;
            }
          } catch (e) {
            await queueRepo.markAsFailed(op.id, e.toString());
          }

          if (success) {
            await queueRepo.markAsSynced([op.id]);
            pushedCount++;
          }
        }

        // 2. Push user's local notebooks to Firestore
        final localNotebooks = await notebookRepo.getAllNotebooks(
          ownerId: uid,
          includeArchived: true,
        );
        for (final nb in localNotebooks) {
          await fbSync.pushNotebook(uid, nb);
        }

        // 3. Pull remote notebooks from Firestore
        final remoteNotebooks = await fbSync.fetchNotebooks(uid);
        for (final rNb in remoteNotebooks) {
          if (rNb.deletedAt != null) {
            await notebookRepo.deleteNotebook(rNb.id);
          } else {
            final local = await notebookRepo.getNotebookById(rNb.id, ownerId: uid);
            if (local == null || rNb.revision >= local.revision) {
              await notebookRepo.saveNotebook(rNb);
            }
          }
        }

        // 4. Pull remote folders from Firestore
        final remoteFolders = await fbSync.fetchFolders(uid);
        for (final rFolder in remoteFolders) {
          if (rFolder.deletedAt != null) {
            await folderRepo.deleteFolder(rFolder.id);
          } else {
            await folderRepo.saveFolder(rFolder);
          }
        }

        // 5. Refresh UI state
        await ref.read(notebooksProvider.notifier).loadFromDatabase();
        final pendingRemaining = await queueRepo.getPendingCount();

        final now = DateTime.now();
        state = state.copyWith(
          status: SyncUiStatus.synced,
          lastSyncedAt: now,
          pendingCount: pendingRemaining,
          lastPushed: pushedCount + localNotebooks.length,
          lastPulled: remoteNotebooks.length,
          clearError: true,
        );

        return SyncResult(
          isSuccess: true,
          pushedCount: pushedCount + localNotebooks.length,
          pulledCount: remoteNotebooks.length,
          timestamp: now,
        );
      } else {
        final now = DateTime.now();
        state = state.copyWith(
          status: SyncUiStatus.synced,
          lastSyncedAt: now,
          pendingCount: 0,
          clearError: true,
        );
        return SyncResult(isSuccess: true, timestamp: now);
      }
    } catch (e) {
      state = state.copyWith(
        status: SyncUiStatus.offline,
        lastError: e.toString(),
      );
      return SyncResult(
        isSuccess: false,
        errorMessage: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
