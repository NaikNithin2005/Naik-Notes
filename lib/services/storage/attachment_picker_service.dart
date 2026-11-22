import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Represents a validated file picked by the user.
class PickedAttachment {
  final File file;
  final String fileName;
  final String mimeType;
  final int fileSize;

  const PickedAttachment({
    required this.file,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });
}

/// Service providing cross-platform file picking and camera capture
/// with extension and file-size validation.
class AttachmentPickerService {
  final ImagePicker _imagePicker;

  AttachmentPickerService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  /// Default supported file extensions for Naik Notes attachments.
  static const List<String> supportedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
    'doc',
    'docx',
    'txt',
  ];

  /// Maximum allowed file size: 50MB.
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  /// Picks one or more attachments using the native file picker.
  ///
  /// Returns an empty list if the user cancels.
  /// Throws an [ArgumentError] if selected file exceeds maximum size or invalid format.
  Future<List<PickedAttachment>> pickAttachments({
    bool allowMultiple = false,
    List<String> allowedExtensions = supportedExtensions,
    int maxSizeBytes = maxFileSizeBytes,
  }) async {
    try {
      final List<PlatformFile> files;
      if (allowMultiple) {
        files = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
      } else {
        final single = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: allowedExtensions,
        );
        files = single != null ? [single] : [];
      }

      if (files.isEmpty) {
        return [];
      }

      final validFiles = <PickedAttachment>[];

      for (final platformFile in files) {
        final path = platformFile.path;
        if (path == null) continue;

        final file = File(path);
        if (!await file.exists()) continue;

        final length = await file.length();
        if (length > maxSizeBytes) {
          final mb = (maxSizeBytes / (1024 * 1024)).toStringAsFixed(0);
          throw ArgumentError(
            'File "${platformFile.name}" exceeds the maximum allowed size of $mb MB.',
          );
        }

        final ext = p.extension(platformFile.name).replaceAll('.', '').toLowerCase();
        if (allowedExtensions.isNotEmpty && !allowedExtensions.contains(ext)) {
          throw ArgumentError('Unsupported file format: .$ext');
        }

        final mime = lookupMimeType(platformFile.name) ?? 'application/octet-stream';

        validFiles.add(
          PickedAttachment(
            file: file,
            fileName: platformFile.name,
            mimeType: mime,
            fileSize: length,
          ),
        );
      }

      return validFiles;
    } catch (e) {
      if (e is ArgumentError) rethrow;
      debugPrint('[AttachmentPickerService] File picking error: $e');
      return [];
    }
  }

  /// Picks a single attachment (convenience wrapper).
  Future<PickedAttachment?> pickSingleAttachment({
    List<String> allowedExtensions = supportedExtensions,
  }) async {
    final list = await pickAttachments(
      allowMultiple: false,
      allowedExtensions: allowedExtensions,
    );
    return list.isNotEmpty ? list.first : null;
  }

  /// Captures a photo directly from device camera on Android and iPadOS/iOS.
  Future<PickedAttachment?> capturePhotoFromCamera() async {
    try {
      final xFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (xFile == null) return null;

      final file = File(xFile.path);
      if (!await file.exists()) return null;

      final length = await file.length();
      final name = p.basename(xFile.path);
      final mime = lookupMimeType(name) ?? 'image/jpeg';

      return PickedAttachment(
        file: file,
        fileName: name,
        mimeType: mime,
        fileSize: length,
      );
    } catch (e) {
      debugPrint('[AttachmentPickerService] Camera capture failed: $e');
      return null;
    }
  }
}

/// Riverpod provider for [AttachmentPickerService].
final attachmentPickerServiceProvider = Provider<AttachmentPickerService>((ref) {
  return AttachmentPickerService();
});
