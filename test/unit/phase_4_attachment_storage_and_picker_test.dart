import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naik_notes/services/storage/attachment_picker_service.dart';
import 'package:naik_notes/services/storage/attachment_storage_service.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AttachmentStorageService storageService;
  late AttachmentPickerService pickerService;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('naik_notes_phase4_');
    storageService = AttachmentStorageService(
      baseDirectoryProvider: () async => tempDir,
    );
    pickerService = AttachmentPickerService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 4: AttachmentStorageService Tests', () {
    test('resolves attachment category accurately from extension and MIME type', () {
      expect(
        storageService.resolveCategory(fileName: 'photo.jpg', mimeType: 'image/jpeg'),
        equals(AttachmentCategory.images),
      );
      expect(
        storageService.resolveCategory(fileName: 'vector.png', mimeType: 'image/png'),
        equals(AttachmentCategory.images),
      );
      expect(
        storageService.resolveCategory(fileName: 'document.pdf', mimeType: 'application/pdf'),
        equals(AttachmentCategory.pdfs),
      );
      expect(
        storageService.resolveCategory(fileName: 'sketch_canvas.png', isSketch: true),
        equals(AttachmentCategory.sketches),
      );
      expect(
        storageService.resolveCategory(fileName: 'lecture_notes.docx'),
        equals(AttachmentCategory.documents),
      );
      expect(
        storageService.resolveCategory(fileName: 'code.txt'),
        equals(AttachmentCategory.documents),
      );
    });

    test('sanitizes user IDs for safe directory structure isolation', () {
      expect(AttachmentStorageService.sanitizeUid('user@example.com'), equals('user_example_com'));
      expect(AttachmentStorageService.sanitizeUid('alice-123_456'), equals('alice-123_456'));
      expect(AttachmentStorageService.sanitizeUid('___'), equals('local_user'));
      expect(AttachmentStorageService.sanitizeUid(''), equals('local_user'));
    });

    test('imports and compresses large images to max 1920 dimension with thumbnail', () async {
      // Create a 2400x1600 test image
      final largeImage = img.Image(width: 2400, height: 1600);
      img.fill(largeImage, color: img.ColorRgb8(200, 100, 50));
      final jpgBytes = img.encodeJpg(largeImage);

      final sourceFile = File(p.join(tempDir.path, 'source_large.jpg'));
      await sourceFile.writeAsBytes(jpgBytes);

      final result = await storageService.importFile(
        uid: 'test_user_p4',
        sourceFile: sourceFile,
        fileName: 'source_large.jpg',
        mimeType: 'image/jpeg',
      );

      expect(result.localId, isNotEmpty);
      expect(result.category, equals(AttachmentCategory.images));
      expect(await result.file.exists(), isTrue);

      // Verify resized dimensions <= 1920
      final decodedProcessed = img.decodeImage(await result.file.readAsBytes());
      expect(decodedProcessed, isNotNull);
      expect(decodedProcessed!.width, lessThanOrEqualTo(1920));
      expect(decodedProcessed.height, lessThanOrEqualTo(1920));

      // Verify thumbnail was created
      expect(result.thumbnailFile, isNotNull);
      expect(await result.thumbnailFile!.exists(), isTrue);
      final decodedThumb = img.decodeImage(await result.thumbnailFile!.readAsBytes());
      expect(decodedThumb, isNotNull);
      expect(decodedThumb!.width, lessThanOrEqualTo(256));
      expect(decodedThumb.height, lessThanOrEqualTo(256));

      // Verify SHA-256 checksum calculation
      expect(result.checksum, isNotEmpty);
      expect(result.checksum.length, equals(64));
    });

    test('imports PNG images preserving transparency', () async {
      final transparentPng = img.Image(width: 400, height: 400, numChannels: 4);
      // Set semi-transparent pixel
      transparentPng.setPixelRgba(10, 10, 255, 0, 0, 128);
      final pngBytes = img.encodePng(transparentPng);

      final sourceFile = File(p.join(tempDir.path, 'source_transp.png'));
      await sourceFile.writeAsBytes(pngBytes);

      final result = await storageService.importFile(
        uid: 'test_user_png',
        sourceFile: sourceFile,
        fileName: 'source_transp.png',
        mimeType: 'image/png',
      );

      expect(result.category, equals(AttachmentCategory.images));
      expect(result.file.path.endsWith('.png'), isTrue);

      final decoded = img.decodeImage(await result.file.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.numChannels, equals(4));
    });

    test('imports in-memory bytes from sketching canvas and saves to sketches directory', () async {
      final sketchImage = img.Image(width: 800, height: 600);
      img.fill(sketchImage, color: img.ColorRgb8(255, 255, 255));
      final sketchBytes = img.encodePng(sketchImage);

      final result = await storageService.importBytes(
        uid: 'test_user_sketch',
        bytes: sketchBytes,
        fileName: 'sketch_001.png',
        mimeType: 'image/png',
        isSketch: true,
      );

      expect(result.category, equals(AttachmentCategory.sketches));
      expect(result.file.path.contains('sketches'), isTrue);
      expect(await result.file.exists(), isTrue);
      expect(result.fileSize, equals(sketchBytes.length));
    });

    test('safely deletes local files without crashing if missing', () async {
      final nonExistentPath = p.join(tempDir.path, 'ghost_file.pdf');
      await expectLater(
        storageService.deleteLocalFile(nonExistentPath),
        completes,
      );
      await expectLater(
        storageService.deleteLocalFile(null),
        completes,
      );
    });
  });

  group('Phase 4: AttachmentPickerService Tests', () {
    test('instantiates picker service', () {
      expect(pickerService, isNotNull);
    });

    test('defines supported extensions covering images, PDFs, and documents', () {
      expect(AttachmentPickerService.supportedExtensions, contains('jpg'));
      expect(AttachmentPickerService.supportedExtensions, contains('jpeg'));
      expect(AttachmentPickerService.supportedExtensions, contains('png'));
      expect(AttachmentPickerService.supportedExtensions, contains('webp'));
      expect(AttachmentPickerService.supportedExtensions, contains('pdf'));
      expect(AttachmentPickerService.supportedExtensions, contains('doc'));
      expect(AttachmentPickerService.supportedExtensions, contains('docx'));
      expect(AttachmentPickerService.supportedExtensions, contains('txt'));
    });

    test('enforces 50MB maximum file size limit', () {
      expect(AttachmentPickerService.maxFileSizeBytes, equals(50 * 1024 * 1024));
    });
  });
}
