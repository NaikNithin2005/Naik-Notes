import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/diagnostics/performance_monitor.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/notebook_model.dart';
import '../../../data/models/sync_operation_model.dart';
import '../../../data/repositories/notebook_repository.dart';
import '../../sync/data/sync_provider.dart';

import '../../authentication/data/auth_provider.dart';
import 'welcome_notebook_service.dart';

/// State notifier managing the reactive list of notebooks, backed by Drift SQLite.
class NotebooksNotifier extends Notifier<List<Notebook>> {
  final _uuid = const Uuid();
  NotebookRepository get _repository => ref.read(notebookRepositoryProvider);

  @override
  List<Notebook> build() {
    ref.watch(notebookRepositoryProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user != null) {
      Future.microtask(() => loadForUser(user.id));
    } else {
      state = const [];
    }
    return const [];
  }

  Future<void> loadForUser(String? userId) async {
    if (userId == null) {
      if (ref.mounted) state = const [];
      return;
    }
    await AppPerformanceMonitor.trace('notebook_load_metadata', () async {
      var dbNotebooks = await _repository.getAllNotebooks(
        ownerId: userId,
        includeArchived: true,
      );
      if (!ref.mounted) return;
      if (dbNotebooks.isEmpty) {
        try {
          await ref
              .read(welcomeNotebookServiceProvider)
              .ensureWelcomeNotebookCreated(userId);
          if (!ref.mounted) return;
          dbNotebooks = await _repository.getAllNotebooks(
            ownerId: userId,
            includeArchived: true,
          );
        } catch (_) {}
      }
      if (ref.mounted) {
        state = dbNotebooks;
      }
    });
  }

  Future<void> loadFromDatabase() async {
    final user = ref.read(authProvider).user;
    await loadForUser(user?.id);
  }

  Future<void> loadNotebooks() => loadFromDatabase();

  Future<Notebook> addNotebook({
    required String title,
    String description = '',
    String? folderId,
    required String coverId,
    required String coverColorHex,
    String? coverImageUrl,
    required String paperTemplateId,
    String orientation = 'portrait',
    String pageSize = 'A4',
  }) async {
    final now = DateTime.now();
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final newNotebook = Notebook(
      id: _uuid.v4(),
      ownerId: currentUserId,
      folderId: folderId,
      title: title,
      description: description,
      coverId: coverId,
      coverColorHex: coverColorHex,
      coverImageUrl: coverImageUrl,
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
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebook(currentUserId, newNotebook);
      } catch (e) {
        // Logged gracefully, offline sync queue will retry
      }
    }
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueNotebookMutation(newNotebook, SyncOperationType.insert);
    } catch (_) {}
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
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final updated = state.firstWhere((n) => n.id == id);
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebook(currentUserId, updated);
      } catch (_) {}
    }
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueNotebookMutation(updated, SyncOperationType.update);
    } catch (_) {}
  }

  Future<Notebook?> duplicateNotebook(String id) async {
    final duplicated = await _repository.duplicateNotebook(id);
    if (duplicated != null) {
      state = [duplicated, ...state];
      final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
      if (currentUserId != 'local_user') {
        try {
          await ref
              .read(firebaseSyncServiceProvider)
              .pushNotebook(currentUserId, duplicated);
        } catch (_) {}
      }
      try {
        await ref
            .read(syncServiceProvider)
            .enqueueNotebookMutation(duplicated, SyncOperationType.insert);
      } catch (_) {}
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
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final nb = state.firstWhere((n) => n.id == notebookId);
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebook(currentUserId, nb);
      } catch (_) {}
    }
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueNotebookMutation(nb, SyncOperationType.update);
    } catch (_) {}
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
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final nb = state.firstWhere((n) => n.id == notebookId);
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebook(currentUserId, nb);
      } catch (_) {}
    }
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueNotebookMutation(nb, SyncOperationType.update);
    } catch (_) {}
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
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final nb = state.firstWhere((n) => n.id == notebookId);
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebook(currentUserId, nb);
      } catch (_) {}
    }
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueNotebookMutation(nb, SyncOperationType.update);
    } catch (_) {}
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
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final nb = state.firstWhere((n) => n.id == notebookId);
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebook(currentUserId, nb);
      } catch (_) {}
    }
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueNotebookMutation(nb, SyncOperationType.update);
    } catch (_) {}
  }

  Future<void> updateCover(
    String notebookId, {
    String? coverId,
    String? coverColorHex,
    String? coverImageUrl,
  }) async {
    Notebook? updatedNb;
    state = [
      for (final nb in state)
        if (nb.id == notebookId) ...[
          () {
            final updated = nb.copyWith(
              coverId: coverId ?? nb.coverId,
              coverColorHex: coverColorHex ?? nb.coverColorHex,
              coverImageUrl: coverImageUrl ?? nb.coverImageUrl,
              updatedAt: DateTime.now(),
              revision: nb.revision + 1,
            );
            updatedNb = updated;
            return updated;
          }(),
        ] else
          nb,
    ];
    if (updatedNb != null) {
      await _repository.saveNotebook(updatedNb!);
      final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
      if (currentUserId != 'local_user') {
        try {
          await ref
              .read(firebaseSyncServiceProvider)
              .pushNotebook(currentUserId, updatedNb!);
        } catch (_) {}
      }
      try {
        await ref
            .read(syncServiceProvider)
            .enqueueNotebookMutation(updatedNb!, SyncOperationType.update);
      } catch (_) {}
    }
  }

  Future<void> deleteNotebook(String notebookId) async {
    final toDelete = state.firstWhere(
      (nb) => nb.id == notebookId,
      orElse: () => Notebook(
        id: notebookId,
        ownerId: 'local_user',
        title: 'Deleted Notebook',
        coverId: '',
        coverColorHex: '',
        paperTemplateId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    state = state.where((nb) => nb.id != notebookId).toList();
    await _repository.deleteNotebook(notebookId);
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .deleteNotebook(currentUserId, notebookId);
      } catch (_) {}
    }
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueNotebookMutation(toDelete, SyncOperationType.delete);
    } catch (_) {}
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
