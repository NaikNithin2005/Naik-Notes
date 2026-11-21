import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/notebook_model.dart';
import '../../../data/models/page_model.dart';
import '../../../data/models/sticky_note_model.dart';
import '../../../data/models/stroke_model.dart';
import '../../../data/models/sync_operation_model.dart';
import '../../../services/storage/firebase_storage_service.dart';
import '../../../services/history/note_history_service.dart';
import '../../../services/sync/firebase_sync_service.dart';
import '../../../services/sync/sync_service.dart';
import '../../authentication/data/auth_provider.dart';
import '../../notebooks/data/notebook_provider.dart';

enum SyncUiStatus { synced, saving, syncing, offline, error, pending, conflict }

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

  String _extractCleanTitle(String title) {
    final copyPattern = RegExp(
      r'\s*\((?:Cloud Copy|Conflict Copy|Copy)(?:\s+\d+)?\)$',
      caseSensitive: false,
    );
    String clean = title.trim();
    while (copyPattern.hasMatch(clean)) {
      clean = clean.replaceAll(copyPattern, '').trim();
    }
    return clean.isEmpty ? 'Untitled Notebook' : clean;
  }

  void _setupRealTimeSync(String uid) {
    final fbSync = ref.read(firebaseSyncServiceProvider);
    fbSync.listenToNotebooks(uid, (remoteNotebooks) async {
      if (!ref.mounted) return;
      try {
        final notebookRepo = ref.read(notebookRepositoryProvider);
        bool hasChanges = false;

        for (final rNb in remoteNotebooks) {
          // 1. Tombstone check: if permanently deleted, purge from cloud too!
          if (await notebookRepo.isTombstoned(rNb.id)) {
            await fbSync.permanentlyDeleteNotebook(uid, rNb.id);
            continue;
          }

          // 2. Duplicate safeguard: prevent resurrecting redundant (Cloud Copy) duplicates
          final cleanTitle = _extractCleanTitle(rNb.title);
          final cleanBaseLower = cleanTitle.toLowerCase();
          final isCopy = rNb.title != cleanTitle;

          final allLocal = await notebookRepo.getAllNotebooks(
            ownerId: uid,
            includeArchived: true,
          );
          final hasCanonical = allLocal.any(
            (n) =>
                n.id != rNb.id &&
                _extractCleanTitle(n.title).toLowerCase() == cleanBaseLower &&
                n.deletedAt == null,
          );

          if (isCopy && hasCanonical) {
            // A canonical notebook already exists locally; purge redundant remote copy
            await notebookRepo.permanentlyDeleteNotebook(rNb.id, ownerId: uid);
            await fbSync.permanentlyDeleteNotebook(uid, rNb.id);
            continue;
          }

          final targetNb = isCopy ? rNb.copyWith(title: cleanTitle) : rNb;
          final local = await notebookRepo.getAnyNotebookById(rNb.id, ownerId: uid);

          if (targetNb.deletedAt != null) {
            // Remote is soft-deleted
            if (local != null && local.deletedAt == null) {
              await notebookRepo.deleteNotebook(targetNb.id, deletionId: targetNb.deletionId);
              hasChanges = true;
            }
          } else {
            // Remote is active
            if (local != null && local.deletedAt != null) {
              // Local is in Trash! Only restore if remote was explicitly edited/restored after deletion
              if (targetNb.updatedAt.isAfter(local.deletedAt!) && targetNb.revision > local.revision) {
                await notebookRepo.restoreNotebook(targetNb.id);
                hasChanges = true;
              } else {
                // Re-propagate local deletion to cloud
                await fbSync.deleteNotebook(uid, local.id, deletionId: local.deletionId);
              }
            } else if (local == null) {
              // Truly new notebook from another device
              await notebookRepo.saveNotebook(targetNb);
              if (isCopy) {
                await fbSync.pushNotebook(uid, targetNb);
              }
              hasChanges = true;
            } else if (targetNb.revision > local.revision ||
                (targetNb.revision == local.revision && targetNb.updatedAt.isAfter(local.updatedAt))) {
              await notebookRepo.saveNotebook(targetNb);
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

        // 0. Tombstone & Retention Sync
        final remoteTombstones = await fbSync.fetchTombstones(uid);
        for (final t in remoteTombstones) {
          await notebookRepo.saveTombstone(t);
        }
        final localTombstones = await notebookRepo.getAllTombstones(ownerId: uid);
        if (localTombstones.isNotEmpty) {
          await fbSync.pushTombstonesBatch(uid, localTombstones);
        }
        await notebookRepo.cleanupExpiredTrash(retentionDays: 30, ownerId: uid);
        final noteRepo = ref.read(noteRepositoryProvider);
        await noteRepo.cleanupExpiredTrash(retentionDays: 30, ownerId: uid);

        // 2. Push user's pending local notebooks to Firestore in batch
        final localNotebooks = await notebookRepo.getAllNotebooks(
          ownerId: uid,
          includeArchived: true,
        );
        final localDeletedNotebooks = await notebookRepo.getDeletedNotebooks(ownerId: uid);
        final pendingNotebooks = [...localNotebooks, ...localDeletedNotebooks]
            .where((nb) => nb.syncStatus == 'pending')
            .toList();
        if (pendingNotebooks.isNotEmpty) {
          await fbSync.pushNotebooksBatch(uid, pendingNotebooks);
        }

        // 3. Pull remote notebooks from Firestore with deterministic conflict resolution & copy prevention
        final remoteNotebooks = await fbSync.fetchNotebooks(uid);
        for (final rNb in remoteNotebooks) {
          if (await notebookRepo.isTombstoned(rNb.id)) {
            await fbSync.permanentlyDeleteNotebook(uid, rNb.id);
            continue;
          }

          final cleanTitle = _extractCleanTitle(rNb.title);
          final cleanBaseLower = cleanTitle.toLowerCase();
          final isCopy = rNb.title != cleanTitle;

          final allLocal = await notebookRepo.getAllNotebooks(
            ownerId: uid,
            includeArchived: true,
          );
          final hasCanonical = allLocal.any(
            (n) =>
                n.id != rNb.id &&
                _extractCleanTitle(n.title).toLowerCase() == cleanBaseLower &&
                n.deletedAt == null,
          );

          if (isCopy && hasCanonical) {
            // Redundant copy: permanently delete from cloud and tombstone locally
            await notebookRepo.permanentlyDeleteNotebook(rNb.id, ownerId: uid);
            await fbSync.permanentlyDeleteNotebook(uid, rNb.id);
            continue;
          }

          final targetNb = isCopy ? rNb.copyWith(title: cleanTitle) : rNb;
          final local = await notebookRepo.getAnyNotebookById(rNb.id, ownerId: uid);
          if (targetNb.deletedAt != null) {
            if (local != null && local.deletedAt == null) {
              await notebookRepo.deleteNotebook(targetNb.id, deletionId: targetNb.deletionId);
            }
          } else {
            if (local != null && local.deletedAt != null) {
              if (targetNb.updatedAt.isAfter(local.deletedAt!) && targetNb.revision > local.revision) {
                await notebookRepo.restoreNotebook(targetNb.id);
              } else {
                await fbSync.deleteNotebook(uid, local.id, deletionId: local.deletionId);
              }
            } else if (local == null) {
              await notebookRepo.saveNotebook(targetNb);
              if (isCopy) {
                await fbSync.pushNotebook(uid, targetNb);
              }
            } else if (targetNb.revision > local.revision ||
                (targetNb.revision == local.revision && targetNb.updatedAt.isAfter(local.updatedAt))) {
              await notebookRepo.saveNotebook(targetNb);
            }
          }
        }

        // 3b. Push & pull rich-text notes with Multi-Device Collision Detection
        int noteConflicts = 0;
        final localNotes = await noteRepo.getAllNotes(
          ownerId: uid,
          includeArchived: true,
          includeDeleted: true,
        );
        final remoteNotes = await fbSync.fetchNotes(uid);
        final remoteNotesById = {for (final r in remoteNotes) r.id: r};

        for (final rNote in remoteNotes) {
          if (await notebookRepo.isTombstoned(rNote.id)) {
            await fbSync.permanentlyDeleteNote(uid, rNote.id);
            continue;
          }
          final localNote = await noteRepo.getNoteById(rNote.id, ownerId: uid);
          if (rNote.deletedAt != null || rNote.isDeleted) {
            if (localNote != null && !localNote.isDeleted) {
              await noteRepo.deleteNote(rNote.id, deletionId: rNote.deletionId);
            }
          } else {
            if (localNote != null && localNote.isDeleted) {
              if (rNote.updatedAt.isAfter(localNote.deletedAt ?? localNote.updatedAt)) {
                await noteRepo.restoreNote(rNote.id);
              } else {
                await fbSync.deleteNote(uid, localNote.id);
              }
            } else if (localNote == null) {
              await noteRepo.saveNote(rNote);
            } else {
              // Both local and remote active versions exist: detect collisions
              final isLocalModified = localNote.syncStatus == 'pending';
              final isRemoteNewer = rNote.serverVersion > localNote.serverVersion ||
                  (rNote.serverVersion == localNote.serverVersion &&
                      rNote.updatedAt.isAfter(localNote.updatedAt));
              final hasContentDiverged =
                  localNote.contentDelta != rNote.contentDelta ||
                  localNote.title != rNote.title;

              if (isLocalModified && isRemoteNewer && hasContentDiverged) {
                // COLLISION DETECTED!
                // Preserve local offline work as a Conflict Copy (never overwrite)
                final platform = NoteHistoryService.currentDeviceName.split(' ').first;
                final conflictTitle = '${localNote.title} (Conflict Copy - $platform)';

                // Prevent infinite conflict copy duplication on sync retries
                final existingInNotebook = await noteRepo.getAllNotes(
                  ownerId: uid,
                  notebookId: localNote.notebookId,
                );
                final alreadyExists = existingInNotebook.any(
                  (n) => n.title == conflictTitle && n.contentDelta == localNote.contentDelta,
                );

                if (!alreadyExists) {
                  final conflictNote = localNote.copyWith(
                    id: const Uuid().v4(),
                    title: conflictTitle,
                    localVersion: 1,
                    serverVersion: 1,
                    syncStatus: 'pending',
                    updatedAt: DateTime.now(),
                  );
                  await noteRepo.saveNote(conflictNote);
                  await fbSync.pushNote(uid, conflictNote);
                  noteConflicts++;
                }

                // Accept authoritative remote note as canonical
                await noteRepo.saveNote(rNote.copyWith(
                  syncStatus: 'synced',
                  localVersion: rNote.serverVersion,
                ));
              } else if (isRemoteNewer) {
                // Remote is simply newer with no local pending conflict
                await noteRepo.saveNote(rNote.copyWith(
                  syncStatus: 'synced',
                  localVersion: rNote.serverVersion,
                ));
              } else if (isLocalModified) {
                // Local is newer: push to Firestore with incremented revision
                final pushedNote = localNote.copyWith(
                  serverVersion: localNote.localVersion,
                  syncStatus: 'synced',
                  lastSyncedAt: DateTime.now(),
                );
                final ok = await fbSync.pushNote(uid, pushedNote);
                if (ok) {
                  await noteRepo.saveNote(pushedNote);
                }
              }
            }
          }
        }

        // Push any brand-new local notes that do not exist remotely yet
        for (final localNote in localNotes) {
          if (!remoteNotesById.containsKey(localNote.id) &&
              localNote.syncStatus == 'pending' &&
              !localNote.isDeleted) {
            if (await notebookRepo.isTombstoned(localNote.id)) continue;
            final pushed = await fbSync.pushNote(uid, localNote);
            if (pushed) {
              await noteRepo.saveNote(localNote.copyWith(
                syncStatus: 'synced',
                serverVersion: localNote.localVersion,
                lastSyncedAt: DateTime.now(),
              ));
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
          status: noteConflicts > 0 ? SyncUiStatus.conflict : SyncUiStatus.synced,
          lastSyncedAt: now,
          pendingCount: pendingRemaining,
          lastPushed: pushedCount + localNotebooks.length,
          lastPulled: remoteNotes.length + remoteNotebooks.length,
          lastConflicts: state.lastConflicts + noteConflicts,
          clearError: true,
        );

        return SyncResult(
          isSuccess: true,
          pushedCount: pushedCount + localNotebooks.length,
          pulledCount: remoteNotebooks.length + remoteNotes.length,
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
    } finally {
      if (state.status == SyncUiStatus.syncing) {
        state = state.copyWith(status: SyncUiStatus.synced);
      }
    }
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
