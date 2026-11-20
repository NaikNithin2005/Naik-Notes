// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/attachment_model.dart';
import '../../data/repositories/attachment_repository.dart';
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
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  AttachmentSyncCoordinator({
    required GoogleDriveAuthService authService,
    required GoogleDriveStorageService storageService,
    required AttachmentRepository attachmentRepo,
    FirebaseFirestore? firestore,
    Uuid? uuid,
  })  : _authService = authService,
        _storageService = storageService,
        _attachmentRepo = attachmentRepo,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  /// Returns the user-partitioned local directory for cached attachments.
  Future<Directory> getLocalAttachmentDirectory(String uid) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final sanitizedUid = uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dir = Directory(p.join(baseDir.path, 'users', sanitizedUid, 'attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Adds a new attachment to [noteId] from a local [sourceFile].
  ///
  /// 1. Copies file to the local user-partitioned cache directory.
  /// 2. Computes the SHA-256 integrity checksum.
  /// 3. Records attachment in SQLite `AttachmentsTable` with status `pending`.
  /// 4. If Google Drive is authorized, immediately uploads to `appDataFolder`
  ///    and records metadata in Firestore.
  /// 5. If Google Drive is disconnected, preserves file locally with status
  ///    `available_offline` without blocking user note-taking.
  Future<NoteAttachment> addAttachment({
    required String uid,
    required String noteId,
    required File sourceFile,
    required String fileName,
    String? mimeType,
    void Function(double progress)? onProgress,
  }) async {
    final attachmentId = _uuid.v4();
    final resolvedMime = mimeType ??
        lookupMimeType(fileName) ??
        'application/octet-stream';

    // 1. Copy to user cache directory
    final userDir = await getLocalAttachmentDirectory(uid);
    final ext = p.extension(fileName);
    final localCachedFile = File(p.join(userDir.path, '$attachmentId$ext'));
    await sourceFile.copy(localCachedFile.path);

    // 2. Compute checksum and file size
    final checksum = await GoogleDriveStorageService.calculateSha256(localCachedFile);
    final fileSize = await localCachedFile.length();

    // 3. Create domain attachment record
    var attachment = NoteAttachment(
      attachmentId: attachmentId,
      ownerId: uid,
      noteId: noteId,
      fileName: fileName,
      mimeType: resolvedMime,
      fileSize: fileSize,
      localPath: localCachedFile.path,
      checksum: checksum,
      storageProvider: AttachmentStorageProvider.googleDriveAppData,
      uploadStatus: AttachmentUploadStatus.pending,
      createdAt: DateTime.now(),
    );

    await _attachmentRepo.saveAttachment(attachment);

    // 4. Check if Google Drive is authorized
    final driveMeta = await _authService.getConnectionMetadata(uid);
    final isDriveConnected = driveMeta != null && driveMeta.connected;

    if (!isDriveConnected) {
      // Offline / Local-only mode: mark available locally
      await _attachmentRepo.updateAttachmentStatus(
        attachmentId,
        AttachmentUploadStatus.driveDisconnected,
        localPath: localCachedFile.path,
      );
      return attachment.copyWith(
        uploadStatus: AttachmentUploadStatus.driveDisconnected,
      );
    }

    // 5. Upload to Google Drive appDataFolder
    try {
      await _attachmentRepo.updateAttachmentStatus(
        attachmentId,
        AttachmentUploadStatus.uploading,
      );

      final driveFileId = await _storageService.uploadAttachment(
        uid: uid,
        noteId: noteId,
        attachmentId: attachmentId,
        file: localCachedFile,
        fileName: fileName,
        mimeType: resolvedMime,
        knownChecksum: checksum,
        onProgress: onProgress,
      );

      final uploadedAt = DateTime.now();

      // 6. Update Firestore note document attachment references
      await _saveAttachmentToFirestore(
        uid: uid,
        noteId: noteId,
        attachment: attachment.copyWith(
          driveFileId: driveFileId,
          uploadStatus: AttachmentUploadStatus.uploaded,
          uploadedAt: uploadedAt,
        ),
      );

      // 7. Update local SQLite database
      await _attachmentRepo.updateAttachmentStatus(
        attachmentId,
        AttachmentUploadStatus.uploaded,
        driveFileId: driveFileId,
        uploadedAt: uploadedAt,
      );

      return attachment.copyWith(
        driveFileId: driveFileId,
        uploadStatus: AttachmentUploadStatus.uploaded,
        uploadedAt: uploadedAt,
      );
    } catch (e) {
      debugPrint('[AttachmentSyncCoordinator] Upload failed: $e');
      await _attachmentRepo.updateAttachmentStatus(
        attachmentId,
        AttachmentUploadStatus.failed,
        error: e.toString(),
      );
      return attachment.copyWith(
        uploadStatus: AttachmentUploadStatus.failed,
        lastError: e.toString(),
      );
    }
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

    // 2. Prepare destination path in user directory
    final userDir = await getLocalAttachmentDirectory(uid);
    final ext = p.extension(attachment.fileName);
    final destinationFile = File(p.join(userDir.path, '${attachment.attachmentId}$ext'));

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
  Future<void> deleteAttachment({
    required String uid,
    required String noteId,
    required String attachmentId,
  }) async {
    final attachment = await _attachmentRepo.getAttachment(attachmentId);
    if (attachment == null) return;

    // 1. Mark deleted in SQLite
    await _attachmentRepo.markAttachmentDeleted(attachmentId);

    // 2. Delete from Google Drive appDataFolder if uploaded
    if (attachment.driveFileId != null && attachment.driveFileId!.isNotEmpty) {
      try {
        await _storageService.deleteAttachment(
          uid: uid,
          driveFileId: attachment.driveFileId!,
        );
      } catch (e) {
        debugPrint('[AttachmentSyncCoordinator] Drive delete error: $e');
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
      try {
        final file = File(attachment.localPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    // 5. Remove permanently from SQLite
    await _attachmentRepo.deleteAttachmentPermanently(attachmentId);
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
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('notebooks')
        .doc(noteId);

    await _firestore.runTransaction((transaction) async {
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
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('notebooks')
        .doc(noteId);

    await _firestore.runTransaction((transaction) async {
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
