import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../authentication/data/auth_provider.dart';

/// State representation for gallery-style notebook multi-selection.
class NotebookSelectionState {
  final Set<String> selectedNotebookIds;
  final bool isSelectionMode;

  const NotebookSelectionState({
    this.selectedNotebookIds = const {},
    this.isSelectionMode = false,
  });

  int get count => selectedNotebookIds.length;
  int get selectedCount => count;
  bool isSelected(String id) => selectedNotebookIds.contains(id);

  NotebookSelectionState copyWith({
    Set<String>? selectedNotebookIds,
    bool? isSelectionMode,
  }) {
    return NotebookSelectionState(
      selectedNotebookIds: selectedNotebookIds ?? this.selectedNotebookIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }
}

/// Notifier managing multi-selection lifecycle for notebooks.
class NotebookSelectionNotifier extends Notifier<NotebookSelectionState> {
  String? _lastSelectedId;

  @override
  NotebookSelectionState build() {
    // Reset selection when user logs in or out
    ref.watch(authProvider.select((s) => s.user?.id));
    _lastSelectedId = null;
    return const NotebookSelectionState();
  }

  /// Activates selection mode, optionally selecting an initial notebook.
  void enterSelectionMode([String? initialId]) {
    final initialSet = initialId != null ? {initialId} : <String>{};
    _lastSelectedId = initialId;
    state = NotebookSelectionState(
      selectedNotebookIds: initialSet,
      isSelectionMode: true,
    );
  }

  /// Exits selection mode and clears all selections.
  void exitSelectionMode() {
    _lastSelectedId = null;
    state = const NotebookSelectionState();
  }

  /// Toggles selection of an item. Automatically exits selection mode if empty.
  void toggle(String id) {
    final current = Set<String>.from(state.selectedNotebookIds);
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
        selectedNotebookIds: current,
        isSelectionMode: true,
      );
    }
  }

  /// Selects an individual notebook by ID.
  void select(String id) {
    final current = Set<String>.from(state.selectedNotebookIds)..add(id);
    _lastSelectedId = id;
    state = state.copyWith(
      selectedNotebookIds: current,
      isSelectionMode: true,
    );
  }

  /// Deselects an individual notebook by ID.
  void deselect(String id) {
    final current = Set<String>.from(state.selectedNotebookIds)..remove(id);
    if (current.isEmpty) {
      exitSelectionMode();
    } else {
      state = state.copyWith(selectedNotebookIds: current);
    }
  }

  /// Selects all available notebooks from the provided visible IDs.
  void selectAll(Iterable<String> allIds) {
    final set = allIds.toSet();
    if (set.isNotEmpty) {
      state = NotebookSelectionState(
        selectedNotebookIds: set,
        isSelectionMode: true,
      );
    }
  }

  /// Deselects all notebooks and closes selection mode.
  void deselectAll() {
    exitSelectionMode();
  }

  /// Range selection (Shift+Click) between last selected item and target item.
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

    final current = Set<String>.from(state.selectedNotebookIds);
    for (int i = start; i <= end; i++) {
      current.add(orderedIds[i]);
    }
    _lastSelectedId = targetId;

    state = state.copyWith(
      selectedNotebookIds: current,
      isSelectionMode: true,
    );
  }

  /// Clears selection.
  void clear() => exitSelectionMode();
}

/// Global provider for notebook selection state.
final notebookSelectionProvider =
    NotifierProvider<NotebookSelectionNotifier, NotebookSelectionState>(
  NotebookSelectionNotifier.new,
);

