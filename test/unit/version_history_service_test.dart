import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/data/repositories/version_history_repository.dart';
import 'package:naik_notes/services/version_history/version_history_service.dart';

void main() {
  group('VersionHistoryService Tests', () {
    late AppDatabase db;
    late VersionHistoryService service;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;
    late DriftStrokeRepository strokeRepo;
    late DriftStickyNoteRepository stickyRepo;

    const testNotebookId = 'nb-serv-1';
    const testPageId = 'page-serv-1';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final historyRepo = DriftVersionHistoryRepository(db);
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);
      strokeRepo = DriftStrokeRepository(db);
      stickyRepo = DriftStickyNoteRepository(db);

      service = VersionHistoryService(
        repository: historyRepo,
        pageRepository: pageRepo,
        strokeRepository: strokeRepo,
        stickyNoteRepository: stickyRepo,
      );

      await notebookRepo.saveNotebook(
        Notebook(
          id: testNotebookId,
          ownerId: 'local_user',
          coverId: 'classic_leather',
          title: 'Version History Notebook',
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

    test('captureSnapshot snapshots current page strokes and increments version number', () async {
      // 1. Add stroke to page
      await strokeRepo.saveStroke(
        Stroke(
          id: 's-1',
          pageId: testPageId,
          tool: ToolType.ballpointPen,
          colorValue: 0xFF000000,
          width: 2.0,
          opacity: 1.0,
          points: const [StrokePoint(x: 10, y: 10, timestamp: 0)],
          createdAt: DateTime.now(),
        ),
      );

      final snap1 = await service.captureSnapshot(
        testPageId,
        testNotebookId,
        label: 'Initial Notes',
      );
      expect(snap1.versionNumber, 1);
      expect(snap1.label, 'Initial Notes');
      expect(snap1.strokeCount, 1);

      // 2. Add sticky note and another stroke
      await stickyRepo.saveStickyNote(
        StickyNote(
          id: 'sn-1',
          pageId: testPageId,
          x: 20,
          y: 20,
          content: 'Homework due Friday',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      await strokeRepo.saveStroke(
        Stroke(
          id: 's-2',
          pageId: testPageId,
          tool: ToolType.pencil,
          colorValue: 0xFF555555,
          width: 1.0,
          opacity: 0.85,
          points: const [StrokePoint(x: 20, y: 20, timestamp: 10)],
          createdAt: DateTime.now(),
        ),
      );

      final snap2 = await service.captureSnapshot(
        testPageId,
        testNotebookId,
        label: 'Added Sticky Note',
      );
      expect(snap2.versionNumber, 2);
      expect(snap2.strokeCount, 2);
      expect(snap2.noteCount, 1);

      // Verify diff calculations
      final diff = service.calculateDiff(snap1, snap2);
      expect(diff.strokesDelta, 1);
      expect(diff.notesDelta, 1);
      expect(diff.summaryText, '+1 strokes, +1 notes');

      // Timeline retrieval
      final timeline = await service.getPageTimeline(testPageId);
      expect(timeline.length, 2);
      expect(timeline.first.versionNumber, 2);
    });
  });
}
