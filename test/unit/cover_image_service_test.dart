import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naik_notes/services/storage/cover_image_service.dart';
import 'package:naik_notes/services/storage/google_drive_auth_service.dart';
import 'package:naik_notes/services/storage/google_drive_storage_service.dart';

class _FakeDriveAuthService implements GoogleDriveAuthService {
  String? mockToken = 'mock_valid_access_token_123';

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getValidAccessToken) {
      return Future.value(mockToken);
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeDriveStorageService implements GoogleDriveStorageService {
  String? lastDeletedDriveId;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #deleteAttachment) {
      lastDeletedDriveId = invocation.namedArguments[#driveFileId] as String?;
      return Future.value();
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoverImageService Unit Tests', () {
    late _FakeDriveAuthService authService;
    late _FakeDriveStorageService storageService;
    late CoverImageService coverService;
    late Directory tempDir;

    setUp(() async {
      authService = _FakeDriveAuthService();
      storageService = _FakeDriveStorageService();
      tempDir = await Directory.systemTemp.createTemp('naik_cover_test_');
      coverService = CoverImageService(
        authService: authService,
        storageService: storageService,
        cacheDirProvider: () async => tempDir,
      );
    });

    tearDown(() async {
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    test('deterministic cache filename generation', () async {
      final file = await coverService.getCachedCoverFile('drive_123_abc', extension: 'jpg');
      expect(file.path.endsWith('cover_drive_123_abc.jpg'), isTrue);
    });

    test('compresses large images to reasonable dimensions', () {
      // Create a 2000x2000 image in memory
      final rawImage = img.Image(width: 2000, height: 2000);
      img.fill(rawImage, color: img.ColorRgb8(100, 150, 200));
      final rawBytes = Uint8List.fromList(img.encodeJpg(rawImage));

      final compressed = coverService.compressCoverImage(rawBytes);
      expect(compressed.isNotEmpty, isTrue);

      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width <= 1200, isTrue);
      expect(decoded.height <= 1600, isTrue);
    });

    test('getLocallyCachedCover returns null when file is missing', () async {
      final result = await coverService.getLocallyCachedCover('non_existent_drive_id');
      expect(result, isNull);
    });

    test('getLocallyCachedCover returns existing cached file', () async {
      const driveId = 'drive_cached_test_456';
      final cachedFile = await coverService.getCachedCoverFile(driveId, extension: 'jpg');
      await cachedFile.writeAsBytes([1, 2, 3, 4, 5], flush: true);

      final result = await coverService.getLocallyCachedCover(driveId, extension: 'jpg');
      expect(result, isNotNull);
      expect(result!.path, cachedFile.path);

      // Clean up
      await cachedFile.delete();
    });

    test('clearCache deletes specific or all cached covers', () async {
      const driveId = 'drive_to_delete_789';
      final cachedFile = await coverService.getCachedCoverFile(driveId);
      await cachedFile.writeAsBytes([10, 20, 30], flush: true);

      expect(await cachedFile.exists(), isTrue);

      await coverService.clearCache(driveFileId: driveId);
      expect(await cachedFile.exists(), isFalse);
    });

    test('encodeCoverImageToBase64 compresses to max 400px width and encodes to Base64', () async {
      // Create an 800x600 image in memory
      final rawImage = img.Image(width: 800, height: 600);
      img.fill(rawImage, color: img.ColorRgb8(120, 180, 240));
      final rawBytes = Uint8List.fromList(img.encodePng(rawImage));

      final base64String = await CoverImageService.encodeCoverImageToBase64(rawBytes);
      expect(base64String.isNotEmpty, isTrue);

      final decodedBytes = base64Decode(base64String);
      expect(decodedBytes.isNotEmpty, isTrue);

      final decodedImage = img.decodeImage(decodedBytes);
      expect(decodedImage, isNotNull);
      expect(decodedImage!.width, 400);
      expect(decodedImage.height, 300); // 800x600 scaled to width 400 maintains 4:3 aspect ratio
    });
  });
}
