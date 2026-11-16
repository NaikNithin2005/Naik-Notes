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
    test('initializes with clean empty library in production', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = DriftNotebookRepository(db);
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notebookRepositoryProvider.overrideWithValue(repo),
        ],
      );

      final notebooks = container.read(notebooksProvider);
      expect(notebooks.isEmpty, true);

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

      await notifier.addNotebook(
        title: 'Biology 101',
        description: 'Cell structure and genetics',
        coverId: 'minimal_sage',
        coverColorHex: '#4A6B53',
        paperTemplateId: 'dotted_paper',
      );

      final updatedList = container.read(notebooksProvider);
      expect(updatedList.length, 1);
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
      final created = await notifier.addNotebook(
        title: 'Chemistry',
        description: 'Organic chemistry',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
      );
      final originalFav = created.isFavorite;

      await notifier.toggleFavorite(created.id);

      final updated = container
          .read(notebooksProvider)
          .firstWhere((nb) => nb.id == created.id);
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
      final created = await notifier.addNotebook(
        title: 'Draft Notes',
        description: 'Temporary',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'college_ruled',
      );

      await notifier.deleteNotebook(created.id);

      final exists = container
          .read(notebooksProvider)
          .any((nb) => nb.id == created.id);
      expect(exists, false);

      container.dispose();
      await db.close();
    });
  });
}
