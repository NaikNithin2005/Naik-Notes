import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_canvas.dart';
import 'package:naik_notes/features/canvas/rendering/search_highlight_painter.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_document_search_bar.dart';

void main() {
  group('Search Highlight and Canvas Rendering Tests', () {
    testWidgets('SearchHighlightPainter paints without throwing', (
      tester,
    ) async {
      const boxes = [
        WordBoundingBox(
          word: 'Naik',
          left: 50,
          top: 60,
          right: 120,
          bottom: 90,
          confidence: 0.95,
        ),
        WordBoundingBox(
          word: 'Notes',
          left: 140,
          top: 60,
          right: 210,
          bottom: 90,
          confidence: 0.92,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 300),
              painter: SearchHighlightPainter(
                matchingBoxes: boxes,
                activeIndex: 0,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is SearchHighlightPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('HandwritingCanvas renders search highlights overlay layer', (
      tester,
    ) async {
      const boxes = [
        WordBoundingBox(
          word: 'Physics',
          left: 40,
          top: 50,
          right: 130,
          bottom: 85,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 800,
                child: HandwritingCanvas(
                  pageId: 'page-search-test',
                  type: PaperTemplateType.collegeRuled,
                  properties: PaperProperties.defaultFor(
                    PaperTemplateType.collegeRuled,
                  ),
                  width: 600,
                  height: 800,
                  searchMatches: boxes,
                  activeSearchIndex: 0,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(HandwritingCanvas), findsOneWidget);
    });

    testWidgets(
      'PdfDocumentSearchBar updates search query and triggers next/prev match',
      (tester) async {
        String query = '';
        int nextCount = 0;
        int prevCount = 0;
        bool closed = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: PdfDocumentSearchBar(
                  currentMatchIndex: 2,
                  totalMatches: 5,
                  onSearch: (q) => query = q,
                  onNextMatch: () => nextCount++,
                  onPreviousMatch: () => prevCount++,
                  onClose: () => closed = true,
                ),
              ),
            ),
          ),
        );

        // Verify "2 of 5" is displayed
        expect(find.text('2 of 5'), findsOneWidget);

        // Tap Next match
        await tester.tap(find.byTooltip('Next match'));
        await tester.pump();
        expect(nextCount, 1);

        // Tap Previous match
        await tester.tap(find.byTooltip('Previous match'));
        await tester.pump();
        expect(prevCount, 1);

        // Type in search text
        await tester.enterText(find.byType(TextField), 'calculus');
        await tester.pump();
        expect(query, 'calculus');

        // Tap Close
        await tester.tap(find.byTooltip('Close search'));
        await tester.pump();
        expect(closed, true);
      },
    );
  });
}
