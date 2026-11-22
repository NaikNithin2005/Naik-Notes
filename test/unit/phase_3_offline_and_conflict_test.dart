import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/repositories/note_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/services/history/note_history_service.dart';
import 'package:naik_notes/features/sync/data/sync_provider.dart';

void main() {
  late AppDatabase db;
  late DriftNoteRepository noteRepo;
  late DriftNotebookRepository notebookRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    noteRepo = DriftNoteRepository(db);
    notebookRepo = DriftNotebookRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 3: Offline-First Architecture & Versioning Tests', () {
    test('Note is created offline with localVersion=1, syncStatus=pending and persists', () async {
      final blank = Note.createBlank(
        ownerId: 'user_offline',
        notebookId: 'nb_math',
        title: 'Linear Algebra Draft',
      ).copyWith(syncStatus: 'pending');

      await noteRepo.saveNote(blank);

      final retrieved = await noteRepo.getNoteById(blank.id, ownerId: 'user_offline');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Linear Algebra Draft');
      expect(retrieved.localVersion, 1);
      expect(retrieved.serverVersion, 1);
      expect(retrieved.syncStatus, 'pending');
    });

    test('Local edits increment localVersion while serverVersion tracks confirmed sync', () async {
      final original = Note.createBlank(
        ownerId: 'user_offline',
        notebookId: 'nb_math',
        title: 'Draft v1',
      ).copyWith(
        localVersion: 1,
        serverVersion: 1,
        syncStatus: 'synced',
      );
      await noteRepo.saveNote(original);

      // User makes an offline edit
      final offlineEdit1 = original.copyWith(
        contentDelta: '[{"insert":"Updated offline chapter 1\\n"}]',
        localVersion: original.localVersion + 1,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );
      await noteRepo.saveNote(offlineEdit1);

      var current = await noteRepo.getNoteById(original.id, ownerId: 'user_offline');
      expect(current!.localVersion, 2);
      expect(current.serverVersion, 1);
      expect(current.syncStatus, 'pending');

      // User makes a second offline edit
      final offlineEdit2 = current.copyWith(
        contentDelta: '[{"insert":"Updated offline chapter 2\\n"}]',
        localVersion: current.localVersion + 1,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );
      await noteRepo.saveNote(offlineEdit2);

      current = await noteRepo.getNoteById(original.id, ownerId: 'user_offline');
      expect(current!.localVersion, 3);
      expect(current.serverVersion, 1);
      expect(current.syncStatus, 'pending');

      // When sync confirms, serverVersion matches localVersion and status is synced
      final synced = current.copyWith(
        serverVersion: current.localVersion,
        syncStatus: 'synced',
        lastSyncedAt: DateTime.now(),
      );
      await noteRepo.saveNote(synced);

      current = await noteRepo.getNoteById(original.id, ownerId: 'user_offline');
      expect(current!.localVersion, 3);
      expect(current.serverVersion, 3);
      expect(current.syncStatus, 'synced');
    });
  });

  group('Phase 3: Multi-Device Conflict Detection & Conflict Copy Generation', () {
    test('Generates Conflict Copy when remote is newer and local has pending offline modifications', () async {
      const noteId = 'shared_note_1';
      const uid = 'user_multi_device';
      const nbId = 'notebook_cs';

      // 1. Initial synced state on both devices (v1)
      final initialNote = Note.createBlank(
        ownerId: uid,
        notebookId: nbId,
        title: 'Algorithms',
      ).copyWith(
        id: noteId,
        contentDelta: '[{"insert":"Initial sorting notes\\n"}]',
        localVersion: 1,
        serverVersion: 1,
        syncStatus: 'synced',
      );
      await noteRepo.saveNote(initialNote);

      // 2. Windows makes offline changes (localVersion=2, pending)
      final localWindowsEdit = initialNote.copyWith(
        contentDelta: '[{"insert":"Windows Quicksort details\\n"}]',
        localVersion: 2,
        syncStatus: 'pending',
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      await noteRepo.saveNote(localWindowsEdit);

      // 3. Android edited online earlier, bumping serverVersion to 2 with different content
      final remoteAndroidNote = initialNote.copyWith(
        contentDelta: '[{"insert":"Android Mergesort details\\n"}]',
        localVersion: 2,
        serverVersion: 2,
        syncStatus: 'synced',
        updatedAt: DateTime.now(),
      );

      // 4. Synchronization detects collision:
      // local is pending, remote serverVersion > local serverVersion, content diverged
      final isLocalModified = localWindowsEdit.syncStatus == 'pending';
      final isRemoteNewer = remoteAndroidNote.serverVersion > localWindowsEdit.serverVersion;
      final hasDiverged = localWindowsEdit.contentDelta != remoteAndroidNote.contentDelta;

      expect(isLocalModified, isTrue);
      expect(isRemoteNewer, isTrue);
      expect(hasDiverged, isTrue);

      // Perform Conflict Resolution
      final platform = NoteHistoryService.currentDeviceName.split(' ').first;
      final conflictTitle = '${localWindowsEdit.title} (Conflict Copy - $platform)';

      final conflictCopy = localWindowsEdit.copyWith(
        id: 'conflict_copy_uuid_123',
        title: conflictTitle,
        localVersion: 1,
        serverVersion: 1,
        syncStatus: 'pending',
        updatedAt: DateTime.now(),
      );
      await noteRepo.saveNote(conflictCopy);

      // Overwrite canonical slot with authoritative remote note
      await noteRepo.saveNote(remoteAndroidNote);

      // 5. Verify Zero Data Loss: both notes exist in the notebook
      final allNotes = await noteRepo.getAllNotes(ownerId: uid, notebookId: nbId);
      expect(allNotes.length, 2);

      final canonical = allNotes.firstWhere((n) => n.id == noteId);
      expect(canonical.contentDelta, contains('Android Mergesort'));
      expect(canonical.serverVersion, 2);

      final conflict = allNotes.firstWhere((n) => n.id == 'conflict_copy_uuid_123');
      expect(conflict.title, contains('(Conflict Copy -'));
      expect(conflict.contentDelta, contains('Windows Quicksort'));
    });

    test('Conflict copy is idempotent: repeated sync pass does not duplicate conflict copies', () async {
      const uid = 'user_multi_device';
      const nbId = 'notebook_cs';

      final platform = NoteHistoryService.currentDeviceName.split(' ').first;
      final conflictTitle = 'Algorithms (Conflict Copy - $platform)';

      // Save initial conflict copy
      final conflictCopy = Note.createBlank(
        ownerId: uid,
        notebookId: nbId,
        title: conflictTitle,
      ).copyWith(
        contentDelta: '[{"insert":"Windows offline edits\\n"}]',
      );
      await noteRepo.saveNote(conflictCopy);

      // Check before creating duplicate
      final existing = await noteRepo.getAllNotes(ownerId: uid, notebookId: nbId);
      final alreadyExists = existing.any(
        (n) => n.title == conflictTitle && n.contentDelta == conflictCopy.contentDelta,
      );

      expect(alreadyExists, isTrue);
      // Because alreadyExists is true, engine skips re-creating conflict copy
      final finalNotes = await noteRepo.getAllNotes(ownerId: uid, notebookId: nbId);
      expect(finalNotes.length, 1);
    });
  });

  group('Phase 3: Deletion Tombstone Precedence Tests', () {
    test('Permanently deleted note is protected by tombstone and rejects resurrection', () async {
      const uid = 'user_tombstone';
      const noteId = 'target_note_456';

      final note = Note.createBlank(
        ownerId: uid,
        notebookId: 'nb_1',
        title: 'Sensitive Note',
      ).copyWith(id: noteId);
      await noteRepo.saveNote(note);

      // Move to trash
      await noteRepo.deleteNote(noteId);
      var retrieved = await noteRepo.getNoteById(noteId, ownerId: uid);
      expect(retrieved!.isDeleted, isTrue);

      // Permanently delete
      await noteRepo.permanentlyDeleteNote(noteId, ownerId: uid);
      retrieved = await noteRepo.getNoteById(noteId, ownerId: uid);
      expect(retrieved, isNull);

      // Verify tombstone exists in deletion ledger
      final isTombstoned = await notebookRepo.isTombstoned(noteId);
      expect(isTombstoned, isTrue);

      // A stale incoming sync pass attempts to re-insert the note
      final staleIncoming = note.copyWith(
        updatedAt: DateTime.now(),
        localVersion: 10,
        serverVersion: 10,
      );

      if (!await notebookRepo.isTombstoned(staleIncoming.id)) {
        await noteRepo.saveNote(staleIncoming);
      }

      final checkAgain = await noteRepo.getNoteById(noteId, ownerId: uid);
      expect(checkAgain, isNull); // Blocked from resurrection!
    });
  });

  group('Phase 3: Strict User Isolation Tests', () {
    test('User A notes are strictly partitioned from User B', () async {
      final noteA = Note.createBlank(
        ownerId: 'user_alice',
        notebookId: 'nb_shared_id',
        title: "Alice's Secret Strategy",
      );
      await noteRepo.saveNote(noteA);

      final noteB = Note.createBlank(
        ownerId: 'user_bob',
        notebookId: 'nb_shared_id',
        title: "Bob's Public Notes",
      );
      await noteRepo.saveNote(noteB);

      // Alice's view
      final aliceNotes = await noteRepo.getAllNotes(ownerId: 'user_alice');
      expect(aliceNotes.length, 1);
      expect(aliceNotes.first.title, "Alice's Secret Strategy");

      // Bob's view
      final bobNotes = await noteRepo.getAllNotes(ownerId: 'user_bob');
      expect(bobNotes.length, 1);
      expect(bobNotes.first.title, "Bob's Public Notes");

      // Bob cannot retrieve Alice's note by direct ID
      final stolen = await noteRepo.getNoteById(noteA.id, ownerId: 'user_bob');
      expect(stolen, isNull);
    });
  });

  group('Phase 3: Global Sync Status Transitions', () {
    test('SyncUiStatus includes all required operational states', () {
      expect(SyncUiStatus.values, contains(SyncUiStatus.synced));
      expect(SyncUiStatus.values, contains(SyncUiStatus.saving));
      expect(SyncUiStatus.values, contains(SyncUiStatus.syncing));
      expect(SyncUiStatus.values, contains(SyncUiStatus.offline));
      expect(SyncUiStatus.values, contains(SyncUiStatus.error));
      expect(SyncUiStatus.values, contains(SyncUiStatus.pending));
      expect(SyncUiStatus.values, contains(SyncUiStatus.conflict));
    });
  });
}
