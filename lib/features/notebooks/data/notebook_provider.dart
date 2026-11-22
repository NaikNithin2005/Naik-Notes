import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/diagnostics/performance_monitor.dart';
import '../../../data/local/database_provider.dart';
import '../../../data/models/notebook_model.dart';
import '../../../data/models/sync_operation_model.dart';
import '../../../data/repositories/notebook_repository.dart';
import '../../../services/history/note_history_service.dart';
import '../../sync/data/sync_provider.dart';

import '../../authentication/data/auth_provider.dart';
import '../../storage/data/google_drive_provider.dart';
import 'welcome_notebook_service.dart';

/// State notifier managing the reactive list of notebooks, backed by Drift SQLite.
class NotebooksNotifier extends Notifier<List<Notebook>> {
  final _uuid = const Uuid();
  NotebookRepository get _repository => ref.read(notebookRepositoryProvider);

  @override
  List<Notebook> build() {
    final userId = ref.watch(authProvider.select((s) => s.user?.id));

    if (userId != null) {
      Future.microtask(() {
        if (ref.mounted) {
          loadForUser(userId);
        }
      });
    } else {
      state = const [];
    }
    return const [];
  }

  Future<void> loadForUser(String? userId) async {
    if (userId == null || !ref.mounted) {
      if (ref.mounted) state = const [];
      return;
    }
    await AppPerformanceMonitor.trace('notebook_load_metadata', () async {
      if (!ref.mounted) return;
      var dbNotebooks = await _repository.getAllNotebooks(
        ownerId: userId,
        includeArchived: true,
      );
      if (!ref.mounted) return;

      // Universal deduplication safeguard: consolidate historical duplicates and clean titles
      String cleanTitleRecursively(String title) {
        final copyPattern = RegExp(
          r'\s*\((?:Cloud Copy|Conflict Copy|Copy)(?:\s+\d+)?\)$',
          caseSensitive: false,
        );
        String clean = title.trim();
        while (copyPattern.hasMatch(clean)) {
          clean = clean.replaceAll(copyPattern, '').trim();
        }
        return clean.isEmpty ? 'Untitled Notebook' : clean;
      }

      // Group all active (non-deleted) notebooks by their normalized base title
      final groups = <String, List<Notebook>>{};
      for (final nb in dbNotebooks) {
        if (nb.deletedAt == null) {
          final base = cleanTitleRecursively(nb.title).toLowerCase();
          groups.putIfAbsent(base, () => []).add(nb);
        }
      }

      bool hadDuplicates = false;
      final copyPattern = RegExp(
        r'\((?:Cloud Copy|Conflict Copy|Copy)',
        caseSensitive: false,
      );

      for (final entry in groups.entries) {
        final list = entry.value;

        // Sort candidates to select the BEST canonical notebook:
        // 1. Highest page count (preserves content with zero data loss)
        // 2. Clean title preferred over copy suffix
        // 3. Highest revision
        // 4. Newest updatedAt
        list.sort((a, b) {
          if (a.pageCount != b.pageCount) return b.pageCount.compareTo(a.pageCount);

          final aIsCopy = copyPattern.hasMatch(a.title);
          final bIsCopy = copyPattern.hasMatch(b.title);
          if (!aIsCopy && bIsCopy) return -1;
          if (aIsCopy && !bIsCopy) return 1;

          if (a.revision != b.revision) return b.revision.compareTo(a.revision);
          return b.updatedAt.compareTo(a.updatedAt);
        });

        final canonical = list.first;
        final cleanTitle = cleanTitleRecursively(canonical.title);

        // A. If canonical notebook title still has copy suffixes, clean it
        if (canonical.title != cleanTitle) {
          final cleaned = canonical.copyWith(
            title: cleanTitle,
            updatedAt: DateTime.now(),
            syncStatus: 'pending',
          );
          await _repository.saveNotebook(cleaned);
          if (userId != 'local_user') {
            try {
              await ref
                  .read(firebaseSyncServiceProvider)
                  .pushNotebook(userId, cleaned);
            } catch (_) {}
          }
          hadDuplicates = true;
        }

        // B. Permanently delete all other redundant copies in this group
        if (list.length > 1) {
          for (int i = 1; i < list.length; i++) {
            final duplicate = list[i];
            await _repository.permanentlyDeleteNotebook(duplicate.id, ownerId: userId);
            if (userId != 'local_user') {
              try {
                await ref
                    .read(firebaseSyncServiceProvider)
                    .permanentlyDeleteNotebook(userId, duplicate.id);
              } catch (_) {}
            }
            _triggerDriveAutoSync(reason: 'duplicate_cleaned');
            hadDuplicates = true;
          }
        }
      }

      if (hadDuplicates) {
        dbNotebooks = await _repository.getAllNotebooks(
          ownerId: userId,
          includeArchived: true,
        );
        if (!ref.mounted) return;
      }

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
    try {
      await ref.read(pageRepositoryProvider).ensurePagesExist(
        newNotebook.id,
        templateId: paperTemplateId,
        pageSize: pageSize,
        orientation: orientation,
        count: 1,
      );
    } catch (_) {}
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
    try {
      final userEmail = ref.read(authProvider).user?.email ?? 'local_user';
      await ref.read(noteHistoryServiceProvider).recordActivity(
        noteId: newNotebook.id,
        noteTitle: newNotebook.title,
        action: NoteActionType.created,
        userEmail: userEmail,
        details: 'Created notebook with ${newNotebook.pageCount} page',
      );
    } catch (_) {}
    _triggerDriveAutoSync(reason: 'notebook_added');
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
    try {
      final userEmail = ref.read(authProvider).user?.email ?? 'local_user';
      await ref.read(noteHistoryServiceProvider).recordActivity(
        noteId: id,
        noteTitle: newTitle,
        action: NoteActionType.updated,
        userEmail: userEmail,
        details: 'Renamed notebook to "$newTitle"',
      );
    } catch (_) {}
    _triggerDriveAutoSync(reason: 'notebook_renamed');
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
      try {
        final userEmail = ref.read(authProvider).user?.email ?? 'local_user';
        await ref.read(noteHistoryServiceProvider).recordActivity(
          noteId: duplicated.id,
          noteTitle: duplicated.title,
          action: NoteActionType.created,
          userEmail: userEmail,
          details: 'Duplicated from notebook',
        );
      } catch (_) {}
      _triggerDriveAutoSync(reason: 'notebook_duplicated');
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
      try {
        final userEmail = ref.read(authProvider).user?.email ?? 'local_user';
        await ref.read(noteHistoryServiceProvider).recordActivity(
          noteId: notebookId,
          noteTitle: updatedNb!.title,
          action: NoteActionType.updated,
          userEmail: userEmail,
          details: 'Updated notebook cover',
        );
      } catch (_) {}
      _triggerDriveAutoSync(reason: 'cover_updated');
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
    try {
      final userEmail = ref.read(authProvider).user?.email ?? 'local_user';
      await ref.read(noteHistoryServiceProvider).recordActivity(
        noteId: notebookId,
        noteTitle: toDelete.title,
        action: NoteActionType.deleted,
        userEmail: userEmail,
        details: 'Deleted notebook',
      );
    } catch (_) {}
    _triggerDriveAutoSync(
      delay: const Duration(seconds: 1),
      reason: 'notebook_deleted',
    );
  }

  Future<void> bulkDelete(Iterable<String> notebookIds) async {
    final idSet = notebookIds.toSet();
    if (idSet.isEmpty) return;

    state = state.where((nb) => !idSet.contains(nb.id)).toList();
    await _repository.bulkDelete(idSet);

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .deleteNotebooksBatch(currentUserId, idSet.toList());
      } catch (_) {}
    }
    _triggerDriveAutoSync(
      delay: const Duration(seconds: 1),
      reason: 'notebooks_bulk_deleted',
    );
  }

  Future<void> restoreNotebook(String id) async {
    await bulkRestore([id]);
  }

  Future<void> permanentlyDeleteNotebook(String id) async {
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    await _repository.permanentlyDeleteNotebook(id, ownerId: currentUserId);
    state = state.where((nb) => nb.id != id).toList();
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .permanentlyDeleteNotebook(currentUserId, id);
      } catch (_) {}
    }
    _triggerDriveAutoSync(
      delay: const Duration(seconds: 1),
      reason: 'notebook_permanently_deleted',
    );
  }

  Future<void> bulkPermanentDelete(Iterable<String> notebookIds) async {
    final idSet = notebookIds.toSet();
    if (idSet.isEmpty) return;

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    await _repository.bulkPermanentDelete(idSet, ownerId: currentUserId);
    state = state.where((nb) => !idSet.contains(nb.id)).toList();

    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .permanentlyDeleteNotebooksBatch(currentUserId, idSet.toList());
      } catch (_) {}
    }
    _triggerDriveAutoSync(
      delay: const Duration(seconds: 1),
      reason: 'notebooks_bulk_permanently_deleted',
    );
  }

  Future<void> emptyTrash() async {
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final deleted = await _repository.getDeletedNotebooks(ownerId: currentUserId);
    final ids = deleted.map((n) => n.id).toList();
    if (ids.isNotEmpty) {
      await bulkPermanentDelete(ids);
    }
  }

  Future<void> cleanupDuplicates() async {
    final user = ref.read(authProvider).user;
    await loadForUser(user?.id);
  }

  Future<void> bulkRestore(Iterable<String> notebookIds) async {
    final idSet = notebookIds.toSet();
    if (idSet.isEmpty) return;

    await _repository.bulkRestore(idSet);
    final user = ref.read(authProvider).user;
    await loadForUser(user?.id);
    _triggerDriveAutoSync(reason: 'notebooks_bulk_restored');
  }

  Future<void> bulkArchive(Iterable<String> notebookIds, bool archive) async {
    final idSet = notebookIds.toSet();
    if (idSet.isEmpty) return;

    state = [
      for (final nb in state)
        if (idSet.contains(nb.id))
          nb.copyWith(isArchived: archive, updatedAt: DateTime.now())
        else
          nb,
    ];
    await _repository.bulkArchive(idSet, archive);

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updatedList = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebooksBatch(currentUserId, updatedList);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notebooks_bulk_archived');
  }

  Future<void> bulkFavorite(Iterable<String> notebookIds, bool favorite) async {
    final idSet = notebookIds.toSet();
    if (idSet.isEmpty) return;

    state = [
      for (final nb in state)
        if (idSet.contains(nb.id))
          nb.copyWith(isFavorite: favorite, updatedAt: DateTime.now())
        else
          nb,
    ];
    await _repository.bulkToggleFavorite(idSet, favorite);

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updatedList = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebooksBatch(currentUserId, updatedList);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notebooks_bulk_favorited');
  }

  Future<void> bulkMoveToFolder(Iterable<String> notebookIds, String? folderId) async {
    final idSet = notebookIds.toSet();
    if (idSet.isEmpty) return;

    state = [
      for (final nb in state)
        if (idSet.contains(nb.id))
          nb.copyWith(
            folderId: folderId,
            clearFolderId: folderId == null,
            updatedAt: DateTime.now(),
          )
        else
          nb,
    ];
    await _repository.bulkMoveToFolder(idSet, folderId);

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updatedList = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebooksBatch(currentUserId, updatedList);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notebooks_bulk_moved');
  }

  Future<void> bulkUpdateCoverColor(Iterable<String> notebookIds, String colorHex) async {
    final idSet = notebookIds.toSet();
    if (idSet.isEmpty) return;

    state = [
      for (final nb in state)
        if (idSet.contains(nb.id))
          nb.copyWith(
            coverColorHex: colorHex,
            updatedAt: DateTime.now(),
            revision: nb.revision + 1,
          )
        else
          nb,
    ];
    await _repository.bulkUpdateCoverColor(idSet, colorHex);

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updatedList = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotebooksBatch(currentUserId, updatedList);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notebooks_bulk_cover_color');
  }

  void _triggerDriveAutoSync({
    Duration delay = const Duration(seconds: 3),
    String reason = 'notebook_change',
  }) {
    try {
      ref.read(googleDriveProvider.notifier).scheduleAutoSync(
        delay: delay,
        reason: reason,
      );
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

/// Reactive stream provider for notebooks in Trash.
final trashNotebooksProvider = StreamProvider<List<Notebook>>((ref) {
  final userId = ref.watch(authProvider.select((s) => s.user?.id));
  final repo = ref.watch(notebookRepositoryProvider);
  return repo.watchDeletedNotebooks(ownerId: userId);
});
