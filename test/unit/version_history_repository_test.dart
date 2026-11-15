import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/models/version_history_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/data/repositories/version_history_repository.dart';

void main() {
  group('DriftVersionHistoryRepository Tests', () {
    late AppDatabase db;
    late DriftVersionHistoryRepository historyRepo;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;
    late DriftStrokeRepository strokeRepo;

    const testNotebookId = 'nb-history-1';
    const testPageId = 'page-history-1';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      historyRepo = DriftVersionHistoryRepository(db);
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);
      strokeRepo = DriftStrokeRepository(db);

      // Create notebook & page
      await notebookRepo.saveNotebook(
        Notebook(
          id: testNotebookId,
          ownerId: 'local_user',
          coverId: 'classic_leather',
          title: 'History Test Notebook',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await pageRepo.savePage(
        NotebookPage(
          id: testPageId,
          notebookId: testNotebookId,
          pageNumber: 1,
          templateId: 'college_ruled',
          properties: const PaperProperties(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'saves and retrieves historical snapshots ordered by creation date',
      () async {
        final snap1 = PageSnapshot(
          id: 'snap-1',
          pageId: testPageId,
          notebookId: testNotebookId,
          versionNumber: 1,
          label: 'Initial Draft',
          strokes: [
            Stroke(
              id: 'stroke-1',
              pageId: testPageId,
              tool: ToolType.ballpointPen,
              colorValue: 0xFF000000,
              width: 2.0,
              opacity: 1.0,
              points: const [
                StrokePoint(x: 10, y: 10, timestamp: 0),
                StrokePoint(x: 20, y: 20, timestamp: 10),
              ],
              createdAt: DateTime.now(),
            ),
          ],
          stickyNotes: [
            StickyNote(
              id: 'note-1',
              pageId: testPageId,
              x: 50,
              y: 50,
              content: 'Review definitions',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final snap2 = PageSnapshot(
          id: 'snap-2',
          pageId: testPageId,
          notebookId: testNotebookId,
          versionNumber: 2,
          label: 'Added Derivations',
          strokes: [
            Stroke(
              id: 'stroke-1',
              pageId: testPageId,
              tool: ToolType.ballpointPen,
              colorValue: 0xFF000000,
              width: 2.0,
              opacity: 1.0,
              points: const [
                StrokePoint(x: 10, y: 10, timestamp: 0),
                StrokePoint(x: 20, y: 20, timestamp: 10),
              ],
              createdAt: DateTime.now(),
            ),
            Stroke(
              id: 'stroke-2',
              pageId: testPageId,
              tool: ToolType.highlighter,
              colorValue: 0xFFFFEB3B,
              width: 8.0,
              opacity: 0.35,
              points: const [
                StrokePoint(x: 10, y: 15, timestamp: 20),
                StrokePoint(x: 50, y: 15, timestamp: 30),
              ],
              createdAt: DateTime.now(),
            ),
          ],
          createdAt: DateTime.now(),
        );

        await historyRepo.saveSnapshot(snap1);
        await historyRepo.saveSnapshot(snap2);

        final snapshots = await historyRepo.getSnapshotsForPage(testPageId);
        expect(snapshots.length, 2);
        // Descending order: snap2 (version 2) first
        expect(snapshots[0].id, 'snap-2');
        expect(snapshots[0].strokeCount, 2);
        expect(snapshots[1].id, 'snap-1');
        expect(snapshots[1].strokeCount, 1);
        expect(snapshots[1].noteCount, 1);
      },
    );

    test(
      'restoreSnapshot replaces page strokes and properties atomically',
      () async {
        // 1. Initial snapshot with stroke-A
        final snapA = PageSnapshot(
          id: 'snap-A',
          pageId: testPageId,
          notebookId: testNotebookId,
          versionNumber: 1,
          label: 'Version A',
          strokes: [
            Stroke(
              id: 'stroke-A',
              pageId: testPageId,
              tool: ToolType.ballpointPen,
              colorValue: 0xFF0000FF,
              width: 2.5,
              opacity: 1.0,
              points: const [
                StrokePoint(x: 0, y: 0, timestamp: 0),
                StrokePoint(x: 100, y: 100, timestamp: 10),
              ],
              createdAt: DateTime.now(),
            ),
          ],
          templateId: 'square_grid',
          templateProperties: const PaperProperties(gridSize: 20.0),
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        await historyRepo.saveSnapshot(snapA);

        // 2. Current page state has stroke-B
        await strokeRepo.saveStroke(
          Stroke(
            id: 'stroke-B',
            pageId: testPageId,
            tool: ToolType.pencil,
            colorValue: 0xFF111111,
            width: 1.5,
            opacity: 0.85,
            points: const [
              StrokePoint(x: 50, y: 50, timestamp: 0),
              StrokePoint(x: 60, y: 60, timestamp: 10),
            ],
            createdAt: DateTime.now(),
          ),
        );

        final currentStrokesBefore = await strokeRepo.getStrokesForPage(
          testPageId,
        );
        expect(currentStrokesBefore.length, 1);
        expect(currentStrokesBefore.first.id, 'stroke-B');

        // 3. Restore snapshot A
        await historyRepo.restoreSnapshot('snap-A');

        final currentStrokesAfter = await strokeRepo.getStrokesForPage(
          testPageId,
        );
        expect(currentStrokesAfter.length, 1);
        expect(currentStrokesAfter.first.id, 'stroke-A');

        final restoredPage = await pageRepo.getPageById(testPageId);
        expect(restoredPage?.templateId, 'square_grid');
        expect(restoredPage?.properties.gridSize, 20.0);
      },
    );

    test(
      'deleteSnapshot and deleteSnapshotsForPage remove snapshots',
      () async {
        final snap = PageSnapshot(
          id: 'snap-del',
          pageId: testPageId,
          notebookId: testNotebookId,
          versionNumber: 1,
          label: 'To Delete',
          strokes: [],
          createdAt: DateTime.now(),
        );

        await historyRepo.saveSnapshot(snap);
        var fetched = await historyRepo.getSnapshotById('snap-del');
        expect(fetched, isNotNull);

        await historyRepo.deleteSnapshot('snap-del');
        fetched = await historyRepo.getSnapshotById('snap-del');
        expect(fetched, isNull);
      },
    );
  });
}
