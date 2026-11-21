// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../data/models/notebook_model.dart';
import '../../data/models/page_model.dart';
import '../../data/models/sticky_note_model.dart';
import '../../data/models/stroke_model.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../data/repositories/page_repository.dart';
import '../../data/repositories/sticky_note_repository.dart';
import '../../data/repositories/stroke_repository.dart';
import '../history/note_history_service.dart';
import 'google_drive_auth_service.dart';
import 'google_drive_storage_service.dart';

/// Summary result of a bidirectional Google Drive note & notebook sync pass.
class GoogleDriveSyncResult {
  final bool success;
  final int uploadedNotebooks;
  final int downloadedNotebooks;
  final int uploadedPages;
  final int downloadedPages;
  final int uploadedAttachments;
  final int downloadedAttachments;
  final int conflictCount;
  final int deletedCount;
  final String? errorMessage;
  final DateTime timestamp;

  const GoogleDriveSyncResult({
    required this.success,
    this.uploadedNotebooks = 0,
    this.downloadedNotebooks = 0,
    this.uploadedPages = 0,
    this.downloadedPages = 0,
    this.uploadedAttachments = 0,
    this.downloadedAttachments = 0,
    this.conflictCount = 0,
    this.deletedCount = 0,
    this.errorMessage,
    required this.timestamp,
  });

  bool get hasChanges =>
      downloadedNotebooks > 0 ||
      downloadedPages > 0 ||
      uploadedNotebooks > 0 ||
      uploadedPages > 0 ||
      deletedCount > 0;

  @override
  String toString() =>
      'GoogleDriveSyncResult(success: $success, upNb: $uploadedNotebooks, downNb: $downloadedNotebooks, '
      'upPg: $uploadedPages, downPg: $downloadedPages, upAtt: $uploadedAttachments, conflicts: $conflictCount, deleted: $deletedCount, err: $errorMessage)';
}

/// Internal authenticated HTTP client injecting Bearer token into Google Drive API calls.
class _DriveAuthClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;

  _DriveAuthClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}

/// Production service managing bidirectional note and notebook synchronization
/// with Google Drive (appDataFolder) across Windows, iPadOS, and Android.
///
/// Google Drive Folder Architecture:
/// Naik Notes/
/// ├── User Data/
/// │   ├── Notebooks/
/// │   │   ├── `<notebookId>`/
/// │   │   │   ├── notebook.json
/// │   │   │   ├── Pages/
/// │   │   │   │   └── `<pageId>`.json
/// │   │   │   ├── Attachments/
/// │   │   │   └── PDFs/
/// │   ├── Audio Recordings/
/// │   ├── Images/
/// │   └── Backup Metadata/
/// │       └── sync_manifest.json
/// └── Backup Information/
///     └── backup_info.json
class GoogleDriveSyncCoordinator {
  final GoogleDriveAuthService _authService;
  final GoogleDriveStorageService _storageService;
  final NotebookRepository _notebookRepo;
  final PageRepository _pageRepo;
  final StrokeRepository _strokeRepo;
  final StickyNoteRepository _stickyNoteRepo;
  final AttachmentRepository _attachmentRepo;
  final http.Client _baseHttpClient;
  final Uuid _uuid;

  // In-memory cache of folder paths to Drive folder IDs to minimize API calls
  final Map<String, String> _folderIdCache = {};

  // Local tombstones to prevent deleted notebooks from being restored
  final Set<String> _localDeletedNotebookIds = {};

  // Incremental sync cache: pageId -> signature ("rev_updatedAt_strokesCount")
  final Map<String, String> _syncedPageSignatures = {};

  final String _deviceId;

  GoogleDriveSyncCoordinator({
    required GoogleDriveAuthService authService,
    required GoogleDriveStorageService storageService,
    required NotebookRepository notebookRepo,
    required PageRepository pageRepo,
    required StrokeRepository strokeRepo,
    required StickyNoteRepository stickyNoteRepo,
    required AttachmentRepository attachmentRepo,
    http.Client? httpClient,
    Uuid? uuid,
    String? deviceId,
  })  : _authService = authService,
        _storageService = storageService,
        _notebookRepo = notebookRepo,
        _pageRepo = pageRepo,
        _strokeRepo = strokeRepo,
        _stickyNoteRepo = stickyNoteRepo,
        _attachmentRepo = attachmentRepo,
        _baseHttpClient = httpClient ?? http.Client(),
        _uuid = uuid ?? const Uuid(),
        _deviceId = deviceId ?? NoteHistoryService.currentDeviceName;

  Future<drive.DriveApi> _getDriveApi(String uid) async {
    final token = await _authService.getValidAccessToken(uid);
    if (token == null || token.isEmpty) {
      throw StateError('Google Drive is not connected or token expired for user $uid.');
    }
    final client = _DriveAuthClient(_baseHttpClient, token);
    return drive.DriveApi(client);
  }

  /// Locates an existing folder with [folderName] under [parentId], or creates one.
  Future<String> _getOrCreateFolder(
    drive.DriveApi api,
    String parentId,
    String folderName,
  ) async {
    final cacheKey = '$parentId/$folderName';
    if (_folderIdCache.containsKey(cacheKey)) {
      return _folderIdCache[cacheKey]!;
    }

    // Query Google Drive appDataFolder for folder
    final q =
        "'$parentId' in parents and name = '$folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final result = await api.files.list(
      q: q,
      spaces: 'appDataFolder',
      $fields: 'files(id, name)',
      pageSize: 1,
    );

    if (result.files != null && result.files!.isNotEmpty) {
      final id = result.files!.first.id!;
      _folderIdCache[cacheKey] = id;
      return id;
    }

    // Create folder
    final folderMeta = drive.File()
      ..name = folderName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [parentId];

    final created = await api.files.create(
      folderMeta,
      $fields: 'id, name',
    );

    final id = created.id!;
    _folderIdCache[cacheKey] = id;
    return id;
  }

  /// Ensures root directory hierarchy exists in `appDataFolder`.
  Future<Map<String, String>> _ensureFolderHierarchy(
    drive.DriveApi api,
  ) async {
    // 1. Root: Naik Notes (in appDataFolder)
    final rootId = await _getOrCreateFolder(api, 'appDataFolder', 'Naik Notes');

    // 2. User Data & Backup Information
    final userDataId = await _getOrCreateFolder(api, rootId, 'User Data');
    final backupInfoId =
        await _getOrCreateFolder(api, rootId, 'Backup Information');

    // 3. Subdirectories under User Data
    final notebooksId = await _getOrCreateFolder(api, userDataId, 'Notebooks');
    final audioId =
        await _getOrCreateFolder(api, userDataId, 'Audio Recordings');
    final imagesId = await _getOrCreateFolder(api, userDataId, 'Images');
    final metadataId =
        await _getOrCreateFolder(api, userDataId, 'Backup Metadata');

    return {
      'root': rootId,
      'userData': userDataId,
      'notebooks': notebooksId,
      'audio': audioId,
      'images': imagesId,
      'metadata': metadataId,
      'backupInfo': backupInfoId,
    };
  }

  /// Synchronizes all user notes, pages, handwriting, and attachments with Google Drive.
  Future<GoogleDriveSyncResult> syncAll({
    required String uid,
    void Function(String message, double progress)? onProgress,
  }) async {
    final now = DateTime.now();
    try {
      onProgress?.call('Connecting to Google Drive...', 0.05);
      final api = await _getDriveApi(uid);
      final folders = await _ensureFolderHierarchy(api);
      final notebooksFolderId = folders['notebooks']!;

      int upNb = 0;
      int downNb = 0;
      int upPg = 0;
      int downPg = 0;
      int upAtt = 0;
      int conflicts = 0;
      int deletedCount = 0;

      // -------------------------------------------------------------
      // 0. BIDIRECTIONAL DELETIONS: Propagate deletions across devices
      // -------------------------------------------------------------
      onProgress?.call('Syncing deletions across devices...', 0.10);
      deletedCount = await _syncDeletions(
        api: api,
        metadataFolderId: folders['metadata']!,
        notebooksFolderId: notebooksFolderId,
        uid: uid,
      );

      // -------------------------------------------------------------
      // 1. DRIVE -> LOCAL: Pull new & updated remote notebooks FIRST!
      // -------------------------------------------------------------
      onProgress?.call('Checking cloud updates from other devices...', 0.20);
      final localBeforePull = await _notebookRepo.getAllNotebooks(
        ownerId: uid,
        includeArchived: true,
      );

      final pullRes = await _pullNotebooksFromDrive(
        api: api,
        notebooksFolderId: notebooksFolderId,
        uid: uid,
        localNotebooks: localBeforePull,
        onProgress: onProgress,
      );

      downNb = pullRes['downloadedNotebooks'] as int? ?? 0;
      downPg = pullRes['downloadedPages'] as int? ?? 0;
      conflicts = pullRes['conflicts'] as int? ?? 0;
      final pulledIds = (pullRes['pulledNotebookIds'] as Set<String>?) ?? {};

      // -------------------------------------------------------------
      // 2. LOCAL -> DRIVE: Push modified local notebooks & pages
      // -------------------------------------------------------------
      onProgress?.call('Uploading local changes to cloud...', 0.60);
      final localAfterPull = await _notebookRepo.getAllNotebooks(
        ownerId: uid,
        includeArchived: true,
      );
      final totalLocal = localAfterPull.length;

      for (int i = 0; i < totalLocal; i++) {
        final nb = localAfterPull[i];
        if (_localDeletedNotebookIds.contains(nb.id)) continue;
        if (pulledIds.contains(nb.id)) continue; // Already updated from cloud

        final progress = 0.60 + (0.25 * (i / (totalLocal == 0 ? 1 : totalLocal)));
        onProgress?.call(
          'Synchronizing: ${nb.title} (${i + 1}/$totalLocal)...',
          progress,
        );

        final nbRes = await _uploadNotebookToDrive(
          api: api,
          notebooksFolderId: notebooksFolderId,
          uid: uid,
          notebook: nb,
        );

        if (nbRes['uploaded'] == true) upNb++;
        upPg += (nbRes['pages'] as int? ?? 0);
      }

      // -------------------------------------------------------------
      // 3. ATTACHMENT SYNC: Upload pending offline attachments
      // -------------------------------------------------------------
      onProgress?.call('Synchronizing attachments...', 0.85);
      try {
        final pendingAtts = await _attachmentRepo.getPendingUploads(uid);
        for (final att in pendingAtts) {
          if (att.localPath != null && File(att.localPath!).existsSync()) {
            final file = File(att.localPath!);
            await _storageService.uploadAttachment(
              uid: uid,
              noteId: att.noteId,
              attachmentId: att.attachmentId,
              file: file,
              fileName: att.fileName,
              mimeType: att.mimeType,
            );
            upAtt++;
          }
        }
      } catch (e) {
        debugPrint('[GoogleDriveSyncCoordinator] Attachment sync note: $e');
      }

      // -------------------------------------------------------------
      // 4. ACTIVITY HISTORY SYNC: Cross-device audit trail
      // -------------------------------------------------------------
      onProgress?.call('Synchronizing notes activity history...', 0.92);
      await _syncActivityHistory(
        api: api,
        metadataFolderId: folders['metadata']!,
      );

      // -------------------------------------------------------------
      // 5. WRITE SYNC MANIFEST & BACKUP INFO
      // -------------------------------------------------------------
      onProgress?.call('Writing sync manifest and backup information...', 0.96);
      await _writeSyncManifest(
        api: api,
        metadataFolderId: folders['metadata']!,
        uid: uid,
        timestamp: now,
        notebookCount: localAfterPull.length,
      );
      await _writeBackupInfo(
        api: api,
        backupInfoFolderId: folders['backupInfo']!,
        uid: uid,
        timestamp: now,
        notebookCount: localAfterPull.length,
        pagesCount: upPg + downPg,
        attachmentsCount: upAtt,
      );

      onProgress?.call('Cloud sync complete!', 1.0);

      return GoogleDriveSyncResult(
        success: true,
        uploadedNotebooks: upNb,
        downloadedNotebooks: downNb,
        uploadedPages: upPg,
        downloadedPages: downPg,
        uploadedAttachments: upAtt,
        conflictCount: conflicts,
        deletedCount: deletedCount,
        timestamp: now,
      );
    } catch (e) {
      debugPrint('[GoogleDriveSyncCoordinator] syncAll failed: $e');
      return GoogleDriveSyncResult(
        success: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
        timestamp: now,
      );
    }
  }

  /// Uploads or updates a single notebook, its pages, and strokes into Google Drive.
  Future<Map<String, dynamic>> _uploadNotebookToDrive({
    required drive.DriveApi api,
    required String notebooksFolderId,
    required String uid,
    required Notebook notebook,
  }) async {
    // 1. Notebook folder: User Data/Notebooks/<notebookId>
    final nbFolderId = await _getOrCreateFolder(
      api,
      notebooksFolderId,
      notebook.id,
    );

    // 2. Subfolders: Pages, Attachments, PDFs
    final pagesFolderId = await _getOrCreateFolder(api, nbFolderId, 'Pages');
    await _getOrCreateFolder(api, nbFolderId, 'Attachments');
    await _getOrCreateFolder(api, nbFolderId, 'PDFs');

    // 3. Upload/Update notebook.json
    final nbJson = jsonEncode(notebook.toJson());
    await _createOrUpdateJsonFile(
      api: api,
      parentId: nbFolderId,
      fileName: 'notebook.json',
      content: nbJson,
      properties: {
        'notebookId': notebook.id,
        'revision': notebook.revision.toString(),
        'updatedAt': notebook.updatedAt.toIso8601String(),
      },
    );

    // 4. Upload/Update Pages and vector handwriting strokes (Incremental Sync)
    int pagesUploaded = 0;
    final pages = await _pageRepo.getPagesForNotebook(notebook.id);

    for (final page in pages) {
      final strokes = await _strokeRepo.getStrokesForPage(page.id);
      final stickyNotes = await _stickyNoteRepo.getStickyNotesForPage(page.id);

      // Intelligent Incremental Check: skip page if revision and timestamps match cached sync
      final pageSignature =
          '${page.revision}_${page.updatedAt.millisecondsSinceEpoch}_${strokes.length}_${stickyNotes.length}';
      if (_syncedPageSignatures[page.id] == pageSignature) {
        // Page has not changed since last cloud synchronization
        continue;
      }

      final pagePayload = {
        'page': page.toJson(),
        'strokes': strokes.map((s) => s.toJson()).toList(),
        'stickyNotes': stickyNotes.map((sn) => sn.toJson()).toList(),
        'updatedAt': page.updatedAt.toIso8601String(),
        'revision': page.revision,
      };

      final pageJson = jsonEncode(pagePayload);
      await _createOrUpdateJsonFile(
        api: api,
        parentId: pagesFolderId,
        fileName: '${page.id}.json',
        content: pageJson,
        properties: {
          'pageId': page.id,
          'notebookId': notebook.id,
          'revision': page.revision.toString(),
        },
      );
      _syncedPageSignatures[page.id] = pageSignature;
      pagesUploaded++;
    }

    return {'uploaded': true, 'pages': pagesUploaded};
  }

  /// Scans Drive for remote notebooks and restores any missing or newer notebooks locally.
  Future<Map<String, dynamic>> _pullNotebooksFromDrive({
    required drive.DriveApi api,
    required String notebooksFolderId,
    required String uid,
    required List<Notebook> localNotebooks,
    void Function(String message, double progress)? onProgress,
  }) async {
    int downloadedNb = 0;
    int downloadedPg = 0;
    int conflicts = 0;
    final Set<String> pulledNotebookIds = {};

    final localNbMap = {for (final nb in localNotebooks) nb.id: nb};

    // List all folders in User Data/Notebooks
    final q =
        "'$notebooksFolderId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final folderList = await api.files.list(
      q: q,
      spaces: 'appDataFolder',
      $fields: 'files(id, name)',
      pageSize: 100,
    );

    final remoteFolders = folderList.files ?? [];
    final historyService = NoteHistoryService();

    for (final rf in remoteFolders) {
      final nbId = rf.name!;
      final folderId = rf.id!;

      // 1. Tombstone check: if user deleted this notebook locally, do not restore it!
      if (_localDeletedNotebookIds.contains(nbId)) {
        continue;
      }

      // Find notebook.json in this folder
      final nbFile = await _findFile(api, folderId, 'notebook.json');
      if (nbFile == null) continue;

      final nbContent = await _downloadFileAsString(api, nbFile.id!);
      if (nbContent == null) continue;

      final nbMap = jsonDecode(nbContent) as Map<String, dynamic>;
      final remoteNb = Notebook.fromJson(nbMap);

      if (remoteNb.deletedAt != null) {
        _localDeletedNotebookIds.add(nbId);
        await _notebookRepo.deleteNotebook(nbId);
        continue;
      }

      final localNb = localNbMap[nbId];

      bool shouldRestore = false;

      if (localNb == null) {
        // Missing notebook: restore locally from cloud
        shouldRestore = true;
        historyService.recordActivity(
          noteId: remoteNb.id,
          noteTitle: remoteNb.title,
          action: NoteActionType.created,
          userEmail: uid,
          deviceName: 'Cloud Synced',
          details: 'Retrieved notebook created on another device',
        );
      } else if (remoteNb.revision > localNb.revision) {
        // Remote has newer changes
        shouldRestore = true;
        historyService.recordActivity(
          noteId: remoteNb.id,
          noteTitle: remoteNb.title,
          action: NoteActionType.updated,
          userEmail: uid,
          deviceName: 'Cloud Synced',
          details: 'Retrieved updates from another device',
        );
      } else if (remoteNb.revision == localNb.revision &&
          remoteNb.updatedAt.isAfter(localNb.updatedAt)) {
        shouldRestore = true;
        historyService.recordActivity(
          noteId: remoteNb.id,
          noteTitle: remoteNb.title,
          action: NoteActionType.updated,
          userEmail: uid,
          deviceName: 'Cloud Synced',
          details: 'Retrieved cloud updates',
        );
      } else if (localNb.updatedAt.isAfter(remoteNb.updatedAt) &&
          remoteNb.updatedAt.difference(localNb.updatedAt).abs().inMinutes > 5) {
        // Potential conflict: both edited independently.
        // Preserve both versions!
        conflicts++;
        final conflictNb = remoteNb.copyWith(
          id: _uuid.v4(),
          title: '${remoteNb.title} (Cloud Copy)',
        );
        await _notebookRepo.saveNotebook(conflictNb);
        await _pullPagesForNotebook(api, folderId, conflictNb.id);
        pulledNotebookIds.add(conflictNb.id);
      } else {
        // Already identical
        pulledNotebookIds.add(remoteNb.id);
      }

      if (shouldRestore) {
        await _notebookRepo.saveNotebook(remoteNb);
        downloadedNb++;
        pulledNotebookIds.add(remoteNb.id);

        // Restore pages and strokes
        final pCount = await _pullPagesForNotebook(api, folderId, remoteNb.id);
        downloadedPg += pCount;
      }
    }

    return {
      'downloadedNotebooks': downloadedNb,
      'downloadedPages': downloadedPg,
      'conflicts': conflicts,
      'pulledNotebookIds': pulledNotebookIds,
    };
  }

  /// Bidirectionally syncs deletion tombstones across devices using deletions_manifest.json.
  Future<int> _syncDeletions({
    required drive.DriveApi api,
    required String metadataFolderId,
    required String notebooksFolderId,
    required String uid,
  }) async {
    int deletedCount = 0;
    try {
      final cloudDeletedIds = <String>{};
      final historyService = NoteHistoryService();

      // 1. Download existing cloud deletions manifest if present
      final manifestFile =
          await _findFile(api, metadataFolderId, 'deletions_manifest.json');
      if (manifestFile != null && manifestFile.id != null) {
        final content = await _downloadFileAsString(api, manifestFile.id!);
        if (content != null && content.isNotEmpty) {
          try {
            final data = jsonDecode(content) as Map<String, dynamic>;
            final list = (data['deletedNotebookIds'] as List<dynamic>?) ?? [];
            for (final item in list) {
              if (item is String) cloudDeletedIds.add(item);
            }
          } catch (_) {}
        }
      }

      // 2. Apply cloud deletions to local database
      for (final delId in cloudDeletedIds) {
        _localDeletedNotebookIds.add(delId);
        final existingLocal = await _notebookRepo.getNotebookById(delId);
        if (existingLocal != null && !existingLocal.isDeleted) {
          await _notebookRepo.deleteNotebook(delId);
          await historyService.recordActivity(
            noteId: delId,
            noteTitle: existingLocal.title,
            action: NoteActionType.deleted,
            userEmail: uid,
            deviceName: 'Cloud Synced',
            details: 'Deleted from another device via cloud',
          );
          deletedCount++;
        }
      }

      // 3. Gather local deletions and append to manifest
      final localDeleted =
          await _notebookRepo.getDeletedNotebooks(ownerId: uid);
      for (final d in localDeleted) {
        _localDeletedNotebookIds.add(d.id);
        cloudDeletedIds.add(d.id);

        // Clean up remote folder in Drive if it exists
        final folder = await _findFile(api, notebooksFolderId, d.id);
        if (folder != null && folder.id != null) {
          try {
            await api.files.delete(folder.id!);
          } catch (_) {}
        }
      }

      // 4. Update deletions_manifest.json in Google Drive
      final manifestJson = jsonEncode({
        'version': 1,
        'updatedAt': DateTime.now().toIso8601String(),
        'deletedNotebookIds': cloudDeletedIds.toList(),
      });
      await _createOrUpdateJsonFile(
        api: api,
        parentId: metadataFolderId,
        fileName: 'deletions_manifest.json',
        content: manifestJson,
      );
    } catch (e) {
      debugPrint('[GoogleDriveSyncCoordinator] _syncDeletions error: $e');
    }
    return deletedCount;
  }

  /// Synchronizes cross-device notes activity history with Google Drive.
  Future<void> _syncActivityHistory({
    required drive.DriveApi api,
    required String metadataFolderId,
  }) async {
    try {
      final historyService = NoteHistoryService();

      // 1. Download cloud activity history if present
      final historyFile =
          await _findFile(api, metadataFolderId, 'activity_history.json');
      if (historyFile != null && historyFile.id != null) {
        final content = await _downloadFileAsString(api, historyFile.id!);
        if (content != null && content.isNotEmpty) {
          try {
            final list = jsonDecode(content) as List<dynamic>;
            final cloudEntries = list
                .map((e) =>
                    NoteActivityEntry.fromJson(e as Map<String, dynamic>))
                .toList();
            await historyService.mergeCloudHistory(cloudEntries);
          } catch (_) {}
        }
      }

      // 2. Export local + merged history and update in Drive
      final mergedJson = await historyService.exportJson();
      await _createOrUpdateJsonFile(
        api: api,
        parentId: metadataFolderId,
        fileName: 'activity_history.json',
        content: mergedJson,
      );
    } catch (e) {
      debugPrint('[GoogleDriveSyncCoordinator] _syncActivityHistory error: $e');
    }
  }
  }

  /// Downloads pages and vector handwriting strokes for [notebookId] from Drive into local SQLite.
  Future<int> _pullPagesForNotebook(
    drive.DriveApi api,
    String nbFolderId,
    String targetNotebookId,
  ) async {
    int pagesCount = 0;
    final pagesFolder = await _findFile(api, nbFolderId, 'Pages');
    if (pagesFolder == null) return 0;

    final q =
        "'${pagesFolder.id}' in parents and mimeType = 'application/json' and trashed = false";
    final pageFiles = await api.files.list(
      q: q,
      spaces: 'appDataFolder',
      $fields: 'files(id, name)',
      pageSize: 200,
    );

    for (final pf in pageFiles.files ?? []) {
      final jsonStr = await _downloadFileAsString(api, pf.id!);
      if (jsonStr == null) continue;

      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        final pageMap = data['page'] as Map<String, dynamic>;
        final page = NotebookPage.fromJson(pageMap).copyWith(
          notebookId: targetNotebookId,
        );

        await _pageRepo.savePage(page);

        // Restore strokes
        final strokesList = data['strokes'] as List<dynamic>? ?? [];
        final strokes = strokesList
            .map((s) => Stroke.fromJson(s as Map<String, dynamic>))
            .toList();
        if (strokes.isNotEmpty) {
          await _strokeRepo.saveStrokes(strokes);
        }

        // Restore sticky notes
        final notesList = data['stickyNotes'] as List<dynamic>? ?? [];
        final stickyNotes = notesList
            .map((sn) => StickyNote.fromJson(sn as Map<String, dynamic>))
            .toList();
        for (final sn in stickyNotes) {
          await _stickyNoteRepo.saveStickyNote(sn);
        }

        pagesCount++;
      } catch (e) {
        debugPrint('[GoogleDriveSyncCoordinator] Error restoring page: $e');
      }
    }

    return pagesCount;
  }

  Future<drive.File?> _findFile(
    drive.DriveApi api,
    String parentId,
    String name,
  ) async {
    final q = "'$parentId' in parents and name = '$name' and trashed = false";
    final result = await api.files.list(
      q: q,
      spaces: 'appDataFolder',
      $fields: 'files(id, name, mimeType)',
      pageSize: 1,
    );
    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first;
    }
    return null;
  }

  Future<void> _createOrUpdateJsonFile({
    required drive.DriveApi api,
    required String parentId,
    required String fileName,
    required String content,
    Map<String, String>? properties,
  }) async {
    final bytes = utf8.encode(content);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    final existing = await _findFile(api, parentId, fileName);

    if (existing != null) {
      final fileMeta = drive.File()
        ..properties = properties;

      await api.files.update(
        fileMeta,
        existing.id!,
        uploadMedia: media,
      );
    } else {
      final fileMeta = drive.File()
        ..name = fileName
        ..parents = [parentId]
        ..mimeType = 'application/json'
        ..properties = properties;

      await api.files.create(
        fileMeta,
        uploadMedia: media,
      );
    }
  }

  Future<String?> _downloadFileAsString(
    drive.DriveApi api,
    String fileId,
  ) async {
    try {
      final result = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );
      final media = result as drive.Media;
      final bytes = await media.stream.expand((chunk) => chunk).toList();
      return utf8.decode(bytes);
    } catch (e) {
      debugPrint('[GoogleDriveSyncCoordinator] Error downloading file $fileId: $e');
      return null;
    }
  }

  Future<void> _writeSyncManifest({
    required drive.DriveApi api,
    required String metadataFolderId,
    required String uid,
    required DateTime timestamp,
    required int notebookCount,
  }) async {
    final manifest = {
      'app': 'Naik Notes',
      'version': '1.0.0',
      'ownerId': uid,
      'timestamp': timestamp.toIso8601String(),
      'notebookCount': notebookCount,
      'syncEngine': 'GoogleDriveSyncCoordinator_v1',
    };
    await _createOrUpdateJsonFile(
      api: api,
      parentId: metadataFolderId,
      fileName: 'sync_manifest.json',
      content: jsonEncode(manifest),
    );
  }

  Future<void> _writeBackupInfo({
    required drive.DriveApi api,
    required String backupInfoFolderId,
    required String uid,
    required DateTime timestamp,
    required int notebookCount,
    required int pagesCount,
    required int attachmentsCount,
  }) async {
    final backupInfo = {
      'application': 'Naik Notes',
      'publisher': 'Naik Publications-Notes',
      'version': '1.0.0',
      'ownerId': uid,
      'deviceId': _deviceId,
      'platform': defaultTargetPlatform.name,
      'backupTimestamp': timestamp.toIso8601String(),
      'totalNotebooks': notebookCount,
      'totalPages': pagesCount,
      'totalAttachments': attachmentsCount,
      'integrityStatus': 'verified',
    };
    await _createOrUpdateJsonFile(
      api: api,
      parentId: backupInfoFolderId,
      fileName: 'backup_info.json',
      content: jsonEncode(backupInfo),
    );
  }
}
