import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/canvas/rendering/active_stroke_painter.dart';
import 'package:naik_notes/features/canvas/rendering/lasso_painter.dart';
import 'package:naik_notes/features/canvas/rendering/stroke_painter.dart';
import 'package:naik_notes/features/templates/presentation/widgets/paper_template_view.dart';
import 'package:uuid/uuid.dart';

/// Interactive vector handwriting canvas.
/// Captures stylus, digitizer, mouse, and touch events with high-performance
/// direct-to-canvas rendering, palm rejection, pressure & tilt sensitivity,
/// and lasso transformations in resolution-independent document space.
class HandwritingCanvas extends ConsumerStatefulWidget {
  final String pageId;
  final PaperTemplateType type;
  final PaperProperties properties;
  final double width;
  final double height;
  final bool readOnly;

  const HandwritingCanvas({
    super.key,
    required this.pageId,
    required this.type,
    required this.properties,
    required this.width,
    required this.height,
    this.readOnly = false,
  });

  @override
  ConsumerState<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends ConsumerState<HandwritingCanvas> {
  final _uuid = const Uuid();

  Stroke? _activeStroke;
  List<Offset> _lassoPoints = [];
  bool _isStylusDetected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(strokesNotifierProvider.notifier)
          .loadStrokesForPage(widget.pageId);
    });
  }

  @override
  void didUpdateWidget(covariant HandwritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId) {
      _activeStroke = null;
      _lassoPoints = [];
      ref
          .read(strokesNotifierProvider.notifier)
          .loadStrokesForPage(widget.pageId);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.readOnly) return;

    final isStylus =
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus;

    if (isStylus && !_isStylusDetected) {
      setState(() => _isStylusDetected = true);
    }

    // Palm rejection: if palm rejection is enabled and stylus is detected,
    // ignore normal touch events for drawing
    final palmRejection = ref.read(palmRejectionEnabledProvider);
    if (palmRejection &&
        _isStylusDetected &&
        event.kind == PointerDeviceKind.touch) {
      return;
    }

    final tool = event.kind == PointerDeviceKind.invertedStylus
        ? ToolType.eraser
        : ref.read(activeToolProvider);

    if (tool == ToolType.pan) return;

    final docPoint = event.localPosition;

    // Check if tapping outside lasso selection to clear selection
    final selectedIds = ref.read(selectedStrokesProvider(widget.pageId));
    if (selectedIds.isNotEmpty && tool != ToolType.lasso) {
      final strokes = ref.read(pageStrokesProvider(widget.pageId));
      final bbox = _computeSelectionBoundingBox(strokes, selectedIds);
      if (bbox != null && !bbox.inflate(20.0).contains(docPoint)) {
        ref
            .read(strokesNotifierProvider.notifier)
            .clearSelection(widget.pageId);
      }
    }

    if (tool == ToolType.eraser) {
      ref
          .read(strokesNotifierProvider.notifier)
          .eraseAt(
            widget.pageId,
            docPoint,
            tolerance: ref.read(strokeWidthProvider) * 1.5,
          );
      return;
    }

    if (tool == ToolType.lasso) {
      setState(() {
        _lassoPoints = [docPoint];
      });
      return;
    }

    // Drawing tool
    final color = ref.read(strokeColorProvider);
    final width = ref.read(strokeWidthProvider);
    final opacity = ref.read(strokeOpacityProvider);
    final pressureEnabled = ref.read(pressureSensitivityEnabledProvider);

    final initialPressure = pressureEnabled && event.pressure != 0.0
        ? event.pressure.clamp(0.05, 1.0)
        : 0.5;

    final initialTilt = event.tilt;

    final newStroke = Stroke(
      id: 'stroke-${_uuid.v4()}',
      pageId: widget.pageId,
      tool: tool,
      colorValue: color.toARGB32(),
      width: width,
      opacity: opacity,
      points: [
        StrokePoint(
          x: docPoint.dx,
          y: docPoint.dy,
          pressure: initialPressure,
          tilt: initialTilt,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
      createdAt: DateTime.now(),
    );

    setState(() {
      _activeStroke = newStroke;
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.readOnly) return;

    final palmRejection = ref.read(palmRejectionEnabledProvider);
    if (palmRejection &&
        _isStylusDetected &&
        event.kind == PointerDeviceKind.touch) {
      return;
    }

    final tool = event.kind == PointerDeviceKind.invertedStylus
        ? ToolType.eraser
        : ref.read(activeToolProvider);

    if (tool == ToolType.pan) return;

    final docPoint = event.localPosition;

    if (tool == ToolType.eraser) {
      ref
          .read(strokesNotifierProvider.notifier)
          .eraseAt(
            widget.pageId,
            docPoint,
            tolerance: ref.read(strokeWidthProvider) * 1.5,
          );
      return;
    }

    if (tool == ToolType.lasso && _lassoPoints.isNotEmpty) {
      setState(() {
        _lassoPoints.add(docPoint);
      });
      return;
    }

    if (_activeStroke == null) return;

    final pressureEnabled = ref.read(pressureSensitivityEnabledProvider);
    final pressure = pressureEnabled && event.pressure != 0.0
        ? event.pressure.clamp(0.05, 1.0)
        : 0.5;

    final updatedPoints = List<StrokePoint>.from(_activeStroke!.points)
      ..add(
        StrokePoint(
          x: docPoint.dx,
          y: docPoint.dy,
          pressure: pressure,
          tilt: event.tilt,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      );

    setState(() {
      _activeStroke = _activeStroke!.copyWith(points: updatedPoints);
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.readOnly) return;

    final tool = event.kind == PointerDeviceKind.invertedStylus
        ? ToolType.eraser
        : ref.read(activeToolProvider);

    if (tool == ToolType.pan) return;

    if (tool == ToolType.lasso && _lassoPoints.length > 2) {
      ref
          .read(strokesNotifierProvider.notifier)
          .selectWithLasso(widget.pageId, _lassoPoints);
      setState(() {
        _lassoPoints = [];
      });
      return;
    }

    if (_activeStroke != null) {
      final strokeToSave = _activeStroke!;
      setState(() {
        _activeStroke = null;
      });

      // Laser pointer is transient; does not get stored into document database
      if (strokeToSave.tool != ToolType.laserPointer) {
        ref
            .read(strokesNotifierProvider.notifier)
            .addStroke(widget.pageId, strokeToSave);
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() {
      _activeStroke = null;
      _lassoPoints = [];
    });
  }

  Rect? _computeSelectionBoundingBox(
    List<Stroke> strokes,
    Set<String> selectedIds,
  ) {
    if (selectedIds.isEmpty) return null;
    Rect? bbox;
    for (final s in strokes) {
      if (selectedIds.contains(s.id)) {
        bbox = bbox == null
            ? s.boundingBox
            : bbox.expandToInclude(s.boundingBox);
      }
    }
    return bbox;
  }

  @override
  Widget build(BuildContext context) {
    final pageStrokes = ref.watch(pageStrokesProvider(widget.pageId));
    final selectedIds = ref.watch(selectedStrokesProvider(widget.pageId));
    final selectionBox = _computeSelectionBoundingBox(pageStrokes, selectedIds);
    final activeTool = ref.watch(activeToolProvider);
    final isPanMode = activeTool == ToolType.pan || widget.readOnly;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Layer 1: Vector Paper Template Background
          Positioned.fill(
            child: PaperTemplateView(
              type: widget.type,
              properties: widget.properties,
              width: widget.width,
              height: widget.height,
            ),
          ),

          // Layer 2: Completed Vector Strokes
          Positioned.fill(
            child: CustomPaint(
              painter: StrokePainter(
                strokes: pageStrokes,
                visibleBounds: Rect.fromLTWH(0, 0, widget.width, widget.height),
              ),
            ),
          ),

          // Layer 3: Active In-Progress Stroke
          if (_activeStroke != null)
            Positioned.fill(
              child: CustomPaint(
                painter: ActiveStrokePainter(activeStroke: _activeStroke),
              ),
            ),

          // Layer 4: Lasso Loop & Selection Handles
          Positioned.fill(
            child: CustomPaint(
              painter: LassoPainter(
                lassoPoints: _lassoPoints,
                selectionBoundingBox: selectionBox,
              ),
            ),
          ),

          // Layer 5: Drag Gesture Detector for Moving Selected Strokes
          if (selectionBox != null && !selectionBox.isEmpty)
            Positioned(
              left: selectionBox.left,
              top: selectionBox.top,
              width: selectionBox.width,
              height: selectionBox.height,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  ref
                      .read(strokesNotifierProvider.notifier)
                      .translateSelected(widget.pageId, details.delta);
                },
              ),
            ),

          // Layer 6: Floating Selection Action Bar
          if (selectionBox != null && !selectionBox.isEmpty)
            Positioned(
              left: (selectionBox.center.dx - 120).clamp(
                10.0,
                widget.width - 250,
              ),
              top: (selectionBox.top - 46).clamp(10.0, widget.height - 50),
              child: _buildSelectionToolbar(context),
            ),

          // Layer 7: Full-Surface Pointer Event Listener for Hardware-Accelerated Input
          if (!isPanMode)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Duplicate',
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .duplicateSelected(widget.pageId);
              },
            ),
            IconButton(
              tooltip: 'Copy to Clipboard',
              icon: const Icon(Icons.content_copy, size: 18),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .copySelected(widget.pageId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Strokes copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: 'Delete Selected',
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.red,
              ),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .deleteSelected(widget.pageId);
              },
            ),
            const VerticalDivider(width: 8, thickness: 1),
            IconButton(
              tooltip: 'Deselect',
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .clearSelection(widget.pageId);
              },
            ),
          ],
        ),
      ),
    );
  }
}
