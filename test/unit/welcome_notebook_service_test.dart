import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/features/notebooks/data/welcome_notebook_service.dart';

void main() {
  group('WelcomeNotebookService Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;
    late DriftStrokeRepository strokeRepo;
    late DriftStickyNoteRepository stickyRepo;
    late WelcomeNotebookService welcomeService;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);
      strokeRepo = DriftStrokeRepository(db);
      stickyRepo = DriftStickyNoteRepository(db);
      welcomeService = WelcomeNotebookService(
        notebookRepo,
        pageRepo,
        strokeRepo,
        stickyRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'creates 9-page interactive welcome notebook with guided activities',
      () async {
        const userId = 'user_test_123';

        expect(await welcomeService.hasWelcomeNotebook(userId), isFalse);

        final notebook = await welcomeService.createWelcomeNotebook(userId);

        expect(notebook.id, equals('welcome_notebook_$userId'));
        expect(notebook.title, equals('Welcome to Naik Notes'));
        expect(notebook.pageCount, equals(9));
        expect(await welcomeService.hasWelcomeNotebook(userId), isTrue);

        final pages = await pageRepo.getPagesForNotebook(notebook.id);
        expect(pages.length, equals(9));

        // Verify page templates
        expect(pages[0].templateId, equals('college_ruled'));
        expect(pages[3].templateId, equals('blank_paper'));
        expect(pages[4].templateId, equals('square_grid'));
        expect(pages[5].templateId, equals('dotted_paper'));
        expect(pages[6].templateId, equals('cornell_notes'));
        expect(pages[7].templateId, equals('blank_paper'));

        // Verify sticky notes generated for all pages
        for (final page in pages) {
          final notes = await stickyRepo.getStickyNotesForPage(page.id);
          expect(
            notes.isNotEmpty,
            isTrue,
            reason: 'Page ${page.pageNumber} should have a guide note',
          );
          expect(notes.first.content, contains('Activity ${page.pageNumber}'));
        }

        // Verify sample strokes exist on Activity 1, 2, 3, 4, 5
        final page1Strokes = await strokeRepo.getStrokesForPage(pages[0].id);
        expect(page1Strokes.isNotEmpty, isTrue);

        final page2Strokes = await strokeRepo.getStrokesForPage(pages[1].id);
        expect(page2Strokes.length, equals(3)); // 3 sample strokes
      },
    );

    test('ensureWelcomeNotebookCreated prevents duplicate creation', () async {
      const userId = 'user_test_456';

      final nb1 = await welcomeService.ensureWelcomeNotebookCreated(userId);
      expect(nb1, isNotNull);

      final allNotebooksBefore = await notebookRepo.getAllNotebooks(
        includeArchived: true,
      );
      expect(allNotebooksBefore.length, equals(1));

      // Attempt second creation
      final nb2 = await welcomeService.ensureWelcomeNotebookCreated(userId);
      expect(nb2, isNotNull);
      expect(nb2!.id, equals(nb1!.id));

      final allNotebooksAfter = await notebookRepo.getAllNotebooks(
        includeArchived: true,
      );
      expect(allNotebooksAfter.length, equals(1)); // No duplicate
    });
  });
}
