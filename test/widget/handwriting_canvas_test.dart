import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_canvas.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_toolbar.dart';

class InMemoryStrokeRepository implements StrokeRepository {
  final Map<String, List<Stroke>> _storage = {};

  @override
  Future<List<Stroke>> getStrokesForPage(String pageId) async {
    return (_storage[pageId] ?? []).where((s) => s.deletedAt == null).toList();
  }

  @override
  Stream<List<Stroke>> watchStrokesForPage(String pageId) {
    return Stream.value(
      (_storage[pageId] ?? []).where((s) => s.deletedAt == null).toList(),
    );
  }

  @override
  Future<void> saveStroke(Stroke stroke) async {
    final list = _storage.putIfAbsent(stroke.pageId, () => []);
    list.removeWhere((s) => s.id == stroke.id);
    list.add(stroke);
  }

  @override
  Future<void> saveStrokes(List<Stroke> strokes) async {
    for (final s in strokes) {
      await saveStroke(s);
    }
  }

  @override
  Future<void> softDeleteStroke(String strokeId) async {
    for (final list in _storage.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == strokeId) {
          list[i] = list[i].copyWith(deletedAt: DateTime.now());
        }
      }
    }
  }

  @override
  Future<void> softDeleteStrokes(List<String> strokeIds) async {
    for (final id in strokeIds) {
      await softDeleteStroke(id);
    }
  }

  @override
  Future<void> restoreStroke(String strokeId) async {
    for (final list in _storage.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == strokeId) {
          list[i] = list[i].copyWith(clearDeletedAt: true);
        }
      }
    }
  }

  @override
  Future<void> permanentlyDeleteStroke(String strokeId) async {
    for (final list in _storage.values) {
      list.removeWhere((s) => s.id == strokeId);
    }
  }

  @override
  Future<void> clearPage(String pageId) async {
    final list = _storage[pageId] ?? [];
    for (int i = 0; i < list.length; i++) {
      list[i] = list[i].copyWith(deletedAt: DateTime.now());
    }
  }
}

void main() {
  group('Handwriting Canvas & Toolbar Widget Tests', () {
    late InMemoryStrokeRepository mockRepo;
    const testPageId = 'widget-test-page';

    setUp(() {
      mockRepo = InMemoryStrokeRepository();
    });

    Widget createTestApp({required Widget child}) {
      return ProviderScope(
        overrides: [strokeRepositoryProvider.overrideWithValue(mockRepo)],
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets('renders HandwritingToolbar with writing tools and swatches', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestApp(
          child: const Column(
            children: [HandwritingToolbar(pageId: testPageId)],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tool buttons should be visible
      expect(find.byIcon(Icons.edit), findsOneWidget); // Fountain
      expect(find.byIcon(Icons.border_color), findsOneWidget); // Ballpoint
      expect(find.byIcon(Icons.mode_edit_outline), findsOneWidget); // Pencil
      expect(find.byIcon(Icons.brush), findsOneWidget); // Brush
      expect(find.byIcon(Icons.highlight), findsOneWidget); // Highlighter
      expect(
        find.byIcon(Icons.cleaning_services_outlined),
        findsOneWidget,
      ); // Eraser
      expect(find.byIcon(Icons.gesture), findsOneWidget); // Lasso
      expect(find.byIcon(Icons.undo), findsOneWidget); // Undo
      expect(find.byIcon(Icons.redo), findsOneWidget); // Redo
    });

    testWidgets('switches tools and changes width preset on toolbar tap', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      late WidgetRef capturedRef;

      await tester.pumpWidget(
        createTestApp(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const Column(
                children: [HandwritingToolbar(pageId: testPageId)],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is fountain pen
      expect(capturedRef.read(activeToolProvider), ToolType.fountainPen);

      // Tap ballpoint tool
      await tester.tap(find.byIcon(Icons.border_color));
      await tester.pumpAndSettle();
      expect(capturedRef.read(activeToolProvider), ToolType.ballpointPen);

      // Tap "Bold" width chip
      await tester.tap(find.text('Bold'));
      await tester.pumpAndSettle();
      expect(capturedRef.read(strokeWidthProvider), 5.0);
    });

    testWidgets(
      'drawing on HandwritingCanvas produces vector stroke and enables undo',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        late WidgetRef capturedRef;

        await tester.pumpWidget(
          createTestApp(
            child: Consumer(
              builder: (context, ref, _) {
                capturedRef = ref;
                return Column(
                  children: [
                    const HandwritingToolbar(pageId: testPageId),
                    Expanded(
                      child: Center(
                        child: HandwritingCanvas(
                          pageId: testPageId,
                          type: PaperTemplateType.collegeRuled,
                          properties: PaperProperties.defaultFor(
                            PaperTemplateType.collegeRuled,
                          ),
                          width: 500,
                          height: 700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially no strokes and undo disabled
        expect(
          capturedRef.read(pageStrokesProvider(testPageId)).isEmpty,
          isTrue,
        );
        expect(capturedRef.read(canUndoProvider(testPageId)), isFalse);

        // Find canvas center
        final canvasFinder = find.byType(HandwritingCanvas);
        expect(canvasFinder, findsOneWidget);
        final canvasTopLeft = tester.getTopLeft(canvasFinder);

        // Perform stylus/finger gesture: down at (100, 100), move to (200, 200), up
        final gesture = await tester.startGesture(
          canvasTopLeft + const Offset(100, 100),
          kind: PointerDeviceKind.stylus,
        );
        await tester.pump();

        await gesture.moveTo(canvasTopLeft + const Offset(150, 150));
        await tester.pump();

        await gesture.moveTo(canvasTopLeft + const Offset(200, 200));
        await tester.pump();

        await gesture.up();
        await tester.pumpAndSettle();

        // Verify stroke was saved in provider
        final strokes = capturedRef.read(pageStrokesProvider(testPageId));
        expect(strokes.length, 1);
        expect(strokes.first.points.length, greaterThanOrEqualTo(2));
        expect(capturedRef.read(canUndoProvider(testPageId)), isTrue);

        // Tap Undo button on toolbar
        await tester.ensureVisible(find.byIcon(Icons.undo));
        await tester.tap(find.byIcon(Icons.undo));
        await tester.pumpAndSettle();

        // Verify stroke was undone
        expect(
          capturedRef.read(pageStrokesProvider(testPageId)).isEmpty,
          isTrue,
        );
        expect(capturedRef.read(canUndoProvider(testPageId)), isFalse);
        expect(capturedRef.read(canRedoProvider(testPageId)), isTrue);
      },
    );
  });
}
