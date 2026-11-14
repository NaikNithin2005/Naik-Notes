import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/notebook_model.dart';
import '../../../data/repositories/notebook_repository.dart';

/// State notifier managing the reactive list of notebooks, backed by Drift SQLite.
class NotebooksNotifier extends Notifier<List<Notebook>> {
  final _uuid = const Uuid();
  late final NotebookRepository _repository;

  @override
  List<Notebook> build() {
    _repository = ref.watch(notebookRepositoryProvider);
    return _initialSampleNotebooks();
  }

  Future<void> loadFromDatabase() async {
    await _repository.populateDefaultSamplesIfEmpty();
    final dbNotebooks = await _repository.getAllNotebooks(
      includeArchived: true,
    );
    if (dbNotebooks.isNotEmpty) {
      state = dbNotebooks;
    }
  }

  List<Notebook> _initialSampleNotebooks() {
    final now = DateTime.now();
    return [
      Notebook(
        id: 'nb-1-math',
        ownerId: 'user-default',
        folderId: 'folder-math-sci',
        title: 'Advanced Mathematics & Calculus',
        description: 'Derivatives, integrals, differential equations notes',
        coverId: 'dark_academia_leather',
        coverColorHex: '#1E2A38',
        paperTemplateId: 'square_grid',
        pageCount: 14,
        isFavorite: true,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Notebook(
        id: 'nb-2-physics',
        ownerId: 'user-default',
        folderId: 'folder-math-sci',
        title: 'Quantum Physics Lecture Notes',
        description: 'Lecture recordings, diagrams and formulas',
        coverId: 'academic_navy',
        coverColorHex: '#1B365D',
        paperTemplateId: 'cornell_notes',
        pageCount: 28,
        isFavorite: true,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
      Notebook(
        id: 'nb-3-planner',
        ownerId: 'user-default',
        folderId: 'folder-research',
        title: '2026 Academic & Research Planner',
        description: 'Weekly goals, exam schedules and project milestones',
        coverId: 'pastel_sage',
        coverColorHex: '#8A9E8E',
        paperTemplateId: 'weekly_planner',
        pageCount: 52,
        isFavorite: false,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Notebook(
        id: 'nb-4-ideas',
        ownerId: 'user-default',
        folderId: 'folder-personal',
        title: 'Creative Sketches & Journal',
        description: 'Freehand mind maps, thoughts and sketches',
        coverId: 'nature_earth',
        coverColorHex: '#9E4731',
        paperTemplateId: 'dotted_paper',
        pageCount: 9,
        isFavorite: false,
        isArchived: false,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  Future<Notebook> addNotebook({
    required String title,
    String description = '',
    String? folderId,
    required String coverId,
    required String coverColorHex,
    required String paperTemplateId,
    String orientation = 'portrait',
    String pageSize = 'A4',
  }) async {
    final now = DateTime.now();
    final newNotebook = Notebook(
      id: _uuid.v4(),
      ownerId: 'user-default',
      folderId: folderId,
      title: title,
      description: description,
      coverId: coverId,
      coverColorHex: coverColorHex,
      paperTemplateId: paperTemplateId,
      orientation: orientation,
      pageSize: pageSize,
      pageCount: 1,
      isFavorite: false,
      isArchived: false,
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );

    state = [newNotebook, ...state];
    await _repository.saveNotebook(newNotebook);
    return newNotebook;
  }

  Future<void> renameNotebook(
    String id,
    String newTitle, {
    String? newDescription,
  }) async {
    state = [
      for (final nb in state)
        if (nb.id == id)
          nb.copyWith(
            title: newTitle,
            description: newDescription ?? nb.description,
            updatedAt: DateTime.now(),
          )
        else
          nb,
    ];
    await _repository.renameNotebook(
      id,
      newTitle,
      newDescription: newDescription,
    );
  }

  Future<Notebook?> duplicateNotebook(String id) async {
    final duplicated = await _repository.duplicateNotebook(id);
    if (duplicated != null) {
      state = [duplicated, ...state];
    }
    return duplicated;
  }

  Future<void> moveToFolder(String notebookId, String? folderId) async {
    state = [
      for (final nb in state)
        if (nb.id == notebookId)
          nb.copyWith(
            folderId: folderId,
            clearFolderId: folderId == null,
            updatedAt: DateTime.now(),
          )
        else
          nb,
    ];
    await _repository.moveNotebookToFolder(notebookId, folderId);
  }

  Future<void> archiveNotebook(String notebookId) async {
    state = [
      for (final nb in state)
        if (nb.id == notebookId)
          nb.copyWith(isArchived: true, updatedAt: DateTime.now())
        else
          nb,
    ];
    await _repository.archiveNotebook(notebookId);
  }

  Future<void> unarchiveNotebook(String notebookId) async {
    state = [
      for (final nb in state)
        if (nb.id == notebookId)
          nb.copyWith(isArchived: false, updatedAt: DateTime.now())
        else
          nb,
    ];
    await _repository.unarchiveNotebook(notebookId);
  }

  Future<void> toggleFavorite(String notebookId) async {
    state = [
      for (final nb in state)
        if (nb.id == notebookId)
          nb.copyWith(isFavorite: !nb.isFavorite, updatedAt: DateTime.now())
        else
          nb,
    ];
    await _repository.toggleFavorite(notebookId);
  }

  Future<void> deleteNotebook(String notebookId) async {
    state = state.where((nb) => nb.id != notebookId).toList();
    await _repository.deleteNotebook(notebookId);
  }

  void reorderNotebooks(int oldIndex, int newIndex) {
    final items = [...state];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = items;
  }
}

/// Global provider for notebooks list.
final notebooksProvider = NotifierProvider<NotebooksNotifier, List<Notebook>>(
  NotebooksNotifier.new,
);

/// Search query notifier.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Dashboard filter notifier (0: All, 1: Recent, 2: Favorites, 3: Archived).
class DashboardFilterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setFilter(int f) => state = f;
}

final dashboardFilterProvider = NotifierProvider<DashboardFilterNotifier, int>(
  DashboardFilterNotifier.new,
);

/// Grid/List view mode notifier.
class IsGridViewNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void setGridView(bool v) => state = v;
}

final isGridViewProvider = NotifierProvider<IsGridViewNotifier, bool>(
  IsGridViewNotifier.new,
);
