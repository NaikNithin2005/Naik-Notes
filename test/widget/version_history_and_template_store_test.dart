import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/version_history_model.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/data/repositories/version_history_repository.dart';
import 'package:naik_notes/features/template_store/presentation/widgets/template_store_sheet.dart';
import 'package:naik_notes/features/version_history/presentation/widgets/version_history_sheet.dart';

void main() {
  group('Version History & Template Store Widget Tests', () {
    late AppDatabase db;
    late DriftVersionHistoryRepository historyRepo;
    late DriftNotebookRepository notebookRepo;
    late DriftPageRepository pageRepo;

    const testNotebookId = 'nb-w-1';
    const testPageId = 'page-w-1';

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      historyRepo = DriftVersionHistoryRepository(db);
      notebookRepo = DriftNotebookRepository(db);
      pageRepo = DriftPageRepository(db);

      await notebookRepo.saveNotebook(
        Notebook(
          id: testNotebookId,
          ownerId: 'local_user',
          coverId: 'classic_leather',
          title: 'Widget Notebook',
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

    testWidgets(
      'VersionHistorySheet displays snapshots and triggers restore dialog',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        // Seed a snapshot
        await historyRepo.saveSnapshot(
          PageSnapshot(
            id: 'snap-w-1',
            pageId: testPageId,
            notebookId: testNotebookId,
            versionNumber: 1,
            label: 'Pre-Exam Review',
            strokes: [],
            stickyNotes: [],
            deviceInfo: 'Surface Pen',
            createdAt: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(
                body: VersionHistorySheet(
                  pageId: testPageId,
                  notebookId: testNotebookId,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify header and elements
        expect(find.text('Page Version History'), findsOneWidget);
        expect(find.text('Save Snapshot'), findsOneWidget);
        expect(find.text('Pre-Exam Review'), findsOneWidget);
        expect(find.text('Surface Pen'), findsOneWidget);
        expect(find.text('Restore'), findsOneWidget);

        // Tap restore to trigger confirmation dialog
        await tester.tap(find.text('Restore'));
        await tester.pumpAndSettle();

        expect(find.text('Restore Version?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // Cancel dialog
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Restore Version?'), findsNothing);
      },
    );

    testWidgets(
      'TemplateStoreSheet renders categories, search, and template cards',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [appDatabaseProvider.overrideWithValue(db)],
            child: const MaterialApp(
              home: Scaffold(body: TemplateStoreSheet()),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify store header & chips
        expect(find.text('Community Template Store'), findsOneWidget);
        expect(find.text('Import JSON'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
        expect(find.widgetWithText(FilterChip, 'Engineering'), findsOneWidget);
        expect(
          find.widgetWithText(FilterChip, 'Math & Science'),
          findsOneWidget,
        );
        expect(find.widgetWithText(FilterChip, 'Planning'), findsOneWidget);

        // Verify template card content
        expect(find.text('Dark Mode Precision Quad Grid'), findsOneWidget);

        // Tap Category Filter
        await tester.tap(find.widgetWithText(FilterChip, 'Engineering'));
        await tester.pumpAndSettle();

        expect(find.text('Dark Mode Precision Quad Grid'), findsOneWidget);
      },
    );
  });
}
