import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Production Firebase Storage Service.
/// Handles user-isolated image and document uploads with UID enforcement.
class FirebaseStorageService {
  final FirebaseStorage _storage;

  FirebaseStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads a custom notebook cover image to `users/{uid}/notebooks/{notebookId}/covers/{fileName}`
  /// and returns the public download URL.
  Future<String> uploadNotebookCover({
    required String uid,
    required String notebookId,
    required Uint8List imageBytes,
    String? extension,
  }) async {
    try {
      final ext = extension ?? 'jpg';
      final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final path = 'users/$uid/notebooks/$notebookId/covers/$fileName';

      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
        customMetadata: {
          'ownerId': uid,
          'notebookId': notebookId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = ref.putData(imageBytes, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage Cover Upload Error: $e');
      throw Exception('Failed to upload notebook cover: $e');
    }
  }

  /// Uploads an asset (image, attachment) for a notebook page to
  /// `users/{uid}/notebooks/{notebookId}/pages/{pageId}/{fileName}`
  Future<String> uploadPageAsset({
    required String uid,
    required String notebookId,
    required String pageId,
    required Uint8List bytes,
    required String fileName,
    String contentType = 'image/jpeg',
  }) async {
    try {
      final path = 'users/$uid/notebooks/$notebookId/pages/$pageId/$fileName';
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'ownerId': uid,
          'notebookId': notebookId,
          'pageId': pageId,
        },
      );

      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Firebase Storage Page Asset Upload Error: $e');
      throw Exception('Failed to upload page asset: $e');
    }
  }

  /// Deletes a file from Firebase Storage given its URL.
  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Firebase Storage Delete Note: $e');
    }
  }
}
