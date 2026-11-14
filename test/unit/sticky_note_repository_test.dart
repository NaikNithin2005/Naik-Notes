import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';

void main() {
  group('DriftStickyNoteRepository SQLite Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;
    late DriftStickyNoteRepository stickyRepo;

    const testNotebookId = 'nb-sticky-test';
    const testPageId = 'page-sticky-test';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);
      stickyRepo = DriftStickyNoteRepository(db);

      final now = DateTime.now();
      await notebookRepo.saveNotebook(
        Notebook(
          id: testNotebookId,
          ownerId: 'user-test',
          title: 'Sticky Note Test Notebook',
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

    test('persists a sticky note and retrieves by pageId', () async {
      final now = DateTime.now();
      final note = StickyNote(
        id: 'sticky-1',
        pageId: testPageId,
        x: 100,
        y: 200,
        width: 180,
        height: 150,
        content: 'Formulas to memorize for quiz',
        colorHex: StickyNoteColors.skyBlue,
        createdAt: now,
        updatedAt: now,
      );

      await stickyRepo.saveStickyNote(note);

      final loaded = await stickyRepo.getStickyNotesForPage(testPageId);
      expect(loaded.length, 1);
      expect(loaded.first.id, 'sticky-1');
      expect(loaded.first.x, 100.0);
      expect(loaded.first.y, 200.0);
      expect(loaded.first.content, 'Formulas to memorize for quiz');
      expect(loaded.first.colorHex, StickyNoteColors.skyBlue);
    });

    test('updates position, content, and color correctly', () async {
      final now = DateTime.now();
      final note = StickyNote(
        id: 'sticky-update',
        pageId: testPageId,
        x: 50,
        y: 50,
        content: 'Initial text',
        createdAt: now,
        updatedAt: now,
      );

      await stickyRepo.saveStickyNote(note);

      // Update position
      await stickyRepo.updatePosition('sticky-update', 150, 250);
      var loaded = await stickyRepo.getStickyNotesForPage(testPageId);
      expect(loaded.first.x, 150.0);
      expect(loaded.first.y, 250.0);

      // Update content
      await stickyRepo.updateContent('sticky-update', 'Updated text notes');
      loaded = await stickyRepo.getStickyNotesForPage(testPageId);
      expect(loaded.first.content, 'Updated text notes');

      // Update color
      await stickyRepo.updateColor(
        'sticky-update',
        StickyNoteColors.pastelPink,
      );
      loaded = await stickyRepo.getStickyNotesForPage(testPageId);
      expect(loaded.first.colorHex, StickyNoteColors.pastelPink);
    });

    test('deletes a sticky note by id', () async {
      final now = DateTime.now();
      final note = StickyNote(
        id: 'sticky-del',
        pageId: testPageId,
        x: 10,
        y: 10,
        content: 'To be deleted',
        createdAt: now,
        updatedAt: now,
      );

      await stickyRepo.saveStickyNote(note);
      expect((await stickyRepo.getStickyNotesForPage(testPageId)).length, 1);

      await stickyRepo.deleteStickyNote('sticky-del');
      expect(
        (await stickyRepo.getStickyNotesForPage(testPageId)).isEmpty,
        isTrue,
      );
    });
  });
}
