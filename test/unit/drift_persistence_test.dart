import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';

void main() {
  group('Drift SQLite Persistence Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository repository;

    setUp(() {
      // In-memory native SQLite executor for unit testing
      db = AppDatabase(NativeDatabase.memory());
      repository = DriftNotebookRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('persists notebook and retrieves it from SQLite', () async {
      final now = DateTime(2026, 11, 14, 15, 30);
      final testNotebook = Notebook(
        id: 'drift-test-1',
        ownerId: 'user-sqlite',
        title: 'Biochemistry Research',
        description: 'Enzyme kinetics experiments',
        coverId: 'minimal_sage',
        coverColorHex: '#4A6B53',
        paperTemplateId: 'square_grid',
        orientation: 'portrait',
        pageSize: 'A4',
        pageCount: 32,
        isFavorite: true,
        revision: 2,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveNotebook(testNotebook);

      final retrieved = await repository.getNotebookById('drift-test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'drift-test-1');
      expect(retrieved.title, 'Biochemistry Research');
      expect(retrieved.description, 'Enzyme kinetics experiments');
      expect(retrieved.isFavorite, true);
      expect(retrieved.pageCount, 32);
    });

    test('toggles favorite and persists state update', () async {
      final now = DateTime(2026, 11, 14, 15, 30);
      final testNotebook = Notebook(
        id: 'drift-test-2',
        ownerId: 'user-sqlite',
        title: 'World History',
        coverId: 'classic_leather',
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveNotebook(testNotebook);
      await repository.toggleFavorite('drift-test-2');

      final updated = await repository.getNotebookById('drift-test-2');
      expect(updated, isNotNull);
      expect(updated!.isFavorite, true);
    });

    test(
      'soft deletes notebook so it is excluded from active queries',
      () async {
        final now = DateTime(2026, 11, 14, 15, 30);
        final testNotebook = Notebook(
          id: 'drift-test-delete',
          ownerId: 'user-sqlite',
          title: 'Temporary Notes',
          coverId: 'terracotta_art',
          createdAt: now,
          updatedAt: now,
        );

        await repository.saveNotebook(testNotebook);
        var all = await repository.getAllNotebooks();
        expect(all.any((nb) => nb.id == 'drift-test-delete'), true);

        await repository.deleteNotebook('drift-test-delete');
        all = await repository.getAllNotebooks();
        expect(all.any((nb) => nb.id == 'drift-test-delete'), false);
      },
    );

    test(
      'does not populate demo notebooks in production when database is empty',
      () async {
        final initial = await repository.getAllNotebooks();
        expect(initial.isEmpty, true);

        await repository.populateDefaultSamplesIfEmpty();
        final populated = await repository.getAllNotebooks();
        expect(populated.isEmpty, true);
      },
    );
  });
}
