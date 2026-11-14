import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';

class MockStrokeRepository implements StrokeRepository {
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
  group('StrokesNotifier & State Management Tests', () {
    late ProviderContainer container;
    late MockStrokeRepository mockRepo;
    const testPageId = 'page-test-1';

    setUp(() {
      mockRepo = MockStrokeRepository();
      container = ProviderContainer(
        overrides: [strokeRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('adds a stroke, enables undo, updates state and persists', () async {
      final notifier = container.read(strokesNotifierProvider.notifier);

      final stroke = Stroke(
        id: 'stroke-1',
        pageId: testPageId,
        tool: ToolType.fountainPen,
        colorValue: 0xFF000000,
        width: 3.0,
        opacity: 1.0,
        points: [
          const StrokePoint(x: 10, y: 10, timestamp: 1),
          const StrokePoint(x: 50, y: 50, timestamp: 2),
        ],
        createdAt: DateTime.now(),
      );

      await notifier.addStroke(testPageId, stroke);

      final strokes = container.read(pageStrokesProvider(testPageId));
      expect(strokes.length, 1);
      expect(strokes.first.id, 'stroke-1');

      expect(container.read(canUndoProvider(testPageId)), isTrue);
      expect(container.read(canRedoProvider(testPageId)), isFalse);

      final persisted = await mockRepo.getStrokesForPage(testPageId);
      expect(persisted.length, 1);
    });

    test('undo and redo of addStroke works seamlessly', () async {
      final notifier = container.read(strokesNotifierProvider.notifier);

      final stroke = Stroke(
        id: 'stroke-undo',
        pageId: testPageId,
        tool: ToolType.ballpointPen,
        colorValue: 0xFF1D4ED8,
        width: 2.0,
        opacity: 1.0,
        points: [const StrokePoint(x: 20, y: 20, timestamp: 1)],
        createdAt: DateTime.now(),
      );

      await notifier.addStroke(testPageId, stroke);
      expect(container.read(pageStrokesProvider(testPageId)).length, 1);

      // Undo
      await notifier.undo(testPageId);
      expect(container.read(pageStrokesProvider(testPageId)).isEmpty, isTrue);
      expect(container.read(canUndoProvider(testPageId)), isFalse);
      expect(container.read(canRedoProvider(testPageId)), isTrue);

      // Redo
      await notifier.redo(testPageId);
      expect(container.read(pageStrokesProvider(testPageId)).length, 1);
      expect(container.read(canUndoProvider(testPageId)), isTrue);
      expect(container.read(canRedoProvider(testPageId)), isFalse);
    });

    test('eraseAt removes stroke by hit test and can be undone', () async {
      final notifier = container.read(strokesNotifierProvider.notifier);

      final stroke = Stroke(
        id: 'stroke-erase',
        pageId: testPageId,
        tool: ToolType.fountainPen,
        colorValue: 0xFF000000,
        width: 4.0,
        opacity: 1.0,
        points: [
          const StrokePoint(x: 100, y: 100, timestamp: 1),
          const StrokePoint(x: 200, y: 100, timestamp: 2),
        ],
        createdAt: DateTime.now(),
      );

      await notifier.addStroke(testPageId, stroke);

      // Erase near middle of the stroke (150, 100)
      final erased = await notifier.eraseAt(testPageId, const Offset(150, 100));
      expect(erased, contains('stroke-erase'));
      expect(container.read(pageStrokesProvider(testPageId)).isEmpty, isTrue);

      // Undo erase restores the stroke
      await notifier.undo(testPageId);
      expect(container.read(pageStrokesProvider(testPageId)).length, 1);
      expect(
        container.read(pageStrokesProvider(testPageId)).first.id,
        'stroke-erase',
      );
    });

    test(
      'selectWithLasso, translateSelected and clearSelection work',
      () async {
        final notifier = container.read(strokesNotifierProvider.notifier);

        final stroke = Stroke(
          id: 'stroke-lasso',
          pageId: testPageId,
          tool: ToolType.fountainPen,
          colorValue: 0xFF000000,
          width: 2.0,
          opacity: 1.0,
          points: [
            const StrokePoint(x: 50, y: 50, timestamp: 1),
            const StrokePoint(x: 60, y: 60, timestamp: 2),
          ],
          createdAt: DateTime.now(),
        );

        await notifier.addStroke(testPageId, stroke);

        // Select with loop around (40, 40) to (80, 80)
        notifier.selectWithLasso(testPageId, [
          const Offset(40, 40),
          const Offset(80, 40),
          const Offset(80, 80),
          const Offset(40, 80),
        ]);

        final selected = container.read(selectedStrokesProvider(testPageId));
        expect(selected, contains('stroke-lasso'));

        // Translate selected by (30, 20)
        await notifier.translateSelected(testPageId, const Offset(30, 20));

        final updatedStrokes = container.read(pageStrokesProvider(testPageId));
        expect(updatedStrokes.first.points.first.x, 80.0);
        expect(updatedStrokes.first.points.first.y, 70.0);

        // Deselect
        notifier.clearSelection(testPageId);
        expect(
          container.read(selectedStrokesProvider(testPageId)).isEmpty,
          isTrue,
        );
      },
    );

    test('duplicateSelected creates offset clone with unique ID', () async {
      final notifier = container.read(strokesNotifierProvider.notifier);

      final stroke = Stroke(
        id: 'stroke-original',
        pageId: testPageId,
        tool: ToolType.brushPen,
        colorValue: 0xFF000000,
        width: 3.0,
        opacity: 1.0,
        points: [const StrokePoint(x: 10, y: 10, timestamp: 1)],
        createdAt: DateTime.now(),
      );

      await notifier.addStroke(testPageId, stroke);
      notifier.selectWithLasso(testPageId, [
        const Offset(0, 0),
        const Offset(50, 0),
        const Offset(50, 50),
        const Offset(0, 50),
      ]);

      await notifier.duplicateSelected(testPageId);

      final strokes = container.read(pageStrokesProvider(testPageId));
      expect(strokes.length, 2);
      expect(strokes.any((s) => s.id != 'stroke-original'), isTrue);
    });

    test('copySelected and paste onto page works', () async {
      final notifier = container.read(strokesNotifierProvider.notifier);

      final stroke = Stroke(
        id: 'stroke-copy-src',
        pageId: testPageId,
        tool: ToolType.fountainPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: [const StrokePoint(x: 100, y: 100, timestamp: 1)],
        createdAt: DateTime.now(),
      );

      await notifier.addStroke(testPageId, stroke);
      notifier.selectWithLasso(testPageId, [
        const Offset(50, 50),
        const Offset(150, 50),
        const Offset(150, 150),
        const Offset(50, 150),
      ]);

      notifier.copySelected(testPageId);
      await notifier.paste(testPageId, const Offset(300, 300));

      final strokes = container.read(pageStrokesProvider(testPageId));
      expect(strokes.length, 2);
      expect(strokes.last.points.first.x, 300.0);
      expect(strokes.last.points.first.y, 300.0);
    });
  });
}
