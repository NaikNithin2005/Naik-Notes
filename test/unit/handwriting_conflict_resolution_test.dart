import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/models/version_history_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/data/repositories/version_history_repository.dart';

void main() {
  group('Handwriting Stroke Non-Destructive Conflict Resolution Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;
    late DriftStrokeRepository strokeRepo;
    late DriftVersionHistoryRepository historyRepo;

    const testNotebookId = 'nb-conflict-res-1';
    const testPageId = 'page-conflict-res-1';
    final now = DateTime.now();

    setUpAll(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    });

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);
      strokeRepo = DriftStrokeRepository(db);
      historyRepo = DriftVersionHistoryRepository(db);

      await notebookRepo.saveNotebook(
        Notebook(
          id: testNotebookId,
          ownerId: 'user-conflict-tester',
          coverId: 'classic_leather',
          title: 'Handwriting Conflict Notebook',
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
          properties: const PaperProperties(),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('preserves full vector stroke fidelity (x, y, pressure, tilt, timestamp)', () async {
      final samplePoints = [
        const StrokePoint(x: 10.5, y: 20.25, pressure: 0.85, tilt: 0.12, timestamp: 1001),
        const StrokePoint(x: 15.0, y: 25.5, pressure: 0.92, tilt: 0.18, timestamp: 1015),
        const StrokePoint(x: 22.75, y: 35.1, pressure: 0.64, tilt: 0.05, timestamp: 1030),
      ];

      final stroke = Stroke(
        id: 'stroke-hi-fi-1',
        pageId: testPageId,
        tool: ToolType.fountainPen,
        colorValue: 0xFF1E3A8A,
        width: 3.5,
        opacity: 0.95,
        points: samplePoints,
        revision: 1,
        createdAt: now,
      );

      await strokeRepo.saveStroke(stroke);

      final retrieved = await strokeRepo.getStrokesForPage(testPageId);
      expect(retrieved.length, equals(1));
      final s = retrieved.first;

      expect(s.id, equals('stroke-hi-fi-1'));
      expect(s.tool, equals(ToolType.fountainPen));
      expect(s.colorValue, equals(0xFF1E3A8A));
      expect(s.width, equals(3.5));
      expect(s.opacity, equals(0.95));
      expect(s.points.length, equals(3));

      // Exact vector point fidelity validation
      for (int i = 0; i < 3; i++) {
        expect(s.points[i].x, equals(samplePoints[i].x));
        expect(s.points[i].y, equals(samplePoints[i].y));
        expect(s.points[i].pressure, equals(samplePoints[i].pressure));
        expect(s.points[i].tilt, equals(samplePoints[i].tilt));
        expect(s.points[i].timestamp, equals(samplePoints[i].timestamp));
      }
    });

    test('concurrent writes from Device A and Device B are merged without stroke loss', () async {
      // Device A writes stroke A1 and A2
      final strokeA1 = Stroke(
        id: 'stroke-device-a-1',
        pageId: testPageId,
        tool: ToolType.ballpointPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: const [
          StrokePoint(x: 10, y: 10, pressure: 0.5, timestamp: 100),
          StrokePoint(x: 20, y: 20, pressure: 0.5, timestamp: 110),
        ],
        createdAt: now,
      );

      final strokeA2 = Stroke(
        id: 'stroke-device-a-2',
        pageId: testPageId,
        tool: ToolType.highlighter,
        colorValue: 0xFFFFFF00,
        width: 12.0,
        opacity: 0.4,
        points: const [
          StrokePoint(x: 50, y: 50, pressure: 0.7, timestamp: 120),
          StrokePoint(x: 80, y: 50, pressure: 0.7, timestamp: 130),
        ],
        createdAt: now,
      );

      await strokeRepo.saveStroke(strokeA1);
      await strokeRepo.saveStroke(strokeA2);

      // Device B concurrently wrote stroke B1 on the same page
      final strokeB1 = Stroke(
        id: 'stroke-device-b-1',
        pageId: testPageId,
        tool: ToolType.pencil,
        colorValue: 0xFF4A4A4A,
        width: 1.5,
        opacity: 1.0,
        points: const [
          StrokePoint(x: 100, y: 100, pressure: 0.6, timestamp: 105),
          StrokePoint(x: 120, y: 120, pressure: 0.65, timestamp: 115),
        ],
        createdAt: now,
      );

      // Union merge: Save Device B's incoming remote stroke
      await strokeRepo.saveStroke(strokeB1);

      final mergedStrokes = await strokeRepo.getStrokesForPage(testPageId);

      // All 3 strokes MUST exist — zero data loss
      expect(mergedStrokes.length, equals(3));
      final ids = mergedStrokes.map((s) => s.id).toSet();
      expect(ids.contains('stroke-device-a-1'), isTrue);
      expect(ids.contains('stroke-device-a-2'), isTrue);
      expect(ids.contains('stroke-device-b-1'), isTrue);
    });

    test('preserves historical snapshot in PageSnapshotsTable on conflict resolution', () async {
      // 1. Initial strokes on page
      final initialStroke = Stroke(
        id: 'stroke-v1',
        pageId: testPageId,
        tool: ToolType.ballpointPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: const [StrokePoint(x: 5, y: 5, pressure: 0.5, timestamp: 1)],
        createdAt: now,
      );
      await strokeRepo.saveStroke(initialStroke);

      // 2. Snapshot captured before major concurrent remote replacement
      final snapshot = PageSnapshot(
        id: 'snap-conflict-v1',
        pageId: testPageId,
        notebookId: testNotebookId,
        versionNumber: 1,
        label: 'Pre-sync conflict snapshot',
        deviceInfo: 'Windows Desktop Client',
        strokes: [initialStroke],
        createdAt: now,
      );
      await historyRepo.saveSnapshot(snapshot);

      // 3. Remote change introduces new revision strokes
      final remoteStroke = Stroke(
        id: 'stroke-v2-remote',
        pageId: testPageId,
        tool: ToolType.fountainPen,
        colorValue: 0xFFDC2626,
        width: 3.0,
        opacity: 1.0,
        points: const [StrokePoint(x: 50, y: 50, pressure: 0.8, timestamp: 200)],
        revision: 2,
        createdAt: now,
      );
      await strokeRepo.saveStroke(remoteStroke);

      // 4. Verify historical snapshot exists in PageSnapshotsTable
      final snapshots = await historyRepo.getSnapshotsForPage(testPageId);
      expect(snapshots.length, equals(1));
      expect(snapshots.first.label, equals('Pre-sync conflict snapshot'));

      // Restore from snapshot to recover the exact pre-conflict state
      await historyRepo.restoreSnapshot(snapshot.id);
      final restoredStrokes = await strokeRepo.getStrokesForPage(testPageId);
      expect(restoredStrokes.any((s) => s.id == 'stroke-v1'), isTrue);
    });
  });
}
