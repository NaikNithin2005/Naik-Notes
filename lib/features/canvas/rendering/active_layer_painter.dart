import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../data/models/stroke_model.dart';
import 'active_canvas_notifier.dart';
import 'stroke_path_builder.dart';

/// Ultra-low latency CustomPainter driving the active canvas layer:
/// - In-progress vector stroke
/// - Live pen nib animation
/// - Visual eraser ring
/// - Live lasso marching ants
/// - Live shape ghost preview
class ActiveLayerPainter extends CustomPainter {
  final ActiveCanvasNotifier notifier;
  final StrokePathBuilder _builder = const StrokePathBuilder();

  ActiveLayerPainter({required this.notifier}) : super(repaint: notifier);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. In-progress Stroke or Shape
    final activeStroke = notifier.activeStroke;
    if (activeStroke != null) {
      if (activeStroke.points.length == 1) {
        // Quick tap: render a clean, round ink dot sized to stroke width
        final pt = activeStroke.points.first.offset;
        final dotRadius = (activeStroke.width / 2.0).clamp(1.0, 40.0);
        final dotPaint = Paint()
          ..color = Color(activeStroke.colorValue).withValues(alpha: activeStroke.opacity)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawCircle(pt, dotRadius, dotPaint);
      } else if (activeStroke.points.length > 1 || activeStroke.shapeType != null) {
        final rendered = _builder.build(activeStroke);
        if (rendered.fillPath != null && rendered.fillPaint != null) {
          canvas.drawPath(rendered.fillPath!, rendered.fillPaint!);
        }
        canvas.drawPath(rendered.path, rendered.paint);
      }
    }

    // 2. Live Lasso Marching Ants
    final lassoPoints = notifier.lassoPoints;
    if (lassoPoints.length > 1) {
      final path = Path();
      path.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
      for (int i = 1; i < lassoPoints.length; i++) {
        path.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
      }

      // Subtle translucent fill inside closed polygon
      if (lassoPoints.length > 2) {
        final fillPath = Path.from(path)..close();
        final fillPaint = Paint()
          ..color = const Color(0x140284C7) // 8% opacity tint
          ..style = PaintingStyle.fill;
        canvas.drawPath(fillPath, fillPaint);
      }

      // Animated marching ants dashed border
      _drawMarchingAnts(canvas, path, notifier.animationTick);
    }

    // 3. Crisp Eraser Cursor Ring
    final cursor = notifier.cursorPosition;
    if (cursor != null && notifier.isErasing) {
      final r = notifier.eraserRadius;
      // Dual-ring for high contrast on both light and dark paper
      final outerRingPaint = Paint()
        ..color = Colors.black38
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      final innerRingPaint = Paint()
        ..color = const Color(0xFFEF4444) // Red accent
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(cursor, r, outerRingPaint);
      canvas.drawCircle(cursor, r, innerRingPaint);
      // Subtle center dot
      canvas.drawCircle(cursor, 1.5, innerRingPaint..style = PaintingStyle.fill);
    }

    // 4. Live Pen Nib Animation
    if (cursor != null && notifier.isDrawing && !notifier.isErasing && activeStroke?.tool != ToolType.shape) {
      _drawLiveNib(canvas, cursor);
    }
  }

  /// Draws a live directional pen nib following the active pointer
  void _drawLiveNib(Canvas canvas, Offset position) {
    final angle = notifier.pointerAngle;
    final velocity = notifier.pointerVelocity;
    final color = notifier.activeColor;
    final strokeWidth = notifier.activeWidth;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final nibRadius = (strokeWidth / 2.0).clamp(2.0, 12.0);
    final stretch = (velocity / 15.0).clamp(0.0, 6.0);

    // Subtle glow / halo behind nib
    final haloPaint = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-stretch * 0.5, 0),
        width: (nibRadius * 2.8) + stretch,
        height: nibRadius * 2.8,
      ),
      haloPaint,
    );

    // Outer directional nib ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-stretch * 0.4, 0),
        width: (nibRadius * 2.0) + stretch,
        height: nibRadius * 2.0,
      ),
      ringPaint,
    );

    // Core nib tip
    final corePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, nibRadius * 0.7, corePaint);

    canvas.restore();
  }

  /// Draws marching ants animated dashed line
  void _drawMarchingAnts(Canvas canvas, Path path, double phase) {
    final antPaint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const dashLength = 6.0;
    const dashGap = 4.0;
    const totalPeriod = dashLength + dashGap;
    final offsetPhase = phase % totalPeriod;

    for (final metric in path.computeMetrics()) {
      double distance = offsetPhase;
      while (distance < metric.length) {
        final start = distance;
        final end = math.min(distance + dashLength, metric.length);
        if (end > start) {
          final extract = metric.extractPath(start, end);
          canvas.drawPath(extract, antPaint);
        }
        distance += totalPeriod;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ActiveLayerPainter oldDelegate) => true;
}

