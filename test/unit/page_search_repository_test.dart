import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/data/repositories/page_search_repository.dart';

void main() {
  group('DriftPageSearchRepository SQLite Tests', () {
    late AppDatabase db;
    late DriftPageSearchRepository searchRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      searchRepo = DriftPageSearchRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('indexes and retrieves page search entries', () async {
      final now = DateTime.now();
      final entry = PageSearchEntry(
        id: 'idx-1',
        pageId: 'page-101',
        notebookId: 'nb-calc',
        sourceType: 'handwriting',
        textContent: 'Calculus derivatives and integral formulas',
        boundingBoxes: const [
          WordBoundingBox(
            word: 'Calculus',
            left: 20,
            top: 50,
            right: 100,
            bottom: 80,
            confidence: 0.98,
          ),
          WordBoundingBox(
            word: 'derivatives',
            left: 110,
            top: 50,
            right: 210,
            bottom: 80,
            confidence: 0.95,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      await searchRepo.indexPageContent(entry);

      final results = await searchRepo.searchPages('calculus');
      expect(results.length, 1);
      expect(results.first.pageId, 'page-101');
      expect(results.first.notebookId, 'nb-calc');
      expect(results.first.sourceType, 'handwriting');
      expect(results.first.boundingBoxes.length, 2);
      expect(results.first.boundingBoxes.first.word, 'Calculus');
      expect(results.first.boundingBoxes.first.left, 20.0);
    });

    test('searchPages filters by notebookId when provided', () async {
      final now = DateTime.now();
      await searchRepo.indexPageContent(
        PageSearchEntry(
          id: 'idx-1',
          pageId: 'page-1',
          notebookId: 'nb-math',
          sourceType: 'handwriting',
          textContent: 'Quantum physics equations',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await searchRepo.indexPageContent(
        PageSearchEntry(
          id: 'idx-2',
          pageId: 'page-2',
          notebookId: 'nb-physics',
          sourceType: 'handwriting',
          textContent: 'Quantum mechanics notes',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Search all
      final allQuantum = await searchRepo.searchPages('quantum');
      expect(allQuantum.length, 2);

      // Search scoped to nb-physics
      final physicsOnly = await searchRepo.searchPages(
        'quantum',
        notebookId: 'nb-physics',
      );
      expect(physicsOnly.length, 1);
      expect(physicsOnly.first.notebookId, 'nb-physics');
    });

    test(
      're-indexing page updates existing entry and replaces boxes',
      () async {
        final now = DateTime.now();
        final initial = PageSearchEntry(
          id: 'idx-rev1',
          pageId: 'page-rev',
          notebookId: 'nb-rev',
          sourceType: 'handwriting',
          textContent: 'Initial draft',
          boundingBoxes: const [
            WordBoundingBox(
              word: 'Initial',
              left: 10,
              top: 10,
              right: 60,
              bottom: 30,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );
        await searchRepo.indexPageContent(initial);

        final updated = PageSearchEntry(
          id: 'idx-rev2',
          pageId: 'page-rev',
          notebookId: 'nb-rev',
          sourceType: 'handwriting',
          textContent: 'Revised draft with final conclusions',
          boundingBoxes: const [
            WordBoundingBox(
              word: 'Revised',
              left: 10,
              top: 10,
              right: 70,
              bottom: 30,
            ),
            WordBoundingBox(
              word: 'conclusions',
              left: 80,
              top: 10,
              right: 180,
              bottom: 30,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        );
        await searchRepo.indexPageContent(updated);

        final results = await searchRepo.getEntriesForPage('page-rev');
        expect(results.length, 1);
        expect(
          results.first.textContent,
          'Revised draft with final conclusions',
        );
        expect(results.first.boundingBoxes.length, 2);
      },
    );

    test('deletes entries by pageId and by notebookId', () async {
      final now = DateTime.now();
      await searchRepo.indexPageContent(
        PageSearchEntry(
          id: 'idx-del1',
          pageId: 'page-del-1',
          notebookId: 'nb-to-delete',
          sourceType: 'handwriting',
          textContent: 'Delete me soon',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await searchRepo.indexPageContent(
        PageSearchEntry(
          id: 'idx-del2',
          pageId: 'page-del-2',
          notebookId: 'nb-to-delete',
          sourceType: 'pdf',
          textContent: 'Delete me as well',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Verify inserted
      var results = await searchRepo.searchPages('delete');
      expect(results.length, 2);

      // Delete by page
      await searchRepo.deleteEntriesForPage('page-del-1');
      results = await searchRepo.searchPages('delete');
      expect(results.length, 1);
      expect(results.first.pageId, 'page-del-2');

      // Delete entire notebook
      await searchRepo.deleteEntriesForNotebook('nb-to-delete');
      results = await searchRepo.searchPages('delete');
      expect(results.isEmpty, true);
    });
  });
}
