import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_document_search_bar.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_thumbnail_sidebar.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/sticky_note_widget.dart';

class MockPageRepository implements PageRepository {
  final List<NotebookPage> pages = [];

  @override
  Future<List<NotebookPage>> getPagesForNotebook(String notebookId) async =>
      pages;
  @override
  Stream<List<NotebookPage>> watchPagesForNotebook(String notebookId) =>
      Stream.value(pages);
  @override
  Future<NotebookPage?> getPageById(String pageId) async =>
      pages.firstWhere((p) => p.id == pageId);
  @override
  Future<void> savePage(NotebookPage page) async {
    pages.removeWhere((p) => p.id == page.id);
    pages.add(page);
  }

  @override
  Future<void> deletePage(String pageId) async {
    pages.removeWhere((p) => p.id == pageId);
  }

  @override
  Future<void> updatePageTemplate(
    String pageId,
    String templateId,
    PaperProperties properties,
  ) async {}
  @override
  Future<void> toggleBookmark(String pageId) async {
    final idx = pages.indexWhere((p) => p.id == pageId);
    if (idx != -1) {
      pages[idx] = pages[idx].copyWith(isBookmarked: !pages[idx].isBookmarked);
    }
  }

  @override
  Future<List<NotebookPage>> ensurePagesExist(
    String notebookId, {
    String templateId = 'college_ruled',
    String pageSize = 'A4',
    String orientation = 'portrait',
    int count = 1,
  }) async => pages;
}

class MockStickyRepo implements StickyNoteRepository {
  final Map<String, List<StickyNote>> notes = {};

  @override
  Future<List<StickyNote>> getStickyNotesForPage(String pageId) async =>
      notes[pageId] ?? [];
  @override
  Stream<List<StickyNote>> watchStickyNotesForPage(String pageId) =>
      Stream.value(notes[pageId] ?? []);
  @override
  Future<void> saveStickyNote(StickyNote note) async {
    final list = notes.putIfAbsent(note.pageId, () => []);
    list.removeWhere((n) => n.id == note.id);
    list.add(note);
  }

  @override
  Future<void> deleteStickyNote(String id) async {
    for (final list in notes.values) {
      list.removeWhere((n) => n.id == id);
    }
  }

  @override
  Future<void> updatePosition(String id, double x, double y) async {}
  @override
  Future<void> updateContent(String id, String content) async {}
  @override
  Future<void> updateColor(String id, String colorHex) async {}
}

void main() {
  group('PDF Features & Widgets Tests', () {
    late MockPageRepository pageRepo;
    late MockStickyRepo stickyRepo;
    const testNotebookId = 'nb-widget-test';

    final now = DateTime.now();
    final samplePages = [
      NotebookPage(
        id: 'p-1',
        notebookId: testNotebookId,
        pageNumber: 1,
        templateId: 'blank_paper',
        properties: PaperProperties.defaultFor(PaperTemplateType.blankPaper),
        isBookmarked: true,
        createdAt: now,
        updatedAt: now,
      ),
      NotebookPage(
        id: 'p-2',
        notebookId: testNotebookId,
        pageNumber: 2,
        templateId: 'college_ruled',
        properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
        isBookmarked: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      pageRepo = MockPageRepository()..pages.addAll(samplePages);
      stickyRepo = MockStickyRepo();
    });

    Widget createTestApp({required Widget child}) {
      return ProviderScope(
        overrides: [
          pageRepositoryProvider.overrideWithValue(pageRepo),
          stickyNoteRepositoryProvider.overrideWithValue(stickyRepo),
        ],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets(
      'PdfThumbnailSidebar displays page thumbnails and handles selection',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1000, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int selectedPage = 1;
        bool closed = false;

        await tester.pumpWidget(
          createTestApp(
            child: PdfThumbnailSidebar(
              notebookId: testNotebookId,
              pages: samplePages,
              currentPageIndex: 1,
              onSelectPage: (idx) => selectedPage = idx,
              onClose: () => closed = true,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Thumbnails'), findsOneWidget);
        expect(find.text('Page 1'), findsOneWidget);
        expect(find.text('Page 2'), findsOneWidget);

        // Tap Page 2 thumbnail
        await tester.tap(find.text('Page 2'));
        await tester.pumpAndSettle();
        expect(selectedPage, 2);

        // Filter by bookmarked
        await tester.tap(find.text('Bookmarks (1)'));
        await tester.pumpAndSettle();

        // Only Page 1 is bookmarked
        expect(find.text('Page 1'), findsOneWidget);
        expect(find.text('Page 2'), findsNothing);

        // Close sidebar
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(closed, isTrue);
      },
    );

    testWidgets('StickyNoteWidget renders text and allows editing', (
      tester,
    ) async {
      final note = StickyNote(
        id: 'sticky-widget-1',
        pageId: 'p-1',
        x: 50,
        y: 50,
        content: 'Remember thermodynamics chapter',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      bool deleted = false;

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              StickyNoteWidget(note: note, onDelete: () => deleted = true),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Remember thermodynamics chapter'), findsOneWidget);

      // Tap close to delete
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('PdfDocumentSearchBar triggers search and close callbacks', (
      tester,
    ) async {
      String searched = '';
      bool closed = false;

      await tester.pumpWidget(
        createTestApp(
          child: PdfDocumentSearchBar(
            onSearch: (q) => searched = q,
            onNextMatch: () {},
            onPreviousMatch: () {},
            onClose: () => closed = true,
            totalMatches: 3,
            currentMatchIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 of 3'), findsOneWidget);

      // Type search query
      await tester.enterText(find.byType(TextField), 'Quantum');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(searched, 'Quantum');

      // Close search
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(closed, isTrue);
    });
  });
}
