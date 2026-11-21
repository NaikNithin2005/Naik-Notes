import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/auth_provider.dart';
import 'note_provider.dart';

/// State representation for gallery-style note multi-selection.
class NoteSelectionState {
  final Set<String> selectedNoteIds;
  final bool isSelectionMode;

  const NoteSelectionState({
    this.selectedNoteIds = const {},
    this.isSelectionMode = false,
  });

  int get count => selectedNoteIds.length;
  int get selectedCount => count;
  bool isSelected(String id) => selectedNoteIds.contains(id);

  NoteSelectionState copyWith({
    Set<String>? selectedNoteIds,
    bool? isSelectionMode,
  }) {
    return NoteSelectionState(
      selectedNoteIds: selectedNoteIds ?? this.selectedNoteIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }
}

/// Notifier managing multi-selection lifecycle for notes.
class NoteSelectionNotifier extends Notifier<NoteSelectionState> {
  String? _lastSelectedId;

  @override
  NoteSelectionState build() {
    // Reset selection when auth changes
    ref.watch(authProvider.select((s) => s.user?.id));
    // Reset selection when note filter or active notebook changes
    ref.watch(noteFilterProvider);
    _lastSelectedId = null;
    return const NoteSelectionState();
  }

  /// Activates selection mode, optionally selecting an initial note.
  void enterSelectionMode([String? initialId]) {
    final initialSet = initialId != null ? {initialId} : <String>{};
    _lastSelectedId = initialId;
    state = NoteSelectionState(
      selectedNoteIds: initialSet,
      isSelectionMode: true,
    );
  }

  /// Exits selection mode and clears all selections.
  void exitSelectionMode() {
    _lastSelectedId = null;
    state = const NoteSelectionState();
  }

  /// Toggles selection of a note. Automatically exits selection mode if empty.
  void toggle(String id) {
    final current = Set<String>.from(state.selectedNoteIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
      _lastSelectedId = id;
    }

    if (current.isEmpty) {
      exitSelectionMode();
    } else {
      state = state.copyWith(
        selectedNoteIds: current,
        isSelectionMode: true,
      );
    }
  }

  /// Selects an individual note by ID.
  void select(String id) {
    final current = Set<String>.from(state.selectedNoteIds)..add(id);
    _lastSelectedId = id;
    state = state.copyWith(
      selectedNoteIds: current,
      isSelectionMode: true,
    );
  }

  /// Deselects an individual note by ID.
  void deselect(String id) {
    final current = Set<String>.from(state.selectedNoteIds)..remove(id);
    if (current.isEmpty) {
      exitSelectionMode();
    } else {
      state = state.copyWith(selectedNoteIds: current);
    }
  }

  /// Selects all available notes from the provided visible IDs.
  void selectAll(Iterable<String> allIds) {
    final set = allIds.toSet();
    if (set.isNotEmpty) {
      state = NoteSelectionState(
        selectedNoteIds: set,
        isSelectionMode: true,
      );
    }
  }

  /// Deselects all notes and closes selection mode.
  void deselectAll() {
    exitSelectionMode();
  }

  /// Range selection (Shift+Click) between last selected note and target note.
  void rangeSelect(String targetId, List<String> orderedIds) {
    if (_lastSelectedId == null ||
        !orderedIds.contains(_lastSelectedId) ||
        !orderedIds.contains(targetId)) {
      toggle(targetId);
      return;
    }

    final fromIndex = orderedIds.indexOf(_lastSelectedId!);
    final toIndex = orderedIds.indexOf(targetId);
    final start = fromIndex < toIndex ? fromIndex : toIndex;
    final end = fromIndex < toIndex ? toIndex : fromIndex;

    final current = Set<String>.from(state.selectedNoteIds);
    for (int i = start; i <= end; i++) {
      current.add(orderedIds[i]);
    }
    _lastSelectedId = targetId;

    state = state.copyWith(
      selectedNoteIds: current,
      isSelectionMode: true,
    );
  }

  /// Clears selection.
  void clear() => exitSelectionMode();
}

/// Global provider for note selection state.
final noteSelectionProvider =
    NotifierProvider<NoteSelectionNotifier, NoteSelectionState>(
  NoteSelectionNotifier.new,
);

