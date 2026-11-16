import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/shape_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';

void main() {
  group('Geometric Shape Geometry Tests (All 27 Shapes)', () {
    test('verifies all 27 ShapeType values are categorized correctly', () {
      expect(ShapeType.values.length, 27);

      final basicShapes = ShapeType.values
          .where((s) => s.category == ShapeCategory.basic)
          .toList();
      final advancedShapes = ShapeType.values
          .where((s) => s.category == ShapeCategory.advanced)
          .toList();

      expect(basicShapes.length, 17);
      expect(advancedShapes.length, 10);

      // Verify display names are non-empty
      for (final shape in ShapeType.values) {
        expect(shape.displayName, isNotEmpty);
      }
    });

    test(
      'generates valid non-empty Paths for all 27 shapes without throwing',
      () {
        const rect = Rect.fromLTWH(50, 50, 200, 150);

        for (final shape in ShapeType.values) {
          final path = ShapeGeometry.buildPath(shape, rect);
          expect(path, isNotNull);
          final bounds = path.getBounds();
          expect(
            bounds.width,
            greaterThan(0),
            reason: '${shape.name} should have width > 0',
          );
          expect(
            bounds.height,
            greaterThan(0),
            reason: '${shape.name} should have height > 0',
          );
        }
      },
    );

    test('verifies rotation transforms path correctly', () {
      const rect = Rect.fromLTWH(100, 100, 100, 50);
      final unrotated = ShapeGeometry.buildPath(
        ShapeType.rectangle,
        rect,
        rotation: 0,
      );
      final rotated = ShapeGeometry.buildPath(
        ShapeType.rectangle,
        rect,
        rotation: 3.14159 / 2,
      ); // 90 degrees

      final unrotatedBounds = unrotated.getBounds();
      final rotatedBounds = rotated.getBounds();

      // Width and height should swap around center
      expect(
        (rotatedBounds.width - unrotatedBounds.height).abs(),
        lessThan(1.0),
      );
      expect(
        (rotatedBounds.height - unrotatedBounds.width).abs(),
        lessThan(1.0),
      );
    });

    test('verifies closed vs open shapes', () {
      expect(ShapeGeometry.isClosedShape(ShapeType.rectangle), isTrue);
      expect(ShapeGeometry.isClosedShape(ShapeType.circle), isTrue);
      expect(ShapeGeometry.isClosedShape(ShapeType.star), isTrue);
      expect(ShapeGeometry.isClosedShape(ShapeType.heart), isTrue);
      expect(ShapeGeometry.isClosedShape(ShapeType.speechBubble), isTrue);

      expect(ShapeGeometry.isClosedShape(ShapeType.straightLine), isFalse);
      expect(ShapeGeometry.isClosedShape(ShapeType.arrow), isFalse);
      expect(ShapeGeometry.isClosedShape(ShapeType.doubleArrow), isFalse);
      expect(ShapeGeometry.isClosedShape(ShapeType.curvedLine), isFalse);
      expect(ShapeGeometry.isClosedShape(ShapeType.bracket), isFalse);
      expect(ShapeGeometry.isClosedShape(ShapeType.coordinateAxes), isFalse);
    });
  });

  group('ToolConfigsNotifier & Tool Memory Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initializes default configurations for all drawing tools', () {
      final configs = container.read(toolConfigsProvider);
      expect(configs.containsKey(ToolType.fountainPen), isTrue);
      expect(configs.containsKey(ToolType.ballpointPen), isTrue);
      expect(configs.containsKey(ToolType.pencil), isTrue);
      expect(configs.containsKey(ToolType.brushPen), isTrue);
      expect(configs.containsKey(ToolType.highlighter), isTrue);
      expect(configs.containsKey(ToolType.marker), isTrue);

      // Verify specific default attributes
      expect(configs[ToolType.highlighter]?.opacity, 0.35);
      expect(configs[ToolType.pencil]?.opacity, 0.85);
      expect(configs[ToolType.highlighter]?.strokeWidth, 16.0);
    });

    test('updates width, color, opacity and style per tool independently', () {
      final notifier = container.read(toolConfigsProvider.notifier);

      notifier.updateWidth(ToolType.fountainPen, 7.5);
      notifier.updateColor(ToolType.fountainPen, Colors.purple);
      notifier.updateStyle(ToolType.fountainPen, StrokeStyle.dashed);

      notifier.updateWidth(ToolType.pencil, 1.5);
      notifier.updateColor(ToolType.pencil, Colors.teal);
      notifier.updateOpacity(ToolType.pencil, 0.65);

      final configs = container.read(toolConfigsProvider);

      // Fountain Pen should retain modified properties
      expect(configs[ToolType.fountainPen]?.strokeWidth, 7.5);
      expect(configs[ToolType.fountainPen]?.color, Colors.purple);
      expect(configs[ToolType.fountainPen]?.strokeStyle, StrokeStyle.dashed);

      // Pencil should retain its own distinct properties
      expect(configs[ToolType.pencil]?.strokeWidth, 1.5);
      expect(configs[ToolType.pencil]?.color, Colors.teal);
      expect(configs[ToolType.pencil]?.opacity, 0.65);
      expect(configs[ToolType.pencil]?.strokeStyle, StrokeStyle.solid);
    });

    test('resetToDefaults restores original tool presets', () {
      final notifier = container.read(toolConfigsProvider.notifier);
      notifier.updateWidth(ToolType.marker, 99.0);
      expect(
        container.read(toolConfigsProvider)[ToolType.marker]?.strokeWidth,
        99.0,
      );

      notifier.resetToDefaults();
      expect(
        container.read(toolConfigsProvider)[ToolType.marker]?.strokeWidth,
        6.0,
      );
    });
  });

  group('Dual-Geometry Eraser Tests (Circle & Square)', () {
    test(
      'splitByEraserCircle correctly removes points within circle radius',
      () {
        int idCounter = 1;
        final stroke = Stroke(
          id: 'stroke-circle-test',
          pageId: 'page-1',
          tool: ToolType.ballpointPen,
          colorValue: Colors.black.toARGB32(),
          width: 2.0,
          opacity: 1.0,
          points: const [
            StrokePoint(x: 10, y: 10, timestamp: 100),
            StrokePoint(x: 20, y: 10, timestamp: 101),
            StrokePoint(
              x: 30,
              y: 10,
              timestamp: 102,
            ), // Collides with center at (30, 10), radius 5
            StrokePoint(x: 40, y: 10, timestamp: 103),
            StrokePoint(x: 50, y: 10, timestamp: 104),
          ],
          createdAt: DateTime.now(),
        );

        final result = stroke.splitByEraserCircle(
          const Offset(30, 10),
          5.0,
          () => 'split-${idCounter++}',
        );
        // Point (30, 10) is removed, splitting into 2 segments
        expect(result.length, 2);
        expect(result[0].points.map((p) => p.x).toList(), [10.0, 20.0]);
        expect(result[1].points.map((p) => p.x).toList(), [40.0, 50.0]);
      },
    );

    test(
      'splitByEraserSquare correctly removes points within square halfSize',
      () {
        int idCounter = 1;
        final stroke = Stroke(
          id: 'stroke-square-test',
          pageId: 'page-1',
          tool: ToolType.ballpointPen,
          colorValue: Colors.black.toARGB32(),
          width: 2.0,
          opacity: 1.0,
          points: const [
            StrokePoint(x: 10, y: 25, timestamp: 100),
            StrokePoint(x: 15, y: 25, timestamp: 101),
            StrokePoint(
              x: 25,
              y: 25,
              timestamp: 102,
            ), // Inside square at (25, 25) with halfSize 5
            StrokePoint(x: 35, y: 25, timestamp: 103),
            StrokePoint(x: 40, y: 25, timestamp: 104),
          ],
          createdAt: DateTime.now(),
        );

        final result = stroke.splitByEraserSquare(
          const Offset(25, 25),
          5.0,
          () => 'split-${idCounter++}',
        );
        expect(result.length, 2);
        expect(result[0].points.map((p) => p.x).toList(), [10.0, 15.0]);
        expect(result[1].points.map((p) => p.x).toList(), [35.0, 40.0]);
      },
    );
  });

  group('Unlimited Page Insertion & Reordering Tests', () {
    late AppDatabase db;
    late DriftPageRepository pageRepo;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      pageRepo = DriftPageRepository(db);

      container = ProviderContainer(
        overrides: [pageRepositoryProvider.overrideWithValue(pageRepo)],
      );
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('insertPageBefore, insertPageAfter and reorderPages maintain sequential ordering', () async {
      final notifier = container.read(notebookPagesProvider.notifier);

      // 1. Initial 3 pages
      await notifier.loadPages('nb-unlimited-test', count: 3);
      var pages = container.read(notebookPagesProvider)['nb-unlimited-test']!;
      expect(pages.length, 3);
      expect(pages.map((p) => p.pageNumber).toList(), [1, 2, 3]);

      final p2Id = pages[1].id;

      // 2. Insert page BEFORE Page 2
      final insertedBefore = await notifier.insertPageBefore(
        'nb-unlimited-test',
        p2Id,
        templateId: PaperTemplateType.squareGrid.id,
      );
      expect(insertedBefore.pageNumber, 2);

      pages = container.read(notebookPagesProvider)['nb-unlimited-test']!;
      expect(pages.length, 4);
      expect(pages.map((p) => p.pageNumber).toList(), [1, 2, 3, 4]);
      expect(pages[1].id, insertedBefore.id);
      expect(pages[1].templateId, PaperTemplateType.squareGrid.id);
      expect(pages[2].id, p2Id); // The original Page 2 is now Page 3

      // 3. Insert page AFTER original Page 2 (now at index 2)
      final insertedAfter = await notifier.insertPageAfter(
        'nb-unlimited-test',
        p2Id,
        templateId: PaperTemplateType.dottedPaper.id,
      );
      expect(insertedAfter.pageNumber, 4);

      pages = container.read(notebookPagesProvider)['nb-unlimited-test']!;
      expect(pages.length, 5);
      expect(pages.map((p) => p.pageNumber).toList(), [1, 2, 3, 4, 5]);
      expect(pages[3].id, insertedAfter.id);
      expect(pages[3].templateId, PaperTemplateType.dottedPaper.id);

      // 4. Reorder: move the last page (index 4) to index 0 (top of notebook)
      final lastPageId = pages.last.id;
      await notifier.reorderPages('nb-unlimited-test', 4, 0);

      pages = container.read(notebookPagesProvider)['nb-unlimited-test']!;
      expect(pages.length, 5);
      expect(pages.map((p) => p.pageNumber).toList(), [1, 2, 3, 4, 5]);
      expect(pages.first.id, lastPageId);
    });
  });
}
