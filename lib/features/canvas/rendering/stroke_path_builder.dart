import 'dart:math' as math;
import 'dart:ui';

import '../../../data/models/stroke_model.dart';

/// Builder responsible for converting discrete vector [StrokePoint]s into
/// mathematically smooth, hardware-accelerated Flutter [Path]s and [Paint] configurations.
class StrokePathBuilder {
  const StrokePathBuilder();

  /// Builds a rendered representation for a completed or in-progress [Stroke].
  /// Returns a [RenderedStrokePath] containing the path and appropriate [Paint].
  RenderedStrokePath build(Stroke stroke) {
    if (stroke.points.isEmpty) {
      return RenderedStrokePath(path: Path(), paint: Paint());
    }

    switch (stroke.tool) {
      case ToolType.ballpointPen:
        return _buildBallpointPen(stroke);
      case ToolType.fountainPen:
        return _buildFountainPen(stroke);
      case ToolType.brushPen:
        return _buildBrushPen(stroke);
      case ToolType.pencil:
        return _buildPencil(stroke);
      case ToolType.highlighter:
        return _buildHighlighter(stroke);
      case ToolType.eraser:
        return _buildEraser(stroke);
      case ToolType.laserPointer:
        return _buildLaserPointer(stroke);
      case ToolType.shape:
        return _buildShape(stroke);
      case ToolType.lasso:
        return _buildLasso(stroke);
      case ToolType.pan:
        return RenderedStrokePath(path: Path(), paint: Paint());
    }
  }

  /// Ballpoint Pen: Smooth continuous Catmull-Rom/Bezier curve with stable, constant stroke width.
  RenderedStrokePath _buildBallpointPen(Stroke stroke) {
    final path = _buildSmoothCenterline(stroke.points);
    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    return RenderedStrokePath(path: path, paint: paint);
  }

  /// Fountain Pen: Calligraphic dynamic width extrusion based on pressure and stroke angle.
  RenderedStrokePath _buildFountainPen(Stroke stroke) {
    final points = stroke.points;
    if (points.length < 2) {
      final path = Path()
        ..addOval(
          Rect.fromCircle(
            center: points.first.offset,
            radius: stroke.width * (0.3 + 0.7 * points.first.pressure),
          ),
        );
      final paint = Paint()
        ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      return RenderedStrokePath(path: path, paint: paint);
    }

    final outlinePath = _buildExtrudedOutline(
      points,
      baseWidth: stroke.width,
      pressureFactor: 1.2,
      minWidthRatio: 0.35,
      maxWidthRatio: 1.8,
      calligraphicAngle: math.pi / 4.0, // 45-degree nib slant
    );

    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    return RenderedStrokePath(path: outlinePath, paint: paint);
  }

  /// Brush Pen: Wide pressure dynamic range with elastic taper.
  RenderedStrokePath _buildBrushPen(Stroke stroke) {
    final points = stroke.points;
    if (points.length < 2) {
      final path = Path()
        ..addOval(
          Rect.fromCircle(
            center: points.first.offset,
            radius: stroke.width * (0.2 + 1.2 * points.first.pressure),
          ),
        );
      final paint = Paint()
        ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;
      return RenderedStrokePath(path: path, paint: paint);
    }

    final outlinePath = _buildExtrudedOutline(
      points,
      baseWidth: stroke.width,
      pressureFactor: 1.8,
      minWidthRatio: 0.2,
      maxWidthRatio: 2.4,
      calligraphicAngle: null,
    );

    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    return RenderedStrokePath(path: outlinePath, paint: paint);
  }

  /// Pencil: Slightly textured line with pressure-sensitive opacity and width.
  RenderedStrokePath _buildPencil(Stroke stroke) {
    final path = _buildSmoothCenterline(stroke.points);
    final avgPressure = stroke.points.isEmpty
        ? 0.5
        : stroke.points.map((p) => p.pressure).reduce((a, b) => a + b) /
              stroke.points.length;

    final effectiveOpacity = (stroke.opacity * (0.4 + 0.6 * avgPressure)).clamp(
      0.1,
      1.0,
    );

    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: effectiveOpacity)
      ..strokeWidth = stroke.width * (0.7 + 0.5 * avgPressure)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    return RenderedStrokePath(path: path, paint: paint);
  }

  /// Highlighter: Semi-transparent chisel stroke with flat caps and multiply blend mode.
  RenderedStrokePath _buildHighlighter(Stroke stroke) {
    final path = _buildSmoothCenterline(stroke.points);
    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    return RenderedStrokePath(path: path, paint: paint);
  }

  /// Eraser: Preview path for eraser swipe.
  RenderedStrokePath _buildEraser(Stroke stroke) {
    final path = _buildSmoothCenterline(stroke.points);
    final paint = Paint()
      ..color =
          const Color(0x66FF5252) // Semi-transparent red indicator
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    return RenderedStrokePath(path: path, paint: paint);
  }

  /// Laser Pointer: High-visibility neon glowing pointer trail.
  RenderedStrokePath _buildLaserPointer(Stroke stroke) {
    final path = _buildSmoothCenterline(stroke.points);
    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);

    return RenderedStrokePath(path: path, paint: paint);
  }

  /// Shape Tool: Auto-fits strokes into geometric primitives (line, rect, oval).
  RenderedStrokePath _buildShape(Stroke stroke) {
    final points = stroke.points;
    final path = Path();

    if (points.length < 3) {
      if (points.isNotEmpty) {
        path.moveTo(points.first.x, points.first.y);
        for (final p in points) {
          path.lineTo(p.x, p.y);
        }
      }
    } else {
      final first = points.first.offset;
      final last = points.last.offset;
      final isClosed = (first - last).distance < 30.0;
      final bbox = stroke.boundingBox;

      if (isClosed) {
        // Decide between circle/oval and rectangle based on aspect ratio and area
        final rectArea = bbox.width * bbox.height;
        final approxRadius = (bbox.width + bbox.height) / 4.0;
        final circleArea = math.pi * approxRadius * approxRadius;

        if ((rectArea - circleArea).abs() < rectArea * 0.35 &&
            (bbox.width / (bbox.height > 0 ? bbox.height : 1.0) - 1.0).abs() <
                0.3) {
          // Circle or Oval
          path.addOval(bbox);
        } else {
          // Rounded Rectangle
          path.addRRect(
            RRect.fromRectAndRadius(bbox, const Radius.circular(8.0)),
          );
        }
      } else {
        // Straight line between start and end
        path.moveTo(first.dx, first.dy);
        path.lineTo(last.dx, last.dy);
      }
    }

    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    return RenderedStrokePath(path: path, paint: paint);
  }

  /// Lasso Tool: Dashed selection loop.
  RenderedStrokePath _buildLasso(Stroke stroke) {
    final path = _buildSmoothCenterline(stroke.points);
    final paint = Paint()
      ..color = const Color(0xFF0284C7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    return RenderedStrokePath(path: path, paint: paint);
  }

  /// Generates a smooth centerline Path using midpoint quadratic Bezier splines.
  static Path _buildSmoothCenterline(List<StrokePoint> points) {
    final path = Path();
    if (points.isEmpty) return path;

    if (points.length == 1) {
      path.addOval(Rect.fromCircle(center: points.first.offset, radius: 0.5));
      return path;
    }

    if (points.length == 2) {
      path.moveTo(points[0].x, points[0].y);
      path.lineTo(points[1].x, points[1].y);
      return path;
    }

    path.moveTo(points[0].x, points[0].y);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i].offset;
      final p1 = points[i + 1].offset;
      final mid = Offset((p0.dx + p1.dx) / 2.0, (p0.dy + p1.dy) / 2.0);

      if (i == 0) {
        path.lineTo(mid.dx, mid.dy);
      } else {
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
    }

    path.lineTo(points.last.x, points.last.y);
    return path;
  }

  /// Builds a variable-width extruded outline ribbon as a closed polygon [Path].
  /// Computes perpendicular normal vectors for each point, offset by instantaneous width.
  static Path _buildExtrudedOutline(
    List<StrokePoint> points, {
    required double baseWidth,
    required double pressureFactor,
    required double minWidthRatio,
    required double maxWidthRatio,
    double? calligraphicAngle,
  }) {
    final count = points.length;
    final leftSide = <Offset>[];
    final rightSide = <Offset>[];

    for (int i = 0; i < count; i++) {
      final curr = points[i].offset;
      final pressure = points[i].pressure.clamp(0.0, 1.0);

      // Determine local tangent vector
      Offset tangent;
      if (i == 0) {
        tangent = points[1].offset - curr;
      } else if (i == count - 1) {
        tangent = curr - points[i - 1].offset;
      } else {
        tangent = points[i + 1].offset - points[i - 1].offset;
      }

      final len = tangent.distance;
      if (len == 0) {
        tangent = const Offset(1, 0);
      } else {
        tangent = Offset(tangent.dx / len, tangent.dy / len);
      }

      // Normal perpendicular to tangent (-dy, dx)
      Offset normal = Offset(-tangent.dy, tangent.dx);

      // Compute dynamic half-width
      double widthMultiplier = 1.0;
      if (calligraphicAngle != null) {
        // Modulate with nib angle
        final strokeAngle = math.atan2(tangent.dy, tangent.dx);
        final angleDiff = (strokeAngle - calligraphicAngle).abs();
        final angleFactor = math.sin(angleDiff).abs().clamp(0.25, 1.0);
        widthMultiplier = (0.4 + 0.6 * pressure * pressureFactor) * angleFactor;
      } else {
        widthMultiplier =
            (minWidthRatio +
            (maxWidthRatio - minWidthRatio) * pressure * pressureFactor);
      }

      final halfWidth = (baseWidth * widthMultiplier) / 2.0;

      leftSide.add(curr + (normal * halfWidth));
      rightSide.add(curr - (normal * halfWidth));
    }

    // Stitch outline: left side forward -> round cap -> right side backward -> round cap
    final path = Path();
    if (leftSide.isEmpty) return path;

    path.moveTo(leftSide.first.dx, leftSide.first.dy);

    for (int i = 1; i < leftSide.length; i++) {
      path.lineTo(leftSide[i].dx, leftSide[i].dy);
    }

    // End cap
    final lastPoint = points.last.offset;
    final lastNormal = leftSide.last - lastPoint;
    path.arcToPoint(
      rightSide.last,
      radius: Radius.circular(lastNormal.distance),
      clockwise: true,
    );

    // Right side backward
    for (int i = rightSide.length - 2; i >= 0; i--) {
      path.lineTo(rightSide[i].dx, rightSide[i].dy);
    }

    // Start cap
    final firstPoint = points.first.offset;
    final firstNormal = leftSide.first - firstPoint;
    path.arcToPoint(
      leftSide.first,
      radius: Radius.circular(firstNormal.distance),
      clockwise: true,
    );

    path.close();
    return path;
  }
}

/// A container combining a compiled geometric [Path] with its rendering [Paint].
class RenderedStrokePath {
  final Path path;
  final Paint paint;

  const RenderedStrokePath({required this.path, required this.paint});
}
