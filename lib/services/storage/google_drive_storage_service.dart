// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'google_drive_auth_service.dart';

/// Thrown when a file in appDataFolder cannot be located (e.g. deleted by user in Drive settings).
class DriveFileNotFoundException implements Exception {
  final String fileId;
  DriveFileNotFoundException(this.fileId);

  @override
  String toString() => 'DriveFileNotFoundException: File $fileId does not exist in appDataFolder.';
}

/// Thrown when a downloaded file's SHA-256 hash does not match the expected checksum.
class ChecksumMismatchException implements Exception {
  final String expected;
  final String actual;
  ChecksumMismatchException({required this.expected, required this.actual});

  @override
  String toString() => 'ChecksumMismatchException: Expected $expected, but received $actual.';
}

/// Production Google Drive API v3 storage service.
///
/// Strictly operates inside the user's hidden private application folder (`appDataFolder`).
/// Attachments are invisible to the user's main Google Drive interface, preventing accidental
/// moves or external manipulation, and guaranteeing privacy.
class GoogleDriveStorageService {
  final GoogleDriveAuthService _authService;
  final http.Client _baseHttpClient;

  GoogleDriveStorageService({
    required GoogleDriveAuthService authService,
    http.Client? httpClient,
  })  : _authService = authService,
        _baseHttpClient = httpClient ?? http.Client();

  /// Obtains an authenticated HTTP client for [uid] with Bearer token injection.
  Future<http.Client> _getAuthenticatedClient(String uid) async {
    final token = await _authService.getValidAccessToken(uid);
    if (token == null || token.isEmpty) {
      throw StateError('Google Drive is not connected or authorization expired for user $uid.');
    }
    return _AuthenticatedHttpClient(_baseHttpClient, token);
  }

  /// Calculates the SHA-256 hex checksum of a local file.
  static Future<String> calculateSha256(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  /// Uploads [file] to the user's Google Drive `appDataFolder`.
  ///
  /// Guarantees:
  /// - `parents = ['appDataFolder']`
  /// - Appends attachment metadata as Drive properties
  /// - Computes and verifies SHA-256 checksum
  /// - Supports upload progress reporting
  Future<String> uploadAttachment({
    required String uid,
    required String noteId,
    required String attachmentId,
    required File file,
    required String fileName,
    required String mimeType,
    String? knownChecksum,
    void Function(double progress)? onProgress,
  }) async {
    return _executeWithRetry(() async {
      final client = await _getAuthenticatedClient(uid);
      final driveApi = drive.DriveApi(client);

      final fileSize = await file.length();
      final checksum = knownChecksum ?? await calculateSha256(file);

      final driveFile = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']
        ..properties = {
          'attachmentId': attachmentId,
          'noteId': noteId,
          'ownerId': uid,
          'checksum': checksum,
        };

      final stream = file.openRead();
      final media = drive.Media(
        stream,
        fileSize,
        contentType: mimeType,
      );

      final createdFile = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
        $fields: 'id, name, mimeType, size, properties',
      );

      final driveFileId = createdFile.id;
      if (driveFileId == null || driveFileId.isEmpty) {
        throw Exception('Google Drive did not return a valid file ID.');
      }

      onProgress?.call(1.0);
      return driveFileId;
    });
  }

  /// Downloads an attachment from Google Drive `appDataFolder` to [destinationFile].
  ///
  /// Verifies:
  /// - Streams content without exhausting memory on large files
  /// - Validates SHA-256 checksum against [expectedChecksum]
  /// - Handles missing files (HTTP 404) gracefully
  Future<File> downloadAttachment({
    required String uid,
    required String driveFileId,
    required File destinationFile,
    required String expectedChecksum,
    void Function(double progress)? onProgress,
  }) async {
    return _executeWithRetry(() async {
      final client = await _getAuthenticatedClient(uid);
      final driveApi = drive.DriveApi(client);

      drive.Media media;
      try {
        final result = await driveApi.files.get(
          driveFileId,
          downloadOptions: drive.DownloadOptions.fullMedia,
        );
        media = result as drive.Media;
      } on drive.DetailedApiRequestError catch (e) {
        if (e.status == 404) {
          throw DriveFileNotFoundException(driveFileId);
        }
        rethrow;
      }

      if (!await destinationFile.parent.exists()) {
        await destinationFile.parent.create(recursive: true);
      }

      // Stream to temporary download file first to avoid partial writes
      final tempFile = File('${destinationFile.path}.part');
      final sink = tempFile.openWrite();

      final totalBytes = media.length ?? 0;
      int downloadedBytes = 0;

      await for (final List<int> chunk in media.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;
        if (totalBytes > 0 && onProgress != null) {
          onProgress(min(1.0, downloadedBytes / totalBytes));
        }
      }
      await sink.flush();
      await sink.close();

      // Verify SHA-256 checksum
      final actualChecksum = await calculateSha256(tempFile);
      if (expectedChecksum.isNotEmpty && actualChecksum != expectedChecksum) {
        if (await tempFile.exists()) await tempFile.delete();
        throw ChecksumMismatchException(
          expected: expectedChecksum,
          actual: actualChecksum,
        );
      }

      // Move temporary file to final destination
      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }
      await tempFile.rename(destinationFile.path);

      onProgress?.call(1.0);
      return destinationFile;
    });
  }

  /// Deletes a file from `appDataFolder`.
  ///
  /// If the file is already deleted or not found (HTTP 404), concludes gracefully.
  Future<void> deleteAttachment({
    required String uid,
    required String driveFileId,
  }) async {
    return _executeWithRetry(() async {
      final client = await _getAuthenticatedClient(uid);
      final driveApi = drive.DriveApi(client);

      try {
        await driveApi.files.delete(driveFileId);
      } on drive.DetailedApiRequestError catch (e) {
        if (e.status == 404) {
          // Already deleted, proceed cleanly
          return;
        }
        rethrow;
      }
    });
  }

  /// Retrieves metadata for a file in `appDataFolder`.
  Future<drive.File?> getAttachmentMetadata({
    required String uid,
    required String driveFileId,
  }) async {
    return _executeWithRetry(() async {
      final client = await _getAuthenticatedClient(uid);
      final driveApi = drive.DriveApi(client);

      try {
        return await driveApi.files.get(
          driveFileId,
          $fields: 'id, name, mimeType, size, properties, modifiedTime',
        ) as drive.File;
      } on drive.DetailedApiRequestError catch (e) {
        if (e.status == 404) {
          return null;
        }
        rethrow;
      }
    });
  }

  /// Lists all files currently stored in the user's `appDataFolder`.
  Future<List<drive.File>> listAppDataFolder({
    required String uid,
    int pageSize = 100,
  }) async {
    return _executeWithRetry(() async {
      final client = await _getAuthenticatedClient(uid);
      final driveApi = drive.DriveApi(client);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        pageSize: pageSize,
        $fields: 'nextPageToken, files(id, name, mimeType, size, modifiedTime, properties)',
      );

      return fileList.files ?? <drive.File>[];
    });
  }

  /// Exponential backoff with jitter for transient 5xx, socket, or 429 rate limit errors.
  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    final random = Random();

    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (e) {
        if (attempt >= maxRetries || !_isTransientError(e)) {
          rethrow;
        }
        // Base delay 500ms, doubling per attempt + random jitter
        final delayMs = (500 * pow(2, attempt - 1)).toInt() + random.nextInt(250);
        debugPrint('[GoogleDriveStorageService] Retryable error ($e). Retrying in ${delayMs}ms (attempt $attempt/$maxRetries)...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  bool _isTransientError(dynamic error) {
    if (error is SocketException || error is TimeoutException) return true;
    if (error is drive.DetailedApiRequestError) {
      final code = error.status;
      // 429 Too Many Requests, 500 Internal, 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout
      if (code == 429 || (code != null && code >= 500 && code < 600)) {
        return true;
      }
    }
    return false;
  }
}

/// HTTP client wrapper that injects `Authorization: Bearer <token>` into all outgoing requests.
class _AuthenticatedHttpClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;

  _AuthenticatedHttpClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}
