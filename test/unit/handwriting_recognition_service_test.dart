import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/page_search_repository.dart';
import 'package:naik_notes/services/recognition/handwriting_recognition_service.dart';

void main() {
  group('HandwritingRecognitionService Tests', () {
    late AppDatabase db;
    late DriftPageSearchRepository searchRepo;
    late HandwritingRecognitionService recognitionService;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      searchRepo = DriftPageSearchRepository(db);
      recognitionService = HandwritingRecognitionService(
        searchRepository: searchRepo,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'clusterStrokesIntoWords returns empty list for empty or non-pen strokes',
      () {
        final now = DateTime.now();
        final eraserStroke = Stroke(
          id: 's-erase',
          pageId: 'page-1',
          tool: ToolType.eraser,
          colorValue: 0xFF000000,
          width: 10,
          opacity: 1.0,
          points: const [
            StrokePoint(x: 10, y: 10, timestamp: 100),
            StrokePoint(x: 20, y: 20, timestamp: 110),
          ],
          createdAt: now,
        );

        final lassoStroke = Stroke(
          id: 's-lasso',
          pageId: 'page-1',
          tool: ToolType.lasso,
          colorValue: 0xFF000000,
          width: 1,
          opacity: 1.0,
          points: const [StrokePoint(x: 10, y: 10, timestamp: 100)],
          createdAt: now,
        );

        expect(recognitionService.clusterStrokesIntoWords([]), isEmpty);
        expect(
          recognitionService.clusterStrokesIntoWords([
            eraserStroke,
            lassoStroke,
          ]),
          isEmpty,
        );
      },
    );

    test('clusterStrokesIntoWords groups adjacent strokes into one word bounding box', () {
      final now = DateTime.now();
      // Stroke 1: letters "N-a" at x=10..35, y=50..70
      final s1 = Stroke(
        id: 's1',
        pageId: 'page-1',
        tool: ToolType.ballpointPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: const [
          StrokePoint(x: 10, y: 50, timestamp: 100),
          StrokePoint(x: 35, y: 70, timestamp: 120),
        ],
        createdAt: now,
      );

      // Stroke 2: letters "i-k" at x=40..60, y=52..68 (gap = 5px <= 35px threshold)
      final s2 = Stroke(
        id: 's2',
        pageId: 'page-1',
        tool: ToolType.ballpointPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: const [
          StrokePoint(x: 40, y: 52, timestamp: 130),
          StrokePoint(x: 60, y: 68, timestamp: 150),
        ],
        createdAt: now,
      );

      // Stroke 3: second word far to the right at x=150..180 (gap = 90px > 35px threshold)
      final s3 = Stroke(
        id: 's3',
        pageId: 'page-1',
        tool: ToolType.ballpointPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: const [
          StrokePoint(x: 150, y: 50, timestamp: 200),
          StrokePoint(x: 180, y: 70, timestamp: 220),
        ],
        createdAt: now,
      );

      final words = recognitionService.clusterStrokesIntoWords(
        [s1, s2, s3],
        lexicon: ['Naik', 'Notes'],
      );

      expect(words.length, 2);

      // First word cluster covers s1 and s2
      final first = words[0];
      expect(first.word, 'Naik');
      expect(first.strokeIds.contains('s1'), true);
      expect(first.strokeIds.contains('s2'), true);
      expect(first.left, lessThanOrEqualTo(10.0));
      expect(first.right, greaterThanOrEqualTo(60.0));

      // Second word cluster covers s3
      final second = words[1];
      expect(second.word, 'Notes');
      expect(second.strokeIds, ['s3']);
      expect(second.left, lessThanOrEqualTo(150.0));
      expect(second.right, greaterThanOrEqualTo(180.0));
    });

    test(
      'processAndIndexStrokes saves clustered strokes to search repository',
      () async {
        final now = DateTime.now();
        final stroke = Stroke(
          id: 'st-physics',
          pageId: 'page-p1',
          tool: ToolType.fountainPen,
          colorValue: 0xFF000000,
          width: 2.5,
          opacity: 1.0,
          points: const [
            StrokePoint(x: 100, y: 120, timestamp: 100),
            StrokePoint(x: 150, y: 140, timestamp: 150),
          ],
          createdAt: now,
        );

        final entry = await recognitionService.processAndIndexStrokes(
          'page-p1',
          'nb-physics',
          [stroke],
          lexicon: ['Physics'],
        );

        expect(entry.pageId, 'page-p1');
        expect(entry.notebookId, 'nb-physics');
        expect(entry.textContent.contains('Physics'), true);
        expect(entry.boundingBoxes.length, 1);

        // Verify searchRepo can find it
        final searchHits = await searchRepo.searchPages('physics');
        expect(searchHits.length, 1);
        expect(searchHits.first.pageId, 'page-p1');
      },
    );

    test('indexPdfPage and indexStickyNote index content properly', () async {
      await recognitionService.indexPdfPage(
        'page-pdf-1',
        'nb-pdf',
        'Introduction to Electromagnetism Chapter 3',
      );

      await recognitionService.indexStickyNote(
        'page-pdf-1',
        'nb-pdf',
        'note-1',
        'Remember Maxwell equations on Friday exam',
        left: 50,
        top: 80,
        width: 140,
        height: 100,
      );

      final pdfHits = await searchRepo.searchPages('electromagnetism');
      expect(pdfHits.length, 1);
      expect(pdfHits.first.sourceType, 'pdf');

      final noteHits = await searchRepo.searchPages('maxwell');
      expect(noteHits.length, 1);
      expect(noteHits.first.sourceType, 'sticky_note');
      expect(noteHits.first.boundingBoxes.first.width, 140.0);
    });
  });
}
