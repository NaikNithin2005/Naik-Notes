import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/features/notes/data/note_provider.dart';

void main() {
  group('Instant Search & Filter Unit Tests', () {
    late Note note1;
    late Note note2;
    late Note note3;
    late Note pinnedNote;
    late Note archivedNote;
    late Note trashNote;

    setUp(() {
      final baseTime = DateTime(2026, 11, 20, 10, 0);

      note1 = Note(
        id: 'n1',
        ownerId: 'u1',
        notebookId: 'nb_work',
        title: 'Sprint Planning meeting',
        contentDelta: jsonEncode([
          {'insert': 'Discuss Phase 2 architecture and deliverables.\n'}
        ]),
        plainText: 'Discuss Phase 2 architecture and deliverables.\n',
        preview: 'Discuss Phase 2 architecture and deliverables.',
        tags: ['agile', 'planning'],
        isPinned: false,
        isFavorite: true,
        isArchived: false,
        isDeleted: false,
        createdAt: baseTime.add(const Duration(hours: 1)),
        updatedAt: baseTime.add(const Duration(hours: 4)),
      );

      note2 = Note(
        id: 'n2',
        ownerId: 'u1',
        notebookId: 'nb_personal',
        title: 'Grocery Checklist',
        contentDelta: jsonEncode([
          {'insert': 'Almond milk, coffee beans, sourdough bread.\n'}
        ]),
        plainText: 'Almond milk, coffee beans, sourdough bread.\n',
        preview: 'Almond milk, coffee beans, sourdough bread.',
        tags: ['personal', 'shopping'],
        isPinned: false,
        isFavorite: false,
        isArchived: false,
        isDeleted: false,
        createdAt: baseTime.add(const Duration(hours: 2)),
        updatedAt: baseTime.add(const Duration(hours: 2)),
      );

      note3 = Note(
        id: 'n3',
        ownerId: 'u1',
        notebookId: 'nb_work',
        title: 'Flutter Quill Research',
        contentDelta: jsonEncode([
          {'insert': 'Rich text editor WYSIWYG integration notes.\n'}
        ]),
        plainText: 'Rich text editor WYSIWYG integration notes.\n',
        preview: 'Rich text editor WYSIWYG integration notes.',
        tags: ['flutter', 'research'],
        isPinned: false,
        isFavorite: true,
        isArchived: false,
        isDeleted: false,
        createdAt: baseTime.add(const Duration(hours: 3)),
        updatedAt: baseTime.add(const Duration(hours: 5)),
      );

      pinnedNote = Note(
        id: 'n_pin',
        ownerId: 'u1',
        notebookId: 'nb_work',
        title: 'Company Roadmap',
        contentDelta: jsonEncode([
          {'insert': 'Q4 Strategic OKRs and targets.\n'}
        ]),
        plainText: 'Q4 Strategic OKRs and targets.\n',
        preview: 'Q4 Strategic OKRs and targets.',
        tags: ['strategy'],
        isPinned: true,
        isFavorite: false,
        isArchived: false,
        isDeleted: false,
        createdAt: baseTime,
        updatedAt: baseTime.add(const Duration(hours: 1)),
      );

      archivedNote = Note(
        id: 'n_arch',
        ownerId: 'u1',
        notebookId: 'nb_work',
        title: 'Old Deprecated Spec',
        contentDelta: jsonEncode([
          {'insert': 'Legacy spec for archive only.\n'}
        ]),
        plainText: 'Legacy spec for archive only.\n',
        preview: 'Legacy spec for archive only.',
        tags: ['legacy'],
        isPinned: false,
        isFavorite: false,
        isArchived: true,
        isDeleted: false,
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      trashNote = Note(
        id: 'n_trash',
        ownerId: 'u1',
        notebookId: 'nb_personal',
        title: 'Deleted Draft',
        contentDelta: jsonEncode([
          {'insert': 'This was discarded.\n'}
        ]),
        plainText: 'This was discarded.\n',
        preview: 'This was discarded.',
        tags: ['trash'],
        isPinned: false,
        isFavorite: false,
        isArchived: false,
        isDeleted: true,
        deletedAt: baseTime.add(const Duration(days: 1)),
        createdAt: baseTime,
        updatedAt: baseTime,
      );
    });

    test('Local instant search matches titles, content, preview, and tags', () {
      final allNotes = [note1, note2, note3, pinnedNote, archivedNote, trashNote];
      final container = ProviderContainer(
        overrides: [
          notesProvider.overrideWith(() => _MockNotesNotifier(allNotes)),
        ],
      );

      // Search by title substring
      container.read(noteSearchProvider.notifier).setQuery('sprint');
      var results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n1');

      // Search by body content substring
      container.read(noteSearchProvider.notifier).setQuery('deliverables');
      results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n1');

      // Search by tag substring
      container.read(noteSearchProvider.notifier).setQuery('shopping');
      results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n2');

      // Search case-insensitive
      container.read(noteSearchProvider.notifier).setQuery('FLUTTER');
      results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n3');

      // Clear search
      container.read(noteSearchProvider.notifier).clear();
      results = container.read(filteredNotesProvider);
      // All active notes (excludes archived and trash)
      expect(results.length, 4);
    });

    test('Category filter correctly isolates Pinned, Favorites, Archive, and Trash', () {
      final allNotes = [note1, note2, note3, pinnedNote, archivedNote, trashNote];
      final container = ProviderContainer(
        overrides: [
          notesProvider.overrideWith(() => _MockNotesNotifier(allNotes)),
        ],
      );

      // 1. Pinned filter
      container
          .read(noteFilterProvider.notifier)
          .setFilter(NoteFilterType.pinned);
      var results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n_pin');

      // 2. Favorites filter
      container
          .read(noteFilterProvider.notifier)
          .setFilter(NoteFilterType.favorites);
      results = container.read(filteredNotesProvider);
      expect(results.length, 2);
      expect(results.map((n) => n.id).toSet(), {'n1', 'n3'});

      // 3. Archive filter
      container
          .read(noteFilterProvider.notifier)
          .setFilter(NoteFilterType.archive);
      results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n_arch');

      // 4. Trash filter
      container
          .read(noteFilterProvider.notifier)
          .setFilter(NoteFilterType.trash);
      results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n_trash');

      // 5. Notebook filter
      container
          .read(noteFilterProvider.notifier)
          .selectNotebook('nb_personal');
      results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n2');

      // 6. Tag filter
      container.read(noteFilterProvider.notifier).selectTag('agile');
      results = container.read(filteredNotesProvider);
      expect(results.length, 1);
      expect(results.first.id, 'n1');
    });

    test('Sorting orders notes correctly while prioritizing pinned notes', () {
      final allNotes = [note1, note2, note3, pinnedNote];
      final container = ProviderContainer(
        overrides: [
          notesProvider.overrideWith(() => _MockNotesNotifier(allNotes)),
        ],
      );

      // Modified Desc: pinnedNote is pinned so it comes first, then n3 (5h), n1 (4h), n2 (2h)
      container
          .read(noteSortOrderProvider.notifier)
          .setSortOrder(NoteSortOrder.modifiedDesc);
      var results = container.read(filteredNotesProvider);
      expect(results.map((n) => n.id).toList(), ['n_pin', 'n3', 'n1', 'n2']);

      // Title Asc: pinned first, then alphabetical (Flutter Quill, Grocery, Sprint Planning)
      container
          .read(noteSortOrderProvider.notifier)
          .setSortOrder(NoteSortOrder.titleAsc);
      results = container.read(filteredNotesProvider);
      expect(results.map((n) => n.id).toList(), ['n_pin', 'n3', 'n2', 'n1']);
    });
  });
}

class _MockNotesNotifier extends NotesNotifier {
  final List<Note> _initial;
  _MockNotesNotifier(this._initial);

  @override
  List<Note> build() => _initial;
}

