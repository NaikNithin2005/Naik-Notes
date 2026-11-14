import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';

void main() {
  group('DriftStrokeRepository SQLite Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;
    late DriftStrokeRepository strokeRepo;

    const testNotebookId = 'nb-stroke-test';
    const testPageId = 'page-stroke-test';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);
      strokeRepo = DriftStrokeRepository(db);

      final now = DateTime.now();
      await notebookRepo.saveNotebook(
        Notebook(
          id: testNotebookId,
          ownerId: 'user-test',
          title: 'Handwriting Test Notebook',
          coverId: 'dark_academia_leather',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await pageRepo.savePage(
        NotebookPage(
          id: testPageId,
          notebookId: testNotebookId,
          pageNumber: 1,
          templateId: 'college_ruled',
          properties: PaperProperties.defaultFor(
            PaperTemplateType.collegeRuled,
          ),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('persists a stroke and retrieves it by pageId', () async {
      final now = DateTime.now();
      final stroke = Stroke(
        id: 'stroke-1',
        pageId: testPageId,
        tool: ToolType.fountainPen,
        colorValue: 0xFF1D4ED8,
        width: 3.0,
        opacity: 1.0,
        points: [
          StrokePoint(
            x: 10,
            y: 10,
            pressure: 0.5,
            timestamp: now.millisecondsSinceEpoch,
          ),
          StrokePoint(
            x: 20,
            y: 30,
            pressure: 0.8,
            timestamp: now.millisecondsSinceEpoch + 10,
          ),
        ],
        createdAt: now,
      );

      await strokeRepo.saveStroke(stroke);

      final loaded = await strokeRepo.getStrokesForPage(testPageId);
      expect(loaded.length, 1);
      expect(loaded.first.id, 'stroke-1');
      expect(loaded.first.pageId, testPageId);
      expect(loaded.first.tool, ToolType.fountainPen);
      expect(loaded.first.colorValue, 0xFF1D4ED8);
      expect(loaded.first.points.length, 2);
    });

    test('batch saves multiple strokes and retrieves in order', () async {
      final now = DateTime.now();
      final s1 = Stroke(
        id: 'stroke-batch-1',
        pageId: testPageId,
        tool: ToolType.ballpointPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: const [StrokePoint(x: 0, y: 0, timestamp: 1)],
        createdAt: now,
      );
      final s2 = Stroke(
        id: 'stroke-batch-2',
        pageId: testPageId,
        tool: ToolType.highlighter,
        colorValue: 0xFFFFEB3B,
        width: 16.0,
        opacity: 0.35,
        points: const [StrokePoint(x: 10, y: 10, timestamp: 2)],
        createdAt: now.add(const Duration(milliseconds: 5)),
      );

      await strokeRepo.saveStrokes([s1, s2]);

      final loaded = await strokeRepo.getStrokesForPage(testPageId);
      expect(loaded.length, 2);
      expect(loaded[0].id, 'stroke-batch-1');
      expect(loaded[1].id, 'stroke-batch-2');
    });

    test(
      'soft delete hides stroke from query, restore brings it back',
      () async {
        final now = DateTime.now();
        final stroke = Stroke(
          id: 'stroke-soft-del',
          pageId: testPageId,
          tool: ToolType.pencil,
          colorValue: 0xFF1E293B,
          width: 2.5,
          opacity: 0.8,
          points: const [StrokePoint(x: 5, y: 5, timestamp: 1)],
          createdAt: now,
        );

        await strokeRepo.saveStroke(stroke);
        expect((await strokeRepo.getStrokesForPage(testPageId)).length, 1);

        // Soft delete
        await strokeRepo.softDeleteStroke('stroke-soft-del');
        expect(
          (await strokeRepo.getStrokesForPage(testPageId)).isEmpty,
          isTrue,
        );

        // Restore
        await strokeRepo.restoreStroke('stroke-soft-del');
        final restored = await strokeRepo.getStrokesForPage(testPageId);
        expect(restored.length, 1);
        expect(restored.first.id, 'stroke-soft-del');
      },
    );

    test(
      'clearPage soft deletes all strokes for specified page only',
      () async {
        final now = DateTime.now();
        final s1 = Stroke(
          id: 's-page1',
          pageId: testPageId,
          tool: ToolType.brushPen,
          colorValue: 0xFF000000,
          width: 3.0,
          opacity: 1.0,
          points: const [StrokePoint(x: 1, y: 1, timestamp: 1)],
          createdAt: now,
        );

        await strokeRepo.saveStroke(s1);
        expect((await strokeRepo.getStrokesForPage(testPageId)).length, 1);

        await strokeRepo.clearPage(testPageId);
        expect(
          (await strokeRepo.getStrokesForPage(testPageId)).isEmpty,
          isTrue,
        );
      },
    );
  });
}
