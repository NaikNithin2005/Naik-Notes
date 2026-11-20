import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/attachment_model.dart';
import 'package:naik_notes/data/repositories/attachment_repository.dart';

void main() {
  group('AttachmentSyncCoordinator & NoteAttachment Data Tests', () {
    late AppDatabase db;
    late AttachmentRepository repository;
    late Directory tempDir;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repository = AttachmentRepository(db);
      tempDir = await Directory.systemTemp.createTemp('coordinator_test_');
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('NoteAttachment converts to and from Firestore map with Timestamp fields', () {
      final now = DateTime(2026, 11, 20, 14, 30);
      final attachment = NoteAttachment(
        attachmentId: 'att_coord_001',
        driveFileId: 'drive_file_id_999',
        fileName: 'architecture_diagram.png',
        mimeType: 'image/png',
        fileSize: 512000,
        storageProvider: AttachmentStorageProvider.googleDriveAppData,
        createdAt: now,
        uploadedAt: now,
        checksum: 'sha256_dummy_checksum',
        uploadStatus: AttachmentUploadStatus.uploaded,
        noteId: 'note_123',
        ownerId: 'user_456',
        localPath: '/data/user/attachments/att_coord_001.png',
      );

      final firestoreMap = attachment.toFirestore();
      expect(firestoreMap['attachmentId'], equals('att_coord_001'));
      expect(firestoreMap['driveFileId'], equals('drive_file_id_999'));
      expect(firestoreMap['storageProvider'], equals(AttachmentStorageProvider.googleDriveAppData));
      expect(firestoreMap['createdAt'], isA<Timestamp>());
      expect(firestoreMap['uploadedAt'], isA<Timestamp>());
      expect(firestoreMap['schemaVersion'], equals(1));

      final restored = NoteAttachment.fromFirestore(
        firestoreMap,
        noteId: 'note_123',
        ownerId: 'user_456',
        localPath: '/data/user/attachments/att_coord_001.png',
      );

      expect(restored.attachmentId, equals('att_coord_001'));
      expect(restored.driveFileId, equals('drive_file_id_999'));
      expect(restored.fileSize, equals(512000));
      expect(restored.isImage, isTrue);
      expect(restored.humanReadableSize, equals('500.0 KB'));
      expect(restored.uploadStatus, equals(AttachmentUploadStatus.uploaded));
    });

    test('offline attachment stays preserved in SQLite with local-only status', () async {
      final offlineAttachment = NoteAttachment(
        attachmentId: 'att_offline_001',
        ownerId: 'user_offline',
        noteId: 'note_offline',
        fileName: 'offline_sketch.png',
        mimeType: 'image/png',
        fileSize: 1024,
        localPath: '/local/cache/offline_sketch.png',
        checksum: 'checksum_offline',
        storageProvider: AttachmentStorageProvider.googleDriveAppData,
        uploadStatus: AttachmentUploadStatus.driveDisconnected,
        createdAt: DateTime.now(),
      );

      await repository.saveAttachment(offlineAttachment);

      final retrieved = await repository.getAttachment('att_offline_001');
      expect(retrieved, isNotNull);
      expect(retrieved!.uploadStatus, equals(AttachmentUploadStatus.driveDisconnected));
      expect(retrieved.driveFileId, isNull);
    });
  });
}
