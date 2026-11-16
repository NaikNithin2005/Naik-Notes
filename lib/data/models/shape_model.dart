import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Categories of geometric shapes supported in Naik Notes.
enum ShapeCategory {
  basic('basic', 'Basic Shapes'),
  advanced('advanced', 'Advanced Shapes');

  final String id;
  final String displayName;
  const ShapeCategory(this.id, this.displayName);
}

/// All 27 supported geometric shapes in the Naik Notes drawing engine.
enum ShapeType {
  // --- 17 Basic Shapes ---
  straightLine('straight_line', 'Straight Line', ShapeCategory.basic),
  arrow('arrow', 'Arrow', ShapeCategory.basic),
  doubleArrow('double_arrow', 'Double Arrow', ShapeCategory.basic),
  rectangle('rectangle', 'Rectangle', ShapeCategory.basic),
  square('square', 'Square', ShapeCategory.basic),
  roundedRectangle(
    'rounded_rectangle',
    'Rounded Rectangle',
    ShapeCategory.basic,
  ),
  circle('circle', 'Circle', ShapeCategory.basic),
  ellipse('ellipse', 'Ellipse', ShapeCategory.basic),
  triangle('triangle', 'Triangle', ShapeCategory.basic),
  rightAngledTriangle(
    'right_angled_triangle',
    'Right Triangle',
    ShapeCategory.basic,
  ),
  equilateralTriangle(
    'equilateral_triangle',
    'Equilateral Triangle',
    ShapeCategory.basic,
  ),
  diamond('diamond', 'Diamond', ShapeCategory.basic),
  parallelogram('parallelogram', 'Parallelogram', ShapeCategory.basic),
  trapezoid('trapezoid', 'Trapezoid', ShapeCategory.basic),
  pentagon('pentagon', 'Pentagon', ShapeCategory.basic),
  hexagon('hexagon', 'Hexagon', ShapeCategory.basic),
  octagon('octagon', 'Octagon', ShapeCategory.basic),

  // --- 10 Advanced Shapes ---
  star('star', 'Star', ShapeCategory.advanced),
  heart('heart', 'Heart', ShapeCategory.advanced),
  arc('arc', 'Arc', ShapeCategory.advanced),
  sector('sector', 'Sector', ShapeCategory.advanced),
  pieShape('pie_shape', 'Pie Shape', ShapeCategory.advanced),
  curvedLine('curved_line', 'Curved Line', ShapeCategory.advanced),
  speechBubble('speech_bubble', 'Speech Bubble', ShapeCategory.advanced),
  bracket('bracket', 'Bracket', ShapeCategory.advanced),
  coordinateAxes('coordinate_axes', 'Coordinate Axes', ShapeCategory.advanced),
  mathematicalGraph(
    'mathematical_graph',
    'Mathematical Graph',
    ShapeCategory.advanced,
  );

  final String id;
  final String displayName;
  final ShapeCategory category;
  const ShapeType(this.id, this.displayName, this.category);

  static ShapeType fromId(String? id) {
    return ShapeType.values.firstWhere(
      (s) => s.id == id,
      orElse: () => ShapeType.rectangle,
    );
  }

  /// Whether this shape is open/linear (i.e. not closed/fillable).
  bool get isLineLike =>
      this == straightLine ||
      this == arrow ||
      this == doubleArrow ||
      this == curvedLine ||
      this == arc ||
      this == bracket ||
      this == coordinateAxes;

  /// Whether the shape naturally defaults to 1:1 aspect ratio.
  bool get isSquareAspect =>
      this == square ||
      this == circle ||
      this == equilateralTriangle ||
      this == star ||
      this == pentagon ||
      this == hexagon ||
      this == octagon;
}

/// Geometric path generation engine for all 27 shapes.
class ShapeGeometry {
  const ShapeGeometry._();

  /// Whether this shape represents a closed geometric polygon/curve that can be filled.
  static bool isClosedShape(ShapeType shape) =>
      !shape.isLineLike && shape != ShapeType.mathematicalGraph;

  /// Builds a smooth Flutter [Path] for the given [shape] bounded by [rect].
  static Path buildPath(
    ShapeType shape,
    Rect rect, {
    bool constrainProportions = false,
    double rotation = 0.0,
  }) {
    Rect effectiveRect = rect;
    if (constrainProportions || shape.isSquareAspect) {
      final size = math.min(rect.width.abs(), rect.height.abs());
      final left = rect.width < 0 ? rect.right - size : rect.left;
      final top = rect.height < 0 ? rect.bottom - size : rect.top;
      effectiveRect = Rect.fromLTWH(left, top, size, size);
    }

    final l = effectiveRect.left;
    final t = effectiveRect.top;
    final r = effectiveRect.right;
    final b = effectiveRect.bottom;
    final w = effectiveRect.width;
    final h = effectiveRect.height;
    final cx = effectiveRect.center.dx;
    final cy = effectiveRect.center.dy;

    final path = Path();

    switch (shape) {
      case ShapeType.straightLine:
        path.moveTo(l, t);
        path.lineTo(r, b);
        break;

      case ShapeType.arrow:
        _buildArrow(path, Offset(l, t), Offset(r, b), doubleHead: false);
        break;

      case ShapeType.doubleArrow:
        _buildArrow(path, Offset(l, t), Offset(r, b), doubleHead: true);
        break;

      case ShapeType.rectangle:
      case ShapeType.square:
        path.addRect(effectiveRect);
        break;

      case ShapeType.roundedRectangle:
        final radius = Radius.circular(math.min(w, h) * 0.18);
        path.addRRect(RRect.fromRectAndRadius(effectiveRect, radius));
        break;

      case ShapeType.circle:
      case ShapeType.ellipse:
        path.addOval(effectiveRect);
        break;

      case ShapeType.triangle:
        path.moveTo(cx, t);
        path.lineTo(r, b);
        path.lineTo(l, b);
        path.close();
        break;

      case ShapeType.rightAngledTriangle:
        path.moveTo(l, t);
        path.lineTo(l, b);
        path.lineTo(r, b);
        path.close();
        break;

      case ShapeType.equilateralTriangle:
        final side = math.min(w, h);
        final height = side * (math.sqrt(3) / 2.0);
        path.moveTo(cx, cy - (height / 2.0));
        path.lineTo(cx + (side / 2.0), cy + (height / 2.0));
        path.lineTo(cx - (side / 2.0), cy + (height / 2.0));
        path.close();
        break;

      case ShapeType.diamond:
        path.moveTo(cx, t);
        path.lineTo(r, cy);
        path.lineTo(cx, b);
        path.lineTo(l, cy);
        path.close();
        break;

      case ShapeType.parallelogram:
        final slant = w * 0.22;
        path.moveTo(l + slant, t);
        path.lineTo(r, t);
        path.lineTo(r - slant, b);
        path.lineTo(l, b);
        path.close();
        break;

      case ShapeType.trapezoid:
        final inset = w * 0.2;
        path.moveTo(l + inset, t);
        path.lineTo(r - inset, t);
        path.lineTo(r, b);
        path.lineTo(l, b);
        path.close();
        break;

      case ShapeType.pentagon:
        _buildRegularPolygon(
          path,
          cx,
          cy,
          math.min(w, h) / 2.0,
          5,
          -math.pi / 2.0,
        );
        break;

      case ShapeType.hexagon:
        _buildRegularPolygon(
          path,
          cx,
          cy,
          math.min(w, h) / 2.0,
          6,
          -math.pi / 2.0,
        );
        break;

      case ShapeType.octagon:
        _buildRegularPolygon(
          path,
          cx,
          cy,
          math.min(w, h) / 2.0,
          8,
          -math.pi / 8.0,
        );
        break;

      case ShapeType.star:
        _buildStar(path, cx, cy, math.min(w, h) / 2.0, 5);
        break;

      case ShapeType.heart:
        _buildHeart(path, effectiveRect);
        break;

      case ShapeType.arc:
        path.addArc(effectiveRect, math.pi, math.pi);
        break;

      case ShapeType.sector:
        path.moveTo(cx, cy);
        path.arcTo(effectiveRect, -math.pi / 4.0, math.pi / 2.0, false);
        path.close();
        break;

      case ShapeType.pieShape:
        path.moveTo(cx, cy);
        path.arcTo(effectiveRect, -math.pi / 6.0, (4.0 * math.pi) / 3.0, false);
        path.close();
        break;

      case ShapeType.curvedLine:
        path.moveTo(l, b);
        path.cubicTo(
          l + w * 0.25,
          t - h * 0.2,
          l + w * 0.75,
          b + h * 0.2,
          r,
          t,
        );
        break;

      case ShapeType.speechBubble:
        _buildSpeechBubble(path, effectiveRect);
        break;

      case ShapeType.bracket:
        _buildBracket(path, effectiveRect);
        break;

      case ShapeType.coordinateAxes:
        _buildCoordinateAxes(path, effectiveRect);
        break;

      case ShapeType.mathematicalGraph:
        _buildMathematicalGraph(path, effectiveRect);
        break;
    }

    if (rotation != 0.0) {
      final matrix = Matrix4.identity()
        ..translate(cx, cy)
        ..rotateZ(rotation)
        ..translate(-cx, -cy);
      return path.transform(matrix.storage);
    }

    return path;
  }

  static void _buildArrow(
    Path path,
    Offset start,
    Offset end, {
    required bool doubleHead,
  }) {
    path.moveTo(start.dx, start.dy);
    path.lineTo(end.dx, end.dy);

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const arrowLen = 14.0;
    const arrowAngle = math.pi / 6.0;

    // End arrow head
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowLen * math.cos(angle - arrowAngle),
      end.dy - arrowLen * math.sin(angle - arrowAngle),
    );
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowLen * math.cos(angle + arrowAngle),
      end.dy - arrowLen * math.sin(angle + arrowAngle),
    );

    if (doubleHead) {
      path.moveTo(start.dx, start.dy);
      path.lineTo(
        start.dx + arrowLen * math.cos(angle - arrowAngle),
        start.dy + arrowLen * math.sin(angle - arrowAngle),
      );
      path.moveTo(start.dx, start.dy);
      path.lineTo(
        start.dx + arrowLen * math.cos(angle + arrowAngle),
        start.dy + arrowLen * math.sin(angle + arrowAngle),
      );
    }
  }

  static void _buildRegularPolygon(
    Path path,
    double cx,
    double cy,
    double radius,
    int sides,
    double startAngle,
  ) {
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + (i * 2.0 * math.pi / sides);
      final px = cx + radius * math.cos(angle);
      final py = cy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
  }

  static void _buildStar(
    Path path,
    double cx,
    double cy,
    double outerRadius,
    int points,
  ) {
    final innerRadius = outerRadius * 0.42;
    final totalSteps = points * 2;
    final stepAngle = math.pi / points;

    for (int i = 0; i < totalSteps; i++) {
      final r = (i % 2 == 0) ? outerRadius : innerRadius;
      final angle = -math.pi / 2.0 + (i * stepAngle);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
  }

  static void _buildHeart(Path path, Rect rect) {
    final w = rect.width;
    final h = rect.height;
    final l = rect.left;
    final t = rect.top;

    path.moveTo(l + w / 2.0, t + h * 0.85);
    path.cubicTo(
      l + w * 0.1,
      t + h * 0.55,
      l,
      t + h * 0.25,
      l + w * 0.25,
      t + h * 0.1,
    );
    path.cubicTo(
      l + w * 0.42,
      t,
      l + w * 0.48,
      t + h * 0.15,
      l + w * 0.5,
      t + h * 0.28,
    );
    path.cubicTo(
      l + w * 0.52,
      t + h * 0.15,
      l + w * 0.58,
      t,
      l + w * 0.75,
      t + h * 0.1,
    );
    path.cubicTo(
      l + w,
      t + h * 0.25,
      l + w * 0.9,
      t + h * 0.55,
      l + w / 2.0,
      t + h * 0.85,
    );
    path.close();
  }

  static void _buildSpeechBubble(Path path, Rect rect) {
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final h = rect.height;
    final tailHeight = h * 0.22;
    final bodyRect = Rect.fromLTRB(l, t, r, b - tailHeight);
    final rradius = Radius.circular(math.min(rect.width, rect.height) * 0.15);

    path.addRRect(RRect.fromRectAndRadius(bodyRect, rradius));
    // Tail
    final tailLeft = l + rect.width * 0.2;
    final tailRight = l + rect.width * 0.38;
    final tailTip = Offset(l + rect.width * 0.12, b);

    path.moveTo(tailLeft, b - tailHeight);
    path.lineTo(tailTip.dx, tailTip.dy);
    path.lineTo(tailRight, b - tailHeight);
  }

  static void _buildBracket(Path path, Rect rect) {
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final midY = rect.center.dy;
    final depth = rect.width * 0.45;

    // Left curly bracket
    path.moveTo(l + depth, t);
    path.quadraticBezierTo(l, t, l, t + (midY - t) / 2.0);
    path.quadraticBezierTo(l, midY, l - depth * 0.4, midY);
    path.quadraticBezierTo(l, midY, l, midY + (b - midY) / 2.0);
    path.quadraticBezierTo(l, b, l + depth, b);

    // Right curly bracket
    path.moveTo(r - depth, t);
    path.quadraticBezierTo(r, t, r, t + (midY - t) / 2.0);
    path.quadraticBezierTo(r, midY, r + depth * 0.4, midY);
    path.quadraticBezierTo(r, midY, r, midY + (b - midY) / 2.0);
    path.quadraticBezierTo(r, b, r - depth, b);
  }

  static void _buildCoordinateAxes(Path path, Rect rect) {
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    // X axis (horizontal)
    path.moveTo(l, cy);
    path.lineTo(r, cy);
    // X arrow
    path.moveTo(r - 8, cy - 5);
    path.lineTo(r, cy);
    path.lineTo(r - 8, cy + 5);

    // Y axis (vertical)
    path.moveTo(cx, b);
    path.lineTo(cx, t);
    // Y arrow
    path.moveTo(cx - 5, t + 8);
    path.lineTo(cx, t);
    path.lineTo(cx + 5, t + 8);
  }

  static void _buildMathematicalGraph(Path path, Rect rect) {
    _buildCoordinateAxes(path, rect);

    // Light grid lines inside the rect
    final l = rect.left;
    final t = rect.top;
    final r = rect.right;
    final b = rect.bottom;
    const divisions = 4;
    final dx = (r - l) / divisions;
    final dy = (b - t) / divisions;

    for (int i = 1; i < divisions; i++) {
      if ((l + i * dx - rect.center.dx).abs() > 2) {
        path.moveTo(l + i * dx, t);
        path.lineTo(l + i * dx, b);
      }
      if ((t + i * dy - rect.center.dy).abs() > 2) {
        path.moveTo(l, t + i * dy);
        path.lineTo(r, t + i * dy);
      }
    }
  }
}
