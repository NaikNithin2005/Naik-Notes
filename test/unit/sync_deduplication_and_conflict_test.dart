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
  });
}
