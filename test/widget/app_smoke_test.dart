import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/app.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/features/dashboard/presentation/widgets/notebook_card.dart';

void main() {
  group('Naik Notes App Smoke Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftNotebookRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders dashboard with brand, search bar and notebook cards', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notebookRepositoryProvider.overrideWithValue(repo),
          ],
          child: const NaikNotesApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Brand Name and Tagline
      expect(find.text('Naik Notes'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);

      // Verify Quick Action Buttons
      expect(find.text('New Notebook'), findsOneWidget);
      expect(find.text('Import PDF'), findsOneWidget);

      // Verify Filter Buttons
      expect(find.text('All Notebooks'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      // Verify Notebook Card presence
      expect(find.byType(NotebookCard), findsWidgets);
    });

    testWidgets('opens Create Notebook dialog and validates input', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notebookRepositoryProvider.overrideWithValue(repo),
          ],
          child: const NaikNotesApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'New Notebook' button
      final newNotebookButton = find.text('New Notebook');
      expect(newNotebookButton, findsOneWidget);
      await tester.tap(newNotebookButton);
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.text('Create New Notebook'), findsOneWidget);
      expect(find.text('Notebook Title *'), findsOneWidget);

      // Tap create button without title to trigger validation
      final createButton = find.widgetWithText(FilledButton, 'Create Notebook');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a notebook title'), findsOneWidget);

      // Enter valid title
      await tester.enterText(
        find.byType(TextFormField).first,
        'Quantum Mechanics',
      );
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Dialog should close and new notebook should be listed
      expect(find.text('Create New Notebook'), findsNothing);
      expect(find.text('Quantum Mechanics'), findsWidgets);
    });
  });
}
