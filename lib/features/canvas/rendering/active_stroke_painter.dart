import 'package:flutter/material.dart';

import '../../../data/models/stroke_model.dart';
import 'stroke_path_builder.dart';

/// Lightweight, un-cached [CustomPainter] dedicated solely to the single active stroke
/// currently being traced by the user's stylus or touch input.
class ActiveStrokePainter extends CustomPainter {
  final Stroke? activeStroke;
  final StrokePathBuilder _builder = const StrokePathBuilder();

  const ActiveStrokePainter({this.activeStroke});

  @override
  void paint(Canvas canvas, Size size) {
    if (activeStroke == null || activeStroke!.points.isEmpty) return;

    final rendered = _builder.build(activeStroke!);
    canvas.drawPath(rendered.path, rendered.paint);
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) {
    if (oldDelegate.activeStroke == null && activeStroke != null) return true;
    if (oldDelegate.activeStroke != null && activeStroke == null) return true;
    if (activeStroke == null) return false;

    return oldDelegate.activeStroke!.points.length !=
        activeStroke!.points.length;
  }
}
