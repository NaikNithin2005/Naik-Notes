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
    this.errorMessage,
    required this.timestamp,
  });

  @override
  String toString() =>
      'GoogleDriveSyncResult(success: $success, upNb: $uploadedNotebooks, downNb: $downloadedNotebooks, '
      'upPg: $uploadedPages, downPg: $downloadedPages, upAtt: $uploadedAttachments, conflicts: $conflictCount, err: $errorMessage)';
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
  })  : _authService = authService,
        _storageService = storageService,
        _notebookRepo = notebookRepo,
        _pageRepo = pageRepo,
        _strokeRepo = strokeRepo,
        _stickyNoteRepo = stickyNoteRepo,
        _attachmentRepo = attachmentRepo,
        _baseHttpClient = httpClient ?? http.Client(),
        _uuid = uuid ?? const Uuid();

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

      // -------------------------------------------------------------
      // 1. LOCAL -> DRIVE: Push modified local notebooks & pages
      // -------------------------------------------------------------
      onProgress?.call('Checking local notebooks...', 0.15);
      final localNotebooks = await _notebookRepo.getAllNotebooks(
        ownerId: uid,
        includeArchived: true,
      );
      final totalLocal = localNotebooks.length;

      for (int i = 0; i < totalLocal; i++) {
        final nb = localNotebooks[i];
        final progress = 0.2 + (0.4 * (i / (totalLocal == 0 ? 1 : totalLocal)));
        onProgress?.call(
          'Backing up notebook: ${nb.title} (${i + 1}/$totalLocal)...',
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
      // 2. DRIVE -> LOCAL: Pull new/updated remote notebooks
      // -------------------------------------------------------------
      onProgress?.call('Checking cloud updates...', 0.65);
      final pullRes = await _pullNotebooksFromDrive(
        api: api,
        notebooksFolderId: notebooksFolderId,
        uid: uid,
        localNotebooks: localNotebooks,
        onProgress: onProgress,
      );

      downNb = pullRes['downloadedNotebooks'] as int? ?? 0;
      downPg = pullRes['downloadedPages'] as int? ?? 0;
      conflicts = pullRes['conflicts'] as int? ?? 0;

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
      // 4. WRITE SYNC MANIFEST
      // -------------------------------------------------------------
      onProgress?.call('Writing sync manifest...', 0.95);
      await _writeSyncManifest(
        api: api,
        metadataFolderId: folders['metadata']!,
        uid: uid,
        timestamp: now,
        notebookCount: localNotebooks.length,
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

    // 4. Upload/Update Pages and vector handwriting strokes
    int pagesUploaded = 0;
    final pages = await _pageRepo.getPagesForNotebook(notebook.id);

    for (final page in pages) {
      final strokes = await _strokeRepo.getStrokesForPage(page.id);
      final stickyNotes = await _stickyNoteRepo.getStickyNotesForPage(page.id);

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

    for (final rf in remoteFolders) {
      final nbId = rf.name!;
      final folderId = rf.id!;

      // Find notebook.json in this folder
      final nbFile = await _findFile(api, folderId, 'notebook.json');
      if (nbFile == null) continue;

      final nbContent = await _downloadFileAsString(api, nbFile.id!);
      if (nbContent == null) continue;

      final nbMap = jsonDecode(nbContent) as Map<String, dynamic>;
      final remoteNb = Notebook.fromJson(nbMap);

      final localNb = localNbMap[nbId];

      bool shouldRestore = false;

      if (localNb == null) {
        // Missing notebook: restore locally
        shouldRestore = true;
      } else if (remoteNb.revision > localNb.revision) {
        // Remote has newer changes
        shouldRestore = true;
      } else if (remoteNb.revision == localNb.revision &&
          remoteNb.updatedAt.isAfter(localNb.updatedAt)) {
        shouldRestore = true;
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
      }

      if (shouldRestore) {
        await _notebookRepo.saveNotebook(remoteNb);
        downloadedNb++;

        // Restore pages and strokes
        final pCount = await _pullPagesForNotebook(api, folderId, remoteNb.id);
        downloadedPg += pCount;
      }
    }

    return {
      'downloadedNotebooks': downloadedNb,
      'downloadedPages': downloadedPg,
      'conflicts': conflicts,
    };
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
}
