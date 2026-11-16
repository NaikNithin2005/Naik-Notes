import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/core/widgets/naik_empty_state.dart';

void main() {
  group('NaikEmptyState Widget Tests', () {
    testWidgets('renders notebooks empty state and triggers callback', (
      tester,
    ) async {
      bool created = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NaikEmptyState.notebooks(
              onCreateNotebook: () => created = true,
            ),
          ),
        ),
      );

      expect(find.text('Your Library is Empty'), findsOneWidget);
      expect(find.textContaining('Create your first notebook'), findsOneWidget);
      expect(find.text('Create Notebook'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);

      await tester.tap(find.text('Create Notebook'));
      expect(created, isTrue);
    });

    testWidgets('renders folder empty state with custom name', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NaikEmptyState.folder(
              folderName: 'Physics 101',
              onCreateNotebook: () {},
            ),
          ),
        ),
      );

      expect(find.text('No notebooks in "Physics 101"'), findsOneWidget);
      expect(find.text('Add Notebook to Folder'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
    });

    testWidgets('renders search empty state with query', (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NaikEmptyState.search(
              query: 'Quantum Computing',
              onClearSearch: () => cleared = true,
            ),
          ),
        ),
      );

      expect(find.text('No results for "Quantum Computing"'), findsOneWidget);
      expect(find.text('Clear Search'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);

      await tester.tap(find.text('Clear Search'));
      expect(cleared, isTrue);
    });

    testWidgets('renders favorites, recent, and archive empty states', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  NaikEmptyState.favorites(),
                  NaikEmptyState.recent(),
                  NaikEmptyState.archive(),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('No Favorite Notebooks'), findsOneWidget);
      expect(find.text('No Recent Activity'), findsOneWidget);
      expect(find.text('No Archived Notebooks'), findsOneWidget);
    });
  });
}
