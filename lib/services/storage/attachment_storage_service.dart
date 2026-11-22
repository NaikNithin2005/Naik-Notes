import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Categories of attachments stored in Naik Notes.
enum AttachmentCategory {
  images,
  documents,
  pdfs,
  sketches,
  thumbnails,
  temporary,
}

/// Result of local attachment import and processing.
class ProcessedAttachmentResult {
  final String localId;
  final File file;
  final File? thumbnailFile;
  final String fileName;
  final String mimeType;
  final int fileSize;
  final String checksum;
  final AttachmentCategory category;

  const ProcessedAttachmentResult({
    required this.localId,
    required this.file,
    this.thumbnailFile,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.checksum,
    required this.category,
  });
}

/// Service managing local-first attachment storage, subdirectories,
/// image compression, resizing, and thumbnail generation.
class AttachmentStorageService {
  final Uuid _uuid;
  final Future<Directory> Function()? _baseDirProvider;

  AttachmentStorageService({
    Uuid? uuid,
    Future<Directory> Function()? baseDirectoryProvider,
  })  : _uuid = uuid ?? const Uuid(),
        _baseDirProvider = baseDirectoryProvider;

  /// Sanitizes user ID for safe directory naming.
  static String sanitizeUid(String uid) {
    final sanitized = uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final cleaned = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
    return cleaned.isEmpty ? 'local_user' : cleaned;
  }

  /// Returns the base directory for attachments under application documents.
  Future<Directory> getBaseAttachmentsDirectory(String uid) async {
    final baseDocs = _baseDirProvider != null
        ? await _baseDirProvider()
        : await getApplicationDocumentsDirectory();
    final sanitized = sanitizeUid(uid);
    final userBase = Directory(p.join(baseDocs.path, 'users', sanitized, 'attachments'));
    if (!await userBase.exists()) {
      await userBase.create(recursive: true);
    }
    return userBase;
  }

  /// Returns the specific subfolder for an attachment category.
  Future<Directory> getCategoryDirectory(String uid, AttachmentCategory category) async {
    final base = await getBaseAttachmentsDirectory(uid);
    final categoryDir = Directory(p.join(base.path, category.name));
    if (!await categoryDir.exists()) {
      await categoryDir.create(recursive: true);
    }
    return categoryDir;
  }

  /// Ensures all category directories are initialized for [uid].
  Future<void> initializeDirectories(String uid) async {
    for (final category in AttachmentCategory.values) {
      await getCategoryDirectory(uid, category);
    }
  }

  /// Resolves the category based on MIME type and file extension.
  AttachmentCategory resolveCategory({
    required String fileName,
    String? mimeType,
    bool isSketch = false,
  }) {
    if (isSketch) return AttachmentCategory.sketches;

    final resolvedMime = mimeType ?? lookupMimeType(fileName) ?? '';
    final ext = p.extension(fileName).toLowerCase();

    if (resolvedMime == 'application/pdf' || ext == '.pdf') {
      return AttachmentCategory.pdfs;
    }

    if (resolvedMime.startsWith('image/') ||
        ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'].contains(ext)) {
      return AttachmentCategory.images;
    }

    return AttachmentCategory.documents;
  }

  /// Computes SHA-256 checksum for a file.
  static Future<String> calculateSha256(File file) async {
    final stream = file.openRead();
    final digest = await sha256.bind(stream).first;
    return digest.toString();
  }

  /// Computes SHA-256 checksum for byte data.
  static String calculateBytesSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Imports and processes a source file into the local attachment storage.
  ///
  /// - Generates a unique localId.
  /// - Copies and compresses images (max 1920px dimension, ~80% JPEG quality, preserves PNG transparency).
  /// - Generates thumbnail for images.
  /// - Computes SHA-256 checksum and size.
  Future<ProcessedAttachmentResult> importFile({
    required String uid,
    required File sourceFile,
    required String fileName,
    String? mimeType,
    bool isSketch = false,
    bool compressImage = true,
  }) async {
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file does not exist', sourceFile.path);
    }

    final localId = _uuid.v4();
    final category = resolveCategory(
      fileName: fileName,
      mimeType: mimeType,
      isSketch: isSketch,
    );
    final targetDir = await getCategoryDirectory(uid, category);
    final ext = p.extension(fileName).toLowerCase();
    final resolvedMime = mimeType ?? lookupMimeType(fileName) ?? 'application/octet-stream';

    File destinationFile;
    File? thumbnailFile;

    if (category == AttachmentCategory.images || category == AttachmentCategory.sketches) {
      // Process image (resize/compress & thumbnail)
      final rawBytes = await sourceFile.readAsBytes();
      final processResult = await _processImage(
        rawBytes: rawBytes,
        ext: ext,
        destinationDir: targetDir,
        localId: localId,
        compress: compressImage,
      );

      destinationFile = processResult.mainFile;

      // Generate thumbnail
      thumbnailFile = await _generateImageThumbnail(
        uid: uid,
        imageBytes: rawBytes,
        localId: localId,
      );
    } else {
      // PDF or general document: copy directly to category folder
      final destinationPath = p.join(targetDir.path, '${localId}_$fileName');
      destinationFile = await sourceFile.copy(destinationPath);
    }

    final checksum = await calculateSha256(destinationFile);
    final fileSize = await destinationFile.length();

    return ProcessedAttachmentResult(
      localId: localId,
      file: destinationFile,
      thumbnailFile: thumbnailFile,
      fileName: fileName,
      mimeType: resolvedMime,
      fileSize: fileSize,
      checksum: checksum,
      category: category,
    );
  }

  /// Imports in-memory bytes (e.g. from sketching canvas or camera capture).
  Future<ProcessedAttachmentResult> importBytes({
    required String uid,
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
    bool isSketch = false,
  }) async {
    final localId = _uuid.v4();
    final category = resolveCategory(
      fileName: fileName,
      mimeType: mimeType,
      isSketch: isSketch,
    );
    final targetDir = await getCategoryDirectory(uid, category);
    final ext = p.extension(fileName).toLowerCase();
    final resolvedMime = mimeType ?? lookupMimeType(fileName) ?? 'image/png';

    File destinationFile;
    File? thumbnailFile;

    if (category == AttachmentCategory.images || category == AttachmentCategory.sketches) {
      final processResult = await _processImage(
        rawBytes: bytes,
        ext: ext.isNotEmpty ? ext : '.png',
        destinationDir: targetDir,
        localId: localId,
        compress: !isSketch, // keep sketch sharp, compress if photo
      );
      destinationFile = processResult.mainFile;

      thumbnailFile = await _generateImageThumbnail(
        uid: uid,
        imageBytes: bytes,
        localId: localId,
      );
    } else {
      final destinationPath = p.join(targetDir.path, '${localId}_$fileName');
      destinationFile = File(destinationPath);
      await destinationFile.writeAsBytes(bytes);
    }

    final checksum = await calculateSha256(destinationFile);
    final fileSize = await destinationFile.length();

    return ProcessedAttachmentResult(
      localId: localId,
      file: destinationFile,
      thumbnailFile: thumbnailFile,
      fileName: fileName,
      mimeType: resolvedMime,
      fileSize: fileSize,
      checksum: checksum,
      category: category,
    );
  }

  /// Resizes and compresses image if needed.
  Future<({File mainFile})> _processImage({
    required Uint8List rawBytes,
    required String ext,
    required Directory destinationDir,
    required String localId,
    required bool compress,
  }) async {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) {
      // If decoding fails, fall back to writing raw bytes
      final fallbackPath = p.join(destinationDir.path, '$localId$ext');
      final fallbackFile = File(fallbackPath);
      await fallbackFile.writeAsBytes(rawBytes);
      return (mainFile: fallbackFile);
    }

    // Check dimensions (max 1920px dimension)
    img.Image processed = decoded;
    const maxDimension = 1920;
    if (processed.width > maxDimension || processed.height > maxDimension) {
      if (processed.width >= processed.height) {
        processed = img.copyResize(processed, width: maxDimension);
      } else {
        processed = img.copyResize(processed, height: maxDimension);
      }
    }

    Uint8List encodedBytes;
    String targetExt = ext;

    if (ext == '.png') {
      // Preserve transparency for PNG
      encodedBytes = Uint8List.fromList(img.encodePng(processed));
    } else if (ext == '.webp') {
      encodedBytes = Uint8List.fromList(img.encodePng(processed));
      targetExt = '.png';
    } else {
      // JPEG / other images: compress at ~80% quality
      final quality = compress ? 80 : 90;
      encodedBytes = Uint8List.fromList(img.encodeJpg(processed, quality: quality));
      targetExt = '.jpg';
    }

    final filePath = p.join(destinationDir.path, '$localId$targetExt');
    final file = File(filePath);
    await file.writeAsBytes(encodedBytes);

    return (mainFile: file);
  }

  /// Generates a 256px thumbnail for an image.
  Future<File?> _generateImageThumbnail({
    required String uid,
    required Uint8List imageBytes,
    required String localId,
  }) async {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) return null;

      const thumbMax = 256;
      img.Image thumb;
      if (decoded.width >= decoded.height) {
        thumb = img.copyResize(decoded, width: thumbMax);
      } else {
        thumb = img.copyResize(decoded, height: thumbMax);
      }

      final thumbBytes = img.encodeJpg(thumb, quality: 75);
      final thumbDir = await getCategoryDirectory(uid, AttachmentCategory.thumbnails);
      final thumbPath = p.join(thumbDir.path, '${localId}_thumb.jpg');
      final thumbFile = File(thumbPath);
      await thumbFile.writeAsBytes(thumbBytes);
      return thumbFile;
    } catch (e) {
      debugPrint('[AttachmentStorageService] Thumbnail generation failed: $e');
      return null;
    }
  }

  /// Safely deletes a local attachment file if it exists.
  Future<void> deleteLocalFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[AttachmentStorageService] Error deleting local file $filePath: $e');
    }
  }
}

/// Riverpod provider for [AttachmentStorageService].
final attachmentStorageServiceProvider = Provider<AttachmentStorageService>((ref) {
  return AttachmentStorageService();
});
