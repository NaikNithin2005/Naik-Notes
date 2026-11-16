import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/services/pdf/pdf_service.dart';

// Minimal mock repos for testing standalone PDF rendering functions
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';

class _FakeNotebookRepo implements NotebookRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePageRepo implements PageRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfService Export Tests', () {
    late PdfService pdfService;
    late Notebook sampleNotebook;
    late NotebookPage samplePage1;
    late NotebookPage samplePage2;
    late List<Stroke> sampleStrokes;
    late List<StickyNote> sampleNotes;

    setUp(() {
      pdfService = PdfService(_FakeNotebookRepo(), _FakePageRepo());
      final now = DateTime.now();

      sampleNotebook = Notebook(
        id: 'nb-test-pdf',
        ownerId: 'user_1',
        title: 'Organic Chemistry Notes',
        coverId: 'dark_academia_leather',
        coverColorHex: '#1E293B',
        paperTemplateId: 'college_ruled',
        createdAt: now,
        updatedAt: now,
      );

      samplePage1 = NotebookPage(
        id: 'page-1',
        notebookId: sampleNotebook.id,
        pageNumber: 1,
        templateId: 'college_ruled',
        properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
        createdAt: now,
        updatedAt: now,
      );

      samplePage2 = NotebookPage(
        id: 'page-2',
        notebookId: sampleNotebook.id,
        pageNumber: 2,
        templateId: 'square_grid',
        properties: PaperProperties.defaultFor(PaperTemplateType.squareGrid),
        createdAt: now,
        updatedAt: now,
      );

      sampleStrokes = [
        Stroke(
          id: 'stroke-1',
          pageId: samplePage1.id,
          tool: ToolType.fountainPen,
          colorValue: 0xFF0284C7,
          width: 3.0,
          opacity: 1.0,
          points: const [
            StrokePoint(x: 50, y: 100, timestamp: 1000),
            StrokePoint(x: 150, y: 200, timestamp: 1050),
          ],
          createdAt: now,
        ),
      ];

      sampleNotes = [
        StickyNote(
          id: 'note-1',
          pageId: samplePage1.id,
          x: 40,
          y: 60,
          width: 200,
          height: 100,
          content: 'Exothermic reaction review',
          colorHex: '#FEF08A',
          createdAt: now,
          updatedAt: now,
        ),
      ];
    });

    test('exportSinglePagePdf generates valid PDF bytes', () async {
      final bytes = await pdfService.exportSinglePagePdf(
        notebook: sampleNotebook,
        page: samplePage1,
        strokes: sampleStrokes,
        stickyNotes: sampleNotes,
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
      // Valid PDF begins with %PDF-
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('exportPageRangePdf generates valid multi-page PDF bytes', () async {
      final bytes = await pdfService.exportPageRangePdf(
        notebook: sampleNotebook,
        pages: [samplePage1, samplePage2],
        strokesPerPage: {samplePage1.id: sampleStrokes, samplePage2.id: []},
        stickyNotesPerPage: {samplePage1.id: sampleNotes, samplePage2.id: []},
      );

      expect(bytes, isA<Uint8List>());
      expect(bytes.length, greaterThan(1000));
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('renderPageToPng rasterizes canvas to valid PNG bytes', () async {
      final pngBytes = await pdfService.renderPageToPng(
        page: samplePage1,
        strokes: sampleStrokes,
        stickyNotes: sampleNotes,
        pixelRatio: 1.0,
      );

      expect(pngBytes, isA<Uint8List>());
      expect(pngBytes.isNotEmpty, isTrue);
      // Valid PNG begins with magic bytes: 0x89 0x50 0x4E 0x47 (\x89PNG)
      expect(pngBytes[0], equals(0x89));
      expect(pngBytes[1], equals(0x50));
      expect(pngBytes[2], equals(0x4E));
      expect(pngBytes[3], equals(0x47));
    });
  });
}
