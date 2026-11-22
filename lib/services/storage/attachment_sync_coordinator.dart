// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../data/models/attachment_model.dart';
import '../../data/repositories/attachment_repository.dart';
import 'attachment_storage_service.dart';
import 'google_drive_auth_service.dart';
import 'google_drive_storage_service.dart';

/// Central coordinator for Naik Notes hybrid attachment storage.
///
/// Workflow:
/// 1. Note Content & Attachment References -> Cloud Firestore
/// 2. Raw Binaries (Images, PDFs) -> Google Drive API v3 (appDataFolder)
/// 3. Offline Cache & Status Queue -> Drift SQLite + local app directory
class AttachmentSyncCoordinator {
  final GoogleDriveAuthService _authService;
  final GoogleDriveStorageService _storageService;
  final AttachmentRepository _attachmentRepo;
  final AttachmentStorageService _storageHelper;
  final FirebaseFirestore? _firestore;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  String? _listeningUid;

  AttachmentSyncCoordinator({
    required GoogleDriveAuthService authService,
    required GoogleDriveStorageService storageService,
    required AttachmentRepository attachmentRepo,
    AttachmentStorageService? storageHelper,
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _authService = authService,
        _storageService = storageService,
        _attachmentRepo = attachmentRepo,
        _storageHelper = storageHelper ?? AttachmentStorageService(),
        _firestore = firestore ?? (Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null);

  /// Starts listening to network connectivity changes to automatically retry
  /// pending uploads when the device returns online.
  void startConnectivityListener(String uid) {
    if (_listeningUid == uid && _connectivitySub != null) return;
    _listeningUid = uid;
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isConnected = results.any((r) => r != ConnectivityResult.none);
      if (isConnected) {
        debugPrint('[AttachmentSyncCoordinator] Network reconnected; syncing pending uploads...');
        syncPendingUploads(uid);
      }
    });
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Returns the user-partitioned local directory for cached attachments.
  Future<Directory> getLocalAttachmentDirectory(String uid) async {
    return _storageHelper.getBaseAttachmentsDirectory(uid);
  }

  /// Adds a new attachment to [noteId] from a local [sourceFile].
  ///
  /// 1. Copies/compresses file into the application-managed category directory.
  /// 2. Generates thumbnail for images and computes SHA-256 integrity checksum.
  /// 3. Records attachment in SQLite `AttachmentsTable` with status `pending`.
  /// 4. Immediately returns the attachment domain model so it displays in the editor.
  /// 5. Asynchronously triggers Google Drive upload if connected; otherwise marks
  ///    as `drive_disconnected` or `available_offline` without blocking user.
  Future<NoteAttachment> addAttachment({
    required String uid,
    required String noteId,
    required File sourceFile,
    required String fileName,
    String? mimeType,
    bool isSketch = false,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Import, compress, and store locally
    final processed = await _storageHelper.importFile(
      uid: uid,
      sourceFile: sourceFile,
      fileName: fileName,
      mimeType: mimeType,
      isSketch: isSketch,
    );

    // 2. Create domain attachment record
    var attachment = NoteAttachment(
      attachmentId: processed.localId,
      ownerId: uid,
      noteId: noteId,
      fileName: processed.fileName,
      mimeType: processed.mimeType,
      fileSize: processed.fileSize,
      localPath: processed.file.path,
      checksum: processed.checksum,
      storageProvider: AttachmentStorageProvider.googleDriveAppData,
      uploadStatus: AttachmentUploadStatus.pending,
      createdAt: DateTime.now(),
    );

    await _attachmentRepo.saveAttachment(attachment);

    // 3. Check Google Drive connection and upload asynchronously
    _triggerAsyncUpload(
      uid: uid,
      attachment: attachment,
      file: processed.file,
      onProgress: onProgress,
    );

    return attachment;
  }

  /// Adds an attachment directly from in-memory bytes (e.g. sketching canvas or camera).
  Future<NoteAttachment> addAttachmentFromBytes({
    required String uid,
    required String noteId,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    bool isSketch = false,
    void Function(double progress)? onProgress,
  }) async {
    final processed = await _storageHelper.importBytes(
      uid: uid,
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType,
      isSketch: isSketch,
    );

    var attachment = NoteAttachment(
      attachmentId: processed.localId,
      ownerId: uid,
      noteId: noteId,
      fileName: processed.fileName,
      mimeType: processed.mimeType,
      fileSize: processed.fileSize,
      localPath: processed.file.path,
      checksum: processed.checksum,
      storageProvider: AttachmentStorageProvider.googleDriveAppData,
      uploadStatus: AttachmentUploadStatus.pending,
      createdAt: DateTime.now(),
    );

    await _attachmentRepo.saveAttachment(attachment);

    _triggerAsyncUpload(
      uid: uid,
      attachment: attachment,
      file: processed.file,
      onProgress: onProgress,
    );

    return attachment;
  }

  /// Helper to trigger asynchronous Drive upload in background.
  void _triggerAsyncUpload({
    required String uid,
    required NoteAttachment attachment,
    required File file,
    void Function(double progress)? onProgress,
  }) {
    unawaited(() async {
      try {
        final driveMeta = await _authService.getConnectionMetadata(uid);
        final isDriveConnected = driveMeta != null && driveMeta.connected;

        if (!isDriveConnected) {
          await _attachmentRepo.updateAttachmentStatus(
            attachment.attachmentId,
            AttachmentUploadStatus.driveDisconnected,
            localPath: file.path,
          );
          return;
        }

        await _attachmentRepo.updateAttachmentStatus(
          attachment.attachmentId,
          AttachmentUploadStatus.uploading,
        );

        final driveFileId = await _storageService.uploadAttachment(
          uid: uid,
          noteId: attachment.noteId,
          attachmentId: attachment.attachmentId,
          file: file,
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
          knownChecksum: attachment.checksum,
          onProgress: onProgress,
        );

        final uploadedAt = DateTime.now();

        await _saveAttachmentToFirestore(
          uid: uid,
          noteId: attachment.noteId,
          attachment: attachment.copyWith(
            driveFileId: driveFileId,
            uploadStatus: AttachmentUploadStatus.uploaded,
            uploadedAt: uploadedAt,
          ),
        );

        await _attachmentRepo.updateAttachmentStatus(
          attachment.attachmentId,
          AttachmentUploadStatus.uploaded,
          driveFileId: driveFileId,
          uploadedAt: uploadedAt,
        );
      } catch (e) {
        debugPrint('[AttachmentSyncCoordinator] Async upload failed for ${attachment.attachmentId}: $e');
        await _attachmentRepo.updateAttachmentStatus(
          attachment.attachmentId,
          AttachmentUploadStatus.failed,
          error: e.toString(),
        );
      }
    }());
  }

  /// Downloads an attachment on-demand if not already present in the local cache.
  Future<File> getAttachmentFile({
    required String uid,
    required NoteAttachment attachment,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Check if local cached copy exists and is intact
    if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      final localFile = File(attachment.localPath!);
      if (await localFile.exists()) {
        final currentHash = await GoogleDriveStorageService.calculateSha256(localFile);
        if (currentHash == attachment.checksum) {
          return localFile;
        }
      }
    }

    // 2. Prepare destination path in user directory category
    final category = _storageHelper.resolveCategory(
      fileName: attachment.fileName,
      mimeType: attachment.mimeType,
    );
    final targetDir = await _storageHelper.getCategoryDirectory(uid, category);
    final ext = p.extension(attachment.fileName);
    final destinationFile = File(p.join(targetDir.path, '${attachment.attachmentId}$ext'));

    if (await destinationFile.exists()) {
      final hash = await GoogleDriveStorageService.calculateSha256(destinationFile);
      if (hash == attachment.checksum) {
        await _attachmentRepo.updateAttachmentStatus(
          attachment.attachmentId,
          AttachmentUploadStatus.uploaded,
          localPath: destinationFile.path,
        );
        return destinationFile;
      }
    }

    // 3. Download from Google Drive appDataFolder
    if (attachment.driveFileId == null || attachment.driveFileId!.isEmpty) {
      throw StateError('Cannot download attachment without a Drive file ID.');
    }

    await _attachmentRepo.updateAttachmentStatus(
      attachment.attachmentId,
      AttachmentUploadStatus.downloading,
    );

    try {
      final downloadedFile = await _storageService.downloadAttachment(
        uid: uid,
        driveFileId: attachment.driveFileId!,
        destinationFile: destinationFile,
        expectedChecksum: attachment.checksum,
        onProgress: onProgress,
      );

      await _attachmentRepo.updateAttachmentStatus(
        attachment.attachmentId,
        AttachmentUploadStatus.uploaded,
        localPath: downloadedFile.path,
      );

      return downloadedFile;
    } on DriveFileNotFoundException {
      await _attachmentRepo.updateAttachmentStatus(
        attachment.attachmentId,
        AttachmentUploadStatus.fileUnavailable,
        error: 'File was deleted from Google Drive.',
      );
      rethrow;
    } catch (e) {
      await _attachmentRepo.updateAttachmentStatus(
        attachment.attachmentId,
        AttachmentUploadStatus.downloadFailed,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Deletes an attachment from local storage, SQLite, Firestore, and Google Drive.
  ///
  /// Safe Deletion Guarantee:
  /// Verifies reference count before deleting the remote file on Google Drive.
  /// If another note or page references the same `driveFileId`, the remote file is preserved.
  Future<void> deleteAttachment({
    required String uid,
    required String noteId,
    required String attachmentId,
  }) async {
    final attachment = await _attachmentRepo.getAttachment(attachmentId);
    if (attachment == null) return;

    // 1. Mark deleted in SQLite
    await _attachmentRepo.markAttachmentDeleted(attachmentId);

    // 2. Safe remote deletion with reference count check
    if (attachment.driveFileId != null && attachment.driveFileId!.isNotEmpty) {
      final activeReferences =
          await _attachmentRepo.countAttachmentsWithDriveFileId(attachment.driveFileId!);

      // Only delete from Drive if no other active notes/pages reference this file
      if (activeReferences <= 0) {
        try {
          await _storageService.deleteAttachment(
            uid: uid,
            driveFileId: attachment.driveFileId!,
          );
        } catch (e) {
          debugPrint('[AttachmentSyncCoordinator] Drive delete error: $e');
        }
      }
    }

    // 3. Remove reference from Firestore note document
    try {
      await _removeAttachmentFromFirestore(
        uid: uid,
        noteId: noteId,
        attachmentId: attachmentId,
      );
    } catch (e) {
      debugPrint('[AttachmentSyncCoordinator] Firestore delete error: $e');
    }

    // 4. Delete local file from cache
    if (attachment.localPath != null) {
      await _storageHelper.deleteLocalFile(attachment.localPath);
    }

    // 5. Remove permanently from SQLite
    await _attachmentRepo.deleteAttachmentPermanently(attachmentId);
  }

  /// Cleans up all attachments belonging to a note when permanently deleted.
  Future<void> onNotePermanentlyDeleted(String uid, String noteId) async {
    final attachments = await _attachmentRepo.getAttachmentsForNote(noteId);
    for (final att in attachments) {
      await deleteAttachment(
        uid: uid,
        noteId: noteId,
        attachmentId: att.attachmentId,
      );
    }
  }

  /// Resets any interrupted uploads (e.g. from app termination) back to pending.
  Future<void> recoverInterruptedUploads(String uid) async {
    await _attachmentRepo.resetUploadingToPending(uid);
    await syncPendingUploads(uid);
  }

  /// Retries uploading any pending or failed attachments when online and Drive is authorized.
  Future<void> syncPendingUploads(String uid) async {
    final driveMeta = await _authService.getConnectionMetadata(uid);
    if (driveMeta == null || !driveMeta.connected) return;

    final pending = await _attachmentRepo.getPendingUploads(uid);
    if (pending.isEmpty) return;

    for (final attachment in pending) {
      if (attachment.localPath == null) continue;
      final file = File(attachment.localPath!);
      if (!await file.exists()) continue;

      try {
        await _attachmentRepo.updateAttachmentStatus(
          attachment.attachmentId,
          AttachmentUploadStatus.uploading,
        );

        final driveFileId = await _storageService.uploadAttachment(
          uid: uid,
          noteId: attachment.noteId,
          attachmentId: attachment.attachmentId,
          file: file,
          fileName: attachment.fileName,
          mimeType: attachment.mimeType,
          knownChecksum: attachment.checksum,
        );

        final uploadedAt = DateTime.now();

        await _saveAttachmentToFirestore(
          uid: uid,
          noteId: attachment.noteId,
          attachment: attachment.copyWith(
            driveFileId: driveFileId,
            uploadStatus: AttachmentUploadStatus.uploaded,
            uploadedAt: uploadedAt,
          ),
        );

        await _attachmentRepo.updateAttachmentStatus(
          attachment.attachmentId,
          AttachmentUploadStatus.uploaded,
          driveFileId: driveFileId,
          uploadedAt: uploadedAt,
        );
      } catch (e) {
        debugPrint('[AttachmentSyncCoordinator] Pending upload retry failed for ${attachment.attachmentId}: $e');
        await _attachmentRepo.updateAttachmentStatus(
          attachment.attachmentId,
          AttachmentUploadStatus.failed,
          error: e.toString(),
        );
      }
    }
  }

  // ===========================================================================
  // Firestore Note Attachment Array Synchronization
  // ===========================================================================

  Future<void> _saveAttachmentToFirestore({
    required String uid,
    required String noteId,
    required NoteAttachment attachment,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    final docRef = firestore
        .collection('users')
        .doc(uid)
        .collection('notebooks')
        .doc(noteId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};
      final rawList = (data['attachments'] as List<dynamic>?) ?? [];

      final existingList = rawList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final existingIndex = existingList.indexWhere(
        (item) => item['attachmentId'] == attachment.attachmentId,
      );

      if (existingIndex >= 0) {
        existingList[existingIndex] = attachment.toFirestore();
      } else {
        existingList.add(attachment.toFirestore());
      }

      transaction.update(docRef, {
        'attachments': existingList,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> _removeAttachmentFromFirestore({
    required String uid,
    required String noteId,
    required String attachmentId,
  }) async {
    final firestore = _firestore;
    if (firestore == null) return;

    final docRef = firestore
        .collection('users')
        .doc(uid)
        .collection('notebooks')
        .doc(noteId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? {};
      final rawList = (data['attachments'] as List<dynamic>?) ?? [];

      final updatedList = rawList
          .map((item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['attachmentId'] != attachmentId)
          .toList();

      transaction.update(docRef, {
        'attachments': updatedList,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
