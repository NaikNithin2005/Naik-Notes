import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/services/pdf/pdf_service.dart';

void main() {
  group('PdfService Unit Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;
    late PdfService pdfService;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);
      pdfService = PdfService(notebookRepo, pageRepo);
    });

    tearDown(() async {
      await db.close();
    });

    test('estimatePageCount accurately counts PDF page objects', () {
      const mockPdfContent = '''
%PDF-1.4
1 0 obj <</Type /Catalog /Pages 2 0 R>> endobj
2 0 obj <</Type /Pages /Kids [3 0 R 4 0 R 5 0 R] /Count 3>> endobj
3 0 obj <</Type /Page /Parent 2 0 R>> endobj
4 0 obj <</Type /Page /Parent 2 0 R>> endobj
5 0 obj <</Type /Page /Parent 2 0 R>> endobj
%%EOF
''';
      final bytes = utf8.encode(mockPdfContent);
      final count = pdfService.estimatePageCount(bytes);
      expect(count, 3);
    });

    test(
      'importPdfFromBytes creates notebook and provisions all pages in SQLite',
      () async {
        const mockPdfContent = '''
%PDF-1.4
1 0 obj <</Type /Page>> endobj
2 0 obj <</Type /Page>> endobj
%%EOF
''';
        final bytes = utf8.encode(mockPdfContent);
        final notebook = await pdfService.importPdfFromBytes(
          bytes: bytes,
          filename: 'Neuroscience_Lecture_01.pdf',
        );

        expect(notebook.isPdf, isTrue);
        expect(notebook.title, 'Neuroscience_Lecture_01');
        expect(notebook.pageCount, 2);

        // Verify persisted in DB
        final savedNotebook = await notebookRepo.getNotebookById(notebook.id);
        expect(savedNotebook, isNotNull);
        expect(savedNotebook!.isPdf, isTrue);

        final pages = await pageRepo.getPagesForNotebook(notebook.id);
        expect(pages.length, 2);
        expect(pages[0].pageNumber, 1);
        expect(pages[0].pdfPageIndex, 0);
        expect(pages[1].pageNumber, 2);
        expect(pages[1].pdfPageIndex, 1);
      },
    );

    test('extractTableOfContents returns structured outline hierarchy', () {
      final toc = pdfService.extractTableOfContents('Test Book', 12);
      expect(toc.isNotEmpty, isTrue);
      expect(toc.first.title, 'Cover & Title Page');
      expect(toc.last.title, 'Summary & References');
      expect(toc.last.pageIndex, 11);
    });

    test('exportFlattenedPdf generates complete binary PDF document', () async {
      final now = DateTime.now();
      final notebook = Notebook(
        id: 'nb-export-test',
        ownerId: 'user-test',
        title: 'Export Test',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );

      final page = NotebookPage(
        id: 'page-export-1',
        notebookId: notebook.id,
        pageNumber: 1,
        templateId: 'blank_paper',
        properties: PaperProperties.defaultFor(PaperTemplateType.blankPaper),
        createdAt: now,
        updatedAt: now,
      );

      final stroke = Stroke(
        id: 'stroke-export-1',
        pageId: page.id,
        tool: ToolType.fountainPen,
        colorValue: 0xFF1D4ED8,
        width: 3.0,
        opacity: 1.0,
        points: [
          const StrokePoint(x: 50, y: 50, timestamp: 1),
          const StrokePoint(x: 100, y: 150, timestamp: 2),
        ],
        createdAt: now,
      );

      final note = StickyNote(
        id: 'sticky-export-1',
        pageId: page.id,
        x: 120,
        y: 80,
        content: 'Review for finals!',
        createdAt: now,
        updatedAt: now,
      );

      final pdfBytes = await pdfService.exportFlattenedPdf(
        notebook: notebook,
        pages: [page],
        strokesPerPage: {
          page.id: [stroke],
        },
        stickyNotesPerPage: {
          page.id: [note],
        },
      );

      expect(pdfBytes.isNotEmpty, isTrue);
      // Valid PDF documents start with %PDF
      final header = utf8.decode(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });
  });
}
