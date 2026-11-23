import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/shape_model.dart';
import '../../../data/models/stroke_model.dart';

/// Notifier driving the ultra-low-latency active canvas layer at 60-120 FPS
/// without triggering Flutter widget tree rebuilds.
class ActiveCanvasNotifier extends ChangeNotifier {
  Stroke? _activeStroke;
  List<Offset> _lassoPoints = [];
  Offset? _cursorPosition;
  Offset? _previousPosition;
  double _pointerAngle = 0.0;
  double _pointerVelocity = 0.0;
  bool _isDrawing = false;
  bool _isStylus = false;
  ToolType _activeTool = ToolType.ballpointPen;
  Color _activeColor = Colors.black;
  double _activeWidth = 3.0;
  double _eraserRadius = 20.0;
  bool _isErasing = false;

  // Shape creation preview
  Offset? _shapeStartPoint;
  ShapeType? _shapeType;
  bool _snappingEnabled = false;

  // Marching ants animation tick for lasso
  double _animationTick = 0.0;

  // Getters
  Stroke? get activeStroke => _activeStroke;
  List<Offset> get lassoPoints => _lassoPoints;
  Offset? get cursorPosition => _cursorPosition;
  double get pointerAngle => _pointerAngle;
  double get pointerVelocity => _pointerVelocity;
  bool get isDrawing => _isDrawing;
  bool get isStylus => _isStylus;
  ToolType get activeTool => _activeTool;
  Color get activeColor => _activeColor;
  double get activeWidth => _activeWidth;
  double get eraserRadius => _eraserRadius;
  bool get isErasing => _isErasing;
  Offset? get shapeStartPoint => _shapeStartPoint;
  ShapeType? get shapeType => _shapeType;
  bool get snappingEnabled => _snappingEnabled;
  double get animationTick => _animationTick;

  void startStroke(Stroke stroke, {required bool isStylus, required ToolType tool, required Color color, required double width}) {
    _activeStroke = stroke;
    _isDrawing = true;
    _isStylus = isStylus;
    _activeTool = tool;
    _activeColor = color;
    _activeWidth = width;
    _isErasing = tool == ToolType.eraser;
    if (stroke.points.isNotEmpty) {
      _cursorPosition = stroke.points.last.offset;
      _previousPosition = _cursorPosition;
    }
    notifyListeners();
  }

  void updateStrokePoint(StrokePoint point) {
    if (_activeStroke == null) return;
    _previousPosition = _cursorPosition;
    _cursorPosition = point.offset;

    if (_previousPosition != null) {
      final dx = _cursorPosition!.dx - _previousPosition!.dx;
      final dy = _cursorPosition!.dy - _previousPosition!.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > 0.5) {
        _pointerAngle = math.atan2(dy, dx);
        _pointerVelocity = dist.clamp(0.0, 30.0);
      }
    }

    final updatedPoints = List<StrokePoint>.from(_activeStroke!.points)..add(point);
    _activeStroke = _activeStroke!.copyWith(points: updatedPoints);
    notifyListeners();
  }

  void updateCursor(Offset? pos, {bool? isErasing, double? radius}) {
    _cursorPosition = pos;
    if (isErasing != null) _isErasing = isErasing;
    if (radius != null) _eraserRadius = radius;
    notifyListeners();
  }

  void startShape({required Offset start, required ShapeType shape, required bool snapping}) {
    _shapeStartPoint = start;
    _shapeType = shape;
    _snappingEnabled = snapping;
    _cursorPosition = start;
    _isDrawing = true;
    notifyListeners();
  }

  void updateShape(Stroke shape) {
    _activeStroke = shape;
    if (shape.points.isNotEmpty) {
      _cursorPosition = shape.points.last.offset;
    }
    notifyListeners();
  }

  void startLasso(Offset start) {
    _lassoPoints = [start];
    _cursorPosition = start;
    _isDrawing = true;
    notifyListeners();
  }

  void updateLasso(Offset point) {
    _lassoPoints.add(point);
    _cursorPosition = point;
    notifyListeners();
  }

  void tickAnimation(double tick) {
    _animationTick = tick;
    if (_lassoPoints.isNotEmpty) {
      notifyListeners();
    }
  }

  void clearActive() {
    _activeStroke = null;
    _lassoPoints = [];
    _shapeStartPoint = null;
    _shapeType = null;
    _isDrawing = false;
    _pointerVelocity = 0.0;
    notifyListeners();
  }
}

