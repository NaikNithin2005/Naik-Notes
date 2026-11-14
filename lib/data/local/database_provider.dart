import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/folder_repository.dart';
import '../repositories/notebook_repository.dart';
import '../repositories/page_repository.dart';
import '../repositories/sticky_note_repository.dart';
import '../repositories/stroke_repository.dart';
import 'app_database.dart';

/// Global provider for the Drift AppDatabase singleton.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

/// Global provider for NotebookRepository.
final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftNotebookRepository(db);
});

/// Global provider for FolderRepository.
final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftFolderRepository(db);
});

/// Global provider for PageRepository.
final pageRepositoryProvider = Provider<PageRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftPageRepository(db);
});

/// Global provider for StrokeRepository.
final strokeRepositoryProvider = Provider<StrokeRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftStrokeRepository(db);
});

/// Global provider for StickyNoteRepository.
final stickyNoteRepositoryProvider = Provider<StickyNoteRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DriftStickyNoteRepository(db);
});
