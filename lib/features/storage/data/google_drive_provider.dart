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
  GoogleDriveAuthService get _authService =>
      ref.read(googleDriveAuthServiceProvider);
  AttachmentRepository get _attachmentRepo =>
      ref.read(attachmentRepositoryProvider);
  GoogleDriveSyncCoordinator get _syncCoordinator =>
      ref.read(googleDriveSyncCoordinatorProvider);

  @override
  GoogleDriveState build() {
    ref.watch(authProvider);
    Future.microtask(() => refreshStatus());
    return const GoogleDriveState();
  }

  String get _currentUid {
    final user = ref.read(authProvider).user;
    return user?.id ?? 'local_user';
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
        final isValid = await _authService.validateDriveAccess(uid);

        if (isValid) {
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
            errorMessage:
                'Google Drive authorization expired. Please reconnect.',
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

      // Validate live API access immediately
      final isAccessValid = await _authService.validateDriveAccess(uid);
      if (!isAccessValid) {
        throw Exception(
          'Google Drive access could not be verified. Please check permissions.',
        );
      }

      final pendingCount = await _attachmentRepo.getPendingUploadsCount(uid);
      final failedCount = await _attachmentRepo.getFailedUploadsCount(uid);

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
      syncNow();

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

  /// Retries uploading and synchronizing all notes and attachments now.
  Future<void> syncNow() async {
    final uid = _currentUid;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      syncProgress: 0.05,
      syncProgressMessage: 'Initiating cloud sync...',
    );

    try {
      final result = await _syncCoordinator.syncAll(
        uid: uid,
        onProgress: (message, progress) {
          state = state.copyWith(
            syncProgress: progress,
            syncProgressMessage: message,
          );
        },
      );

      final pendingCount = await _attachmentRepo.getPendingUploadsCount(uid);
      final failedCount = await _attachmentRepo.getFailedUploadsCount(uid);

      if (result.success) {
        state = state.copyWith(
          status: DriveConnectionStatus.connected,
          isConnected: true,
          totalSyncedNotebooks: result.uploadedNotebooks + result.downloadedNotebooks,
          totalSyncedFiles: result.uploadedPages + result.uploadedAttachments,
          pendingUploadsCount: pendingCount,
          failedUploadsCount: failedCount,
          lastVerifiedAt: DateTime.now(),
          isLoading: false,
          syncProgress: 1.0,
          syncProgressMessage: 'Sync complete',
        );

        // Reload local notebooks into provider
        await ref.read(notebooksProvider.notifier).loadFromDatabase();
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage ?? 'Sync encountered an issue',
          syncProgress: 0.0,
          syncProgressMessage: null,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sync failed: $e',
        syncProgress: 0.0,
        syncProgressMessage: null,
      );
    }
  }
}

final googleDriveProvider =
    NotifierProvider<GoogleDriveNotifier, GoogleDriveState>(
  () => GoogleDriveNotifier(),
);
