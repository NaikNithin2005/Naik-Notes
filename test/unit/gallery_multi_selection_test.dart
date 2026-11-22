import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/features/notebooks/data/notebook_selection_provider.dart';
import 'package:naik_notes/features/notes/data/note_selection_provider.dart';

void main() {
  group('Gallery-Style NotebookSelectionNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has selectionMode false and empty set', () {
      final state = container.read(notebookSelectionProvider);
      expect(state.isSelectionMode, isFalse);
      expect(state.selectedNotebookIds, isEmpty);
      expect(state.selectedCount, equals(0));
    });

    test('enterSelectionMode selects initial item and enables selection mode', () {
      final notifier = container.read(notebookSelectionProvider.notifier);
      notifier.enterSelectionMode('nb-1');

      final state = container.read(notebookSelectionProvider);
      expect(state.isSelectionMode, isTrue);
      expect(state.selectedNotebookIds, contains('nb-1'));
      expect(state.selectedCount, equals(1));
      expect(state.isSelected('nb-1'), isTrue);
      expect(state.isSelected('nb-2'), isFalse);
    });

    test('toggle adds and removes items correctly', () {
      final notifier = container.read(notebookSelectionProvider.notifier);
      notifier.enterSelectionMode('nb-1');
      notifier.toggle('nb-2');

      var state = container.read(notebookSelectionProvider);
      expect(state.selectedCount, equals(2));
      expect(state.selectedNotebookIds, containsAll(['nb-1', 'nb-2']));

      // Toggle nb-1 off
      notifier.toggle('nb-1');
      state = container.read(notebookSelectionProvider);
      expect(state.selectedCount, equals(1));
      expect(state.isSelected('nb-1'), isFalse);
      expect(state.isSelected('nb-2'), isTrue);
      expect(state.isSelectionMode, isTrue);

      // Toggle nb-2 off -> should automatically exit selection mode
      notifier.toggle('nb-2');
      state = container.read(notebookSelectionProvider);
      expect(state.selectedCount, equals(0));
      expect(state.isSelectionMode, isFalse);
    });

    test('selectAll and deselectAll work as expected', () {
      final notifier = container.read(notebookSelectionProvider.notifier);
      final allIds = ['nb-1', 'nb-2', 'nb-3', 'nb-4'];

      notifier.selectAll(allIds);
      var state = container.read(notebookSelectionProvider);
      expect(state.isSelectionMode, isTrue);
      expect(state.selectedCount, equals(4));
      expect(state.selectedNotebookIds, containsAll(allIds));

      notifier.deselectAll();
      state = container.read(notebookSelectionProvider);
      expect(state.isSelectionMode, isFalse);
      expect(state.selectedCount, equals(0));
      expect(state.selectedNotebookIds, isEmpty);
    });

    test('rangeSelect selects inclusive span between anchor and target (Shift+Click)', () {
      final notifier = container.read(notebookSelectionProvider.notifier);
      final orderedIds = ['nb-1', 'nb-2', 'nb-3', 'nb-4', 'nb-5'];

      // Start by selecting nb-2
      notifier.enterSelectionMode('nb-2');

      // Range select down to nb-4
      notifier.rangeSelect('nb-4', orderedIds);
      var state = container.read(notebookSelectionProvider);
      expect(state.selectedCount, equals(3));
      expect(state.selectedNotebookIds, containsAll(['nb-2', 'nb-3', 'nb-4']));
      expect(state.isSelected('nb-1'), isFalse);
      expect(state.isSelected('nb-5'), isFalse);

      // Now range select up to nb-1
      notifier.rangeSelect('nb-1', orderedIds);
      state = container.read(notebookSelectionProvider);
      expect(state.selectedCount, equals(4));
      expect(state.selectedNotebookIds, containsAll(['nb-1', 'nb-2', 'nb-3', 'nb-4']));
    });

    test('exitSelectionMode resets state completely', () {
      final notifier = container.read(notebookSelectionProvider.notifier);
      notifier.selectAll(['nb-1', 'nb-2', 'nb-3']);
      expect(container.read(notebookSelectionProvider).isSelectionMode, isTrue);

      notifier.exitSelectionMode();
      final state = container.read(notebookSelectionProvider);
      expect(state.isSelectionMode, isFalse);
      expect(state.selectedCount, equals(0));
      expect(state.selectedNotebookIds, isEmpty);
    });
  });

  group('Gallery-Style NoteSelectionNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state has selectionMode false and empty set', () {
      final state = container.read(noteSelectionProvider);
      expect(state.isSelectionMode, isFalse);
      expect(state.selectedNoteIds, isEmpty);
      expect(state.selectedCount, equals(0));
    });

    test('enterSelectionMode selects initial note and enables selection mode', () {
      final notifier = container.read(noteSelectionProvider.notifier);
      notifier.enterSelectionMode('note-101');

      final state = container.read(noteSelectionProvider);
      expect(state.isSelectionMode, isTrue);
      expect(state.selectedNoteIds, contains('note-101'));
      expect(state.selectedCount, equals(1));
      expect(state.isSelected('note-101'), isTrue);
      expect(state.isSelected('note-102'), isFalse);
    });

    test('toggle adds and removes notes correctly and auto-exits on empty', () {
      final notifier = container.read(noteSelectionProvider.notifier);
      notifier.enterSelectionMode('note-1');
      notifier.toggle('note-2');

      var state = container.read(noteSelectionProvider);
      expect(state.selectedCount, equals(2));
      expect(state.selectedNoteIds, containsAll(['note-1', 'note-2']));

      notifier.toggle('note-1');
      state = container.read(noteSelectionProvider);
      expect(state.selectedCount, equals(1));
      expect(state.isSelected('note-1'), isFalse);
      expect(state.isSelected('note-2'), isTrue);

      notifier.toggle('note-2');
      state = container.read(noteSelectionProvider);
      expect(state.selectedCount, equals(0));
      expect(state.isSelectionMode, isFalse);
    });

    test('selectAll and deselectAll for notes', () {
      final notifier = container.read(noteSelectionProvider.notifier);
      final notes = ['n-1', 'n-2', 'n-3', 'n-4', 'n-5'];

      notifier.selectAll(notes);
      var state = container.read(noteSelectionProvider);
      expect(state.isSelectionMode, isTrue);
      expect(state.selectedCount, equals(5));
      expect(state.selectedNoteIds, containsAll(notes));

      notifier.deselectAll();
      state = container.read(noteSelectionProvider);
      expect(state.isSelectionMode, isFalse);
      expect(state.selectedCount, equals(0));
      expect(state.selectedNoteIds, isEmpty);
    });

    test('rangeSelect for notes (Shift+Click)', () {
      final notifier = container.read(noteSelectionProvider.notifier);
      final notes = ['n-1', 'n-2', 'n-3', 'n-4', 'n-5'];

      notifier.enterSelectionMode('n-2');
      notifier.rangeSelect('n-5', notes);

      final state = container.read(noteSelectionProvider);
      expect(state.selectedCount, equals(4));
      expect(state.selectedNoteIds, containsAll(['n-2', 'n-3', 'n-4', 'n-5']));
      expect(state.isSelected('n-1'), isFalse);
    });

    test('exitSelectionMode resets state', () {
      final notifier = container.read(noteSelectionProvider.notifier);
      notifier.selectAll(['n-1', 'n-2']);
      notifier.exitSelectionMode();

      final state = container.read(noteSelectionProvider);
      expect(state.isSelectionMode, isFalse);
      expect(state.selectedCount, equals(0));
      expect(state.selectedNoteIds, isEmpty);
    });
  });
}

