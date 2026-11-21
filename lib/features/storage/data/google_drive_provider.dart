import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/repositories/attachment_repository.dart';
import '../../../services/storage/attachment_sync_coordinator.dart';
import '../../../services/storage/google_drive_auth_service.dart';
import '../../../services/storage/google_drive_storage_service.dart';
import '../../../services/storage/google_drive_sync_coordinator.dart';
import '../../authentication/data/auth_provider.dart';
import '../../notebooks/data/notebook_provider.dart';
import '../../../services/history/note_history_service.dart';

/// Explicit lifecycle states for Google Drive authorization and connection.
enum DriveConnectionStatus {
  idle,
  connecting,
  connected,
  failed,
  reconnecting,
}

/// State of the user's personal Google Drive storage and synchronization integration.
class GoogleDriveState {
  final DriveConnectionStatus status;
  final bool isConnected;
  final String? accountEmail;
  final String? accountSubjectId;
  final DateTime? lastVerifiedAt;
  final DateTime? connectedAt;
  final int pendingUploadsCount;
  final int failedUploadsCount;
  final int totalSyncedNotebooks;
  final int totalSyncedFiles;
  final String? storageUsageText;
  final bool isLoading;
  final bool isSyncing;
  final String? errorMessage;
  final double syncProgress;
  final String? syncProgressMessage;

  const GoogleDriveState({
    this.status = DriveConnectionStatus.idle,
    this.isConnected = false,
    this.accountEmail,
    this.accountSubjectId,
    this.lastVerifiedAt,
    this.connectedAt,
    this.pendingUploadsCount = 0,
    this.failedUploadsCount = 0,
    this.totalSyncedNotebooks = 0,
    this.totalSyncedFiles = 0,
    this.storageUsageText,
    this.isLoading = false,
    this.isSyncing = false,
    this.errorMessage,
    this.syncProgress = 0.0,
    this.syncProgressMessage,
  });

  bool get isConnecting => status == DriveConnectionStatus.connecting;
  bool get isReconnecting => status == DriveConnectionStatus.reconnecting;
  bool get hasFailed => status == DriveConnectionStatus.failed;

  GoogleDriveState copyWith({
    DriveConnectionStatus? status,
    bool? isConnected,
    String? accountEmail,
    String? accountSubjectId,
    DateTime? lastVerifiedAt,
    DateTime? connectedAt,
    int? pendingUploadsCount,
    int? failedUploadsCount,
    int? totalSyncedNotebooks,
    int? totalSyncedFiles,
    String? storageUsageText,
    bool? isLoading,
    bool? isSyncing,
    String? errorMessage,
    double? syncProgress,
    String? syncProgressMessage,
    bool clearError = false,
  }) {
    final newConnected = isConnected ?? this.isConnected;
    final newStatus = status ??
        (newConnected
            ? DriveConnectionStatus.connected
            : this.status);

    return GoogleDriveState(
      status: newStatus,
      isConnected: newConnected,
      accountEmail: accountEmail ?? this.accountEmail,
      accountSubjectId: accountSubjectId ?? this.accountSubjectId,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      pendingUploadsCount: pendingUploadsCount ?? this.pendingUploadsCount,
      failedUploadsCount: failedUploadsCount ?? this.failedUploadsCount,
      totalSyncedNotebooks: totalSyncedNotebooks ?? this.totalSyncedNotebooks,
      totalSyncedFiles: totalSyncedFiles ?? this.totalSyncedFiles,
      storageUsageText: storageUsageText ?? this.storageUsageText,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      syncProgress: syncProgress ?? this.syncProgress,
      syncProgressMessage: syncProgressMessage ?? this.syncProgressMessage,
    );
  }
}

final googleDriveAuthServiceProvider = Provider<GoogleDriveAuthService>((ref) {
  return GoogleDriveAuthService();
});

final googleDriveStorageServiceProvider =
    Provider<GoogleDriveStorageService>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  return GoogleDriveStorageService(authService: authService);
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AttachmentRepository(db);
});

final attachmentSyncCoordinatorProvider =
    Provider<AttachmentSyncCoordinator>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  final storageService = ref.watch(googleDriveStorageServiceProvider);
  final attachmentRepo = ref.watch(attachmentRepositoryProvider);

  return AttachmentSyncCoordinator(
    authService: authService,
    storageService: storageService,
    attachmentRepo: attachmentRepo,
  );
});

final googleDriveSyncCoordinatorProvider =
    Provider<GoogleDriveSyncCoordinator>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  final storageService = ref.watch(googleDriveStorageServiceProvider);
  final notebookRepo = ref.watch(notebookRepositoryProvider);
  final pageRepo = ref.watch(pageRepositoryProvider);
  final strokeRepo = ref.watch(strokeRepositoryProvider);
  final stickyNoteRepo = ref.watch(stickyNoteRepositoryProvider);
  final attachmentRepo = ref.watch(attachmentRepositoryProvider);

  return GoogleDriveSyncCoordinator(
    authService: authService,
    storageService: storageService,
    notebookRepo: notebookRepo,
    pageRepo: pageRepo,
    strokeRepo: strokeRepo,
    stickyNoteRepo: stickyNoteRepo,
    attachmentRepo: attachmentRepo,
  );
});

class GoogleDriveNotifier extends Notifier<GoogleDriveState> {
  static const String _prefDeclinedKey = 'google_drive_backup_declined';
  static const String _prefSnoozeKey = 'google_drive_backup_snooze_timestamp';

  GoogleDriveAuthService get _authService =>
      ref.read(googleDriveAuthServiceProvider);
  AttachmentRepository get _attachmentRepo =>
      ref.read(attachmentRepositoryProvider);
  GoogleDriveSyncCoordinator get _syncCoordinator =>
      ref.read(googleDriveSyncCoordinatorProvider);

  Completer<void>? _initCompleter;
  Timer? _autoSyncDebounceTimer;
  Timer? _periodicSyncTimer;
  bool _isDisposed = false;

  /// Completes when the initial Drive status has been validated on startup.
  Future<void> get initializationFuture =>
      _initCompleter?.future ?? Future.value();

  @override
  GoogleDriveState build() {
    _isDisposed = false;
    ref.watch(authProvider);
    _initCompleter = Completer<void>();
    Future.microtask(() {
      if (!_isDisposed) refreshStatus();
    });

    // Automatically check for cloud updates from other devices periodically every 45s
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (!_isDisposed && state.isConnected && !state.isSyncing) {
        debugPrint('[GoogleDriveProvider] Running periodic background cloud sync...');
        syncNow(silent: true);
      }
    });

    ref.onDispose(() {
      _isDisposed = true;
      _autoSyncDebounceTimer?.cancel();
      _periodicSyncTimer?.cancel();
    });
    return const GoogleDriveState();
  }

  String get _currentUid {
    if (_isDisposed) return 'local_user';
    try {
      final user = ref.read(authProvider).user;
      return user?.id ?? 'local_user';
    } catch (_) {
      return 'local_user';
    }
  }

  /// Checks if the user explicitly declined cloud backup.
  Future<bool> isDeclined() async {
    try {
      final val = await _authService.secureStorage.read(key: _prefDeclinedKey);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Sets whether the user explicitly declined cloud backup.
  Future<void> setDeclined(bool value) async {
    try {
      if (value) {
        await _authService.secureStorage.write(
          key: _prefDeclinedKey,
          value: 'true',
        );
      } else {
        await _authService.secureStorage.delete(key: _prefDeclinedKey);
      }
    } catch (_) {}
  }

  /// Checks if the connection prompt is currently snoozed (default 3 days).
  Future<bool> isSnoozed() async {
    try {
      final val = await _authService.secureStorage.read(key: _prefSnoozeKey);
      if (val == null) return false;
      final snoozeTime = DateTime.tryParse(val);
      if (snoozeTime == null) return false;
      return DateTime.now().difference(snoozeTime).inDays < 3;
    } catch (_) {
      return false;
    }
  }

  /// Snoozes the connection prompt for 3 days.
  Future<void> setSnoozed() async {
    try {
      await _authService.secureStorage.write(
        key: _prefSnoozeKey,
        value: DateTime.now().toIso8601String(),
      );
    } catch (_) {}
  }

  /// Refreshes connection status and validates live Google Drive API authorization.
  Future<void> refreshStatus() async {
    final uid = _currentUid;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final meta = await _authService.getConnectionMetadata(uid);
      final pendingCount = await _attachmentRepo.getPendingUploadsCount(uid);
      final failedCount = await _attachmentRepo.getFailedUploadsCount(uid);

      if (meta != null && meta.connected) {
        // Validate live API access
        final validationError = await _authService.validateDriveAccess(uid);

        if (validationError == null) {
          state = state.copyWith(
            status: DriveConnectionStatus.connected,
            isConnected: true,
            accountEmail: meta.googleAccountEmail,
            accountSubjectId: meta.googleAccountSubjectId,
            lastVerifiedAt: DateTime.now(),
            connectedAt: meta.connectedAt,
            pendingUploadsCount: pendingCount,
            failedUploadsCount: failedCount,
            isLoading: false,
          );
        } else {
          // Token expired or access revoked
          state = state.copyWith(
            status: DriveConnectionStatus.reconnecting,
            isConnected: false,
            accountEmail: meta.googleAccountEmail,
            accountSubjectId: meta.googleAccountSubjectId,
            pendingUploadsCount: pendingCount,
            failedUploadsCount: failedCount,
            isLoading: false,
            errorMessage: validationError,
          );
        }
      } else {
        state = state.copyWith(
          status: DriveConnectionStatus.idle,
          isConnected: false,
          accountEmail: null,
          accountSubjectId: null,
          pendingUploadsCount: pendingCount,
          failedUploadsCount: failedCount,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: DriveConnectionStatus.idle,
        isConnected: false,
        isLoading: false,
      );
    } finally {
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.complete();
      }
    }
  }

  /// Connects or reconnects the user's personal Google Drive account.
  Future<bool> connectDrive({bool forceAccountSelection = true}) async {
    if (state.status == DriveConnectionStatus.connecting) {
      return false; // Prevent duplicate requests
    }

    final uid = _currentUid;
    state = state.copyWith(
      status: DriveConnectionStatus.connecting,
      isLoading: true,
      clearError: true,
    );

    try {
      final creds = await _authService.authorizeDrive(
        uid: uid,
        forceAccountSelection: forceAccountSelection,
      );

      // Validate live API access immediately using the acquired token
      final validationError = await _authService.validateDriveAccess(
        uid,
        accessToken: creds.accessToken,
      );
      if (validationError != null) {
        throw Exception(validationError);
      }

      final pendingCount = await _attachmentRepo.getPendingUploadsCount(uid);
      final failedCount = await _attachmentRepo.getFailedUploadsCount(uid);

      // Clear decline flag on explicit connection
      await setDeclined(false);

      state = state.copyWith(
        status: DriveConnectionStatus.connected,
        isConnected: true,
        accountEmail: creds.accountEmail,
        accountSubjectId: creds.subjectId,
        lastVerifiedAt: DateTime.now(),
        connectedAt: DateTime.now(),
        pendingUploadsCount: pendingCount,
        failedUploadsCount: failedCount,
        isLoading: false,
      );

      // Trigger automatic background synchronization immediately upon connection
      scheduleAutoSync(
        delay: const Duration(milliseconds: 300),
        reason: 'initial_connection',
      );

      return true;
    } catch (e) {
      debugPrint('[GoogleDriveProvider] connectDrive error: $e');
      state = state.copyWith(
        status: DriveConnectionStatus.failed,
        isConnected: false,
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Disconnects Google Drive storage.
  Future<void> disconnectDrive() async {
    final uid = _currentUid;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.disconnectDrive(uid);
      state = state.copyWith(
        status: DriveConnectionStatus.idle,
        isConnected: false,
        accountEmail: null,
        accountSubjectId: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to disconnect Google Drive: $e',
      );
    }
  }

  /// Schedules a debounced automatic background sync.
  /// Used when notes, pages, drawings, or annotations are edited.
  void scheduleAutoSync({
    Duration delay = const Duration(seconds: 4),
    String reason = 'data_change',
  }) {
    if (!state.isConnected) return;
    _autoSyncDebounceTimer?.cancel();
    _autoSyncDebounceTimer = Timer(delay, () {
      if (state.isConnected && !state.isSyncing) {
        debugPrint(
          '[GoogleDriveProvider] Executing debounced cloud sync (reason: $reason)...',
        );
        syncNow();
      }
    });
  }

  /// Retries uploading and synchronizing all notes and attachments now.
  Future<void> syncNow({bool silent = false}) async {
    if (_isDisposed || state.isSyncing) return; // Prevent concurrent sync loops
    final uid = _currentUid;
    state = state.copyWith(
      isSyncing: true,
      clearError: true,
      syncProgress: 0.05,
      syncProgressMessage: silent ? null : 'Initiating cloud sync...',
    );

    try {
      final result = await _syncCoordinator.syncAll(
        uid: uid,
        onProgress: silent
            ? null
            : (message, progress) {
                if (!_isDisposed) {
                  state = state.copyWith(
                    syncProgress: progress,
                    syncProgressMessage: message,
                  );
                }
              },
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () => GoogleDriveSyncResult(
          success: false,
          errorMessage: 'Google Drive sync timed out after 45 seconds',
          timestamp: DateTime.now(),
        ),
      );

      if (_isDisposed) return;
      final pendingCount = await _attachmentRepo.getPendingUploadsCount(uid);
      final failedCount = await _attachmentRepo.getFailedUploadsCount(uid);

      if (result.success) {
        state = state.copyWith(
          status: DriveConnectionStatus.connected,
          isConnected: true,
          totalSyncedNotebooks:
              result.uploadedNotebooks + result.downloadedNotebooks,
          totalSyncedFiles: result.uploadedPages + result.uploadedAttachments,
          pendingUploadsCount: pendingCount,
          failedUploadsCount: failedCount,
          lastVerifiedAt: DateTime.now(),
          isSyncing: false,
          syncProgress: 1.0,
          syncProgressMessage: silent ? null : 'Sync complete',
        );

        // Reload local notebooks into provider only if new content was downloaded
        if (result.downloadedNotebooks > 0 || result.downloadedPages > 0) {
          await ref.read(notebooksProvider.notifier).loadFromDatabase();
          ref.read(noteHistoryProvider.notifier).refresh();
        }
      } else {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: result.errorMessage ?? 'Sync encountered an issue',
          syncProgress: 0.0,
          syncProgressMessage: null,
        );
      }
    } catch (e) {
      if (!_isDisposed) {
        state = state.copyWith(
          isSyncing: false,
          errorMessage: 'Sync failed: $e',
          syncProgress: 0.0,
          syncProgressMessage: null,
        );
      }
    } finally {
      if (!_isDisposed && state.isSyncing) {
        state = state.copyWith(isSyncing: false);
      }
    }
  }
}

final googleDriveProvider =
    NotifierProvider<GoogleDriveNotifier, GoogleDriveState>(
  () => GoogleDriveNotifier(),
);
