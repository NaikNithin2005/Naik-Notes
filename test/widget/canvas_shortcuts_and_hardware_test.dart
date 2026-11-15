import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_canvas.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_shortcuts.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_toolbar.dart';
import 'package:naik_notes/platform/models/stylus_event.dart';
import 'package:naik_notes/platform/platform_input_adapter.dart';
import 'package:naik_notes/platform/windows/windows_pen_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftStrokeRepository strokeRepo;
  late WindowsPenAdapter testInputAdapter;

  const testPageId = 'hw-test-page-01';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    strokeRepo = DriftStrokeRepository(db);
    testInputAdapter = WindowsPenAdapter();
  });

  tearDown(() async {
    testInputAdapter.dispose();
    await db.close();
  });

  Widget buildTestApp({
    required Widget child,
    List<dynamic> extraOverrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        strokeRepositoryProvider.overrideWithValue(strokeRepo),
        platformInputAdapterProvider.overrideWithValue(testInputAdapter),
        ...extraOverrides.cast(),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  group('HandwritingShortcuts Widget Tests', () {
    testWidgets(
      'handles keyboard shortcuts for undo, redo, and zoom callbacks',
      (tester) async {
        bool zoomInCalled = false;
        bool zoomOutCalled = false;
        bool resetZoomCalled = false;
        bool addPageCalled = false;
        bool searchCalled = false;

        final container = ProviderContainer(
          overrides: [
            strokeRepositoryProvider.overrideWithValue(strokeRepo),
            platformInputAdapterProvider.overrideWithValue(testInputAdapter),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: HandwritingShortcuts(
                  pageId: testPageId,
                  onZoomIn: () => zoomInCalled = true,
                  onZoomOut: () => zoomOutCalled = true,
                  onResetZoom: () => resetZoomCalled = true,
                  onAddPage: () => addPageCalled = true,
                  onToggleSearch: () => searchCalled = true,
                  child: const Text('Canvas Shortcut Target'),
                ),
              ),
            ),
          ),
        );

        // Verify zoom in (Ctrl + =)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.equal);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        expect(zoomInCalled, isTrue);

        // Verify zoom out (Ctrl + -)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.minus);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        expect(zoomOutCalled, isTrue);

        // Verify reset zoom (Ctrl + 0)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        expect(resetZoomCalled, isTrue);

        // Verify search (Ctrl + F)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        expect(searchCalled, isTrue);

        // Verify add page (Ctrl + N)
        await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
        expect(addPageCalled, isTrue);

        // Verify tool selection key 'E' for Eraser
        await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
        expect(container.read(activeToolProvider), ToolType.eraser);

        // Verify tool selection key 'H' for Highlighter
        await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
        expect(container.read(activeToolProvider), ToolType.highlighter);

        // Verify tool selection key 'P' for Pen
        await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
        expect(container.read(activeToolProvider), ToolType.ballpointPen);

        container.dispose();
      },
    );

    testWidgets('suppresses single-key shortcuts when text field is focused', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          strokeRepositoryProvider.overrideWithValue(strokeRepo),
          platformInputAdapterProvider.overrideWithValue(testInputAdapter),
        ],
      );

      final textController = TextEditingController();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: HandwritingShortcuts(
                pageId: testPageId,
                child: Column(
                  children: [
                    TextField(controller: textController, autofocus: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      container
          .read(activeToolProvider.notifier)
          .setTool(ToolType.ballpointPen);

      // When text field is focused, typing 'E' should write into text field, NOT switch tool to eraser!
      await tester.enterText(find.byType(TextField), 'E');
      await tester.pump();

      expect(textController.text, 'E');
      expect(container.read(activeToolProvider), ToolType.ballpointPen);

      container.dispose();
    });
  });

  group('HandwritingToolbar Hardware Controls Tests', () {
    testWidgets('toggles stylus-only mode from toolbar button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(child: const HandwritingToolbar(pageId: testPageId)),
      );

      final touchFinder = find.byIcon(Icons.touch_app);
      await tester.ensureVisible(touchFinder);
      await tester.pumpAndSettle();

      expect(touchFinder, findsOneWidget);

      // Tap the stylus-only button to activate
      await tester.tap(touchFinder);
      await tester.pumpAndSettle();

      // Now should show stylus active icon
      final stylusFinder = find.byIcon(Icons.edit_note);
      expect(stylusFinder, findsOneWidget);
    });
  });

  group('HandwritingCanvas Hardware Stylus Tests', () {
    testWidgets(
      'stylus-only mode ignores finger touch events and allows stylus',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            strokeRepositoryProvider.overrideWithValue(strokeRepo),
            platformInputAdapterProvider.overrideWithValue(testInputAdapter),
          ],
        );

        // Enable stylus-only mode
        container.read(stylusOnlyModeProvider.notifier).setEnabled(true);
        container
            .read(activeToolProvider.notifier)
            .setTool(ToolType.ballpointPen);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: HandwritingCanvas(
                  pageId: testPageId,
                  type: PaperTemplateType.blankPaper,
                  properties: PaperProperties.defaultFor(
                    PaperTemplateType.blankPaper,
                  ),
                  width: 600,
                  height: 800,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Send touch down and up (finger)
        final touchGesture = await tester.createGesture(
          kind: PointerDeviceKind.touch,
        );
        await touchGesture.down(const Offset(100, 100));
        await touchGesture.moveTo(const Offset(150, 150));
        await touchGesture.up();
        await tester.pump();

        // Strokes should be empty because touch was rejected in stylus-only mode
        expect(container.read(pageStrokesProvider(testPageId)), isEmpty);

        // Now send stylus down and up
        final stylusGesture = await tester.createGesture(
          kind: PointerDeviceKind.stylus,
        );
        await stylusGesture.down(const Offset(200, 200));
        await stylusGesture.moveTo(const Offset(250, 250));
        await stylusGesture.up();
        await tester.pump();

        // Stylus was accepted and saved
        expect(container.read(pageStrokesProvider(testPageId)).length, 1);

        container.dispose();
      },
    );

    testWidgets('hardware double-tap event toggles eraser tool', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          strokeRepositoryProvider.overrideWithValue(strokeRepo),
          platformInputAdapterProvider.overrideWithValue(testInputAdapter),
        ],
      );

      container.read(activeToolProvider.notifier).setTool(ToolType.fountainPen);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: HandwritingCanvas(
                pageId: testPageId,
                type: PaperTemplateType.blankPaper,
                properties: PaperProperties.defaultFor(
                  PaperTemplateType.blankPaper,
                ),
                width: 600,
                height: 800,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Dispatch hardware double-tap event (e.g. Apple Pencil double-tap)
      testInputAdapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.doubleTap,
          preferredAction: 'switchEraser',
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();

      expect(container.read(activeToolProvider), ToolType.eraser);

      // Dispatch double tap again to switch back
      testInputAdapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.doubleTap,
          preferredAction: 'switchEraser',
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();

      expect(container.read(activeToolProvider), ToolType.fountainPen);

      container.dispose();
    });

    testWidgets('hardware barrel button temporarily switches tool to eraser', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          strokeRepositoryProvider.overrideWithValue(strokeRepo),
          platformInputAdapterProvider.overrideWithValue(testInputAdapter),
        ],
      );

      container
          .read(activeToolProvider.notifier)
          .setTool(ToolType.ballpointPen);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: HandwritingCanvas(
                pageId: testPageId,
                type: PaperTemplateType.blankPaper,
                properties: PaperProperties.defaultFor(
                  PaperTemplateType.blankPaper,
                ),
                width: 600,
                height: 800,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // S-Pen / Surface Pen barrel button pressed down
      testInputAdapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.buttonDown,
          button: 1,
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();

      expect(container.read(activeToolProvider), ToolType.eraser);

      // Barrel button released
      testInputAdapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.buttonUp,
          button: 0,
          timestamp: DateTime.now(),
        ),
      );
      await tester.pump();

      expect(container.read(activeToolProvider), ToolType.ballpointPen);

      container.dispose();
    });
  });
}
