import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/folder_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/data/repositories/folder_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/page_search_repository.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';
import 'package:naik_notes/services/search/search_service.dart';

void main() {
  group('SearchService Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftFolderRepository folderRepo;
    late DriftPageRepository pageRepo;
    late DriftPageSearchRepository pageSearchRepo;
    late DriftStickyNoteRepository stickyNoteRepo;
    late SearchService searchService;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      folderRepo = DriftFolderRepository(db);
      pageRepo = DriftPageRepository(db);
      pageSearchRepo = DriftPageSearchRepository(db);
      stickyNoteRepo = DriftStickyNoteRepository(db);

      searchService = SearchService(
        notebookRepository: notebookRepo,
        folderRepository: folderRepo,
        pageRepository: pageRepo,
        pageSearchRepository: pageSearchRepo,
        stickyNoteRepository: stickyNoteRepo,
      );

      final now = DateTime.now();

      // Seed Folder
      await folderRepo.saveFolder(
        Folder(
          id: 'f-science',
          name: 'Computer Science',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Seed Notebooks
      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb-ai',
          ownerId: 'user-test',
          title: 'Artificial Intelligence & Neural Nets',
          description: 'Deep learning notes with backpropagation formulas',
          coverId: 'dark_academia_leather',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb-math',
          ownerId: 'user-test',
          title: 'Linear Algebra',
          description: 'Vector spaces and matrix decomposition',
          coverId: 'minimal_kraft',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Seed Pages
      await pageRepo.savePage(
        NotebookPage(
          id: 'page-ai-1',
          notebookId: 'nb-ai',
          pageNumber: 1,
          templateId: 'square_grid',
          properties: PaperProperties.defaultFor(PaperTemplateType.squareGrid),
          width: 595,
          height: 842,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Seed Page Search Index
      await pageSearchRepo.indexPageContent(
        PageSearchEntry(
          id: 'idx-1',
          pageId: 'page-ai-1',
          notebookId: 'nb-ai',
          sourceType: 'handwriting',
          textContent: 'Gradient descent optimization algorithm notes',
          boundingBoxes: const [
            WordBoundingBox(
              word: 'Gradient',
              left: 40,
              top: 80,
              right: 120,
              bottom: 110,
            ),
            WordBoundingBox(
              word: 'descent',
              left: 130,
              top: 80,
              right: 210,
              bottom: 110,
            ),
          ],
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'searchGlobal returns matches across notebooks, folders, and indexed content',
      () async {
        // 1. Search notebook title
        final aiResults = await searchService.searchGlobal('neural');
        expect(aiResults.length, 1);
        expect(aiResults.first.sourceType, 'notebookTitle');
        expect(aiResults.first.notebookId, 'nb-ai');

        // 2. Search folder
        final folderResults = await searchService.searchGlobal('computer');
        expect(folderResults.length, 1);
        expect(folderResults.first.sourceType, 'folder');
        expect(
          folderResults.first.notebookTitle.contains('Computer Science'),
          true,
        );

        // 3. Search indexed handwriting content
        final hwResults = await searchService.searchGlobal('gradient');
        expect(hwResults.length, 1);
        expect(hwResults.first.sourceType, 'handwriting');
        expect(hwResults.first.notebookId, 'nb-ai');
        expect(hwResults.first.pageNumber, 1);
        expect(hwResults.first.matchingBoxes.length, 1);
        expect(hwResults.first.matchingBoxes.first.word, 'Gradient');
        expect(hwResults.first.snippet.contains('Gradient descent'), true);

        // 4. Empty query
        final emptyResults = await searchService.searchGlobal('   ');
        expect(emptyResults.isEmpty, true);
      },
    );

    test(
      'searchInNotebook returns scoped matches and bounding boxes',
      () async {
        final matches = await searchService.searchInNotebook(
          'nb-ai',
          'descent',
        );
        expect(matches.length, 1);
        expect(matches.first.pageId, 'page-ai-1');
        expect(matches.first.pageNumber, 1);
        expect(matches.first.matchingBoxes.length, 1);
        expect(matches.first.matchingBoxes.first.word, 'descent');
        expect(matches.first.matchingBoxes.first.left, 130.0);

        // Searching for a word not in nb-ai returns empty
        final notFound = await searchService.searchInNotebook(
          'nb-ai',
          'nonexistentterm',
        );
        expect(notFound.isEmpty, true);
      },
    );
  });
}
