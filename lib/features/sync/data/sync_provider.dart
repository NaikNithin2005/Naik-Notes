import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../data/local/database_provider.dart';
import '../../../services/sync/sync_service.dart';

enum SyncUiStatus { synced, syncing, offline, error }

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

/// Riverpod notifier managing synchronization state, triggers, and auto-sync timer.
class SyncNotifier extends Notifier<SyncState> {
  Timer? _autoSyncTimer;

  @override
  SyncState build() {
    ref.onDispose(() {
      _autoSyncTimer?.cancel();
    });

    _startPeriodicSync();

    return const SyncState();
  }

  void _startPeriodicSync() {
    _autoSyncTimer?.cancel();
    if (!AppConfig.enablePeriodicSync) return;
    // Periodic poll every 45 seconds
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

    state = state.copyWith(
      status: SyncUiStatus.syncing,
      clearError: true,
    );

    final syncService = ref.read(syncServiceProvider);
    final result = await syncService.syncAll(ownerId: ownerId);

    if (result.isSuccess) {
      final queueRepo = ref.read(syncQueueRepositoryProvider);
      final remainingCount = await queueRepo.getPendingCount();

      state = state.copyWith(
        status: SyncUiStatus.synced,
        lastSyncedAt: result.timestamp,
        pendingCount: remainingCount,
        lastPushed: result.pushedCount,
        lastPulled: result.pulledCount,
        lastConflicts: result.conflictCount,
        clearError: true,
      );
    } else {
      state = state.copyWith(
        status:
            result.errorMessage?.contains('offline') == true
                ? SyncUiStatus.offline
                : SyncUiStatus.error,
        lastError: result.errorMessage,
      );
    }

    return result;
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(() {
  return SyncNotifier();
});
