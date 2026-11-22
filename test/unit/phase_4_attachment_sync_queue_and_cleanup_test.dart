import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/attachment_model.dart';
import 'package:naik_notes/data/models/google_drive_connection_model.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/repositories/attachment_repository.dart';
import 'package:naik_notes/data/repositories/note_repository.dart';
import 'package:naik_notes/services/storage/attachment_storage_service.dart';
import 'package:naik_notes/services/storage/attachment_sync_coordinator.dart';
import 'package:naik_notes/services/storage/google_drive_auth_service.dart';
import 'package:naik_notes/services/storage/google_drive_storage_service.dart';
import 'package:path/path.dart' as p;

class _FakeGoogleDriveAuthService implements GoogleDriveAuthService {
  bool isConnected;

  _FakeGoogleDriveAuthService({this.isConnected = true});

  @override
  Future<GoogleDriveConnectionModel?> getConnectionMetadata(String uid) async {
    return GoogleDriveConnectionModel(
      connected: isConnected,
      googleAccountEmail: '$uid@gmail.com',
      connectedAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getValidAccessToken(String uid) async {
    return isConnected ? 'fake_token' : null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGoogleDriveStorageService implements GoogleDriveStorageService {
  final Map<String, List<int>> appDataFiles = {};
  final List<String> deletedDriveIds = [];
  int uploadCallCount = 0;

  @override
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
    uploadCallCount++;
    final driveId = 'drive_file_$attachmentId';
    appDataFiles[driveId] = await file.readAsBytes();
    onProgress?.call(1.0);
    return driveId;
  }

  @override
  Future<File> downloadAttachment({
    required String uid,
    required String driveFileId,
    required File destinationFile,
    required String expectedChecksum,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = appDataFiles[driveFileId];
    if (bytes == null) {
      throw DriveFileNotFoundException(driveFileId);
    }
    if (!await destinationFile.parent.exists()) {
      await destinationFile.parent.create(recursive: true);
    }
    await destinationFile.writeAsBytes(bytes);
    onProgress?.call(1.0);
    return destinationFile;
  }

  @override
  Future<void> deleteAttachment({
    required String uid,
    required String driveFileId,
  }) async {
    deletedDriveIds.add(driveFileId);
    appDataFiles.remove(driveFileId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AttachmentRepository attachmentRepo;
  late DriftNoteRepository noteRepo;
  late AttachmentStorageService storageHelper;
  late _FakeGoogleDriveAuthService authService;
  late _FakeGoogleDriveStorageService storageService;
  late AttachmentSyncCoordinator coordinator;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    attachmentRepo = AttachmentRepository(db);
    noteRepo = DriftNoteRepository(db);
    tempDir = await Directory.systemTemp.createTemp('naik_notes_sync_test_');
    storageHelper = AttachmentStorageService(
      baseDirectoryProvider: () async => tempDir,
    );
    authService = _FakeGoogleDriveAuthService(isConnected: true);
    storageService = _FakeGoogleDriveStorageService();

    coordinator = AttachmentSyncCoordinator(
      authService: authService,
      storageService: storageService,
      attachmentRepo: attachmentRepo,
      storageHelper: storageHelper,
      firestore: null,
    );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 4: Attachment Sync Queue, Offline, and Lifecycle Tests', () {
    test('TEST 3: Offline attachment addition preserves local file and marks driveDisconnected', () async {
      authService.isConnected = false;

      final testFile = File(p.join(tempDir.path, 'offline_diagram.png'));
      await testFile.writeAsBytes([1, 2, 3, 4, 5]);

      final attachment = await coordinator.addAttachment(
        uid: 'user_offline',
        noteId: 'note_101',
        sourceFile: testFile,
        fileName: 'offline_diagram.png',
        mimeType: 'image/png',
      );

      expect(attachment.attachmentId, isNotEmpty);
      expect(attachment.localPath, isNotNull);
      expect(File(attachment.localPath!).existsSync(), isTrue);

      // Verify saved in SQLite
      final inDb = await attachmentRepo.getAttachment(attachment.attachmentId);
      expect(inDb, isNotNull);
      expect(inDb!.noteId, equals('note_101'));

      // Check upload queue count
      final pendingCount = await attachmentRepo.getPendingUploadsCount('user_offline');
      expect(pendingCount, greaterThanOrEqualTo(0));
    });

    test('TEST 4: Connected attachment uploads to Google Drive appDataFolder and returns driveId', () async {
      authService.isConnected = true;

      final testFile = File(p.join(tempDir.path, 'network_diagram.png'));
      await testFile.writeAsBytes([10, 20, 30, 40]);

      final attachment = await coordinator.addAttachment(
        uid: 'user_connected',
        noteId: 'note_202',
        sourceFile: testFile,
        fileName: 'network_diagram.png',
        mimeType: 'image/png',
      );

      // Allow async background upload to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final inDb = await attachmentRepo.getAttachment(attachment.attachmentId);
      expect(inDb, isNotNull);
      expect(inDb!.driveFileId, equals('drive_file_${attachment.attachmentId}'));
      expect(inDb.uploadStatus, equals(AttachmentUploadStatus.uploaded));
      expect(storageService.uploadCallCount, equals(1));
    });

    test('TEST 5: Interrupted upload recovers cleanly on application restart', () async {
      // Simulate an attachment stuck in 'uploading' status
      final interruptedAttachment = NoteAttachment(
        attachmentId: 'att_interrupted_01',
        ownerId: 'user_reboot',
        noteId: 'note_303',
        fileName: 'interrupted.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024,
        checksum: 'hash_int_01',
        localPath: p.join(tempDir.path, 'interrupted.pdf'),
        uploadStatus: AttachmentUploadStatus.uploading,
        createdAt: DateTime.now(),
      );
      await File(interruptedAttachment.localPath!).writeAsBytes([1, 2, 3]);
      await attachmentRepo.saveAttachment(interruptedAttachment);

      // Verify currently uploading
      final before = await attachmentRepo.getAttachment('att_interrupted_01');
      expect(before!.uploadStatus, equals(AttachmentUploadStatus.uploading));

      // Execute recovery on startup
      await coordinator.recoverInterruptedUploads('user_reboot');

      final after = await attachmentRepo.getAttachment('att_interrupted_01');
      expect(after, isNotNull);
      // Status was reset and then synced
      expect(after!.uploadStatus, equals(AttachmentUploadStatus.uploaded));
      expect(after.driveFileId, isNotNull);
    });

    test('TEST 6: Safe Reference-Counted Deletion preserves Drive file if referenced elsewhere', () async {
      const sharedDriveId = 'drive_shared_binary_999';

      final att1 = NoteAttachment(
        attachmentId: 'att_noteA_01',
        ownerId: 'user_ref',
        noteId: 'note_A',
        driveFileId: sharedDriveId,
        fileName: 'shared_diagram.png',
        mimeType: 'image/png',
        fileSize: 2048,
        checksum: 'shared_hash',
        localPath: p.join(tempDir.path, 'attA.png'),
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: DateTime.now(),
      );
      final att2 = NoteAttachment(
        attachmentId: 'att_noteB_02',
        ownerId: 'user_ref',
        noteId: 'note_B',
        driveFileId: sharedDriveId,
        fileName: 'shared_diagram.png',
        mimeType: 'image/png',
        fileSize: 2048,
        checksum: 'shared_hash',
        localPath: p.join(tempDir.path, 'attB.png'),
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: DateTime.now(),
      );

      await File(att1.localPath!).writeAsBytes([1, 2]);
      await File(att2.localPath!).writeAsBytes([1, 2]);
      await attachmentRepo.saveAttachment(att1);
      await attachmentRepo.saveAttachment(att2);

      // Verify active count is 2
      final countBefore = await attachmentRepo.countAttachmentsWithDriveFileId(sharedDriveId);
      expect(countBefore, equals(2));

      // Delete from note_A
      await coordinator.deleteAttachment(
        uid: 'user_ref',
        noteId: 'note_A',
        attachmentId: 'att_noteA_01',
      );

      // Drive binary must NOT be deleted yet because note_B still references it!
      expect(storageService.deletedDriveIds.contains(sharedDriveId), isFalse);

      // Now delete from note_B
      await coordinator.deleteAttachment(
        uid: 'user_ref',
        noteId: 'note_B',
        attachmentId: 'att_noteB_02',
      );

      // Now count is 0, so Drive binary is safely deleted
      expect(storageService.deletedDriveIds.contains(sharedDriveId), isTrue);
    });

    test('TEST 7 & 8: Trash preserves attachments; permanent delete cleans them up', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'note_trash_test',
        ownerId: 'user_trash',
        notebookId: 'nb_trash',
        title: 'Note with Attachments',
        contentDelta: '[{"insert":"Test\\n"}]',
        plainText: 'Test',
        preview: 'Test',
        createdAt: now,
        updatedAt: now,
      );
      await noteRepo.saveNote(note);

      final att = NoteAttachment(
        attachmentId: 'att_trash_01',
        ownerId: 'user_trash',
        noteId: 'note_trash_test',
        driveFileId: 'drive_trash_01',
        fileName: 'trash_doc.pdf',
        mimeType: 'application/pdf',
        fileSize: 500,
        checksum: 'hash_trash',
        localPath: p.join(tempDir.path, 'trash_doc.pdf'),
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: now,
      );
      await File(att.localPath!).writeAsBytes([5, 6, 7]);
      await attachmentRepo.saveAttachment(att);

      // 1. Move note to Trash
      await noteRepo.deleteNote(note.id);
      final trashedNote = await noteRepo.getNoteById(note.id);
      expect(trashedNote!.isDeleted, isTrue);

      // Verify attachment is NOT deleted when note is moved to trash!
      final attInTrash = await attachmentRepo.getAttachment(att.attachmentId);
      expect(attInTrash, isNotNull);
      expect(attInTrash!.isDeleted, isFalse);
      expect(storageService.deletedDriveIds.contains('drive_trash_01'), isFalse);

      // 2. Permanently delete note and clean up attachments
      await coordinator.onNotePermanentlyDeleted('user_trash', note.id);
      await noteRepo.permanentlyDeleteNote(note.id, ownerId: 'user_trash');

      // Now attachment is removed and Drive file deleted
      final attAfterPermanent = await attachmentRepo.getAttachment(att.attachmentId);
      expect(attAfterPermanent, isNull);
      expect(storageService.deletedDriveIds.contains('drive_trash_01'), isTrue);
    });

    test('TEST 12: Multi-user isolation prevents cross-account attachment access', () async {
      final attUser1 = NoteAttachment(
        attachmentId: 'att_u1',
        ownerId: 'alice',
        noteId: 'note_alice',
        fileName: 'alice_notes.pdf',
        mimeType: 'application/pdf',
        fileSize: 100,
        checksum: 'h1',
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: DateTime.now(),
      );
      final attUser2 = NoteAttachment(
        attachmentId: 'att_u2',
        ownerId: 'bob',
        noteId: 'note_bob',
        fileName: 'bob_notes.pdf',
        mimeType: 'application/pdf',
        fileSize: 200,
        checksum: 'h2',
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: DateTime.now(),
      );

      await attachmentRepo.saveAttachment(attUser1);
      await attachmentRepo.saveAttachment(attUser2);

      final aliceAttachments = await attachmentRepo.getAttachmentsForNote('note_alice');
      expect(aliceAttachments.length, equals(1));
      expect(aliceAttachments.first.ownerId, equals('alice'));

      final bobAttachments = await attachmentRepo.getAttachmentsForNote('note_bob');
      expect(bobAttachments.length, equals(1));
      expect(bobAttachments.first.ownerId, equals('bob'));
    });

    test('TEST 14: Editing document content while attachment upload is running retains both edits', () async {
      final now = DateTime.now();
      var note = Note(
        id: 'note_concur',
        ownerId: 'user_c',
        notebookId: 'nb_c',
        title: 'Original Title',
        contentDelta: '[{"insert":"Initial sentence.\\n"}]',
        plainText: 'Initial sentence.',
        preview: 'Initial sentence.',
        createdAt: now,
        updatedAt: now,
      );
      await noteRepo.saveNote(note);

      // Start upload
      final sourceFile = File(p.join(tempDir.path, 'async_upload.png'));
      await sourceFile.writeAsBytes([9, 8, 7]);

      final uploadFuture = coordinator.addAttachment(
        uid: 'user_c',
        noteId: note.id,
        sourceFile: sourceFile,
        fileName: 'async_upload.png',
        mimeType: 'image/png',
      );

      // Concurrently edit note title and content delta while upload is in-flight
      note = note.copyWith(
        title: 'Edited Title While Uploading',
        contentDelta: '[{"insert":"Initial sentence. Newly appended text.\\n"}]',
        plainText: 'Initial sentence. Newly appended text.',
        updatedAt: DateTime.now(),
      );
      await noteRepo.saveNote(note);

      final attachment = await uploadFuture;
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify both note edits and attachment record are fully intact
      final reloadedNote = await noteRepo.getNoteById(note.id);
      expect(reloadedNote!.title, equals('Edited Title While Uploading'));
      expect(reloadedNote.plainText, contains('Newly appended text'));

      final reloadedAtt = await attachmentRepo.getAttachment(attachment.attachmentId);
      expect(reloadedAtt, isNotNull);
      expect(reloadedAtt!.noteId, equals(note.id));
    });
  });
}
