import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotebooksNotifier Tests', () {
    test('initializes with default sample notebooks', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftNotebookRepository(db);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notebookRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final notebooks = container.read(notebooksProvider);
      expect(notebooks.isNotEmpty, true);
      expect(notebooks.any((nb) => nb.title.contains('Mathematics')), true);

      container.dispose();
      await db.close();
    });

    test('adds a new notebook to the front of the list', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftNotebookRepository(db);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notebookRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final notifier = container.read(notebooksProvider.notifier);
      final initialCount = container.read(notebooksProvider).length;

      await notifier.addNotebook(
        title: 'Biology 101',
        description: 'Cell structure and genetics',
        coverId: 'minimal_sage',
        coverColorHex: '#4A6B53',
        paperTemplateId: 'dotted_paper',
      );

      final updatedList = container.read(notebooksProvider);
      expect(updatedList.length, initialCount + 1);
      expect(updatedList.first.title, 'Biology 101');
      expect(updatedList.first.coverId, 'minimal_sage');

      container.dispose();
      await db.close();
    });

    test('toggles favorite status of a notebook', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftNotebookRepository(db);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notebookRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final notifier = container.read(notebooksProvider.notifier);
      final firstNotebook = container.read(notebooksProvider).first;
      final originalFav = firstNotebook.isFavorite;

      await notifier.toggleFavorite(firstNotebook.id);

      final updated = container
          .read(notebooksProvider)
          .firstWhere((nb) => nb.id == firstNotebook.id);
      expect(updated.isFavorite, !originalFav);

      container.dispose();
      await db.close();
    });

    test('deletes a notebook correctly', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftNotebookRepository(db);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notebookRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final notifier = container.read(notebooksProvider.notifier);
      final target = container.read(notebooksProvider).first;

      await notifier.deleteNotebook(target.id);

      final exists = container
          .read(notebooksProvider)
          .any((nb) => nb.id == target.id);
      expect(exists, false);

      container.dispose();
      await db.close();
    });
  });
}
