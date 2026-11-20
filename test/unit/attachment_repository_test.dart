import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/attachment_model.dart';
import 'package:naik_notes/data/repositories/attachment_repository.dart';

void main() {
  late AppDatabase db;
  late AttachmentRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = AttachmentRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AttachmentRepository SQLite & Drift Tests', () {
    test('saves and retrieves attachment by ID', () async {
      final attachment = NoteAttachment(
        attachmentId: 'att_001',
        ownerId: 'user_123',
        noteId: 'note_abc',
        fileName: 'circuit_diagram.png',
        mimeType: 'image/png',
        fileSize: 20480,
        localPath: '/local/cache/att_001.png',
        checksum: 'sha256_dummy_hash_001',
        storageProvider: AttachmentStorageProvider.googleDriveAppData,
        uploadStatus: AttachmentUploadStatus.pending,
        createdAt: DateTime(2026, 11, 20, 10, 0),
      );

      await repository.saveAttachment(attachment);

      final retrieved = await repository.getAttachment('att_001');
      expect(retrieved, isNotNull);
      expect(retrieved!.attachmentId, equals('att_001'));
      expect(retrieved.fileName, equals('circuit_diagram.png'));
      expect(retrieved.fileSize, equals(20480));
      expect(retrieved.uploadStatus, equals(AttachmentUploadStatus.pending));
      expect(retrieved.isImage, isTrue);
      expect(retrieved.isPdf, isFalse);
    });

    test('updates attachment status, driveFileId, and uploaded timestamp', () async {
      final attachment = NoteAttachment(
        attachmentId: 'att_002',
        ownerId: 'user_123',
        noteId: 'note_abc',
        fileName: 'research_paper.pdf',
        mimeType: 'application/pdf',
        fileSize: 1048576, // 1MB
        localPath: '/local/cache/att_002.pdf',
        checksum: 'sha256_dummy_hash_002',
        storageProvider: AttachmentStorageProvider.googleDriveAppData,
        uploadStatus: AttachmentUploadStatus.pending,
        createdAt: DateTime(2026, 11, 20, 10, 0),
      );

      await repository.saveAttachment(attachment);

      final uploadedTime = DateTime(2026, 11, 20, 10, 5);
      await repository.updateAttachmentStatus(
        'att_002',
        AttachmentUploadStatus.uploaded,
        driveFileId: 'drive_file_id_xyz',
        uploadedAt: uploadedTime,
      );

      final updated = await repository.getAttachment('att_002');
      expect(updated, isNotNull);
      expect(updated!.uploadStatus, equals(AttachmentUploadStatus.uploaded));
      expect(updated.driveFileId, equals('drive_file_id_xyz'));
      expect(updated.uploadedAt, equals(uploadedTime));
      expect(updated.isPdf, isTrue);
      expect(updated.humanReadableSize, equals('1.0 MB'));
    });

    test('queries pending and failed uploads counts accurately', () async {
      await repository.saveAttachment(
        NoteAttachment(
          attachmentId: 'att_p1',
          ownerId: 'user_123',
          noteId: 'note_1',
          fileName: 'p1.png',
          mimeType: 'image/png',
          fileSize: 100,
          checksum: 'hash1',
          uploadStatus: AttachmentUploadStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      await repository.saveAttachment(
        NoteAttachment(
          attachmentId: 'att_p2',
          ownerId: 'user_123',
          noteId: 'note_1',
          fileName: 'p2.png',
          mimeType: 'image/png',
          fileSize: 100,
          checksum: 'hash2',
          uploadStatus: AttachmentUploadStatus.pending,
          createdAt: DateTime.now(),
        ),
      );

      await repository.saveAttachment(
        NoteAttachment(
          attachmentId: 'att_f1',
          ownerId: 'user_123',
          noteId: 'note_1',
          fileName: 'f1.png',
          mimeType: 'image/png',
          fileSize: 100,
          checksum: 'hash3',
          uploadStatus: AttachmentUploadStatus.failed,
          createdAt: DateTime.now(),
        ),
      );

      expect(await repository.getPendingUploadsCount('user_123'), equals(2));
      expect(await repository.getFailedUploadsCount('user_123'), equals(1));

      final pendingList = await repository.getPendingUploads('user_123');
      expect(pendingList.length, equals(3)); // 2 pending + 1 failed
    });

    test('filters attachments by noteId and excludes soft-deleted items', () async {
      await repository.saveAttachment(
        NoteAttachment(
          attachmentId: 'att_n1',
          ownerId: 'user_123',
          noteId: 'target_note',
          fileName: 'n1.png',
          mimeType: 'image/png',
          fileSize: 100,
          checksum: 'hash1',
          createdAt: DateTime.now(),
        ),
      );

      await repository.saveAttachment(
        NoteAttachment(
          attachmentId: 'att_n2',
          ownerId: 'user_123',
          noteId: 'target_note',
          fileName: 'n2.png',
          mimeType: 'image/png',
          fileSize: 100,
          checksum: 'hash2',
          createdAt: DateTime.now(),
        ),
      );

      await repository.saveAttachment(
        NoteAttachment(
          attachmentId: 'att_other',
          ownerId: 'user_123',
          noteId: 'other_note',
          fileName: 'other.png',
          mimeType: 'image/png',
          fileSize: 100,
          checksum: 'hash3',
          createdAt: DateTime.now(),
        ),
      );

      final noteAttachments = await repository.getAttachmentsForNote('target_note');
      expect(noteAttachments.length, equals(2));

      // Soft delete att_n1
      await repository.markAttachmentDeleted('att_n1');

      final remaining = await repository.getAttachmentsForNote('target_note');
      expect(remaining.length, equals(1));
      expect(remaining.first.attachmentId, equals('att_n2'));

      // Hard delete att_n2
      await repository.deleteAttachmentPermanently('att_n2');
      final afterHardDelete = await repository.getAttachmentsForNote('target_note');
      expect(afterHardDelete, isEmpty);
    });
  });
}
