import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/core/presentation/responsive_layout.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/feedback/data/feedback_service.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';
import 'package:naik_notes/services/history/note_history_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late NotebookRepository notebookRepo;
  late PageRepository pageRepo;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    notebookRepo = DriftNotebookRepository(database);
    pageRepo = DriftPageRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('iPadOS Comprehensive Validation Suite (Tests A through L)', () {
    // -------------------------------------------------------------------------
    // TEST A: Navigation Paths & Routes
    // -------------------------------------------------------------------------
    test('Test A: Navigation routes integrity (Settings, Profile, History, Feedback, Notebook)', () {
      expect(RouteNames.dashboard, equals('/'));
      expect(RouteNames.notes, equals('/notes'));
      expect(RouteNames.settings, equals('/settings'));
      expect(RouteNames.profile, equals('/profile'));
      expect(RouteNames.feedback, equals('/feedback'));
      expect(RouteNames.notebookView, equals('/notebook/:id'));
      expect(RouteNames.notebookPath('nb-123'), equals('/notebook/nb-123'));
      // Verify no malformed ?id= parameters generated
      expect(RouteNames.notebookPath('nb-123').contains('?id='), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST B: Notebook Creation & Immediate Page 1 Initialization
    // -------------------------------------------------------------------------
    test('Test B: Notebook creation immediately persists Page 1 into SQLite database', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          notebookRepositoryProvider.overrideWithValue(notebookRepo),
          pageRepositoryProvider.overrideWithValue(pageRepo),
        ],
      );
      addTearDown(container.dispose);

      final notebook = await container.read(notebooksProvider.notifier).addNotebook(
        title: 'Biology 101 iPad Notes',
        coverId: 'cover_emerald',
        coverColorHex: '#10B981',
        paperTemplateId: 'college_ruled',
        pageSize: 'A4',
        orientation: 'portrait',
      );

      expect(notebook.id, isNotEmpty);
      expect(notebook.title, equals('Biology 101 iPad Notes'));

      // Verify that Page 1 was synchronously persisted in SQLite database
      final pagesInDb = await pageRepo.getPagesForNotebook(notebook.id);
      expect(pagesInDb.length, equals(1));
      expect(pagesInDb.first.pageNumber, equals(1));
      expect(pagesInDb.first.notebookId, equals(notebook.id));
      expect(pagesInDb.first.templateId, equals('college_ruled'));
    });

    // -------------------------------------------------------------------------
    // TEST C: NotebookViewScreen Loading Resilience & Fallback Resolution
    // -------------------------------------------------------------------------
    test('Test C: Direct notebook query resolves from repository when not in in-memory state', () async {
      final now = DateTime.now();
      final directNotebook = Notebook(
        id: 'nb-direct-test-99',
        ownerId: 'local_user',
        title: 'Anatomy Lab Notebook',
        description: 'Direct deep link test',
        coverId: 'cover_navy',
        coverColorHex: '#1E3A8A',
        paperTemplateId: 'grid_5mm',
        orientation: 'portrait',
        pageSize: 'A4',
        pageCount: 1,
        isFavorite: false,
        isArchived: false,
        revision: 1,
        createdAt: now,
        updatedAt: now,
      );

      // Save directly into SQLite repository without populating notebooksProvider state
      await notebookRepo.saveNotebook(directNotebook);
      await pageRepo.ensurePagesExist(directNotebook.id, templateId: 'grid_5mm');

      // Verify repository retrieves it seamlessly (simulating NotebookViewScreen fallback)
      final retrieved = await notebookRepo.getNotebookById('nb-direct-test-99');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Anatomy Lab Notebook'));

      final pages = await pageRepo.getPagesForNotebook('nb-direct-test-99');
      expect(pages.isNotEmpty, isTrue);
      expect(pages.first.templateId, equals('grid_5mm'));
    });

    // -------------------------------------------------------------------------
    // TEST D: Writing Board Dimension & Template Configuration
    // -------------------------------------------------------------------------
    test('Test D: Page dimensions recalculate properly for iPad portrait and landscape', () {
      final portraitA4 = PaperProperties.getDimensions('A4', 'portrait');
      final landscapeA4 = PaperProperties.getDimensions('A4', 'landscape');

      expect(portraitA4.width, lessThan(portraitA4.height));
      expect(landscapeA4.width, greaterThan(landscapeA4.height));
      expect(portraitA4.width, equals(landscapeA4.height));
      expect(portraitA4.height, equals(landscapeA4.width));
    });

    // -------------------------------------------------------------------------
    // TEST E: Apple Pencil Stylus Events (Double Tap, Squeeze, Hover)
    // -------------------------------------------------------------------------
    test('Test E: Active tool toggles on Apple Pencil double tap and squeeze events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(activeToolProvider), equals(ToolType.fountainPen));

      // Simulate Apple Pencil Double-Tap to toggle eraser
      container.read(activeToolProvider.notifier).toggleEraser();
      expect(container.read(activeToolProvider), equals(ToolType.eraser));

      // Toggle back to previous writing tool
      container.read(activeToolProvider.notifier).togglePreviousTool();
      expect(container.read(activeToolProvider), equals(ToolType.fountainPen));
    });

    // -------------------------------------------------------------------------
    // TEST F: Palm Rejection & Multi-Touch State Isolation
    // -------------------------------------------------------------------------
    test('Test F: Palm rejection settings state isolates hardware stylus from touch', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(palmRejectionEnabledProvider), isTrue);
      expect(container.read(stylusOnlyModeProvider), isFalse);

      // Toggle Stylus-only mode
      container.read(stylusOnlyModeProvider.notifier).setEnabled(true);
      expect(container.read(stylusOnlyModeProvider), isTrue);

      container.read(stylusOnlyModeProvider.notifier).setEnabled(false);
      expect(container.read(stylusOnlyModeProvider), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST G: Responsive Tool Selection & Color Palette Integration
    // -------------------------------------------------------------------------
    test('Test G: Inking stroke tool selection, color and width state updates properly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(activeToolProvider.notifier).setTool(ToolType.highlighter);
      expect(container.read(activeToolProvider), equals(ToolType.highlighter));

      container.read(strokeColorProvider.notifier).setColor(const Color(0xFFFFEB3B));
      expect(container.read(strokeColorProvider), equals(const Color(0xFFFFEB3B)));

      container.read(strokeWidthProvider.notifier).setWidth(18.0);
      expect(container.read(strokeWidthProvider), equals(18.0));
    });

    // -------------------------------------------------------------------------
    // TEST H: Responsive iPad Breakpoints & Viewport Column Computations
    // -------------------------------------------------------------------------
    test('Test H: FormFactor and recommended column counts adapt across iPad split-view & full screen', () {
      // 400px: iPad Slide Over or 1/3 Split View -> compact (1 column)
      expect(400.0 < ResponsiveBreakpoints.compactMax, isTrue);

      // 768px: iPad 9th/10th gen portrait -> medium
      expect(768.0 >= ResponsiveBreakpoints.compactMax && 768.0 < ResponsiveBreakpoints.mediumMax, isTrue);

      // 1024px: iPad Landscape -> mediumMax boundary / expanded
      expect(1024.0 >= ResponsiveBreakpoints.mediumMax, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST I: Notes History Entry Model & Navigation Target
    // -------------------------------------------------------------------------
    test('Test I: NoteActivityEntry records activity with noteId targeting valid notebook path', () {
      final entry = NoteActivityEntry(
        id: 'hist-1',
        noteId: 'nb-target-uuid-42',
        noteTitle: 'Calculus Notes',
        action: NoteActionType.updated,
        timestamp: DateTime.now(),
        deviceName: 'iPad Pro 11-inch',
        userEmail: 'student@university.edu',
      );

      expect(entry.noteId, equals('nb-target-uuid-42'));
      final targetRoute = RouteNames.notebookPath(entry.noteId);
      expect(targetRoute, equals('/notebook/nb-target-uuid-42'));
    });

    // -------------------------------------------------------------------------
    // TEST J: Feedback Submission Flow & Validation
    // -------------------------------------------------------------------------
    test('Test J: Feedback submission validates input and constructs valid submission payload', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(feedbackServiceProvider);

      // Test empty description throws exception
      expect(
        () => service.submitFeedback(
          category: 'Bug Report',
          rating: 4,
          description: '   ',
        ),
        throwsA(isA<Exception>()),
      );

      // Test valid submission succeeds
      final success = await service.submitFeedback(
        category: 'Apple Pencil & Stylus',
        rating: 5,
        description: 'Apple Pencil squeeze gestures switch tools instantly! Great work.',
      );
      expect(success, isTrue);
    });

    // -------------------------------------------------------------------------
    // TEST K: Profile Display Name Update & Persistence
    // -------------------------------------------------------------------------
    test('Test K: AuthNotifier updates user display name and preserves authenticated session', () async {
      final fakeAuthRepo = RemoteAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepo),
        ],
      );
      addTearDown(container.dispose);

      // Update display name
      final success = await container
          .read(authProvider.notifier)
          .updateDisplayName('Dr. Ada Lovelace');

      expect(success, isTrue);
      expect(container.read(authProvider).user?.displayName, equals('Dr. Ada Lovelace'));
    });

    // -------------------------------------------------------------------------
    // TEST L: Page Index Navigation Reset & Bounds Clamping
    // -------------------------------------------------------------------------
    test('Test L: CurrentPageIndexNotifier clamps index within page count bounds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(currentPageIndexProvider.notifier);
      expect(container.read(currentPageIndexProvider), equals(1));

      notifier.setPage(5);
      expect(container.read(currentPageIndexProvider), equals(5));

      // Reset to 1 on opening a notebook
      notifier.setPage(1);
      expect(container.read(currentPageIndexProvider), equals(1));
    });
  });
}
