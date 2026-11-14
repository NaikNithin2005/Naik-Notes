import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';
import 'package:naik_notes/features/pdf/data/sticky_note_provider.dart';

class MockStickyNoteRepository implements StickyNoteRepository {
  final Map<String, List<StickyNote>> _storage = {};

  @override
  Future<List<StickyNote>> getStickyNotesForPage(String pageId) async {
    return _storage[pageId] ?? [];
  }

  @override
  Stream<List<StickyNote>> watchStickyNotesForPage(String pageId) {
    return Stream.value(_storage[pageId] ?? []);
  }

  @override
  Future<void> saveStickyNote(StickyNote note) async {
    final list = _storage.putIfAbsent(note.pageId, () => []);
    list.removeWhere((n) => n.id == note.id);
    list.add(note);
  }

  @override
  Future<void> deleteStickyNote(String id) async {
    for (final list in _storage.values) {
      list.removeWhere((n) => n.id == id);
    }
  }

  @override
  Future<void> updatePosition(String id, double x, double y) async {
    for (final list in _storage.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == id) {
          list[i] = list[i].copyWith(x: x, y: y);
        }
      }
    }
  }

  @override
  Future<void> updateContent(String id, String content) async {
    for (final list in _storage.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == id) {
          list[i] = list[i].copyWith(content: content);
        }
      }
    }
  }

  @override
  Future<void> updateColor(String id, String colorHex) async {
    for (final list in _storage.values) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == id) {
          list[i] = list[i].copyWith(colorHex: colorHex);
        }
      }
    }
  }
}

void main() {
  group('StickyNotesNotifier Tests', () {
    late ProviderContainer container;
    late MockStickyNoteRepository mockRepo;
    const testPageId = 'page-sticky-prov-1';

    setUp(() {
      mockRepo = MockStickyNoteRepository();
      container = ProviderContainer(
        overrides: [stickyNoteRepositoryProvider.overrideWithValue(mockRepo)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('adds sticky note, updates state and persists', () async {
      final notifier = container.read(stickyNotesProvider.notifier);

      final note = await notifier.addStickyNote(
        testPageId,
        x: 120,
        y: 180,
        content: 'Review chapter 4',
      );

      final notes = container.read(pageStickyNotesProvider(testPageId));
      expect(notes.length, 1);
      expect(notes.first.id, note.id);
      expect(notes.first.x, 120.0);
      expect(notes.first.y, 180.0);
      expect(notes.first.content, 'Review chapter 4');

      final persisted = await mockRepo.getStickyNotesForPage(testPageId);
      expect(persisted.length, 1);
      expect(persisted.first.id, note.id);
    });

    test(
      'updates position, content and color across state and repository',
      () async {
        final notifier = container.read(stickyNotesProvider.notifier);

        final note = await notifier.addStickyNote(
          testPageId,
          x: 50,
          y: 50,
          content: 'Initial text',
        );

        // Move
        await notifier.updatePosition(testPageId, note.id, 200, 300);
        var current = container.read(pageStickyNotesProvider(testPageId));
        expect(current.first.x, 200.0);
        expect(current.first.y, 300.0);

        // Edit content
        await notifier.updateContent(testPageId, note.id, 'New content');
        current = container.read(pageStickyNotesProvider(testPageId));
        expect(current.first.content, 'New content');

        // Change color
        await notifier.updateColor(
          testPageId,
          note.id,
          StickyNoteColors.mintGreen,
        );
        current = container.read(pageStickyNotesProvider(testPageId));
        expect(current.first.colorHex, StickyNoteColors.mintGreen);
      },
    );

    test('deletes sticky note and removes from state and storage', () async {
      final notifier = container.read(stickyNotesProvider.notifier);

      final note = await notifier.addStickyNote(testPageId, x: 10, y: 10);
      expect(container.read(pageStickyNotesProvider(testPageId)).length, 1);

      await notifier.deleteStickyNote(testPageId, note.id);
      expect(
        container.read(pageStickyNotesProvider(testPageId)).isEmpty,
        isTrue,
      );

      final persisted = await mockRepo.getStickyNotesForPage(testPageId);
      expect(persisted.isEmpty, isTrue);
    });
  });
}
