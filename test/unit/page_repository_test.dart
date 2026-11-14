import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';

void main() {
  group('DriftPageRepository SQLite Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);

      // Create a test parent notebook in DB
      final now = DateTime.now();
      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb-pages-test',
          ownerId: 'user-test',
          title: 'Physics Lab Notebook',
          coverId: 'dark_academia_leather',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('creates and retrieves default pages for a notebook', () async {
      final pages = await pageRepo.ensurePagesExist(
        'nb-pages-test',
        templateId: 'engineering_paper',
        count: 3,
      );

      expect(pages.length, 3);
      expect(pages[0].pageNumber, 1);
      expect(pages[0].templateId, 'engineering_paper');
      expect(pages[0].properties.backgroundColorHex, '#F2F8F4');

      final retrieved = await pageRepo.getPagesForNotebook('nb-pages-test');
      expect(retrieved.length, 3);
    });

    test('updates page template and custom properties', () async {
      final pages = await pageRepo.ensurePagesExist('nb-pages-test', count: 1);
      final page1 = pages.first;

      const updatedProps = PaperProperties(
        backgroundColorHex: '#FAF0F2',
        lineColorHex: '#E53E3E',
        lineSpacing: 25.0,
      );

      await pageRepo.updatePageTemplate(
        page1.id,
        'cornell_notes',
        updatedProps,
      );

      final reloaded = await pageRepo.getPageById(page1.id);
      expect(reloaded, isNotNull);
      expect(reloaded!.templateId, 'cornell_notes');
      expect(reloaded.properties.backgroundColorHex, '#FAF0F2');
      expect(reloaded.properties.lineSpacing, 25.0);
    });

    test('deletes a page correctly', () async {
      final pages = await pageRepo.ensurePagesExist('nb-pages-test', count: 2);
      expect(pages.length, 2);

      await pageRepo.deletePage(pages.first.id);

      final remaining = await pageRepo.getPagesForNotebook('nb-pages-test');
      expect(remaining.length, 1);
      expect(remaining.first.id, pages.last.id);
    });

    test('supports mixing multiple templates in one notebook', () async {
      final now = DateTime.now();
      final page1 = NotebookPage(
        id: 'p-1',
        notebookId: 'nb-pages-test',
        pageNumber: 1,
        templateId: 'college_ruled',
        properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
        createdAt: now,
        updatedAt: now,
      );
      final page2 = NotebookPage(
        id: 'p-2',
        notebookId: 'nb-pages-test',
        pageNumber: 2,
        templateId: 'cornell_notes',
        properties: PaperProperties.defaultFor(PaperTemplateType.cornellNotes),
        createdAt: now,
        updatedAt: now,
      );
      final page3 = NotebookPage(
        id: 'p-3',
        notebookId: 'nb-pages-test',
        pageNumber: 3,
        templateId: 'music_manuscript',
        properties: PaperProperties.defaultFor(
          PaperTemplateType.musicManuscript,
        ),
        createdAt: now,
        updatedAt: now,
      );

      await pageRepo.savePage(page1);
      await pageRepo.savePage(page2);
      await pageRepo.savePage(page3);

      final mixedPages = await pageRepo.getPagesForNotebook('nb-pages-test');
      expect(mixedPages.length, 3);
      expect(mixedPages[0].templateId, 'college_ruled');
      expect(mixedPages[1].templateId, 'cornell_notes');
      expect(mixedPages[2].templateId, 'music_manuscript');
    });
  });
}
