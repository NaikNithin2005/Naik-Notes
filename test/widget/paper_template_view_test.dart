import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/repositories/folder_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/features/notebooks/presentation/screens/notebook_view_screen.dart';
import 'package:naik_notes/features/templates/presentation/painters/paper_template_painter.dart';
import 'package:naik_notes/features/templates/presentation/widgets/paper_template_view.dart';
import 'package:naik_notes/features/templates/presentation/widgets/template_customizer_sheet.dart';

void main() {
  group('Paper Template & Customizer Widget Tests', () {
    testWidgets('PaperTemplateView renders vector canvas for all templates', (
      tester,
    ) async {
      final sampleTypes = [
        PaperTemplateType.blankPaper,
        PaperTemplateType.collegeRuled,
        PaperTemplateType.dottedPaper,
        PaperTemplateType.squareGrid,
        PaperTemplateType.cornellNotes,
        PaperTemplateType.meetingNotes,
        PaperTemplateType.dailyPlanner,
        PaperTemplateType.weeklyPlanner,
        PaperTemplateType.engineeringPaper,
        PaperTemplateType.isometricPaper,
        PaperTemplateType.musicManuscript,
        PaperTemplateType.checklist,
        PaperTemplateType.journalPages,
      ];

      for (final type in sampleTypes) {
        final props = PaperProperties.defaultFor(type);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PaperTemplateView(
                type: type,
                properties: props,
                width: 300,
                height: 400,
              ),
            ),
          ),
        );

        expect(find.byType(PaperTemplateView), findsOneWidget);
        expect(find.byType(CustomPaint), findsWidgets);

        // Verify the painter is attached
        final customPaint = tester.widget<CustomPaint>(
          find
              .descendant(
                of: find.byType(PaperTemplateView),
                matching: find.byType(CustomPaint),
              )
              .first,
        );
        expect(customPaint.painter, isA<PaperTemplatePainter>());
      }
    });

    testWidgets(
      'TemplateCustomizerSheet opens and selects different template',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        PaperTemplateType? appliedType;
        PaperProperties? appliedProps;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => TemplateCustomizerSheet(
                          initialType: PaperTemplateType.collegeRuled,
                          initialProperties: PaperProperties.defaultFor(
                            PaperTemplateType.collegeRuled,
                          ),
                          onApply: (type, props, applyToAll) {
                            appliedType = type;
                            appliedProps = props;
                          },
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        );

        // Open sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.text('Paper Template & Style'), findsOneWidget);
        expect(find.text('Live Preview'), findsOneWidget);

        // Scroll to Cornell Notes and select
        await tester.ensureVisible(find.text('Cornell Notes'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cornell Notes'));
        await tester.pumpAndSettle();

        // Tap Apply Template button
        await tester.ensureVisible(find.text('Apply Template'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apply Template'));
        await tester.pumpAndSettle();

        expect(appliedType, PaperTemplateType.cornellNotes);
        expect(appliedProps?.marginLeft, 150.0);
      },
    );

    testWidgets(
      'NotebookViewScreen displays PaperTemplateView and page navigation',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final notebookRepo = DriftNotebookRepository(db);
        final folderRepo = DriftFolderRepository(db);
        final pageRepo = DriftPageRepository(db);

        final now = DateTime.now();
        await notebookRepo.saveNotebook(
          Notebook(
            id: 'nb-1-math',
            ownerId: 'user-default',
            title: 'Advanced Mathematics & Calculus',
            description: 'Calculus and Linear Algebra',
            coverId: 'classic_leather',
            coverColorHex: '#8B4513',
            paperTemplateId: 'square_grid',
            pageCount: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await pageRepo.ensurePagesExist(
          'nb-1-math',
          templateId: 'square_grid',
          count: 2,
        );

        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() {
          tester.binding.setSurfaceSize(null);
          db.close();
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              notebookRepositoryProvider.overrideWithValue(notebookRepo),
              folderRepositoryProvider.overrideWithValue(folderRepo),
              pageRepositoryProvider.overrideWithValue(pageRepo),
            ],
            child: const MaterialApp(
              home: NotebookViewScreen(notebookId: 'nb-1-math'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check header and title
        expect(find.text('Advanced Mathematics & Calculus'), findsOneWidget);

        // Check bottom page navigation controls
        expect(find.text('Add Page'), findsOneWidget);

        // Check PaperTemplateView is rendered on canvas
        expect(find.byType(PaperTemplateView), findsOneWidget);

        // Check paper settings button is present
        expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      },
    );
  });
}
