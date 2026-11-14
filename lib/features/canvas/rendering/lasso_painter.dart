import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Painter for drawing in-progress lasso loops and the selection boundary box
/// around selected vector strokes.
class LassoPainter extends CustomPainter {
  final List<Offset> lassoPoints;
  final Rect? selectionBoundingBox;

  const LassoPainter({required this.lassoPoints, this.selectionBoundingBox});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw in-progress lasso loop if user is currently tracing one
    if (lassoPoints.length > 1) {
      final lassoPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      path.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
      for (int i = 1; i < lassoPoints.length; i++) {
        path.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
      }

      // Draw dashed stroke
      _drawDashedPath(canvas, path, lassoPaint, dashLength: 6, dashGap: 4);
    }

    // 2. Draw selection boundary box if strokes are selected
    if (selectionBoundingBox != null && !selectionBoundingBox!.isEmpty) {
      final box = selectionBoundingBox!;

      // Light cyan filled background
      final fillPaint = Paint()
        ..color = const Color(0x140284C7)
        ..style = PaintingStyle.fill;
      canvas.drawRect(box, fillPaint);

      // Dashed border
      final borderPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final boxPath = Path()..addRect(box);
      _drawDashedPath(canvas, boxPath, borderPaint, dashLength: 6, dashGap: 4);

      // Corner handles for scaling/rotating
      final handlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final handleBorderPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      const handleRadius = 6.0;
      final corners = [
        box.topLeft,
        box.topRight,
        box.bottomLeft,
        box.bottomRight,
      ];

      for (final corner in corners) {
        canvas.drawCircle(corner, handleRadius, handlePaint);
        canvas.drawCircle(corner, handleRadius, handleBorderPaint);
      }
    }
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashLength,
    required double dashGap,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        final extract = metric.extractPath(distance, end);
        canvas.drawPath(extract, paint);
        distance += dashLength + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant LassoPainter oldDelegate) {
    return oldDelegate.lassoPoints.length != lassoPoints.length ||
        oldDelegate.selectionBoundingBox != selectionBoundingBox;
  }
}
