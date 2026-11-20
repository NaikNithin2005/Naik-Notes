import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Service for storing custom notebook covers and assets locally in the
/// application documents directory.
class FirebaseStorageService {
  FirebaseStorageService();

  /// Saves a custom notebook cover image to `covers/{uid}/{notebookId}/{fileName}`
  /// and returns the local file path.
  Future<String> uploadNotebookCover({
    required String uid,
    required String notebookId,
    required Uint8List imageBytes,
    String? extension,
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, 'covers', uid, notebookId));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final ext = extension ?? 'jpg';
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(imageBytes);
      return file.path;
    } catch (e) {
      debugPrint('Cover Storage Error: $e');
      throw Exception('Failed to save notebook cover: $e');
    }
  }

  /// Saves an asset (image, attachment) for a notebook page to
  /// `assets/{uid}/{notebookId}/{pageId}/{fileName}` and returns the local file path.
  Future<String> uploadPageAsset({
    required String uid,
    required String notebookId,
    required String pageId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(appDir.path, 'assets', uid, notebookId, pageId));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final file = File(p.join(dir.path, fileName));
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('Asset Storage Error: $e');
      throw Exception('Failed to save page asset: $e');
    }
  }

  /// Deletes a local file or cover given its path or URL.
  Future<void> deleteFileByUrl(String url) async {
    try {
      final file = File(url);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Storage Delete Error: $e');
    }
  }
}
