import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/note_model.dart';
import '../../../data/repositories/note_repository.dart';
import '../../authentication/data/auth_provider.dart';
import '../../storage/data/google_drive_provider.dart';
import '../../sync/data/sync_provider.dart';
import '../services/note_auto_save_coordinator.dart';

/// Filter categories for note lists.
enum NoteFilterType {
  all,
  pinned,
  favorites,
  recent,
  archive,
  trash,
  notebook,
  tag,
}

/// Active filter state for note navigation.
class NoteFilterState {
  final NoteFilterType type;
  final String? notebookId;
  final String? tag;

  const NoteFilterState({
    this.type = NoteFilterType.all,
    this.notebookId,
    this.tag,
  });

  NoteFilterState copyWith({
    NoteFilterType? type,
    String? notebookId,
    String? tag,
    bool clearNotebookId = false,
    bool clearTag = false,
  }) {
    return NoteFilterState(
      type: type ?? this.type,
      notebookId: clearNotebookId ? null : (notebookId ?? this.notebookId),
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }
}

/// Sorting order for note lists.
enum NoteSortOrder {
  modifiedDesc,
  createdDesc,
  titleAsc,
}

/// Notifier managing reactive list of active notes for current authenticated user.
class NotesNotifier extends Notifier<List<Note>> {
  StreamSubscription<List<Note>>? _notesSub;

  NoteRepository get _repo => ref.read(noteRepositoryProvider);

  @override
  List<Note> build() {
    final uid = ref.watch(authProvider.select((s) => s.user?.id ?? 'local_user'));

    _notesSub?.cancel();
    _notesSub = _repo
        .watchAllNotes(ownerId: uid, includeArchived: true, includeDeleted: true)
        .listen((notes) {
      state = notes;
    });

    ref.onDispose(() {
      _notesSub?.cancel();
    });

    // Initial load
    Future.microtask(() => loadNotes(uid));
    return const [];
  }

  Future<void> loadNotes(String uid) async {
    final notes = await _repo.getAllNotes(
      ownerId: uid,
      includeArchived: true,
      includeDeleted: true,
    );
    state = notes;
  }

  /// Creates a new note and selects it.
  Future<Note> createNote({
    required String notebookId,
    String title = 'Untitled Note',
    List<String> tags = const [],
  }) async {
    final uid = ref.read(authProvider).user?.id ?? 'local_user';
    final newNote = Note.createBlank(
      ownerId: uid,
      notebookId: notebookId,
      title: title,
      tags: tags,
    );

    await _repo.saveNote(newNote);
    state = [newNote, ...state];

    // Select the newly created note
    ref.read(selectedNoteProvider.notifier).selectNote(newNote);
    return newNote;
  }

  Future<void> saveNote(Note note) async {
    await _repo.saveNote(note);
    state = [
      for (final n in state)
        if (n.id == note.id) note else n,
    ];
  }

  Future<void> renameNote(String noteId, String newTitle) async {
    final existing = state.firstWhere(
      (n) => n.id == noteId,
      orElse: () => Note.createBlank(ownerId: 'unknown', notebookId: ''),
    );
    if (existing.id.isEmpty) return;

    final updated = existing.copyWith(
      title: newTitle.trim().isEmpty ? 'Untitled Note' : newTitle.trim(),
      updatedAt: DateTime.now(),
    );
    await saveNote(updated);

    // Update active note if currently selected
    final selected = ref.read(selectedNoteProvider);
    if (selected?.id == noteId) {
      ref.read(selectedNoteProvider.notifier).selectNote(updated);
    }
  }

  Future<void> deleteNote(String noteId) async {
    await _repo.deleteNote(noteId);
    state = [
      for (final n in state)
        if (n.id == noteId)
          n.copyWith(isDeleted: true, deletedAt: DateTime.now())
        else
          n,
    ];

    // If active note was deleted, clear selection
    if (ref.read(selectedNoteProvider)?.id == noteId) {
      ref.read(selectedNoteProvider.notifier).selectNote(null);
    }
  }

  Future<void> restoreNote(String noteId) async {
    await _repo.restoreNote(noteId);
    state = [
      for (final n in state)
        if (n.id == noteId)
          n.copyWith(isDeleted: false, clearDeletedAt: true)
        else
          n,
    ];
  }

  Future<void> permanentlyDeleteNote(String noteId) async {
    await _repo.permanentlyDeleteNote(noteId);
    state = state.where((n) => n.id != noteId).toList();
    if (ref.read(selectedNoteProvider)?.id == noteId) {
      ref.read(selectedNoteProvider.notifier).selectNote(null);
    }
  }

  Future<void> togglePin(String noteId) async {
    await _repo.togglePin(noteId);
    state = [
      for (final n in state)
        if (n.id == noteId) n.copyWith(isPinned: !n.isPinned) else n,
    ];
    final selected = ref.read(selectedNoteProvider);
    if (selected?.id == noteId) {
      ref
          .read(selectedNoteProvider.notifier)
          .selectNote(selected!.copyWith(isPinned: !selected.isPinned));
    }
  }

  Future<void> toggleFavorite(String noteId) async {
    await _repo.toggleFavorite(noteId);
    state = [
      for (final n in state)
        if (n.id == noteId) n.copyWith(isFavorite: !n.isFavorite) else n,
    ];
    final selected = ref.read(selectedNoteProvider);
    if (selected?.id == noteId) {
      ref
          .read(selectedNoteProvider.notifier)
          .selectNote(selected!.copyWith(isFavorite: !selected.isFavorite));
    }
  }

  Future<void> archiveNote(String noteId) async {
    await _repo.archiveNote(noteId);
    state = [
      for (final n in state)
        if (n.id == noteId) n.copyWith(isArchived: true) else n,
    ];
    final selected = ref.read(selectedNoteProvider);
    if (selected?.id == noteId) {
      ref.read(selectedNoteProvider.notifier).selectNote(null);
    }
  }

  Future<void> unarchiveNote(String noteId) async {
    await _repo.unarchiveNote(noteId);
    state = [
      for (final n in state)
        if (n.id == noteId) n.copyWith(isArchived: false) else n,
    ];
  }

  Future<void> moveNoteToNotebook(String noteId, String targetNotebookId) async {
    await _repo.moveNoteToNotebook(noteId, targetNotebookId);
    state = [
      for (final n in state)
        if (n.id == noteId) n.copyWith(notebookId: targetNotebookId) else n,
    ];
    final selected = ref.read(selectedNoteProvider);
    if (selected?.id == noteId) {
      ref
          .read(selectedNoteProvider.notifier)
          .selectNote(selected!.copyWith(notebookId: targetNotebookId));
    }
  }

  Future<Note?> duplicateNote(String noteId) async {
    final copy = await _repo.duplicateNote(noteId);
    if (copy != null) {
      state = [copy, ...state];
      ref.read(selectedNoteProvider.notifier).selectNote(copy);
    }
    return copy;
  }

  Future<void> addTag(String noteId, String tag) async {
    await _repo.addTag(noteId, tag);
    final trimmed = tag.trim();
    state = [
      for (final n in state)
        if (n.id == noteId && !n.tags.contains(trimmed))
          n.copyWith(tags: [...n.tags, trimmed])
        else
          n,
    ];
    final selected = ref.read(selectedNoteProvider);
    if (selected != null && selected.id == noteId && !selected.tags.contains(trimmed)) {
      ref
          .read(selectedNoteProvider.notifier)
          .selectNote(selected.copyWith(tags: [...selected.tags, trimmed]));
    }
  }

  Future<void> removeTag(String noteId, String tag) async {
    await _repo.removeTag(noteId, tag);
    state = [
      for (final n in state)
        if (n.id == noteId)
          n.copyWith(tags: n.tags.where((t) => t != tag).toList())
        else
          n,
    ];
    final selected = ref.read(selectedNoteProvider);
    if (selected != null && selected.id == noteId) {
      ref.read(selectedNoteProvider.notifier).selectNote(
            selected.copyWith(tags: selected.tags.where((t) => t != tag).toList()),
          );
    }
  }

  Future<void> emptyTrash() async {
    final uid = ref.read(authProvider).user?.id ?? 'local_user';
    await _repo.emptyTrash(ownerId: uid);
    state = state.where((n) => !n.isDeleted).toList();
  }

  Future<void> bulkDelete(Iterable<String> noteIds) async {
    final idSet = noteIds.toSet();
    if (idSet.isEmpty) return;

    await _repo.bulkDelete(idSet);
    final now = DateTime.now();
    state = [
      for (final n in state)
        if (idSet.contains(n.id))
          n.copyWith(isDeleted: true, deletedAt: now)
        else
          n,
    ];

    if (idSet.contains(ref.read(selectedNoteProvider)?.id)) {
      ref.read(selectedNoteProvider.notifier).selectNote(null);
    }

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .deleteNotesBatch(currentUserId, idSet.toList());
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notes_bulk_deleted');
  }

  Future<void> bulkRestore(Iterable<String> noteIds) async {
    final idSet = noteIds.toSet();
    if (idSet.isEmpty) return;

    await _repo.bulkRestore(idSet);
    state = [
      for (final n in state)
        if (idSet.contains(n.id))
          n.copyWith(isDeleted: false, clearDeletedAt: true)
        else
          n,
    ];

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final restored = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotesBatch(currentUserId, restored);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notes_bulk_restored');
  }

  Future<void> bulkPermanentDelete(Iterable<String> noteIds) async {
    final idSet = noteIds.toSet();
    if (idSet.isEmpty) return;

    await _repo.bulkPermanentDelete(idSet);
    state = state.where((n) => !idSet.contains(n.id)).toList();

    if (idSet.contains(ref.read(selectedNoteProvider)?.id)) {
      ref.read(selectedNoteProvider.notifier).selectNote(null);
    }

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .permanentlyDeleteNotesBatch(currentUserId, idSet.toList());
      } catch (_) {}
    }
  }

  Future<void> bulkTogglePin(Iterable<String> noteIds, bool pin) async {
    final idSet = noteIds.toSet();
    if (idSet.isEmpty) return;

    await _repo.bulkTogglePin(idSet, pin);
    state = [
      for (final n in state)
        if (idSet.contains(n.id)) n.copyWith(isPinned: pin) else n,
    ];

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updated = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotesBatch(currentUserId, updated);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notes_bulk_pinned');
  }

  Future<void> bulkToggleFavorite(Iterable<String> noteIds, bool favorite) async {
    final idSet = noteIds.toSet();
    if (idSet.isEmpty) return;

    await _repo.bulkToggleFavorite(idSet, favorite);
    state = [
      for (final n in state)
        if (idSet.contains(n.id)) n.copyWith(isFavorite: favorite) else n,
    ];

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updated = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotesBatch(currentUserId, updated);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notes_bulk_favorited');
  }

  Future<void> bulkArchive(Iterable<String> noteIds, bool archive) async {
    final idSet = noteIds.toSet();
    if (idSet.isEmpty) return;

    await _repo.bulkArchive(idSet, archive);
    state = [
      for (final n in state)
        if (idSet.contains(n.id)) n.copyWith(isArchived: archive) else n,
    ];

    if (archive && idSet.contains(ref.read(selectedNoteProvider)?.id)) {
      ref.read(selectedNoteProvider.notifier).selectNote(null);
    }

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updated = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotesBatch(currentUserId, updated);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notes_bulk_archived');
  }

  Future<void> bulkMoveToNotebook(Iterable<String> noteIds, String targetNotebookId) async {
    final idSet = noteIds.toSet();
    if (idSet.isEmpty) return;

    await _repo.bulkMoveToNotebook(idSet, targetNotebookId);
    state = [
      for (final n in state)
        if (idSet.contains(n.id)) n.copyWith(notebookId: targetNotebookId) else n,
    ];

    final selected = ref.read(selectedNoteProvider);
    if (selected != null && idSet.contains(selected.id)) {
      ref.read(selectedNoteProvider.notifier).selectNote(
            selected.copyWith(notebookId: targetNotebookId),
          );
    }

    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    if (currentUserId != 'local_user') {
      final updated = state.where((n) => idSet.contains(n.id)).toList();
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushNotesBatch(currentUserId, updated);
      } catch (_) {}
    }
    _triggerDriveAutoSync(reason: 'notes_bulk_moved');
  }

  Future<void> bulkAddTag(Iterable<String> noteIds, String tag) async {
    final idSet = noteIds.toSet();
    final clean = tag.trim();
    if (idSet.isEmpty || clean.isEmpty) return;

    await _repo.bulkAddTag(idSet, clean);
    state = [
      for (final n in state)
        if (idSet.contains(n.id) && !n.tags.contains(clean))
          n.copyWith(tags: [...n.tags, clean])
        else
          n,
    ];
  }

  Future<void> bulkRemoveTag(Iterable<String> noteIds, String tag) async {
    final idSet = noteIds.toSet();
    final clean = tag.trim();
    if (idSet.isEmpty || clean.isEmpty) return;

    await _repo.bulkRemoveTag(idSet, clean);
    state = [
      for (final n in state)
        if (idSet.contains(n.id))
          n.copyWith(tags: n.tags.where((t) => t != clean).toList())
        else
          n,
    ];
  }

  void _triggerDriveAutoSync({String reason = 'note_bulk_change'}) {
    try {
      ref.read(googleDriveProvider.notifier).scheduleAutoSync(
            delay: const Duration(seconds: 3),
            reason: reason,
          );
    } catch (_) {}
  }
}

/// Global provider for all notes.
final notesProvider = NotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

/// Notifier managing active note selection for the editor pane.
class SelectedNoteNotifier extends Notifier<Note?> {
  @override
  Note? build() => null;

  void selectNote(Note? note) {
    if (state?.id != note?.id) {
      // Flush any pending auto-save before switching notes
      ref.read(noteAutoSaveCoordinatorProvider.notifier).flushPendingSave(
            noteId: state?.id,
          );
    }
    state = note;
  }

  void updateSelectedNote(Note note) {
    if (state?.id == note.id) {
      state = note;
    }
  }
}

final selectedNoteProvider =
    NotifierProvider<SelectedNoteNotifier, Note?>(SelectedNoteNotifier.new);

/// Notifier managing active filter / folder / notebook selection.
class NoteFilterNotifier extends Notifier<NoteFilterState> {
  @override
  NoteFilterState build() => const NoteFilterState(type: NoteFilterType.all);

  void setFilter(NoteFilterType type, {String? notebookId, String? tag}) {
    state = NoteFilterState(type: type, notebookId: notebookId, tag: tag);
  }

  void selectNotebook(String notebookId) {
    state = NoteFilterState(
      type: NoteFilterType.notebook,
      notebookId: notebookId,
    );
  }

  void selectTag(String tag) {
    state = NoteFilterState(
      type: NoteFilterType.tag,
      tag: tag,
    );
  }
}

final noteFilterProvider =
    NotifierProvider<NoteFilterNotifier, NoteFilterState>(
  NoteFilterNotifier.new,
);

/// Notifier managing local instant search query.
class NoteSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final noteSearchProvider =
    NotifierProvider<NoteSearchNotifier, String>(NoteSearchNotifier.new);

/// Notifier managing note sorting order.
class NoteSortOrderNotifier extends Notifier<NoteSortOrder> {
  @override
  NoteSortOrder build() => NoteSortOrder.modifiedDesc;

  void setSortOrder(NoteSortOrder order) => state = order;
}

final noteSortOrderProvider =
    NotifierProvider<NoteSortOrderNotifier, NoteSortOrder>(
  NoteSortOrderNotifier.new,
);

/// Computed provider returning notes filtered and sorted according to current settings.
final filteredNotesProvider = Provider<List<Note>>((ref) {
  final allNotes = ref.watch(notesProvider);
  final filter = ref.watch(noteFilterProvider);
  final query = ref.watch(noteSearchProvider).trim().toLowerCase();
  final sortOrder = ref.watch(noteSortOrderProvider);

  // 1. Filter by category
  List<Note> list = switch (filter.type) {
    NoteFilterType.all =>
      allNotes.where((n) => !n.isDeleted && !n.isArchived).toList(),
    NoteFilterType.pinned =>
      allNotes.where((n) => !n.isDeleted && !n.isArchived && n.isPinned).toList(),
    NoteFilterType.favorites => allNotes
        .where((n) => !n.isDeleted && !n.isArchived && n.isFavorite)
        .toList(),
    NoteFilterType.recent =>
      allNotes.where((n) => !n.isDeleted && !n.isArchived).toList(),
    NoteFilterType.archive =>
      allNotes.where((n) => !n.isDeleted && n.isArchived).toList(),
    NoteFilterType.trash => allNotes.where((n) => n.isDeleted).toList(),
    NoteFilterType.notebook => allNotes
        .where((n) =>
            !n.isDeleted &&
            !n.isArchived &&
            n.notebookId == filter.notebookId)
        .toList(),
    NoteFilterType.tag => allNotes
        .where((n) =>
            !n.isDeleted &&
            !n.isArchived &&
            filter.tag != null &&
            n.tags.contains(filter.tag))
        .toList(),
  };

  // 2. Filter by search query (instant local Dart search across titles, plainText, preview, tags)
  if (query.isNotEmpty) {
    list = list.where((n) {
      final inTitle = n.title.toLowerCase().contains(query);
      final inText = n.plainText.toLowerCase().contains(query);
      final inPreview = n.preview.toLowerCase().contains(query);
      final inTags = n.tags.any((t) => t.toLowerCase().contains(query));
      return inTitle || inText || inPreview || inTags;
    }).toList();
  }

  // 3. Sort notes
  switch (sortOrder) {
    case NoteSortOrder.modifiedDesc:
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      break;
    case NoteSortOrder.createdDesc:
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      break;
    case NoteSortOrder.titleAsc:
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      break;
  }

  return list;
});

/// Computed provider for tags with their note counts.
final allTagsWithCountProvider = Provider<Map<String, int>>((ref) {
  final notes = ref.watch(notesProvider).where((n) => !n.isDeleted && !n.isArchived);
  final map = <String, int>{};
  for (final note in notes) {
    for (final tag in note.tags) {
      map[tag] = (map[tag] ?? 0) + 1;
    }
  }
  return map;
});

/// Computed provider for notebooks with their note counts.
final notebooksNoteCountProvider = Provider<Map<String, int>>((ref) {
  final notes = ref.watch(notesProvider).where((n) => !n.isDeleted && !n.isArchived);
  final map = <String, int>{};
  for (final note in notes) {
    map[note.notebookId] = (map[note.notebookId] ?? 0) + 1;
  }
  return map;
});
