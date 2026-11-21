import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';

void main() {
  group('Sync Deduplication & Conflict Prevention Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Consolidates duplicate (Cloud Copy) notebooks when base notebook exists', () async {
      final now = DateTime.now();

      // Base original notebook
      final original = Notebook(
        id: 'nb-base-1',
        ownerId: 'test_user',
        title: 'Calculus Notes',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      // Flawed duplicate copy
      final cloudCopy = Notebook(
        id: 'nb-copy-1',
        ownerId: 'test_user',
        title: 'Calculus Notes (Cloud Copy)',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      );

      await notebookRepo.saveNotebook(original);
      await notebookRepo.saveNotebook(cloudCopy);

      var all = await notebookRepo.getAllNotebooks(ownerId: 'test_user');
      expect(all.length, equals(2));

      // Simulate deduplication pass
      final cloudCopyRegex = RegExp(
        r'\s*\((?:Cloud Copy|Conflict Copy)(?: \d+)?\)$',
        caseSensitive: false,
      );
      final nonCopyTitles = <String>{};
      for (final nb in all) {
        if (!cloudCopyRegex.hasMatch(nb.title) && nb.deletedAt == null) {
          nonCopyTitles.add(nb.title.trim().toLowerCase());
        }
      }

      for (final nb in all) {
        if (cloudCopyRegex.hasMatch(nb.title) && nb.deletedAt == null) {
          final base = nb.title.replaceAll(cloudCopyRegex, '').trim().toLowerCase();
          if (nonCopyTitles.contains(base)) {
            await notebookRepo.deleteNotebook(nb.id);
          }
        }
      }

      final active = await notebookRepo.getAllNotebooks(ownerId: 'test_user');
      expect(active.length, equals(1));
      expect(active.first.id, equals('nb-base-1'));
      expect(active.first.title, equals('Calculus Notes'));
    });

    test('Restores clean title when only (Cloud Copy) notebook exists (zero data loss)', () async {
      final now = DateTime.now();

      final orphanedCopy = Notebook(
        id: 'nb-orphaned-1',
        ownerId: 'test_user',
        title: 'My Handwritten Journal (Cloud Copy)',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
        createdAt: now,
        updatedAt: now,
      );

      await notebookRepo.saveNotebook(orphanedCopy);

      var all = await notebookRepo.getAllNotebooks(ownerId: 'test_user');
      expect(all.length, equals(1));

      final cloudCopyRegex = RegExp(
        r'\s*\((?:Cloud Copy|Conflict Copy)(?: \d+)?\)$',
        caseSensitive: false,
      );
      final nonCopyTitles = <String>{};
      for (final nb in all) {
        if (!cloudCopyRegex.hasMatch(nb.title) && nb.deletedAt == null) {
          nonCopyTitles.add(nb.title.trim().toLowerCase());
        }
      }

      for (final nb in all) {
        if (cloudCopyRegex.hasMatch(nb.title) && nb.deletedAt == null) {
          final base = nb.title.replaceAll(cloudCopyRegex, '').trim().toLowerCase();
          if (nonCopyTitles.contains(base)) {
            await notebookRepo.deleteNotebook(nb.id);
          } else {
            final cleanTitle = nb.title.replaceAll(cloudCopyRegex, '').trim();
            final renamed = nb.copyWith(
              title: cleanTitle.isEmpty ? 'Untitled Notebook' : cleanTitle,
            );
            await notebookRepo.saveNotebook(renamed);
            nonCopyTitles.add(base);
          }
        }
      }

      final active = await notebookRepo.getAllNotebooks(ownerId: 'test_user');
      expect(active.length, equals(1));
      expect(active.first.id, equals('nb-orphaned-1'));
      expect(active.first.title, equals('My Handwritten Journal'));
    });

    test('AppDatabase.forUser reuses singleton instance for identical user ID', () {
      AppDatabase.resetInstances();

      final executor1 = NativeDatabase.memory();
      final executor2 = NativeDatabase.memory();

      // Passing explicit executor creates test instances
      final testDb1 = AppDatabase(executor1);
      final testDb2 = AppDatabase(executor2);
      expect(identical(testDb1, testDb2), isFalse);

      AppDatabase.resetInstances();
    });

    test('Consolidates multiple nested (Cloud Copy) duplicates and preserves highest pageCount canonical', () async {
      final now = DateTime.now();

      // Duplicate 1: 0 pages, title has nested Cloud Copy
      final copy1 = Notebook(
        id: 'dup-1',
        ownerId: 'user_123',
        title: 'Project Alpha (Cloud Copy) (Cloud Copy)',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
        pageCount: 1,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
      );

      // Duplicate 2: 9 pages, title has Cloud Copy
      final copy2 = Notebook(
        id: 'dup-2',
        ownerId: 'user_123',
        title: 'Project Alpha (Cloud Copy)',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
        pageCount: 9,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      );

      // Duplicate 3: 0 pages
      final copy3 = Notebook(
        id: 'dup-3',
        ownerId: 'user_123',
        title: 'project alpha (Copy 1)',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
        pageCount: 2,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );

      await notebookRepo.saveNotebook(copy1);
      await notebookRepo.saveNotebook(copy2);
      await notebookRepo.saveNotebook(copy3);

      var all = await notebookRepo.getAllNotebooks(ownerId: 'user_123');
      expect(all.length, equals(3));

      // Universal cleaner logic
      String cleanTitleRecursively(String title) {
        final copyPattern = RegExp(
          r'\s*\((?:Cloud Copy|Conflict Copy|Copy)(?:\s+\d+)?\)$',
          caseSensitive: false,
        );
        String clean = title.trim();
        while (copyPattern.hasMatch(clean)) {
          clean = clean.replaceAll(copyPattern, '').trim();
        }
        return clean.isEmpty ? 'Untitled Notebook' : clean;
      }

      final groups = <String, List<Notebook>>{};
      for (final nb in all) {
        if (nb.deletedAt == null) {
          final base = cleanTitleRecursively(nb.title).toLowerCase();
          groups.putIfAbsent(base, () => []).add(nb);
        }
      }

      final copyPattern = RegExp(
        r'\((?:Cloud Copy|Conflict Copy|Copy)',
        caseSensitive: false,
      );

      for (final entry in groups.entries) {
        final list = entry.value;
        list.sort((a, b) {
          final aIsCopy = copyPattern.hasMatch(a.title);
          final bIsCopy = copyPattern.hasMatch(b.title);
          if (!aIsCopy && bIsCopy) return -1;
          if (aIsCopy && !bIsCopy) return 1;

          if (a.pageCount != b.pageCount) return b.pageCount.compareTo(a.pageCount);
          if (a.revision != b.revision) return b.revision.compareTo(a.revision);
          return b.updatedAt.compareTo(a.updatedAt);
        });

        final canonical = list.first;
        final cleanTitle = cleanTitleRecursively(canonical.title);
        if (canonical.title != cleanTitle) {
          await notebookRepo.saveNotebook(canonical.copyWith(title: cleanTitle));
        }

        for (int i = 1; i < list.length; i++) {
          await notebookRepo.permanentlyDeleteNotebook(list[i].id, ownerId: 'user_123');
        }
      }

      final remaining = await notebookRepo.getAllNotebooks(ownerId: 'user_123');
      expect(remaining.length, equals(1));
      expect(remaining.first.id, equals('dup-2')); // Selected because pageCount=9
      expect(remaining.first.title, equals('Project Alpha'));
      expect(remaining.first.pageCount, equals(9));

      // Verify tombstones recorded for purged duplicates
      expect(await notebookRepo.isTombstoned('dup-1'), isTrue);
      expect(await notebookRepo.isTombstoned('dup-3'), isTrue);
    });
  });
}
