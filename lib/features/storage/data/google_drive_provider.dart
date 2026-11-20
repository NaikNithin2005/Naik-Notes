import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/repositories/attachment_repository.dart';
import '../../../services/storage/attachment_sync_coordinator.dart';
import '../../../services/storage/google_drive_auth_service.dart';
import '../../../services/storage/google_drive_storage_service.dart';
import '../../authentication/data/auth_provider.dart';

/// State of the user's personal Google Drive attachment storage integration.
class GoogleDriveState {
  final bool isConnected;
  final String? accountEmail;
  final String? accountSubjectId;
  final DateTime? lastVerifiedAt;
  final DateTime? connectedAt;
  final int pendingUploadsCount;
  final int failedUploadsCount;
  final bool isLoading;
  final String? errorMessage;

  const GoogleDriveState({
    this.isConnected = false,
    this.accountEmail,
    this.accountSubjectId,
    this.lastVerifiedAt,
    this.connectedAt,
    this.pendingUploadsCount = 0,
    this.failedUploadsCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  GoogleDriveState copyWith({
    bool? isConnected,
    String? accountEmail,
    String? accountSubjectId,
    DateTime? lastVerifiedAt,
    DateTime? connectedAt,
    int? pendingUploadsCount,
    int? failedUploadsCount,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GoogleDriveState(
      isConnected: isConnected ?? this.isConnected,
      accountEmail: accountEmail ?? this.accountEmail,
      accountSubjectId: accountSubjectId ?? this.accountSubjectId,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      pendingUploadsCount: pendingUploadsCount ?? this.pendingUploadsCount,
      failedUploadsCount: failedUploadsCount ?? this.failedUploadsCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final googleDriveAuthServiceProvider = Provider<GoogleDriveAuthService>((ref) {
  return GoogleDriveAuthService();
});

final googleDriveStorageServiceProvider = Provider<GoogleDriveStorageService>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  return GoogleDriveStorageService(authService: authService);
});

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return AttachmentRepository(db);
});

final attachmentSyncCoordinatorProvider = Provider<AttachmentSyncCoordinator>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  final storageService = ref.watch(googleDriveStorageServiceProvider);
  final attachmentRepo = ref.watch(attachmentRepositoryProvider);

  return AttachmentSyncCoordinator(
    authService: authService,
    storageService: storageService,
    attachmentRepo: attachmentRepo,
  );
});

class GoogleDriveNotifier extends Notifier<GoogleDriveState> {
  GoogleDriveAuthService get _authService => ref.read(googleDriveAuthServiceProvider);
  AttachmentRepository get _attachmentRepo => ref.read(attachmentRepositoryProvider);
  AttachmentSyncCoordinator get _syncCoordinator => ref.read(attachmentSyncCoordinatorProvider);

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

  /// Refreshes connection status and pending uploads count from Firestore and SQLite.
  Future<void> refreshStatus() async {
    final uid = _currentUid;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final meta = await _authService.getConnectionMetadata(uid);
      final pendingCount = await _attachmentRepo.getPendingUploadsCount(uid);
      final failedCount = await _attachmentRepo.getFailedUploadsCount(uid);

      if (meta != null && meta.connected) {
        state = state.copyWith(
          isConnected: true,
          accountEmail: meta.googleAccountEmail,
          accountSubjectId: meta.googleAccountSubjectId,
          lastVerifiedAt: meta.lastVerifiedAt,
          connectedAt: meta.connectedAt,
          pendingUploadsCount: pendingCount,
          failedUploadsCount: failedCount,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
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
        isLoading: false,
        errorMessage: 'Failed to verify Google Drive status: $e',
      );
    }
  }

  /// Connects or reconnects the user's personal Google Drive account.
  Future<bool> connectDrive({bool forceAccountSelection = true}) async {
    final uid = _currentUid;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final creds = await _authService.authorizeDrive(
        uid: uid,
        forceAccountSelection: forceAccountSelection,
      );

      // Trigger sync of any pending offline attachments immediately upon connection
      _syncCoordinator.syncPendingUploads(uid).catchError((e) {
        // Log sync errors in background
      });

      final pendingCount = await _attachmentRepo.getPendingUploadsCount(uid);
      final failedCount = await _attachmentRepo.getFailedUploadsCount(uid);

      state = state.copyWith(
        isConnected: true,
        accountEmail: creds.accountEmail,
        accountSubjectId: creds.subjectId,
        lastVerifiedAt: DateTime.now(),
        connectedAt: DateTime.now(),
        pendingUploadsCount: pendingCount,
        failedUploadsCount: failedCount,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Disconnects Google Drive attachment storage.
  /// Local cached files and note references are preserved.
  Future<void> disconnectDrive() async {
    final uid = _currentUid;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authService.disconnectDrive(uid);
      state = state.copyWith(
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

  /// Retries uploading any pending or failed attachments now.
  Future<void> syncNow() async {
    final uid = _currentUid;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _syncCoordinator.syncPendingUploads(uid);
      await refreshStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sync failed: $e',
      );
    }
  }
}

final googleDriveProvider =
    NotifierProvider<GoogleDriveNotifier, GoogleDriveState>(() => GoogleDriveNotifier());
