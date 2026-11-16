import 'package:flutter/material.dart';

import '../../../data/models/stroke_model.dart';
import 'stroke_path_builder.dart';

/// Highly optimized [CustomPainter] that renders a collection of vector [Stroke]s.
/// Supports viewport culling to avoid drawing strokes completely outside visible area.
class StrokePainter extends CustomPainter {
  final List<Stroke> strokes;
  final Rect? visibleBounds;
  final StrokePathBuilder _builder = const StrokePathBuilder();

  const StrokePainter({required this.strokes, this.visibleBounds});

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty) return;

    // Highlighters are painted first in a separate pass so pen ink sits on top of highlight
    final highlighters = <Stroke>[];
    final standardStrokes = <Stroke>[];

    for (final s in strokes) {
      if (s.deletedAt != null) continue;

      // Viewport culling
      if (visibleBounds != null && !visibleBounds!.overlaps(s.boundingBox)) {
        continue;
      }

      if (s.tool == ToolType.highlighter) {
        highlighters.add(s);
      } else {
        standardStrokes.add(s);
      }
    }

    // Pass 1: Render highlighters
    if (highlighters.isNotEmpty) {
      canvas.saveLayer(Offset.zero & size, Paint());
      for (final s in highlighters) {
        final rendered = _builder.build(s);
        canvas.drawPath(rendered.path, rendered.paint);
      }
      canvas.restore();
    }

    // Pass 2: Render standard ink strokes (ballpoint, fountain, brush, pencil, marker, shape)
    for (final s in standardStrokes) {
      final rendered = _builder.build(s);
      if (rendered.fillPath != null && rendered.fillPaint != null) {
        canvas.drawPath(rendered.fillPath!, rendered.fillPaint!);
      }
      canvas.drawPath(rendered.path, rendered.paint);
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) {
    if (oldDelegate.strokes.length != strokes.length) return true;
    if (oldDelegate.visibleBounds != visibleBounds) return true;
    // Fast pointer check or revision check
    for (int i = 0; i < strokes.length; i++) {
      if (strokes[i].id != oldDelegate.strokes[i].id ||
          strokes[i].revision != oldDelegate.strokes[i].revision) {
        return true;
      }
    }
    return false;
  }
}
