import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/repositories/note_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';

void main() {
  group('Centralized Deletion, Tombstone Ledger & 30-Day Trash Retention Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftNoteRepository noteRepo;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      noteRepo = DriftNoteRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Moving notebook to trash sets deletedAt, deletionId, and excludes from active list', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-test-1',
        ownerId: 'user-1',
        title: 'Operating Systems',
        coverId: 'cover_1',
        coverColorHex: '#1E88E5',
        paperTemplateId: 'blank',
        createdAt: now,
        updatedAt: now,
      );

      await notebookRepo.saveNotebook(nb);
      var active = await notebookRepo.getAllNotebooks(ownerId: 'user-1');
      expect(active.length, equals(1));

      // Move to trash
      await notebookRepo.deleteNotebook('nb-test-1');

      // Active list must be empty
      active = await notebookRepo.getAllNotebooks(ownerId: 'user-1');
      expect(active.isEmpty, isTrue);

      // Trash list must contain it
      final trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.length, equals(1));
      expect(trash.first.id, equals('nb-test-1'));
      expect(trash.first.deletedAt, isNotNull);
      expect(trash.first.deletionId, isNotNull);
      expect(trash.first.syncStatus, equals('pending'));
    });

    test('Permanently deleting notebook records tombstone and completely purges record', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-perm-1',
        ownerId: 'user-1',
        title: 'Compiler Design',
        coverId: 'cover_1',
        coverColorHex: '#1E88E5',
        paperTemplateId: 'blank',
        createdAt: now,
        updatedAt: now,
      );

      await notebookRepo.saveNotebook(nb);

      // Permanently delete
      await notebookRepo.permanentlyDeleteNotebook('nb-perm-1', ownerId: 'user-1');

      // Excluded from active, trash, and any queries
      final active = await notebookRepo.getAllNotebooks(ownerId: 'user-1');
      final trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      final any = await notebookRepo.getAnyNotebookById('nb-perm-1');

      expect(active.isEmpty, isTrue);
      expect(trash.isEmpty, isTrue);
      expect(any, isNull);

      // Tombstone MUST be recorded
      final isTomb = await notebookRepo.isTombstoned('nb-perm-1');
      expect(isTomb, isTrue);

      final tombstones = await notebookRepo.getAllTombstones(ownerId: 'user-1');
      expect(tombstones.length, equals(1));
      expect(tombstones.first.id, equals('nb-perm-1'));
      expect(tombstones.first.entityType, equals('notebook'));
    });

    test('Tombstoned notebook CANNOT be resurrected by stale incoming save', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-tomb-resurrect',
        ownerId: 'user-1',
        title: 'Stale Cloud Notebook',
        coverId: 'cover_1',
        coverColorHex: '#1E88E5',
        paperTemplateId: 'blank',
        createdAt: now,
        updatedAt: now,
      );

      // Record tombstone first (simulating another device permanently deleting it)
      await notebookRepo.permanentlyDeleteNotebook('nb-tomb-resurrect', ownerId: 'user-1');
      expect(await notebookRepo.isTombstoned('nb-tomb-resurrect'), isTrue);

      // Stale sync tries to insert the notebook
      await notebookRepo.saveNotebook(nb);

      // Must NOT be inserted
      final retrieved = await notebookRepo.getAnyNotebookById('nb-tomb-resurrect');
      expect(retrieved, isNull);

      final active = await notebookRepo.getAllNotebooks(ownerId: 'user-1');
      expect(active.isEmpty, isTrue);
    });

    test('Restoring notebook clears deletedAt, increments revision, and syncStatus is pending', () async {
      final now = DateTime.now();
      final nb = Notebook(
        id: 'nb-restore-1',
        ownerId: 'user-1',
        title: 'Distributed Systems',
        coverId: 'cover_1',
        coverColorHex: '#1E88E5',
        paperTemplateId: 'blank',
        revision: 1,
        createdAt: now,
        updatedAt: now,
      );

      await notebookRepo.saveNotebook(nb);
      await notebookRepo.deleteNotebook('nb-restore-1');

      var trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.length, equals(1));

      // Restore
      await notebookRepo.restoreNotebook('nb-restore-1');

      trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.isEmpty, isTrue);

      final active = await notebookRepo.getAllNotebooks(ownerId: 'user-1');
      expect(active.length, equals(1));
      expect(active.first.id, equals('nb-restore-1'));
      expect(active.first.deletedAt, isNull);
      expect(active.first.deletionId, isNull);
      expect(active.first.revision, equals(2));
      expect(active.first.syncStatus, equals('pending'));
    });

    test('30-day auto-retention cleanup permanently deletes expired items and retains recent ones', () async {
      final now = DateTime.now();

      // Item deleted 35 days ago (EXPIRED)
      final expiredNb = Notebook(
        id: 'nb-expired-35d',
        ownerId: 'user-1',
        title: 'Old Notes',
        coverId: 'cover_1',
        coverColorHex: '#1E88E5',
        paperTemplateId: 'blank',
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 35)),
        deletedAt: now.subtract(const Duration(days: 35)),
        deletionId: 'del-old',
      );

      // Item deleted 5 days ago (RETAINED)
      final recentNb = Notebook(
        id: 'nb-recent-5d',
        ownerId: 'user-1',
        title: 'Recent Draft',
        coverId: 'cover_1',
        coverColorHex: '#1E88E5',
        paperTemplateId: 'blank',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 5)),
        deletedAt: now.subtract(const Duration(days: 5)),
        deletionId: 'del-recent',
      );

      await notebookRepo.saveNotebook(expiredNb);
      await notebookRepo.saveNotebook(recentNb);

      var trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.length, equals(2));

      // Run 30-day retention cleanup
      final purgedIds = await notebookRepo.cleanupExpiredTrash(retentionDays: 30, ownerId: 'user-1');

      expect(purgedIds, contains('nb-expired-35d'));
      expect(purgedIds.contains('nb-recent-5d'), isFalse);

      // Expired item is permanently purged and tombstoned
      expect(await notebookRepo.isTombstoned('nb-expired-35d'), isTrue);
      expect(await notebookRepo.getAnyNotebookById('nb-expired-35d'), isNull);

      // Recent item remains in trash
      trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.length, equals(1));
      expect(trash.first.id, equals('nb-recent-5d'));
    });

    test('Notes repository: deletion, permanent deletion, and tombstone safeguards work identically', () async {
      final now = DateTime.now();
      final note = Note(
        id: 'note-tomb-1',
        ownerId: 'user-1',
        notebookId: 'nb-parent-1',
        title: 'Algorithms Midterm Prep',
        contentDelta: '[{"insert":"\\n"}]',
        plainText: '',
        preview: '',
        tags: const [],
        isPinned: false,
        isFavorite: false,
        isArchived: false,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await noteRepo.saveNote(note);
      var all = await noteRepo.getAllNotes(ownerId: 'user-1');
      expect(all.length, equals(1));

      // Soft delete
      await noteRepo.deleteNote('note-tomb-1');
      all = await noteRepo.getAllNotes(ownerId: 'user-1');
      expect(all.isEmpty, isTrue);

      final trash = await noteRepo.getTrashNotes(ownerId: 'user-1');
      expect(trash.length, equals(1));
      expect(trash.first.id, equals('note-tomb-1'));

      // Permanent delete
      await noteRepo.permanentlyDeleteNote('note-tomb-1', ownerId: 'user-1');

      final trashAfter = await noteRepo.getTrashNotes(ownerId: 'user-1');
      expect(trashAfter.isEmpty, isTrue);

      // Resurrect attempt should fail
      await noteRepo.saveNote(note);
      final activeAfter = await noteRepo.getAllNotes(ownerId: 'user-1');
      expect(activeAfter.isEmpty, isTrue);
    });

    test('Bulk permanent deletion and bulk restore on multiple notebooks', () async {
      final now = DateTime.now();
      final nb1 = Notebook(
        id: 'nb-bulk-1',
        ownerId: 'user-1',
        title: 'Math 101',
        coverId: 'c1',
        coverColorHex: '#123456',
        paperTemplateId: 'p1',
        createdAt: now,
        updatedAt: now,
      );
      final nb2 = Notebook(
        id: 'nb-bulk-2',
        ownerId: 'user-1',
        title: 'Physics 101',
        coverId: 'c2',
        coverColorHex: '#654321',
        paperTemplateId: 'p2',
        createdAt: now,
        updatedAt: now,
      );

      await notebookRepo.saveNotebook(nb1);
      await notebookRepo.saveNotebook(nb2);

      // Bulk move to trash
      await notebookRepo.bulkDelete(['nb-bulk-1', 'nb-bulk-2']);
      var trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.length, equals(2));

      // Bulk restore
      await notebookRepo.bulkRestore(['nb-bulk-1']);
      trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.length, equals(1));
      expect(trash.first.id, equals('nb-bulk-2'));

      // Bulk permanent delete
      await notebookRepo.bulkPermanentDelete(['nb-bulk-2'], ownerId: 'user-1');
      trash = await notebookRepo.getDeletedNotebooks(ownerId: 'user-1');
      expect(trash.isEmpty, isTrue);

      expect(await notebookRepo.isTombstoned('nb-bulk-2'), isTrue);
    });
  });
}
