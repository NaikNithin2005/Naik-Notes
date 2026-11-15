import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/features/audio/data/audio_provider.dart';
import 'package:naik_notes/services/recognition/handwriting_recognition_provider.dart';
import 'package:uuid/uuid.dart';

/// Available standard color palette for the digital pens.
class PenColors {
  static const inkSlate = Color(0xFF1E293B);
  static const classicBlack = Color(0xFF0F172A);
  static const royalBlue = Color(0xFF1D4ED8);
  static const burgundyRed = Color(0xFFBE123C);
  static const emeraldGreen = Color(0xFF047857);
  static const deepPurple = Color(0xFF6D28D9);
  static const vintageSepia = Color(0xFF78350F);
  static const highlighterYellow = Color(0xFFFFEB3B);
  static const highlighterGreen = Color(0xFF69F0AE);
  static const highlighterPink = Color(0xFFFF80AB);
  static const highlighterBlue = Color(0xFF80D8FF);

  static const List<Color> penPalette = [
    inkSlate,
    classicBlack,
    royalBlue,
    burgundyRed,
    emeraldGreen,
    deepPurple,
    vintageSepia,
  ];

  static const List<Color> highlighterPalette = [
    highlighterYellow,
    highlighterGreen,
    highlighterPink,
    highlighterBlue,
  ];
}

class ActiveToolNotifier extends Notifier<ToolType> {
  ToolType _previousTool = ToolType.fountainPen;

  @override
  ToolType build() => ToolType.fountainPen;

  void setTool(ToolType tool) {
    if (state != tool && state != ToolType.eraser) {
      _previousTool = state;
    }
    state = tool;
  }

  void toggleEraser() {
    if (state == ToolType.eraser) {
      state = _previousTool;
    } else {
      _previousTool = state;
      state = ToolType.eraser;
    }
  }

  void togglePreviousTool() {
    final temp = state;
    state = _previousTool;
    _previousTool = temp;
  }
}

/// Selected active tool provider.
final activeToolProvider = NotifierProvider<ActiveToolNotifier, ToolType>(
  ActiveToolNotifier.new,
);

class StylusOnlyModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void setEnabled(bool enabled) => state = enabled;
}

/// Inking mode where finger touches only pan/zoom and only stylus draws ink.
final stylusOnlyModeProvider = NotifierProvider<StylusOnlyModeNotifier, bool>(
  StylusOnlyModeNotifier.new,
);

class StylusHoverState {
  final bool isHovering;
  final Offset position;
  final double distance;
  final double tilt;

  const StylusHoverState({
    this.isHovering = false,
    this.position = Offset.zero,
    this.distance = 0.0,
    this.tilt = 0.0,
  });
}

class StylusHoverNotifier extends Notifier<StylusHoverState> {
  @override
  StylusHoverState build() => const StylusHoverState();

  void updateHover({
    required Offset position,
    double distance = 0.0,
    double tilt = 0.0,
  }) {
    state = StylusHoverState(
      isHovering: true,
      position: position,
      distance: distance,
      tilt: tilt,
    );
  }

  void clearHover() {
    if (state.isHovering) {
      state = const StylusHoverState();
    }
  }
}

/// Real-time hover cursor coordinates and distance above the digitizer.
final stylusHoverProvider =
    NotifierProvider<StylusHoverNotifier, StylusHoverState>(
      StylusHoverNotifier.new,
    );

class StrokeColorNotifier extends Notifier<Color> {
  @override
  Color build() => PenColors.inkSlate;
  void setColor(Color color) => state = color;
}

/// Current active stroke color.
final strokeColorProvider = NotifierProvider<StrokeColorNotifier, Color>(
  StrokeColorNotifier.new,
);

class StrokeWidthNotifier extends Notifier<double> {
  @override
  double build() => 3.0;
  void setWidth(double width) => state = width;
}

/// Current stroke width in document points.
final strokeWidthProvider = NotifierProvider<StrokeWidthNotifier, double>(
  StrokeWidthNotifier.new,
);

class StrokeOpacityNotifier extends Notifier<double> {
  @override
  double build() => 1.0;
  void setOpacity(double opacity) => state = opacity;
}

/// Current stroke opacity (0.0 to 1.0).
final strokeOpacityProvider = NotifierProvider<StrokeOpacityNotifier, double>(
  StrokeOpacityNotifier.new,
);

class PalmRejectionNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
  void setEnabled(bool enabled) => state = enabled;
}

/// Whether hardware palm rejection is enabled.
final palmRejectionEnabledProvider =
    NotifierProvider<PalmRejectionNotifier, bool>(PalmRejectionNotifier.new);

class PressureSensitivityNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
  void setEnabled(bool enabled) => state = enabled;
}

/// Whether pressure sensitivity is enabled.
final pressureSensitivityEnabledProvider =
    NotifierProvider<PressureSensitivityNotifier, bool>(
      PressureSensitivityNotifier.new,
    );

/// Action interface for the undo/redo history stack.
abstract class StrokeAction {
  const StrokeAction();
}

class AddStrokeAction extends StrokeAction {
  final Stroke stroke;
  const AddStrokeAction(this.stroke);
}

class DeleteStrokesAction extends StrokeAction {
  final List<Stroke> strokes;
  const DeleteStrokesAction(this.strokes);
}

class TransformStrokesAction extends StrokeAction {
  final List<Stroke> before;
  final List<Stroke> after;
  const TransformStrokesAction({required this.before, required this.after});
}

class ClearPageAction extends StrokeAction {
  final List<Stroke> clearedStrokes;
  const ClearPageAction(this.clearedStrokes);
}

/// State container holding all loaded strokes, undo/redo stacks, and lasso selections.
class StrokesState {
  final Map<String, List<Stroke>> pageStrokes;
  final Map<String, List<StrokeAction>> undoStacks;
  final Map<String, List<StrokeAction>> redoStacks;
  final Map<String, Set<String>> selectedStrokeIds;
  final List<Stroke> clipboard;

  const StrokesState({
    this.pageStrokes = const {},
    this.undoStacks = const {},
    this.redoStacks = const {},
    this.selectedStrokeIds = const {},
    this.clipboard = const [],
  });

  StrokesState copyWith({
    Map<String, List<Stroke>>? pageStrokes,
    Map<String, List<StrokeAction>>? undoStacks,
    Map<String, List<StrokeAction>>? redoStacks,
    Map<String, Set<String>>? selectedStrokeIds,
    List<Stroke>? clipboard,
  }) {
    return StrokesState(
      pageStrokes: pageStrokes ?? this.pageStrokes,
      undoStacks: undoStacks ?? this.undoStacks,
      redoStacks: redoStacks ?? this.redoStacks,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      clipboard: clipboard ?? this.clipboard,
    );
  }
}

/// Notifier managing handwriting strokes, lasso manipulation, erasing, and undo/redo.
class StrokesNotifier extends Notifier<StrokesState> {
  final _uuid = const Uuid();

  @override
  StrokesState build() {
    return const StrokesState();
  }

  StrokeRepository get _repo => ref.read(strokeRepositoryProvider);

  /// Loads strokes from local SQLite persistence for the specified page.
  Future<void> loadStrokesForPage(String pageId) async {
    final strokes = await _repo.getStrokesForPage(pageId);
    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = strokes;

    state = state.copyWith(pageStrokes: updatedMap);
  }

  /// Adds a newly completed stroke to the page and database.
  Future<void> addStroke(String pageId, Stroke stroke) async {
    final currentList = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    currentList.add(stroke);

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = currentList;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(AddStrokeAction(stroke));

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    final updatedRedo = Map<String, List<StrokeAction>>.from(state.redoStacks);
    updatedRedo[pageId] = [];

    state = state.copyWith(
      pageStrokes: updatedMap,
      undoStacks: updatedUndo,
      redoStacks: updatedRedo,
    );

    await _repo.saveStroke(stroke);

    // Synchronize stroke with active audio recording session
    try {
      final audioService = ref.read(audioServiceProvider);
      if (audioService.recordState.isRecording) {
        audioService.addBookmark(
          'Stroke #${currentList.length}',
          pageId: pageId,
          strokeId: stroke.id,
        );
      }
    } catch (_) {}
  }

  /// Indexes handwriting strokes for full-text search recognition.
  Future<void> indexPageStrokes(String pageId, String notebookId) async {
    final strokes =
        state.pageStrokes[pageId] ?? await _repo.getStrokesForPage(pageId);
    final recognitionService = ref.read(handwritingRecognitionServiceProvider);
    await recognitionService.processAndIndexStrokes(
      pageId,
      notebookId,
      strokes,
    );
  }

  /// Erases any strokes at [point] within [tolerance].
  Future<List<String>> eraseAt(
    String pageId,
    Offset point, {
    double tolerance = 16.0,
  }) async {
    final currentList = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    final erasedStrokes = <Stroke>[];
    final remainingStrokes = <Stroke>[];

    for (final s in currentList) {
      if (s.containsPoint(point, tolerance: tolerance)) {
        erasedStrokes.add(s);
      } else {
        remainingStrokes.add(s);
      }
    }

    if (erasedStrokes.isEmpty) return [];

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = remainingStrokes;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(DeleteStrokesAction(erasedStrokes));

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    final updatedRedo = Map<String, List<StrokeAction>>.from(state.redoStacks);
    updatedRedo[pageId] = [];

    state = state.copyWith(
      pageStrokes: updatedMap,
      undoStacks: updatedUndo,
      redoStacks: updatedRedo,
    );

    await _repo.softDeleteStrokes(erasedStrokes.map((s) => s.id).toList());
    return erasedStrokes.map((s) => s.id).toList();
  }

  /// Selects strokes falling within the closed lasso polygon.
  void selectWithLasso(String pageId, List<Offset> polygon) {
    if (polygon.length < 3) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final selectedIds = <String>{};

    for (final s in currentList) {
      if (s.isInsidePolygon(polygon)) {
        selectedIds.add(s.id);
      }
    }

    final updatedSelections = Map<String, Set<String>>.from(
      state.selectedStrokeIds,
    );
    updatedSelections[pageId] = selectedIds;

    state = state.copyWith(selectedStrokeIds: updatedSelections);
  }

  /// Clears any lasso selection on the page.
  void clearSelection(String pageId) {
    final updatedSelections = Map<String, Set<String>>.from(
      state.selectedStrokeIds,
    );
    updatedSelections[pageId] = {};
    state = state.copyWith(selectedStrokeIds: updatedSelections);
  }

  /// Translates currently selected strokes by [delta] (dx, dy).
  Future<void> translateSelected(String pageId, Offset delta) async {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final beforeStrokes = <Stroke>[];
    final afterStrokes = <Stroke>[];
    final updatedList = <Stroke>[];

    for (final s in currentList) {
      if (selectedIds.contains(s.id)) {
        beforeStrokes.add(s);
        final moved = s.translated(delta).copyWith(revision: s.revision + 1);
        afterStrokes.add(moved);
        updatedList.add(moved);
      } else {
        updatedList.add(s);
      }
    }

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = updatedList;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(
      TransformStrokesAction(before: beforeStrokes, after: afterStrokes),
    );

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    state = state.copyWith(pageStrokes: updatedMap, undoStacks: updatedUndo);

    await _repo.saveStrokes(afterStrokes);
  }

  /// Scales currently selected strokes relative to [origin].
  Future<void> scaleSelected(
    String pageId,
    double scaleX,
    double scaleY,
    Offset origin,
  ) async {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final beforeStrokes = <Stroke>[];
    final afterStrokes = <Stroke>[];
    final updatedList = <Stroke>[];

    for (final s in currentList) {
      if (selectedIds.contains(s.id)) {
        beforeStrokes.add(s);
        final scaled = s
            .scaled(scaleX, scaleY, origin)
            .copyWith(revision: s.revision + 1);
        afterStrokes.add(scaled);
        updatedList.add(scaled);
      } else {
        updatedList.add(s);
      }
    }

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = updatedList;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(
      TransformStrokesAction(before: beforeStrokes, after: afterStrokes),
    );

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    state = state.copyWith(pageStrokes: updatedMap, undoStacks: updatedUndo);

    await _repo.saveStrokes(afterStrokes);
  }

  /// Duplicates currently selected strokes with a slight visual offset.
  Future<void> duplicateSelected(String pageId) async {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final duplicates = <Stroke>[];
    final newSelectedIds = <String>{};

    for (final s in currentList) {
      if (selectedIds.contains(s.id)) {
        final newId = 'stroke-${_uuid.v4()}';
        final duplicated = s
            .translated(const Offset(20, 20))
            .copyWith(id: newId, createdAt: DateTime.now(), revision: 1);
        duplicates.add(duplicated);
        newSelectedIds.add(newId);
      }
    }

    final updatedList = List<Stroke>.from(currentList)..addAll(duplicates);
    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = updatedList;

    final updatedSelections = Map<String, Set<String>>.from(
      state.selectedStrokeIds,
    );
    updatedSelections[pageId] = newSelectedIds;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    for (final d in duplicates) {
      currentUndo.add(AddStrokeAction(d));
    }
    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    state = state.copyWith(
      pageStrokes: updatedMap,
      selectedStrokeIds: updatedSelections,
      undoStacks: updatedUndo,
    );

    await _repo.saveStrokes(duplicates);
  }

  /// Deletes currently selected strokes.
  Future<void> deleteSelected(String pageId) async {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final deletedStrokes = <Stroke>[];
    final remainingStrokes = <Stroke>[];

    for (final s in currentList) {
      if (selectedIds.contains(s.id)) {
        deletedStrokes.add(s);
      } else {
        remainingStrokes.add(s);
      }
    }

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = remainingStrokes;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(DeleteStrokesAction(deletedStrokes));

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    final updatedSelections = Map<String, Set<String>>.from(
      state.selectedStrokeIds,
    );
    updatedSelections[pageId] = {};

    state = state.copyWith(
      pageStrokes: updatedMap,
      undoStacks: updatedUndo,
      selectedStrokeIds: updatedSelections,
    );

    await _repo.softDeleteStrokes(deletedStrokes.map((s) => s.id).toList());
  }

  /// Copies selected strokes to the in-memory clipboard.
  void copySelected(String pageId) {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final toCopy = currentList
        .where((s) => selectedIds.contains(s.id))
        .toList();
    state = state.copyWith(clipboard: toCopy);
  }

  /// Pastes clipboard strokes onto [pageId], centered around [targetCenter].
  Future<void> paste(String pageId, Offset targetCenter) async {
    if (state.clipboard.isEmpty) return;

    Rect? bbox;
    for (final s in state.clipboard) {
      bbox = bbox == null ? s.boundingBox : bbox.expandToInclude(s.boundingBox);
    }

    final sourceCenter = bbox?.center ?? Offset.zero;
    final delta = targetCenter - sourceCenter;

    final newStrokes = <Stroke>[];
    final newSelectedIds = <String>{};

    for (final s in state.clipboard) {
      final newId = 'stroke-${_uuid.v4()}';
      final pasted = s
          .translated(delta)
          .copyWith(
            id: newId,
            pageId: pageId,
            createdAt: DateTime.now(),
            revision: 1,
          );
      newStrokes.add(pasted);
      newSelectedIds.add(newId);
    }

    final currentList = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    currentList.addAll(newStrokes);

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = currentList;

    final updatedSelections = Map<String, Set<String>>.from(
      state.selectedStrokeIds,
    );
    updatedSelections[pageId] = newSelectedIds;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(DeleteStrokesAction(newStrokes));

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    state = state.copyWith(
      pageStrokes: updatedMap,
      selectedStrokeIds: updatedSelections,
      undoStacks: updatedUndo,
    );

    await _repo.saveStrokes(newStrokes);
  }

  /// Undoes the last stroke action on [pageId].
  Future<void> undo(String pageId) async {
    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    if (currentUndo.isEmpty) return;

    final lastAction = currentUndo.removeLast();
    final currentRedo = List<StrokeAction>.from(state.redoStacks[pageId] ?? []);
    currentRedo.add(lastAction);

    final currentStrokes = List<Stroke>.from(state.pageStrokes[pageId] ?? []);

    if (lastAction is AddStrokeAction) {
      currentStrokes.removeWhere((s) => s.id == lastAction.stroke.id);
      await _repo.softDeleteStroke(lastAction.stroke.id);
    } else if (lastAction is DeleteStrokesAction) {
      currentStrokes.addAll(lastAction.strokes);
      await _repo.saveStrokes(lastAction.strokes);
    } else if (lastAction is TransformStrokesAction) {
      for (final before in lastAction.before) {
        final idx = currentStrokes.indexWhere((s) => s.id == before.id);
        if (idx != -1) currentStrokes[idx] = before;
      }
      await _repo.saveStrokes(lastAction.before);
    } else if (lastAction is ClearPageAction) {
      currentStrokes.addAll(lastAction.clearedStrokes);
      await _repo.saveStrokes(lastAction.clearedStrokes);
    }

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = currentStrokes;

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    final updatedRedo = Map<String, List<StrokeAction>>.from(state.redoStacks);
    updatedRedo[pageId] = currentRedo;

    state = state.copyWith(
      pageStrokes: updatedMap,
      undoStacks: updatedUndo,
      redoStacks: updatedRedo,
    );
  }

  /// Redoes the previously undone action on [pageId].
  Future<void> redo(String pageId) async {
    final currentRedo = List<StrokeAction>.from(state.redoStacks[pageId] ?? []);
    if (currentRedo.isEmpty) return;

    final action = currentRedo.removeLast();
    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(action);

    final currentStrokes = List<Stroke>.from(state.pageStrokes[pageId] ?? []);

    if (action is AddStrokeAction) {
      currentStrokes.add(action.stroke);
      await _repo.saveStroke(action.stroke);
    } else if (action is DeleteStrokesAction) {
      final idsToDelete = action.strokes.map((s) => s.id).toSet();
      currentStrokes.removeWhere((s) => idsToDelete.contains(s.id));
      await _repo.softDeleteStrokes(idsToDelete.toList());
    } else if (action is TransformStrokesAction) {
      for (final after in action.after) {
        final idx = currentStrokes.indexWhere((s) => s.id == after.id);
        if (idx != -1) currentStrokes[idx] = after;
      }
      await _repo.saveStrokes(action.after);
    } else if (action is ClearPageAction) {
      currentStrokes.clear();
      await _repo.clearPage(pageId);
    }

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = currentStrokes;

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    final updatedRedo = Map<String, List<StrokeAction>>.from(state.redoStacks);
    updatedRedo[pageId] = currentRedo;

    state = state.copyWith(
      pageStrokes: updatedMap,
      undoStacks: updatedUndo,
      redoStacks: updatedRedo,
    );
  }

  /// Clears all strokes on the page.
  Future<void> clearPage(String pageId) async {
    final currentStrokes = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    if (currentStrokes.isEmpty) return;

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = [];

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    currentUndo.add(ClearPageAction(currentStrokes));

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    final updatedRedo = Map<String, List<StrokeAction>>.from(state.redoStacks);
    updatedRedo[pageId] = [];

    state = state.copyWith(
      pageStrokes: updatedMap,
      undoStacks: updatedUndo,
      redoStacks: updatedRedo,
    );

    await _repo.clearPage(pageId);
  }
}

/// Global provider for the stroke manager.
final strokesNotifierProvider = NotifierProvider<StrokesNotifier, StrokesState>(
  StrokesNotifier.new,
);

/// Computed provider for whether undo is available for [pageId].
final canUndoProvider = Provider.family<bool, String>((ref, pageId) {
  final state = ref.watch(strokesNotifierProvider);
  return (state.undoStacks[pageId] ?? []).isNotEmpty;
});

/// Computed provider for whether redo is available for [pageId].
final canRedoProvider = Provider.family<bool, String>((ref, pageId) {
  final state = ref.watch(strokesNotifierProvider);
  return (state.redoStacks[pageId] ?? []).isNotEmpty;
});

/// Computed provider for active strokes on [pageId].
final pageStrokesProvider = Provider.family<List<Stroke>, String>((
  ref,
  pageId,
) {
  final state = ref.watch(strokesNotifierProvider);
  return state.pageStrokes[pageId] ?? [];
});

/// Computed provider for selected stroke IDs on [pageId].
final selectedStrokesProvider = Provider.family<Set<String>, String>((
  ref,
  pageId,
) {
  final state = ref.watch(strokesNotifierProvider);
  return state.selectedStrokeIds[pageId] ?? {};
});
