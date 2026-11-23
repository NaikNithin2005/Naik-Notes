import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:naik_notes/data/models/canvas_element_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/data/models/shape_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/data/canvas_elements_provider.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/canvas/rendering/active_canvas_notifier.dart';
import 'package:naik_notes/features/canvas/rendering/active_layer_painter.dart';
import 'package:naik_notes/features/canvas/rendering/lasso_painter.dart';
import 'package:naik_notes/features/canvas/rendering/search_highlight_painter.dart';
import 'package:naik_notes/features/canvas/rendering/stroke_painter.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';
import 'package:naik_notes/features/templates/presentation/widgets/paper_template_view.dart';
import 'package:naik_notes/platform/models/stylus_event.dart';
import 'package:naik_notes/platform/platform_input_adapter.dart';
import 'canvas_element_widget.dart';

/// Ultra-low latency vector handwriting canvas with isolated two-layer rendering:
/// - Static Layer: Paper template & committed strokes/elements cached via RepaintBoundary
/// - Active Layer: Active inking, live nib animation, eraser ring, shape ghost trace & lasso marching ants
///   updating at 60-120 FPS via ActiveCanvasNotifier without rebuilding the widget tree.
class HandwritingCanvas extends ConsumerStatefulWidget {
  final String pageId;
  final PaperTemplateType type;
  final PaperProperties properties;
  final double width;
  final double height;
  final bool readOnly;
  final List<WordBoundingBox> searchMatches;
  final int activeSearchIndex;

  const HandwritingCanvas({
    super.key,
    required this.pageId,
    required this.type,
    required this.properties,
    required this.width,
    required this.height,
    this.readOnly = false,
    this.searchMatches = const [],
    this.activeSearchIndex = 0,
  });

  @override
  ConsumerState<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends ConsumerState<HandwritingCanvas>
    with SingleTickerProviderStateMixin {
  final _uuid = const Uuid();

  // Ultra-low latency active layer controller
  late final ActiveCanvasNotifier _activeNotifier = ActiveCanvasNotifier();
  late final AnimationController _marchingAntsController;

  Offset? _shapeStartPoint;
  bool _isStylusDetected = false;
  Offset? _selectionDragStart;
  bool _isDraggingSelection = false;
  StreamSubscription<StylusEvent>? _stylusSub;
  ToolType? _toolBeforeBarrelButton;

  // Multi-pointer ID tracking for gesture isolation & anti-zigzag engine
  final Set<int> _activePointerIds = <int>{};
  int? _activeInkingPointerId;
  bool _isMultiTouchActive = false;

  // Double-tap detection for Shape Edit Mode
  Offset? _lastTapPoint;
  int _lastTapTime = 0;

  @override
  void initState() {
    super.initState();
    _marchingAntsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _marchingAntsController.addListener(() {
      _activeNotifier.tickAnimation(_marchingAntsController.value * 10.0);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(strokesNotifierProvider.notifier)
          .loadStrokesForPage(widget.pageId);
    });
    _stylusSub = ref
        .read(platformInputAdapterProvider)
        .events
        .listen(_onStylusEvent);
  }

  @override
  void dispose() {
    _marchingAntsController.dispose();
    _activeNotifier.dispose();
    _stylusSub?.cancel();
    super.dispose();
  }

  void _onStylusEvent(StylusEvent event) {
    if (widget.readOnly || !mounted) return;

    void handleEvent() {
      if (!mounted) return;
      switch (event.type) {
        case StylusEventType.doubleTap:
          if (event.preferredAction == 'switchPrevious') {
            ref.read(activeToolProvider.notifier).togglePreviousTool();
          } else {
            ref.read(activeToolProvider.notifier).toggleEraser();
          }
          break;
        case StylusEventType.squeeze:
          ref.read(activeToolProvider.notifier).togglePreviousTool();
          break;
        case StylusEventType.buttonDown:
          _toolBeforeBarrelButton = ref.read(activeToolProvider);
          ref.read(activeToolProvider.notifier).setTool(ToolType.eraser);
          break;
        case StylusEventType.buttonUp:
          if (_toolBeforeBarrelButton != null) {
            ref
                .read(activeToolProvider.notifier)
                .setTool(_toolBeforeBarrelButton!);
            _toolBeforeBarrelButton = null;
          }
          break;
        case StylusEventType.hoverMove:
          if (event.position != null) {
            ref
                .read(stylusHoverProvider.notifier)
                .updateHover(
                  position: event.position!,
                  distance: event.distance,
                  tilt: event.tilt,
                );
          }
          break;
        case StylusEventType.hoverExit:
          ref.read(stylusHoverProvider.notifier).clearHover();
          break;
        default:
          break;
      }
    }

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => handleEvent());
    } else {
      handleEvent();
    }
  }

  @override
  void didUpdateWidget(covariant HandwritingCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId) {
      _activeNotifier.clearActive();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref
              .read(strokesNotifierProvider.notifier)
              .loadStrokesForPage(widget.pageId);
        }
      });
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

    // Stylus-only mode: when enabled, touch events never draw ink
    final stylusOnly = ref.read(stylusOnlyModeProvider);
    if (stylusOnly && event.kind == PointerDeviceKind.touch) {
      return;
    }

    // Palm rejection: if palm rejection is enabled and stylus is detected,
    // ignore normal touch events for drawing
    final palmRejection = ref.read(palmRejectionEnabledProvider);
    if (palmRejection &&
        _isStylusDetected &&
        event.kind == PointerDeviceKind.touch) {
      return;
    }

    _activePointerIds.add(event.pointer);

    // Multi-touch isolation (Anti-Zigzag): if two or more touches are detected,
    // cancel active drawing stroke immediately so no zigzag lines connect the fingers!
    if (_activePointerIds.length > 1 && !isStylus) {
      _isMultiTouchActive = true;
      _activeNotifier.clearActive();
      return;
    }

    _isMultiTouchActive = false;
    _activeInkingPointerId = event.pointer;

    final isBarrelButtonPressed = (event.buttons & kSecondaryMouseButton) != 0;
    final tool =
        (event.kind == PointerDeviceKind.invertedStylus ||
            isBarrelButtonPressed)
        ? ToolType.eraser
        : ref.read(activeToolProvider);

    if (tool == ToolType.pan) return;

    final docPoint = event.localPosition;

    // Check for double-tap on existing shapes to enter Edit Mode
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastTapPoint != null &&
        (docPoint - _lastTapPoint!).distance < 24.0 &&
        (now - _lastTapTime) < 380) {
      final strokes = ref.read(pageStrokesProvider(widget.pageId));
      for (int i = strokes.length - 1; i >= 0; i--) {
        final s = strokes[i];
        if (s.tool == ToolType.shape || s.shapeType != null) {
          if (s.boundingBox.inflate(18.0).contains(docPoint)) {
            ref.read(strokesNotifierProvider.notifier).selectStrokeAt(
                  widget.pageId,
                  docPoint,
                  tolerance: 18.0,
                );
            _lastTapPoint = null;
            return;
          }
        }
      }
    }
    _lastTapPoint = docPoint;
    _lastTapTime = now;

    // 1. Text Tool: Immediately spawn an editable text box overlay at (x, y)
    if (tool == ToolType.text) {
      final newTextElem = CanvasElement(
        id: 'elem-${_uuid.v4()}',
        pageId: widget.pageId,
        type: CanvasElementType.text,
        x: docPoint.dx.clamp(0.0, widget.width - 220),
        y: docPoint.dy.clamp(0.0, widget.height - 80),
        width: 220,
        height: 70,
        colorHex: '#0F172A',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ref.read(canvasElementsProvider.notifier).addElement(newTextElem);
      return;
    }

    // Paint Bucket Tool: Fill page background or tapped vector closed shape
    if (tool == ToolType.fillBucket) {
      final color = ref.read(strokeColorProvider);
      final strokes = ref.read(pageStrokesProvider(widget.pageId));
      Stroke? hitShape;
      for (int i = strokes.length - 1; i >= 0; i--) {
        final s = strokes[i];
        if (s.boundingBox.inflate(12.0).contains(docPoint)) {
          hitShape = s;
          break;
        }
      }
      if (hitShape != null) {
        final updatedShape = hitShape.copyWith(
          isFilled: true,
          fillColorValue: color.toARGB32(),
          fillOpacity: ref.read(strokeOpacityProvider),
          revision: hitShape.revision + 1,
        );
        ref.read(strokesNotifierProvider.notifier).saveStroke(updatedShape);
      } else {
        final hex =
            '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
        final newProps = widget.properties.copyWith(backgroundColorHex: hex);
        ref
            .read(notebookPagesProvider.notifier)
            .updatePageProperties(pageId: widget.pageId, properties: newProps);
      }
      return;
    }

    // Deselect if tapping outside lasso selection
    final selectedIds = ref.read(selectedStrokesProvider(widget.pageId));
    if (selectedIds.isNotEmpty && tool != ToolType.lasso) {
      final strokes = ref.read(pageStrokesProvider(widget.pageId));
      final bbox = _computeSelectionBoundingBox(strokes, selectedIds);
      if (bbox != null && !bbox.inflate(24.0).contains(docPoint)) {
        ref
            .read(strokesNotifierProvider.notifier)
            .clearSelection(widget.pageId);
      }
    }

    // 2. Eraser Tool: Precision cursor ring & segment splitting
    if (tool == ToolType.eraser) {
      final radius = ref.read(eraserRadiusProvider);
      final mode = ref.read(eraserModeProvider);
      _activeNotifier.updateCursor(docPoint, isErasing: true, radius: radius);
      ref
          .read(strokesNotifierProvider.notifier)
          .eraseAt(widget.pageId, docPoint, tolerance: radius, mode: mode);
      return;
    }

    // 3. Lasso Tool: Animated marching ants trace
    if (tool == ToolType.lasso) {
      if (selectedIds.isNotEmpty) {
        final strokes = ref.read(pageStrokesProvider(widget.pageId));
        final bbox = _computeSelectionBoundingBox(strokes, selectedIds);
        if (bbox != null && bbox.inflate(15.0).contains(docPoint)) {
          _isDraggingSelection = true;
          _selectionDragStart = docPoint;
          return;
        }
      }
      _isDraggingSelection = false;
      _selectionDragStart = null;
      _activeNotifier.startLasso(docPoint);
      if (!_marchingAntsController.isAnimating) {
        _marchingAntsController.repeat();
      }
      return;
    }

    // 4. Shape Tool: Live Ghost Trace Preview
    if (tool == ToolType.shape) {
      _shapeStartPoint = docPoint;
      final shapeType = ref.read(selectedShapeTypeProvider);
      final color = ref.read(strokeColorProvider);
      final width = ref.read(strokeWidthProvider);
      final opacity = ref.read(strokeOpacityProvider);
      final strokeStyle = ref.read(shapeStrokeStyleProvider);
      final isFilled = ref.read(shapeIsFilledProvider);
      final fillColor = ref.read(shapeFillColorProvider) ?? color;
      final fillOpacity = ref.read(shapeFillOpacityProvider);
      final snapping = ref.read(snappingEnabledProvider);

      final newShape = Stroke(
        id: 'stroke-${_uuid.v4()}',
        pageId: widget.pageId,
        tool: ToolType.shape,
        shapeType: shapeType,
        colorValue: color.toARGB32(),
        width: width,
        opacity: opacity,
        strokeStyle: strokeStyle,
        isFilled: isFilled,
        fillColorValue: isFilled ? fillColor.toARGB32() : null,
        fillOpacity: fillOpacity,
        boundingBox: Rect.fromPoints(docPoint, docPoint),
        points: [
          StrokePoint(x: docPoint.dx, y: docPoint.dy, timestamp: 0),
          StrokePoint(x: docPoint.dx, y: docPoint.dy, timestamp: 1),
        ],
        createdAt: DateTime.now(),
      );

      _activeNotifier.startShape(start: docPoint, shape: shapeType, snapping: snapping);
      _activeNotifier.updateShape(newShape);
      return;
    }

    // 5. Drawing Tools: Live Nib & Quadratic Curve
    final color = ref.read(strokeColorProvider);
    final width = ref.read(strokeWidthProvider);
    final opacity = ref.read(strokeOpacityProvider);
    final strokeStyle = ref.read(strokeStyleProvider);
    final pressureEnabled = ref.read(pressureSensitivityEnabledProvider);

    final initialPressure = pressureEnabled && event.pressure != 0.0
        ? event.pressure.clamp(0.05, 1.0)
        : 0.5;

    final newStroke = Stroke(
      id: 'stroke-${_uuid.v4()}',
      pageId: widget.pageId,
      tool: tool,
      colorValue: color.toARGB32(),
      width: width,
      opacity: opacity,
      strokeStyle: strokeStyle,
      points: [
        StrokePoint(
          x: docPoint.dx,
          y: docPoint.dy,
          pressure: initialPressure,
          tilt: event.tilt,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        ),
      ],
      createdAt: DateTime.now(),
    );

    _activeNotifier.startStroke(
      newStroke,
      isStylus: isStylus,
      tool: tool,
      color: color,
      width: width,
    );
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (widget.readOnly) return;
    if (_isMultiTouchActive) return;
    if (_activeInkingPointerId != null &&
        event.pointer != _activeInkingPointerId) {
      return;
    }

    final stylusOnly = ref.read(stylusOnlyModeProvider);
    if (stylusOnly && event.kind == PointerDeviceKind.touch) {
      return;
    }

    final palmRejection = ref.read(palmRejectionEnabledProvider);
    if (palmRejection &&
        _isStylusDetected &&
        event.kind == PointerDeviceKind.touch) {
      return;
    }

    final isBarrelButtonPressed = (event.buttons & kSecondaryMouseButton) != 0;
    final tool =
        (event.kind == PointerDeviceKind.invertedStylus ||
            isBarrelButtonPressed)
        ? ToolType.eraser
        : ref.read(activeToolProvider);

    if (tool == ToolType.pan || tool == ToolType.fillBucket || tool == ToolType.text) return;

    final docPoint = event.localPosition;

    if (tool == ToolType.eraser) {
      final radius = ref.read(eraserRadiusProvider);
      final mode = ref.read(eraserModeProvider);
      _activeNotifier.updateCursor(docPoint, isErasing: true, radius: radius);
      ref
          .read(strokesNotifierProvider.notifier)
          .eraseAt(widget.pageId, docPoint, tolerance: radius, mode: mode);
      return;
    }

    if (tool == ToolType.lasso) {
      if (_isDraggingSelection && _selectionDragStart != null) {
        final delta = docPoint - _selectionDragStart!;
        _selectionDragStart = docPoint;
        ref
            .read(strokesNotifierProvider.notifier)
            .translateSelected(widget.pageId, delta);
        return;
      }
      _activeNotifier.updateLasso(docPoint);
      return;
    }

    // Dynamic Shape live ghost preview with precision angle & proportion snapping
    if (tool == ToolType.shape &&
        _shapeStartPoint != null &&
        _activeNotifier.activeStroke != null) {
      var currentPoint = docPoint;
      final snapping = ref.read(snappingEnabledProvider);
      final shapeType = _activeNotifier.activeStroke!.shapeType ?? ShapeType.rectangle;

      if (snapping) {
        if (shapeType.isLineLike) {
          final dx = currentPoint.dx - _shapeStartPoint!.dx;
          final dy = currentPoint.dy - _shapeStartPoint!.dy;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist > 12) {
            final angle = math.atan2(dy, dx);
            const snapAngle = math.pi / 4.0;
            final nearestSnap = (angle / snapAngle).round() * snapAngle;
            if ((angle - nearestSnap).abs() < 0.16) {
              currentPoint = Offset(
                _shapeStartPoint!.dx + dist * math.cos(nearestSnap),
                _shapeStartPoint!.dy + dist * math.sin(nearestSnap),
              );
            }
          }
        } else if (shapeType.isSquareAspect) {
          final dx = currentPoint.dx - _shapeStartPoint!.dx;
          final dy = currentPoint.dy - _shapeStartPoint!.dy;
          final side = math.max(dx.abs(), dy.abs());
          currentPoint = Offset(
            _shapeStartPoint!.dx + side * (dx < 0 ? -1.0 : 1.0),
            _shapeStartPoint!.dy + side * (dy < 0 ? -1.0 : 1.0),
          );
        }
      }

      final shapeBBox = Rect.fromPoints(_shapeStartPoint!, currentPoint);
      final updatedShape = _activeNotifier.activeStroke!.copyWith(
        boundingBox: shapeBBox,
        points: [
          StrokePoint(
            x: _shapeStartPoint!.dx,
            y: _shapeStartPoint!.dy,
            timestamp: 0,
          ),
          StrokePoint(x: currentPoint.dx, y: currentPoint.dy, timestamp: 1),
        ],
      );
      _activeNotifier.updateShape(updatedShape);
      return;
    }

    if (!_activeNotifier.isDrawing || _activeNotifier.activeStroke == null) return;

    final pressureEnabled = ref.read(pressureSensitivityEnabledProvider);
    final pressure = pressureEnabled && event.pressure != 0.0
        ? event.pressure.clamp(0.05, 1.0)
        : 0.5;

    _activeNotifier.updateStrokePoint(
      StrokePoint(
        x: docPoint.dx,
        y: docPoint.dy,
        pressure: pressure,
        tilt: event.tilt,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void _onPointerUp(PointerUpEvent event) {
    ref.read(stylusHoverProvider.notifier).clearHover();
    _shapeStartPoint = null;

    _activePointerIds.remove(event.pointer);
    if (_activeInkingPointerId == event.pointer) {
      _activeInkingPointerId = null;
    }
    if (_activePointerIds.isEmpty) {
      _isMultiTouchActive = false;
    }
    if (_isMultiTouchActive) {
      return;
    }

    if (widget.readOnly) return;
    if (_activeInkingPointerId != null &&
        event.pointer != _activeInkingPointerId) {
      return;
    }
    _activeInkingPointerId = null;

    final isBarrelButtonPressed = (event.buttons & kSecondaryMouseButton) != 0;
    final tool =
        (event.kind == PointerDeviceKind.invertedStylus ||
            isBarrelButtonPressed)
        ? ToolType.eraser
        : ref.read(activeToolProvider);

    if (tool == ToolType.pan || tool == ToolType.fillBucket || tool == ToolType.text) {
      _activeNotifier.clearActive();
      return;
    }

    if (tool == ToolType.lasso) {
      if (_marchingAntsController.isAnimating) {
        _marchingAntsController.stop();
        _marchingAntsController.reset();
      }
      if (_isDraggingSelection) {
        _isDraggingSelection = false;
        _selectionDragStart = null;
        return;
      }
      final lassoPoints = List<Offset>.from(_activeNotifier.lassoPoints);
      _activeNotifier.clearActive();
      if (lassoPoints.length > 2) {
        ref
            .read(strokesNotifierProvider.notifier)
            .selectWithLasso(widget.pageId, lassoPoints);
      } else if (lassoPoints.isNotEmpty) {
        ref
            .read(strokesNotifierProvider.notifier)
            .selectStrokeAt(widget.pageId, lassoPoints.first);
      }
      return;
    }

    final strokeToSave = _activeNotifier.activeStroke;
    _activeNotifier.clearActive();

    if (strokeToSave != null) {
      if (strokeToSave.tool != ToolType.laserPointer) {
        ref
            .read(strokesNotifierProvider.notifier)
            .addStroke(widget.pageId, strokeToSave);
      }
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointerIds.remove(event.pointer);
    if (_activeInkingPointerId == event.pointer) {
      _activeInkingPointerId = null;
    }
    if (_activePointerIds.isEmpty) {
      _isMultiTouchActive = false;
    }
    if (_marchingAntsController.isAnimating) {
      _marchingAntsController.stop();
      _marchingAntsController.reset();
    }
    _activeNotifier.clearActive();
    _shapeStartPoint = null;
  }

  void _onPointerHover(PointerHoverEvent event) {
    if (widget.readOnly) return;
    if (event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.invertedStylus) {
      ref
          .read(stylusHoverProvider.notifier)
          .updateHover(
            position: event.localPosition,
            tilt: event.tilt,
            distance: event.distance,
          );
    }
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
    final hoverState = ref.watch(stylusHoverProvider);
    final isPanMode = activeTool == ToolType.pan || widget.readOnly;
    final canvasElements = ref.watch(pageCanvasElementsProvider(widget.pageId));
    final activeElemId = ref.watch(canvasElementsProvider).activeSelectedElementId;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // =================================================================
          // LAYER 1: STATIC LAYER (RepaintBoundary - cached in GPU texture)
          // =================================================================
          Positioned.fill(
            child: RepaintBoundary(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Vector Paper Template Background
                  Positioned.fill(
                    child: PaperTemplateView(
                      type: widget.type,
                      properties: widget.properties,
                      width: widget.width,
                      height: widget.height,
                    ),
                  ),

                  // Committed Vector Strokes
                  Positioned.fill(
                    child: CustomPaint(
                      painter: StrokePainter(
                        strokes: pageStrokes,
                        visibleBounds: Rect.fromLTWH(0, 0, widget.width, widget.height),
                      ),
                    ),
                  ),

                  // Search Highlights Layer
                  if (widget.searchMatches.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: SearchHighlightPainter(
                            matchingBoxes: widget.searchMatches,
                            activeIndex: widget.activeSearchIndex,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // =================================================================
          // LAYER 2: UNIFIED CANVAS ELEMENTS (Text, Sticky Notes, Images, Math)
          // =================================================================
          ...canvasElements.map((elem) {
            return CanvasElementWidget(
              element: elem,
              isSelected: elem.id == activeElemId,
              onSelect: () {
                ref.read(canvasElementsProvider.notifier).selectElement(elem.id);
              },
              onDeselect: () {
                ref.read(canvasElementsProvider.notifier).selectElement(null);
              },
            );
          }),

          // =================================================================
          // LAYER 3: ACTIVE LAYER (CustomPainter with repaint: notifier)
          // Drives 60-120 FPS live inking, nib animation, eraser ring,
          // shape ghost trace, and lasso marching ants with zero widget rebuilds.
          // =================================================================
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ActiveLayerPainter(notifier: _activeNotifier),
              ),
            ),
          ),

          // Stylus hover reticle cursor
          if (!isPanMode && hoverState.isHovering)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: StylusHoverPainter(
                    position: hoverState.position,
                    radius: activeTool == ToolType.eraser
                        ? ref.watch(eraserRadiusProvider)
                        : (ref.watch(strokeWidthProvider) / 2).clamp(1.5, 50.0),
                    color: activeTool == ToolType.eraser
                        ? const Color(0xFFEF4444)
                        : ref.watch(strokeColorProvider),
                  ),
                ),
              ),
            ),

          // =================================================================
          // LAYER 4: LASSO LOOP & SELECTION BOUNDING BOX
          // =================================================================
          if (selectionBox != null && !selectionBox.isEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: LassoPainter(
                    lassoPoints: const [],
                    selectionBoundingBox: selectionBox,
                  ),
                ),
              ),
            ),

          // Selection Box Interactive Drag Area (Translate)
          if (selectionBox != null && !selectionBox.isEmpty) ...[
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

            // Corner Resize Handle (Bottom-Right)
            Positioned(
              left: selectionBox.right - 12,
              top: selectionBox.bottom - 12,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final scaleX = (selectionBox.width + details.delta.dx) / selectionBox.width;
                  final scaleY = (selectionBox.height + details.delta.dy) / selectionBox.height;
                  ref.read(strokesNotifierProvider.notifier).scaleSelected(
                    widget.pageId,
                    scaleX.clamp(0.5, 3.0),
                    scaleY.clamp(0.5, 3.0),
                    selectionBox.topLeft,
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),

            // Top Rotation Handle (24px above top center)
            Positioned(
              left: selectionBox.topCenter.dx - 14,
              top: selectionBox.top - 38,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  final center = selectionBox.center;
                  final prev = Offset(selectionBox.topCenter.dx, selectionBox.top - 24);
                  final curr = prev + details.delta;
                  final angle = math.atan2(curr.dy - center.dy, curr.dx - center.dx) -
                      math.atan2(prev.dy - center.dy, prev.dx - center.dx);
                  ref.read(strokesNotifierProvider.notifier).rotateSelected(
                    widget.pageId,
                    angle,
                    center,
                  );
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],

          // Floating Selection Context Bar Above Box
          if (selectionBox != null && !selectionBox.isEmpty)
            Positioned(
              left: (selectionBox.center.dx - 140).clamp(
                10.0,
                widget.width - 290,
              ),
              top: (selectionBox.top - 54).clamp(10.0, widget.height - 60),
              child: _buildSelectionToolbar(context, selectionBox),
            ),

          // =================================================================
          // LAYER 5: HARDWARE POINTER EVENT LISTENER
          // =================================================================
          if (!isPanMode)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                onPointerHover: _onPointerHover,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionToolbar(BuildContext context, Rect selectionBox) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bring to Front
            IconButton(
              tooltip: 'Bring to Front',
              icon: const Icon(Icons.flip_to_front_rounded, size: 17),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .reorderSelected(widget.pageId, bringToFront: true);
              },
            ),

            // Send to Back
            IconButton(
              tooltip: 'Send to Back',
              icon: const Icon(Icons.flip_to_back_rounded, size: 17),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .reorderSelected(widget.pageId, bringToFront: false);
              },
            ),

            // Recolor Selection
            IconButton(
              tooltip: 'Recolor',
              icon: const Icon(Icons.palette_outlined, size: 17),
              onPressed: () => _showRecolorMenu(context),
            ),

            // Duplicate
            IconButton(
              tooltip: 'Duplicate',
              icon: const Icon(Icons.copy_rounded, size: 17),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .duplicateSelected(widget.pageId);
              },
            ),

            // Copy to Clipboard (supports cross-page paste)
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.content_copy_rounded, size: 17),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .copySelected(widget.pageId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied selection to cross-page clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),

            // Paste from Clipboard
            IconButton(
              tooltip: 'Paste Here',
              icon: const Icon(Icons.content_paste_rounded, size: 17),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .paste(widget.pageId, selectionBox.center + const Offset(20, 20));
              },
            ),

            // Delete Selected
            IconButton(
              tooltip: 'Delete Selected',
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 17,
                color: Colors.redAccent,
              ),
              onPressed: () {
                ref
                    .read(strokesNotifierProvider.notifier)
                    .deleteSelected(widget.pageId);
              },
            ),

            const VerticalDivider(width: 8, thickness: 1),

            // Deselect
            IconButton(
              tooltip: 'Deselect',
              icon: const Icon(Icons.close_rounded, size: 17),
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

  void _showRecolorMenu(BuildContext context) {
    const colors = [
      Color(0xFF0F172A),
      Color(0xFF2563EB),
      Color(0xFF0284C7),
      Color(0xFF059669),
      Color(0xFFDC2626),
      Color(0xFFD97706),
      Color(0xFF7C3AED),
      Color(0xFFEA580C),
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recolor Selection', style: TextStyle(fontSize: 16)),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors.map((col) {
            return GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                ref
                    .read(strokesNotifierProvider.notifier)
                    .recolorSelected(widget.pageId, col);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: col,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black26),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Floating reticle cursor showing exact pen width and ink color while hovering above digitizer.
class StylusHoverPainter extends CustomPainter {
  final Offset position;
  final double radius;
  final Color color;

  const StylusHoverPainter({
    required this.position,
    required this.radius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, radius, ringPaint);
    canvas.drawCircle(position, 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant StylusHoverPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.radius != radius ||
        oldDelegate.color != color;
  }
}
