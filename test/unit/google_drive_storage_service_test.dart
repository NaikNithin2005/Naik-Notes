import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/services/storage/google_drive_storage_service.dart';

void main() {
  group('GoogleDriveStorageService Logic & Checksum Tests', () {
    late Directory tempDir;
    late File testFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('naik_notes_drive_test_');
      testFile = File('${tempDir.path}/test_image.png');
      await testFile.writeAsString('Naik Notes Vector Handwriting Attachment Payload 2026');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('calculates correct SHA-256 integrity hash for local file', () async {
      final checksum = await GoogleDriveStorageService.calculateSha256(testFile);

      expect(checksum, isNotEmpty);
      expect(checksum.length, equals(64)); // Standard SHA-256 hex length
      // Consistent hash check
      final checksum2 = await GoogleDriveStorageService.calculateSha256(testFile);
      expect(checksum, equals(checksum2));
    });

    test('DriveFileNotFoundException prints formatted fileId', () {
      final exception = DriveFileNotFoundException('file_abc_123');
      expect(exception.fileId, equals('file_abc_123'));
      expect(exception.toString(), contains('file_abc_123'));
      expect(exception.toString(), contains('appDataFolder'));
    });

    test('ChecksumMismatchException reports expected and actual hashes', () {
      final exception = ChecksumMismatchException(
        expected: 'hash_expected_123',
        actual: 'hash_corrupted_456',
      );

      expect(exception.expected, equals('hash_expected_123'));
      expect(exception.actual, equals('hash_corrupted_456'));
      expect(exception.toString(), contains('hash_expected_123'));
      expect(exception.toString(), contains('hash_corrupted_456'));
    });
  });
}
