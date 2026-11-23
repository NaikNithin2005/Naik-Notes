// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../features/storage/data/google_drive_provider.dart';
import 'google_drive_auth_service.dart';
import 'google_drive_storage_service.dart';

/// Result summary of a cover image upload operation.
class CoverUploadResult {
  final String driveFileId;
  final String fileName;
  final String localPath;
  final DateTime updatedAt;

  const CoverUploadResult({
    required this.driveFileId,
    required this.fileName,
    required this.localPath,
    required this.updatedAt,
  });
}

/// HTTP client wrapper injecting Bearer token into outgoing Google Drive requests.
class _DriveBearerClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;

  _DriveBearerClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}

/// Centralized service for notebook cover images: compression, Google Drive appDataFolder
/// upload/download, local deterministic caching, and in-flight download deduplication.
class CoverImageService {
  final GoogleDriveAuthService _authService;
  final GoogleDriveStorageService _storageService;
  final http.Client _baseHttpClient;
  final Future<Directory> Function()? _cacheDirProvider;

  final Map<String, Future<File?>> _inFlightDownloads = {};
  Directory? _cachedDir;

  CoverImageService({
    required GoogleDriveAuthService authService,
    required GoogleDriveStorageService storageService,
    http.Client? httpClient,
    Future<Directory> Function()? cacheDirProvider,
  })  : _authService = authService,
        _storageService = storageService,
        _baseHttpClient = httpClient ?? http.Client(),
        _cacheDirProvider = cacheDirProvider;

  /// Obtains the local cache directory for notebook covers.
  Future<Directory> getCacheDirectory() async {
    final customProvider = _cacheDirProvider;
    if (customProvider != null) {
      final dir = await customProvider();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    }
    if (_cachedDir != null && await _cachedDir!.exists()) {
      return _cachedDir!;
    }
    final baseDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(baseDir.path, 'naik_covers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedDir = dir;
    return dir;
  }

  /// Returns the deterministic cache file for a given Drive file ID.
  Future<File> getCachedCoverFile(String driveFileId, {String extension = 'jpg'}) async {
    final dir = await getCacheDirectory();
    final cleanExt = extension.replaceAll('.', '');
    return File(p.join(dir.path, 'cover_$driveFileId.$cleanExt'));
  }

  /// Checks if a cover image is already cached on the local filesystem.
  Future<File?> getLocallyCachedCover(String driveFileId, {String extension = 'jpg'}) async {
    try {
      final file = await getCachedCoverFile(driveFileId, extension: extension);
      if (await file.exists() && (await file.length()) > 0) {
        return file;
      }
    } catch (_) {}
    return null;
  }

  /// Compresses raw image bytes to ensure cross-device network efficiency.
  Uint8List compressCoverImage(Uint8List rawBytes) {
    try {
      final decoded = img.decodeImage(rawBytes);
      if (decoded == null) return rawBytes;

      img.Image resized = decoded;
      if (decoded.width > 1200 || decoded.height > 1600) {
        resized = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 1200 : null,
          height: decoded.height > decoded.width ? 1600 : null,
          interpolation: img.Interpolation.linear,
        );
      }
      return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
    } catch (e) {
      debugPrint('[CoverImageService] Image compression notice: $e');
      return rawBytes;
    }
  }

  /// Compresses cover image bytes to a max width of 400px (quality 75 JPEG)
  /// and converts to a Base64 string for seamless Cloud Firestore cross-device syncing.
  /// Runs inside compute() isolate to keep the UI thread completely unblocked.
  static Future<String> encodeCoverImageToBase64(Uint8List rawBytes) async {
    return compute(_isolateCompressAndEncodeBase64, rawBytes);
  }

  static String _isolateCompressAndEncodeBase64(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Failed to decode image bytes for cover compression');
    }
    img.Image resized = decoded;
    if (decoded.width > 400) {
      resized = img.copyResize(decoded, width: 400);
    }
    final compressed = img.encodeJpg(resized, quality: 75);
    return base64Encode(compressed);
  }

  /// Uploads a notebook cover to Google Drive `appDataFolder` and caches locally.
  /// Also cleans up the previous Drive cover if replacing an existing one.
  Future<CoverUploadResult> uploadCoverImage({
    required String uid,
    required String notebookId,
    required Uint8List rawBytes,
    String? extension,
    String? previousDriveFileId,
  }) async {
    final ext = (extension ?? 'jpg').replaceAll('.', '');
    final compressed = compressCoverImage(rawBytes);

    String? token;
    try {
      token = await _authService.getValidAccessToken(uid);
    } catch (e) {
      debugPrint('[CoverImageService] Auth token check: $e');
    }

    String driveFileId;
    final fileName = 'cover_${notebookId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    if (token != null && token.isNotEmpty) {
      final authClient = _DriveBearerClient(_baseHttpClient, token);
      final driveApi = drive.DriveApi(authClient);

      final mimeType = ext.toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';
      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']
        ..properties = {
          'ownerId': uid,
          'notebookId': notebookId,
          'type': 'notebook_cover',
        };

      final media = drive.Media(
        Stream.value(compressed),
        compressed.length,
        contentType: mimeType,
      );

      final created = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, mimeType',
      );

      driveFileId = created.id ?? 'local_${DateTime.now().millisecondsSinceEpoch}';

      // Clean up previous Drive cover file if different
      if (previousDriveFileId != null &&
          previousDriveFileId.isNotEmpty &&
          previousDriveFileId != driveFileId &&
          !previousDriveFileId.startsWith('local_')) {
        try {
          await _storageService.deleteAttachment(
            uid: uid,
            driveFileId: previousDriveFileId,
          );
        } catch (e) {
          debugPrint('[CoverImageService] Cleanup previous cover: $e');
        }
      }
    } else {
      // Offline fallback: assign a local deterministic id
      driveFileId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    }

    // Always cache the compressed file locally
    final cachedFile = await getCachedCoverFile(driveFileId, extension: ext);
    await cachedFile.writeAsBytes(compressed, flush: true);

    return CoverUploadResult(
      driveFileId: driveFileId,
      fileName: fileName,
      localPath: cachedFile.path,
      updatedAt: DateTime.now(),
    );
  }

  /// Downloads and caches a cover image from Google Drive using [driveFileId].
  /// Returns the local cached [File] or null if unavailable.
  Future<File?> getCoverImageFile({
    required String uid,
    required String driveFileId,
    String extension = 'jpg',
  }) async {
    if (driveFileId.isEmpty) return null;

    // 1. Fast local cache check
    final localFile = await getLocallyCachedCover(driveFileId, extension: extension);
    if (localFile != null) return localFile;

    // If it's a purely local offline ID, we cannot download it from Drive
    if (driveFileId.startsWith('local_')) return null;

    // 2. In-flight download deduplication
    if (_inFlightDownloads.containsKey(driveFileId)) {
      return _inFlightDownloads[driveFileId];
    }

    final downloadFuture = _downloadAndCache(
      uid: uid,
      driveFileId: driveFileId,
      extension: extension,
    );

    _inFlightDownloads[driveFileId] = downloadFuture;

    try {
      return await downloadFuture;
    } finally {
      _inFlightDownloads.remove(driveFileId);
    }
  }

  Future<File?> _downloadAndCache({
    required String uid,
    required String driveFileId,
    required String extension,
  }) async {
    try {
      final token = await _authService.getValidAccessToken(uid);
      if (token == null || token.isEmpty) return null;

      final authClient = _DriveBearerClient(_baseHttpClient, token);
      final driveApi = drive.DriveApi(authClient);

      final result = await driveApi.files.get(
        driveFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      final media = result as drive.Media;
      final cachedFile = await getCachedCoverFile(driveFileId, extension: extension);
      final tempFile = File('${cachedFile.path}.tmp');

      if (!await tempFile.parent.exists()) {
        await tempFile.parent.create(recursive: true);
      }

      final sink = tempFile.openWrite();
      await for (final chunk in media.stream) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();

      if (await cachedFile.exists()) {
        await cachedFile.delete();
      }
      await tempFile.rename(cachedFile.path);
      return cachedFile;
    } catch (e) {
      debugPrint('[CoverImageService] Download cover error ($driveFileId): $e');
      return null;
    }
  }

  /// Clears cached cover image files.
  Future<void> clearCache({String? driveFileId}) async {
    try {
      if (driveFileId != null) {
        final file = await getCachedCoverFile(driveFileId);
        if (await file.exists()) await file.delete();
      } else {
        final dir = await getCacheDirectory();
        if (await dir.exists()) {
          await dir.delete(recursive: true);
          _cachedDir = null;
        }
      }
    } catch (e) {
      debugPrint('[CoverImageService] clearCache error: $e');
    }
  }
}

/// Global provider for [CoverImageService].
final coverImageServiceProvider = Provider<CoverImageService>((ref) {
  final authService = ref.watch(googleDriveAuthServiceProvider);
  final storageService = ref.watch(googleDriveStorageServiceProvider);
  return CoverImageService(
    authService: authService,
    storageService: storageService,
  );
});
