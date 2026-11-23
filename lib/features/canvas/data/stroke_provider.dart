import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/shape_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/stroke_repository.dart';
import 'package:naik_notes/features/audio/data/audio_provider.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';
import 'package:naik_notes/features/pdf/data/sticky_note_provider.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';
import 'package:naik_notes/features/sync/data/sync_provider.dart';
import 'package:naik_notes/services/recognition/handwriting_recognition_provider.dart';
import 'package:uuid/uuid.dart';

/// Configuration memory for an individual drawing tool.
class ToolConfig {
  final ToolType tool;
  final double width;
  final Color color;
  final double opacity;
  final StrokeStyle strokeStyle;

  const ToolConfig({
    required this.tool,
    required this.width,
    required this.color,
    required this.opacity,
    this.strokeStyle = StrokeStyle.solid,
  });

  double get strokeWidth => width;

  ToolConfig copyWith({
    double? width,
    Color? color,
    double? opacity,
    StrokeStyle? strokeStyle,
  }) {
    return ToolConfig(
      tool: tool,
      width: width ?? this.width,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      strokeStyle: strokeStyle ?? this.strokeStyle,
    );
  }
}

/// State notifier managing per-tool configuration memory.
class ToolConfigsNotifier extends Notifier<Map<ToolType, ToolConfig>> {
  @override
  Map<ToolType, ToolConfig> build() {
    return {
      ToolType.fountainPen: const ToolConfig(
        tool: ToolType.fountainPen,
        width: 3.0,
        color: PenColors.inkSlate,
        opacity: 1.0,
      ),
      ToolType.ballpointPen: const ToolConfig(
        tool: ToolType.ballpointPen,
        width: 2.0,
        color: PenColors.royalBlue,
        opacity: 1.0,
      ),
      ToolType.pencil: const ToolConfig(
        tool: ToolType.pencil,
        width: 2.5,
        color: Color(0xFF4B5563),
        opacity: 0.85,
      ),
      ToolType.brushPen: const ToolConfig(
        tool: ToolType.brushPen,
        width: 4.5,
        color: Color(0xFF111827),
        opacity: 1.0,
      ),
      ToolType.highlighter: const ToolConfig(
        tool: ToolType.highlighter,
        width: 16.0,
        color: PenColors.highlighterYellow,
        opacity: 0.35,
      ),
      ToolType.marker: const ToolConfig(
        tool: ToolType.marker,
        width: 6.0,
        color: Color(0xFFDC2626),
        opacity: 1.0,
      ),
      ToolType.calligraphyPen: const ToolConfig(
        tool: ToolType.calligraphyPen,
        width: 4.0,
        color: Color(0xFF1E293B),
        opacity: 1.0,
      ),
      ToolType.technicalPen: const ToolConfig(
        tool: ToolType.technicalPen,
        width: 1.5,
        color: Color(0xFF0F172A),
        opacity: 1.0,
      ),
      ToolType.customBrush: const ToolConfig(
        tool: ToolType.customBrush,
        width: 5.0,
        color: Color(0xFF4338CA),
        opacity: 0.9,
      ),
      ToolType.fillBucket: const ToolConfig(
        tool: ToolType.fillBucket,
        width: 0.0,
        color: Color(0xFF3B82F6),
        opacity: 1.0,
      ),
      ToolType.shape: const ToolConfig(
        tool: ToolType.shape,
        width: 2.5,
        color: PenColors.inkSlate,
        opacity: 1.0,
      ),
    };
  }

  void updateConfig(
    ToolType tool, {
    double? width,
    Color? color,
    double? opacity,
    StrokeStyle? strokeStyle,
  }) {
    final current =
        state[tool] ??
        ToolConfig(
          tool: tool,
          width: tool.defaultWidth,
          color: PenColors.inkSlate,
          opacity: tool.defaultOpacity,
        );
    state = {
      ...state,
      tool: current.copyWith(
        width: width,
        color: color,
        opacity: opacity,
        strokeStyle: strokeStyle,
      ),
    };
  }

  void updateWidth(ToolType tool, double width) =>
      updateConfig(tool, width: width);

  void updateColor(ToolType tool, Color color) =>
      updateConfig(tool, color: color);

  void updateOpacity(ToolType tool, double opacity) =>
      updateConfig(tool, opacity: opacity);

  void updateStyle(ToolType tool, StrokeStyle style) =>
      updateConfig(tool, strokeStyle: style);

  void resetToDefaults() => state = build();
}

final toolConfigsProvider =
    NotifierProvider<ToolConfigsNotifier, Map<ToolType, ToolConfig>>(
      ToolConfigsNotifier.new,
    );

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

/// Available eraser operating modes.
enum EraserMode {
  stroke('stroke', 'Stroke Eraser (Whole Stroke)'),
  partial('partial', 'Partial Eraser (Segment Split)'),
  object('object', 'Object Eraser (Whole Object)');

  final String id;
  final String label;
  const EraserMode(this.id, this.label);

  static EraserMode fromId(String id) {
    return EraserMode.values.firstWhere(
      (m) => m.id == id,
      orElse: () => EraserMode.object,
    );
  }
}

class EraserModeNotifier extends Notifier<EraserMode> {
  @override
  EraserMode build() => EraserMode.partial;
  void setMode(EraserMode mode) => state = mode;
  void toggle() => state = state == EraserMode.partial
      ? EraserMode.stroke
      : EraserMode.partial;
}

/// Global provider for active eraser mode (stroke, partial, object).
final eraserModeProvider = NotifierProvider<EraserModeNotifier, EraserMode>(
  EraserModeNotifier.new,
);

/// Geometric boundary shape for the eraser tool.
enum EraserShape {
  circle('circle', 'Circular Eraser'),
  square('square', 'Square Eraser');

  final String id;
  final String label;
  const EraserShape(this.id, this.label);
}

class EraserShapeNotifier extends Notifier<EraserShape> {
  @override
  EraserShape build() => EraserShape.circle;
  void setShape(EraserShape shape) => state = shape;
}

final eraserShapeProvider = NotifierProvider<EraserShapeNotifier, EraserShape>(
  EraserShapeNotifier.new,
);

class EraserRadiusNotifier extends Notifier<double> {
  @override
  double build() => 20.0;
  void setRadius(double radius) => state = radius;
}

/// Global provider for eraser radius size.
final eraserRadiusProvider = NotifierProvider<EraserRadiusNotifier, double>(
  EraserRadiusNotifier.new,
);

class ActiveToolNotifier extends Notifier<ToolType> {
  ToolType _previousTool = ToolType.fountainPen;

  @override
  ToolType build() => ToolType.fountainPen;

  void setTool(ToolType tool) {
    if (state != tool && state != ToolType.eraser) {
      _previousTool = state;
    }
    state = tool;

    // Synchronize active drawing parameters to the selected tool's remembered config
    final configs = ref.read(toolConfigsProvider);
    final config = configs[tool];
    if (config != null) {
      ref
          .read(strokeWidthProvider.notifier)
          .setWidth(config.width, syncConfig: false);
      ref
          .read(strokeColorProvider.notifier)
          .setColor(config.color, syncConfig: false);
      ref
          .read(strokeOpacityProvider.notifier)
          .setOpacity(config.opacity, syncConfig: false);
      ref
          .read(strokeStyleProvider.notifier)
          .setStyle(config.strokeStyle, syncConfig: false);
    }
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
  void setColor(Color color, {bool syncConfig = true}) {
    state = color;
    if (syncConfig) {
      final activeTool = ref.read(activeToolProvider);
      ref
          .read(toolConfigsProvider.notifier)
          .updateConfig(activeTool, color: color);
    }
  }
}

/// Current active stroke color.
final strokeColorProvider = NotifierProvider<StrokeColorNotifier, Color>(
  StrokeColorNotifier.new,
);

class StrokeWidthNotifier extends Notifier<double> {
  @override
  double build() => 3.0;
  void setWidth(double width, {bool syncConfig = true}) {
    state = width;
    if (syncConfig) {
      final activeTool = ref.read(activeToolProvider);
      ref
          .read(toolConfigsProvider.notifier)
          .updateConfig(activeTool, width: width);
    }
  }
}

/// Current stroke width in document points.
final strokeWidthProvider = NotifierProvider<StrokeWidthNotifier, double>(
  StrokeWidthNotifier.new,
);

class StrokeOpacityNotifier extends Notifier<double> {
  @override
  double build() => 1.0;
  void setOpacity(double opacity, {bool syncConfig = true}) {
    state = opacity;
    if (syncConfig) {
      final activeTool = ref.read(activeToolProvider);
      ref
          .read(toolConfigsProvider.notifier)
          .updateConfig(activeTool, opacity: opacity);
    }
  }
}

/// Current stroke opacity (0.0 to 1.0).
final strokeOpacityProvider = NotifierProvider<StrokeOpacityNotifier, double>(
  StrokeOpacityNotifier.new,
);

class StrokeStyleNotifier extends Notifier<StrokeStyle> {
  @override
  StrokeStyle build() => StrokeStyle.solid;
  void setStyle(StrokeStyle style, {bool syncConfig = true}) {
    state = style;
    if (syncConfig) {
      final activeTool = ref.read(activeToolProvider);
      ref
          .read(toolConfigsProvider.notifier)
          .updateConfig(activeTool, strokeStyle: style);
    }
  }
}

/// Current stroke style (solid, dashed, dotted).
final strokeStyleProvider = NotifierProvider<StrokeStyleNotifier, StrokeStyle>(
  StrokeStyleNotifier.new,
);

class SelectedShapeTypeNotifier extends Notifier<ShapeType> {
  @override
  ShapeType build() => ShapeType.rectangle;
  void setShapeType(ShapeType type) => state = type;
}

final selectedShapeTypeProvider =
    NotifierProvider<SelectedShapeTypeNotifier, ShapeType>(
      SelectedShapeTypeNotifier.new,
    );

class ShapeFillColorNotifier extends Notifier<Color?> {
  @override
  Color? build() => null;
  void setColor(Color? color) => state = color;
}

final shapeFillColorProvider = NotifierProvider<ShapeFillColorNotifier, Color?>(
  ShapeFillColorNotifier.new,
);

class ShapeFillOpacityNotifier extends Notifier<double> {
  @override
  double build() => 0.5;
  void setOpacity(double opacity) => state = opacity;
}

final shapeFillOpacityProvider =
    NotifierProvider<ShapeFillOpacityNotifier, double>(
      ShapeFillOpacityNotifier.new,
    );

class ShapeIsFilledNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void toggle() => state = !state;
  void setFilled(bool filled) => state = filled;
}

final shapeIsFilledProvider = NotifierProvider<ShapeIsFilledNotifier, bool>(
  ShapeIsFilledNotifier.new,
);

class ShapeStrokeStyleNotifier extends Notifier<StrokeStyle> {
  @override
  StrokeStyle build() => StrokeStyle.solid;
  void setStyle(StrokeStyle style) => state = style;
}

final shapeStrokeStyleProvider =
    NotifierProvider<ShapeStrokeStyleNotifier, StrokeStyle>(
      ShapeStrokeStyleNotifier.new,
    );

class SnappingEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
  void setEnabled(bool enabled) => state = enabled;
}

/// Global toggle for precision shape and line snapping.
final snappingEnabledProvider = NotifierProvider<SnappingEnabledNotifier, bool>(
  SnappingEnabledNotifier.new,
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
  static const int maxUndoHistory = 50;

  final Map<String, List<Stroke>> _pendingCloudStrokes = {};
  final Map<String, Timer> _strokeDebounceTimers = {};
  final Map<String, StreamSubscription> _strokeSubscriptions = {};

  void _pushAction(List<StrokeAction> stack, StrokeAction action) {
    stack.add(action);
    if (stack.length > maxUndoHistory) {
      stack.removeAt(0);
    }
  }

  @override
  StrokesState build() {
    ref.onDispose(() {
      for (final timer in _strokeDebounceTimers.values) {
        timer.cancel();
      }
      _strokeDebounceTimers.clear();
      for (final sub in _strokeSubscriptions.values) {
        sub.cancel();
      }
      _strokeSubscriptions.clear();
    });
    return const StrokesState();
  }

  StrokeRepository get _repo => ref.read(strokeRepositoryProvider);

  Future<String?> _resolveNotebookId(String pageId) async {
    final allPagesMap = ref.read(notebookPagesProvider);
    for (final entry in allPagesMap.entries) {
      if (entry.value.any((p) => p.id == pageId)) {
        return entry.key;
      }
    }
    try {
      final page = await ref.read(pageRepositoryProvider).getPageById(pageId);
      return page?.notebookId;
    } catch (_) {
      return null;
    }
  }

  /// Loads strokes from local SQLite persistence for the specified page.
  /// Also synchronizes with Cloud Firestore and attaches a real-time listener.
  Future<void> loadStrokesForPage(String pageId) async {
    final strokes = await _repo.getStrokesForPage(pageId);
    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = strokes;

    state = state.copyWith(pageStrokes: updatedMap);

    // Cloud stroke hydration and real-time listening
    final uid = ref.read(authProvider).user?.id;
    if (uid != null && uid != 'local_user') {
      final notebookId = await _resolveNotebookId(pageId);
      if (notebookId != null) {
        try {
          final fbSync = ref.read(firebaseSyncServiceProvider);
          final remoteStrokes =
              await fbSync.fetchStrokes(uid, notebookId, pageId);
          if (remoteStrokes.isNotEmpty) {
            await _repo.saveStrokes(remoteStrokes);
            final merged = await _repo.getStrokesForPage(pageId);
            final newMap = Map<String, List<Stroke>>.from(state.pageStrokes);
            newMap[pageId] = merged;
            state = state.copyWith(pageStrokes: newMap);
          }

          // Attach real-time stroke subscription
          _strokeSubscriptions[pageId]?.cancel();
          final sub = fbSync.listenToStrokes(uid, notebookId, pageId,
              (incoming) async {
            if (incoming.isNotEmpty && ref.mounted) {
              await _repo.saveStrokes(incoming);
              final activeStrokes =
                  incoming.where((s) => s.deletedAt == null).toList();
              final currentStrokes = state.pageStrokes[pageId] ?? [];
              final Map<String, Stroke> byId = {
                for (final s in currentStrokes) s.id: s,
                for (final s in activeStrokes) s.id: s,
              };
              final mergedList = byId.values.toList()
                ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
              final m = Map<String, List<Stroke>>.from(state.pageStrokes);
              m[pageId] = mergedList;
              state = state.copyWith(pageStrokes: m);
            }
          });
          if (sub != null) {
            _strokeSubscriptions[pageId] = sub;
          }
        } catch (e) {
          debugPrint('[StrokeNotifier] Cloud strokes load/sync error: $e');
        }
      }
    }
  }

  void _scheduleCloudStrokePush(String pageId, Stroke stroke) {
    _pendingCloudStrokes.putIfAbsent(pageId, () => []).add(stroke);
    _strokeDebounceTimers[pageId]?.cancel();
    _strokeDebounceTimers[pageId] =
        Timer(const Duration(milliseconds: 1200), () {
      flushPendingStrokes(pageId: pageId);
    });
  }

  /// Explicitly flushes pending strokes to Firestore.
  Future<void> flushPendingStrokes({String? pageId}) async {
    final targets =
        pageId != null ? [pageId] : _pendingCloudStrokes.keys.toList();
    for (final pid in targets) {
      _strokeDebounceTimers[pid]?.cancel();
      _strokeDebounceTimers.remove(pid);
      final strokesToPush = _pendingCloudStrokes.remove(pid);
      if (strokesToPush == null || strokesToPush.isEmpty) continue;

      final uid = ref.read(authProvider).user?.id;
      if (uid != null && uid != 'local_user') {
        final notebookId = await _resolveNotebookId(pid);
        if (notebookId != null) {
          try {
            await ref.read(firebaseSyncServiceProvider).pushStrokes(
                  uid,
                  notebookId,
                  pid,
                  strokesToPush,
                );
          } catch (e) {
            debugPrint('[StrokeNotifier] flushPendingStrokes error: $e');
          }
        }
      }
    }
  }

  /// Adds a newly completed stroke to the page and database.
  Future<void> addStroke(String pageId, Stroke stroke) async {
    final currentList = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    currentList.add(stroke);

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = currentList;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    _pushAction(currentUndo, AddStrokeAction(stroke));

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
    _scheduleCloudStrokePush(pageId, stroke);

    // Schedule debounced Google Drive cloud backup for handwriting strokes
    try {
      ref.read(googleDriveProvider.notifier).scheduleAutoSync(
        delay: const Duration(seconds: 5),
        reason: 'handwriting_strokes',
      );
    } catch (_) {}

    // Synchronize stroke with active audio recording session
    final isRecordingActive = ref.read(isAudioRecordingActiveProvider);
    if (isRecordingActive) {
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
  }

  /// Updates or saves an existing stroke.
  Future<void> saveStroke(Stroke stroke) async {
    final pageId = stroke.pageId;
    final currentList = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    final index = currentList.indexWhere((s) => s.id == stroke.id);
    if (index != -1) {
      currentList[index] = stroke;
    } else {
      currentList.add(stroke);
    }
    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = currentList;
    state = state.copyWith(pageStrokes: updatedMap);
    await _repo.saveStroke(stroke);
    try {
      ref.read(googleDriveProvider.notifier).scheduleAutoSync(
        delay: const Duration(seconds: 5),
        reason: 'handwriting_strokes',
      );
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

  /// Erases strokes at [point] using [tolerance], [mode] (stroke, partial, object), and [shape] (circle, square).
  Future<List<String>> eraseAt(
    String pageId,
    Offset point, {
    double tolerance = 20.0,
    EraserMode mode = EraserMode.object,
    EraserShape shape = EraserShape.circle,
  }) async {
    final currentList = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    if (currentList.isEmpty) return [];

    if (mode == EraserMode.stroke || mode == EraserMode.object) {
      final erasedStrokes = <Stroke>[];
      final remainingStrokes = <Stroke>[];

      for (final s in currentList) {
        bool hit = false;
        if (shape == EraserShape.circle) {
          hit = s.containsPoint(point, tolerance: tolerance);
        } else {
          final box = Rect.fromCenter(
            center: point,
            width: tolerance * 2.0,
            height: tolerance * 2.0,
          );
          hit =
              s.boundingBox.inflate(tolerance).overlaps(box) &&
              (s.containsPoint(point, tolerance: tolerance) ||
                  s.boundingBox.overlaps(box));
        }

        if (hit) {
          erasedStrokes.add(s);
        } else {
          remainingStrokes.add(s);
        }
      }

      if (mode == EraserMode.object) {
        final notes = ref.read(pageStickyNotesProvider(pageId));
        for (final n in notes) {
          final noteBox = Rect.fromLTWH(n.x, n.y, n.width, n.height);
          if (noteBox.inflate(tolerance).contains(point)) {
            ref
                .read(stickyNotesProvider.notifier)
                .deleteStickyNote(pageId, n.id);
          }
        }
      }

      if (erasedStrokes.isEmpty) return [];

      final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
      updatedMap[pageId] = remainingStrokes;

      final currentUndo = List<StrokeAction>.from(
        state.undoStacks[pageId] ?? [],
      );
      _pushAction(currentUndo, DeleteStrokesAction(erasedStrokes));

      final updatedUndo = Map<String, List<StrokeAction>>.from(
        state.undoStacks,
      );
      updatedUndo[pageId] = currentUndo;

      final updatedRedo = Map<String, List<StrokeAction>>.from(
        state.redoStacks,
      );
      updatedRedo[pageId] = [];

      state = state.copyWith(
        pageStrokes: updatedMap,
        undoStacks: updatedUndo,
        redoStacks: updatedRedo,
      );

      await _repo.softDeleteStrokes(erasedStrokes.map((s) => s.id).toList());
      return erasedStrokes.map((s) => s.id).toList();
    } else {
      // Partial stroke splitting
      bool anyModified = false;
      final beforeList = <Stroke>[];
      final afterList = <Stroke>[];
      final updatedStrokes = <Stroke>[];
      final deletedIds = <String>[];

      for (final s in currentList) {
        if (!s.boundingBox.inflate(tolerance).contains(point)) {
          updatedStrokes.add(s);
          continue;
        }

        final split = shape == EraserShape.circle
            ? s.splitByEraserCircle(
                point,
                tolerance,
                () => 'stroke-${_uuid.v4()}',
              )
            : s.splitByEraserSquare(
                point,
                tolerance,
                () => 'stroke-${_uuid.v4()}',
              );

        if (split.length == 1 && split.first.id == s.id) {
          updatedStrokes.add(s);
        } else {
          anyModified = true;
          beforeList.add(s);
          afterList.addAll(split);
          updatedStrokes.addAll(split);
          deletedIds.add(s.id);
        }
      }

      if (!anyModified) return [];

      final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
      updatedMap[pageId] = updatedStrokes;

      final currentUndo = List<StrokeAction>.from(
        state.undoStacks[pageId] ?? [],
      );
      _pushAction(
        currentUndo,
        TransformStrokesAction(before: beforeList, after: afterList),
      );

      final updatedUndo = Map<String, List<StrokeAction>>.from(
        state.undoStacks,
      );
      updatedUndo[pageId] = currentUndo;

      final updatedRedo = Map<String, List<StrokeAction>>.from(
        state.redoStacks,
      );
      updatedRedo[pageId] = [];

      state = state.copyWith(
        pageStrokes: updatedMap,
        undoStacks: updatedUndo,
        redoStacks: updatedRedo,
      );

      if (deletedIds.isNotEmpty) {
        await _repo.softDeleteStrokes(deletedIds);
      }
      if (afterList.isNotEmpty) {
        await _repo.saveStrokes(afterList);
      }
      return deletedIds;
    }
  }

  /// Selects or toggles an individual stroke at [point].
  void selectStrokeAt(String pageId, Offset point, {double tolerance = 12.0}) {
    final currentList = state.pageStrokes[pageId] ?? [];
    String? hitStrokeId;
    for (int i = currentList.length - 1; i >= 0; i--) {
      if (currentList[i].containsPoint(point, tolerance: tolerance)) {
        hitStrokeId = currentList[i].id;
        break;
      }
    }

    final updatedSelections = Map<String, Set<String>>.from(
      state.selectedStrokeIds,
    );
    if (hitStrokeId != null) {
      updatedSelections[pageId] = {hitStrokeId};
    } else {
      updatedSelections[pageId] = {};
    }
    state = state.copyWith(selectedStrokeIds: updatedSelections);
  }

  /// Rotates currently selected strokes by [angleRadians] around [origin].
  Future<void> rotateSelected(
    String pageId,
    double angleRadians,
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
        final rotated = s
            .rotated(angleRadians, origin)
            .copyWith(revision: s.revision + 1);
        afterStrokes.add(rotated);
        updatedList.add(rotated);
      } else {
        updatedList.add(s);
      }
    }

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = updatedList;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    _pushAction(
      currentUndo,
      TransformStrokesAction(before: beforeStrokes, after: afterStrokes),
    );

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    state = state.copyWith(pageStrokes: updatedMap, undoStacks: updatedUndo);
    await _repo.saveStrokes(afterStrokes);
  }

  /// Deletes currently selected strokes on [pageId].
  Future<void> deleteSelected(String pageId) async {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final toDelete = currentList
        .where((s) => selectedIds.contains(s.id))
        .toList();
    final remaining = currentList
        .where((s) => !selectedIds.contains(s.id))
        .toList();

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = remaining;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    _pushAction(currentUndo, DeleteStrokesAction(toDelete));

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
    await _repo.softDeleteStrokes(toDelete.map((s) => s.id).toList());
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
    _pushAction(
      currentUndo,
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
    _pushAction(
      currentUndo,
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
      _pushAction(currentUndo, AddStrokeAction(d));
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
    _pushAction(currentUndo, DeleteStrokesAction(newStrokes));

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    state = state.copyWith(
      pageStrokes: updatedMap,
      selectedStrokeIds: updatedSelections,
      undoStacks: updatedUndo,
    );

    await _repo.saveStrokes(newStrokes);
  }

  /// Recolors currently selected strokes to [newColor].
  Future<void> recolorSelected(String pageId, Color newColor) async {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = state.pageStrokes[pageId] ?? [];
    final beforeStrokes = <Stroke>[];
    final afterStrokes = <Stroke>[];
    final updatedList = <Stroke>[];

    for (final s in currentList) {
      if (selectedIds.contains(s.id)) {
        beforeStrokes.add(s);
        final recolored = s.copyWith(
          colorValue: newColor.toARGB32(),
          revision: s.revision + 1,
        );
        afterStrokes.add(recolored);
        updatedList.add(recolored);
      } else {
        updatedList.add(s);
      }
    }

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = updatedList;

    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    _pushAction(
      currentUndo,
      TransformStrokesAction(before: beforeStrokes, after: afterStrokes),
    );

    final updatedUndo = Map<String, List<StrokeAction>>.from(state.undoStacks);
    updatedUndo[pageId] = currentUndo;

    state = state.copyWith(pageStrokes: updatedMap, undoStacks: updatedUndo);
    await _repo.saveStrokes(afterStrokes);
  }

  /// Changes z-order of selected strokes (bring to front or send to back).
  Future<void> reorderSelected(String pageId, {required bool bringToFront}) async {
    final selectedIds = state.selectedStrokeIds[pageId] ?? {};
    if (selectedIds.isEmpty) return;

    final currentList = List<Stroke>.from(state.pageStrokes[pageId] ?? []);
    final selected = currentList.where((s) => selectedIds.contains(s.id)).toList();
    final nonSelected = currentList.where((s) => !selectedIds.contains(s.id)).toList();

    final reordered = bringToFront
        ? [...nonSelected, ...selected]
        : [...selected, ...nonSelected];

    final updatedMap = Map<String, List<Stroke>>.from(state.pageStrokes);
    updatedMap[pageId] = reordered;

    state = state.copyWith(pageStrokes: updatedMap);
    await _repo.saveStrokes(reordered);
  }

  /// Undoes the last stroke action on [pageId].
  Future<void> undo(String pageId) async {
    final currentUndo = List<StrokeAction>.from(state.undoStacks[pageId] ?? []);
    if (currentUndo.isEmpty) return;

    final lastAction = currentUndo.removeLast();
    final currentRedo = List<StrokeAction>.from(state.redoStacks[pageId] ?? []);
    _pushAction(currentRedo, lastAction);

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
    _pushAction(currentUndo, action);

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
    _pushAction(currentUndo, ClearPageAction(currentStrokes));

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
