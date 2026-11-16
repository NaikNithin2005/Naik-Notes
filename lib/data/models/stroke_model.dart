import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'shape_model.dart';

/// Tools supported by the Naik Notes handwriting engine.
enum ToolType {
  fountainPen('fountain_pen', 'Fountain Pen', 3.0, 1.0),
  ballpointPen('ballpoint_pen', 'Ballpoint Pen', 2.0, 1.0),
  pencil('pencil', 'Pencil', 2.5, 0.85),
  brushPen('brush_pen', 'Brush Pen', 4.5, 1.0),
  marker('marker', 'Marker', 6.0, 1.0),
  highlighter('highlighter', 'Highlighter', 16.0, 0.35),
  calligraphyPen('calligraphy_pen', 'Calligraphy Pen', 4.0, 1.0),
  technicalPen('technical_pen', 'Technical Pen', 1.5, 1.0),
  customBrush('custom_brush', 'Custom Brush', 5.0, 0.9),
  fillBucket('fill_bucket', 'Fill Bucket', 0.0, 1.0),
  eraser('eraser', 'Eraser', 20.0, 1.0),
  lasso('lasso', 'Selection Tool', 1.0, 1.0),
  shape('shape', 'Shape Tool', 2.5, 1.0),
  text('text', 'Text Tool', 16.0, 1.0),
  laserPointer('laser_pointer', 'Laser Pointer', 8.0, 0.9),
  pan('pan', 'Pan & Zoom', 0.0, 0.0);

  final String id;
  final String displayName;
  final double defaultWidth;
  final double defaultOpacity;

  const ToolType(
    this.id,
    this.displayName,
    this.defaultWidth,
    this.defaultOpacity,
  );

  bool get isWritingTool =>
      this == ToolType.fountainPen ||
      this == ToolType.ballpointPen ||
      this == ToolType.pencil ||
      this == ToolType.brushPen ||
      this == ToolType.marker ||
      this == ToolType.highlighter ||
      this == ToolType.calligraphyPen ||
      this == ToolType.technicalPen ||
      this == ToolType.customBrush;

  static ToolType fromId(String id) {
    return ToolType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => ToolType.ballpointPen,
    );
  }
}

/// Outline and stroke line patterns.
enum StrokeStyle {
  solid('solid', 'Solid'),
  dashed('dashed', 'Dashed'),
  dotted('dotted', 'Dotted');

  final String id;
  final String label;
  const StrokeStyle(this.id, this.label);

  static StrokeStyle fromId(String? id) {
    return StrokeStyle.values.firstWhere(
      (s) => s.id == id,
      orElse: () => StrokeStyle.solid,
    );
  }
}

/// A single timestamped vector point along a handwriting stroke.
class StrokePoint {
  final double x;
  final double y;
  final double pressure; // 0.0 to 1.0
  final double tilt; // in radians
  final int timestamp; // milliseconds epoch

  const StrokePoint({
    required this.x,
    required this.y,
    this.pressure = 0.5,
    this.tilt = 0.0,
    required this.timestamp,
  });

  Offset get offset => Offset(x, y);

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'pressure': pressure,
    'tilt': tilt,
    'timestamp': timestamp,
  };

  factory StrokePoint.fromJson(Map<String, dynamic> json) => StrokePoint(
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    pressure: (json['pressure'] as num?)?.toDouble() ?? 0.5,
    tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
    timestamp: json['timestamp'] as int? ?? 0,
  );

  StrokePoint copyWith({
    double? x,
    double? y,
    double? pressure,
    double? tilt,
    int? timestamp,
  }) {
    return StrokePoint(
      x: x ?? this.x,
      y: y ?? this.y,
      pressure: pressure ?? this.pressure,
      tilt: tilt ?? this.tilt,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// An immutable vector stroke rendered on a page canvas.
class Stroke {
  final String id;
  final String pageId;
  final ToolType tool;
  final int colorValue; // ARGB 32-bit int
  final double width; // in document points
  final double opacity; // 0.0 to 1.0
  final List<StrokePoint> points;
  final Rect boundingBox;
  final int revision;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final StrokeStyle strokeStyle;
  final ShapeType? shapeType;
  final int? fillColorValue;
  final double fillOpacity;
  final bool isFilled;
  final double rotation;

  Stroke({
    required this.id,
    required this.pageId,
    required this.tool,
    required this.colorValue,
    required this.width,
    required this.opacity,
    required this.points,
    Rect? boundingBox,
    this.revision = 1,
    required this.createdAt,
    this.deletedAt,
    this.strokeStyle = StrokeStyle.solid,
    this.shapeType,
    this.fillColorValue,
    this.fillOpacity = 1.0,
    this.isFilled = false,
    this.rotation = 0.0,
  }) : boundingBox = boundingBox ?? computeBoundingBox(points, width);

  Color get color => Color(colorValue).withValues(alpha: opacity);

  static Rect computeBoundingBox(List<StrokePoint> pts, double strokeWidth) {
    if (pts.isEmpty) return Rect.zero;

    double minX = pts.first.x;
    double maxX = pts.first.x;
    double minY = pts.first.y;
    double maxY = pts.first.y;

    for (final p in pts) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
    }

    final pad = (strokeWidth / 2.0) + 4.0;
    return Rect.fromLTRB(minX - pad, minY - pad, maxX + pad, maxY + pad);
  }

  /// Determines if a point is within hit-test distance of any segment in this stroke.
  bool containsPoint(Offset target, {double tolerance = 12.0}) {
    if (!boundingBox.inflate(tolerance).contains(target)) return false;

    if (points.length == 1) {
      return (points.first.offset - target).distanceSquared <=
          (tolerance * tolerance);
    }

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i].offset;
      final p2 = points[i + 1].offset;
      if (_distanceToSegment(target, p1, p2) <= tolerance + (width / 2.0)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if any point in this stroke falls within a lasso polygon.
  bool isInsidePolygon(List<Offset> polygon) {
    if (polygon.length < 3 || points.isEmpty) return false;

    // Check if stroke center or any sample point is inside
    final center = boundingBox.center;
    if (_pointInPolygon(center, polygon)) return true;

    for (int i = 0; i < points.length; i += 3) {
      if (_pointInPolygon(points[i].offset, polygon)) return true;
    }
    return false;
  }

  /// Creates a translated copy of this stroke by (dx, dy).
  Stroke translated(Offset delta) {
    final movedPoints = points
        .map((p) => p.copyWith(x: p.x + delta.dx, y: p.y + delta.dy))
        .toList();
    return copyWith(points: movedPoints, boundingBox: boundingBox.shift(delta));
  }

  /// Creates a scaled copy of this stroke relative to an origin point.
  Stroke scaled(double scaleX, double scaleY, Offset origin) {
    final scaledPoints = points.map((p) {
      final relX = p.x - origin.dx;
      final relY = p.y - origin.dy;
      return p.copyWith(
        x: origin.dx + (relX * scaleX),
        y: origin.dy + (relY * scaleY),
      );
    }).toList();

    return copyWith(
      points: scaledPoints,
      width: width * ((scaleX + scaleY) / 2.0).clamp(0.2, 5.0),
      boundingBox: computeBoundingBox(scaledPoints, width),
    );
  }

  /// Creates a rotated copy of this stroke by [angleRadians] around [origin].
  Stroke rotated(double angleRadians, Offset origin) {
    final cosA = math.cos(angleRadians);
    final sinA = math.sin(angleRadians);
    final rotatedPoints = points.map((p) {
      final relX = p.x - origin.dx;
      final relY = p.y - origin.dy;
      return p.copyWith(
        x: origin.dx + (relX * cosA - relY * sinA),
        y: origin.dy + (relX * sinA + relY * cosA),
      );
    }).toList();

    return copyWith(
      points: rotatedPoints,
      boundingBox: computeBoundingBox(rotatedPoints, width),
    );
  }

  /// Partially erases the portion of this stroke covered by the eraser circle at [eraserCenter]
  /// with [radius], splitting the remaining portions into new contiguous stroke segments.
  /// If the stroke does not intersect the circle, returns `[this]`.
  /// If the stroke is completely erased, returns an empty list `[]`.
  List<Stroke> splitByEraserCircle(
    Offset eraserCenter,
    double radius,
    String Function() idGenerator,
  ) {
    if (points.isEmpty) return [];

    // Fast bounding box intersection test
    final eraserBBox = Rect.fromCircle(center: eraserCenter, radius: radius);
    if (!boundingBox.inflate(radius).overlaps(eraserBBox)) {
      return [this];
    }

    final remainingSegments = <List<StrokePoint>>[];
    List<StrokePoint> currentSegment = [];
    bool didIntersect = false;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final dist = (pt.offset - eraserCenter).distance;
      final insideCircle = dist <= radius;

      if (insideCircle) {
        didIntersect = true;
        if (currentSegment.length >= 2) {
          remainingSegments.add(currentSegment);
        }
        currentSegment = [];
      } else {
        if (currentSegment.isNotEmpty && i > 0) {
          final pPrev = points[i - 1].offset;
          if (_distanceToSegment(eraserCenter, pPrev, pt.offset) <= radius) {
            didIntersect = true;
            if (currentSegment.length >= 2) {
              remainingSegments.add(currentSegment);
            }
            currentSegment = [];
          }
        }
        currentSegment.add(pt);
      }
    }

    // Also check if isolated 2-point stroke segment was crossed
    if (!didIntersect && points.length >= 2) {
      for (int i = 0; i < points.length - 1; i++) {
        if (_distanceToSegment(
              eraserCenter,
              points[i].offset,
              points[i + 1].offset,
            ) <=
            radius) {
          didIntersect = true;
          break;
        }
      }
      if (didIntersect) {
        // If it intersected across the segment but points were on opposite sides,
        // split or clear
        currentSegment = [];
      }
    }

    if (currentSegment.length >= 2) {
      remainingSegments.add(currentSegment);
    }

    if (!didIntersect) {
      return [this];
    }

    if (remainingSegments.isEmpty) {
      return [];
    }

    return remainingSegments.map((segment) {
      return Stroke(
        id: idGenerator(),
        pageId: pageId,
        tool: tool,
        colorValue: colorValue,
        width: width,
        opacity: opacity,
        points: segment,
        boundingBox: computeBoundingBox(segment, width),
        revision: revision + 1,
        createdAt: createdAt,
        strokeStyle: strokeStyle,
        shapeType: shapeType,
        fillColorValue: fillColorValue,
        fillOpacity: fillOpacity,
        isFilled: isFilled,
        rotation: rotation,
      );
    }).toList();
  }

  /// Partially erases the portion of this stroke covered by the square eraser with [halfSize]
  /// centered at [eraserCenter].
  List<Stroke> splitByEraserSquare(
    Offset eraserCenter,
    double halfSize,
    String Function() idGenerator,
  ) {
    if (points.isEmpty) return [];

    final eraserBBox = Rect.fromCenter(
      center: eraserCenter,
      width: halfSize * 2.0,
      height: halfSize * 2.0,
    );

    if (!boundingBox.inflate(halfSize).overlaps(eraserBBox)) {
      return [this];
    }

    final remainingSegments = <List<StrokePoint>>[];
    List<StrokePoint> currentSegment = [];
    bool didIntersect = false;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final insideSquare =
          (pt.x - eraserCenter.dx).abs() <= halfSize &&
          (pt.y - eraserCenter.dy).abs() <= halfSize;

      if (insideSquare) {
        didIntersect = true;
        if (currentSegment.length >= 2) {
          remainingSegments.add(currentSegment);
        }
        currentSegment = [];
      } else {
        if (currentSegment.isNotEmpty && i > 0) {
          final pPrev = points[i - 1].offset;
          if (_distanceToSegment(eraserCenter, pPrev, pt.offset) <= halfSize) {
            didIntersect = true;
            if (currentSegment.length >= 2) {
              remainingSegments.add(currentSegment);
            }
            currentSegment = [];
          }
        }
        currentSegment.add(pt);
      }
    }

    if (!didIntersect && points.length >= 2) {
      for (int i = 0; i < points.length - 1; i++) {
        if (_distanceToSegment(
              eraserCenter,
              points[i].offset,
              points[i + 1].offset,
            ) <=
            halfSize) {
          didIntersect = true;
          break;
        }
      }
      if (didIntersect) {
        currentSegment = [];
      }
    }

    if (currentSegment.length >= 2) {
      remainingSegments.add(currentSegment);
    }

    if (!didIntersect) return [this];
    if (remainingSegments.isEmpty) return [];

    return remainingSegments.map((segment) {
      return Stroke(
        id: idGenerator(),
        pageId: pageId,
        tool: tool,
        colorValue: colorValue,
        width: width,
        opacity: opacity,
        points: segment,
        boundingBox: computeBoundingBox(segment, width),
        revision: revision + 1,
        createdAt: createdAt,
        strokeStyle: strokeStyle,
        shapeType: shapeType,
        fillColorValue: fillColorValue,
        fillOpacity: fillOpacity,
        isFilled: isFilled,
        rotation: rotation,
      );
    }).toList();
  }

  Stroke copyWith({
    String? id,
    String? pageId,
    ToolType? tool,
    int? colorValue,
    double? width,
    double? opacity,
    List<StrokePoint>? points,
    Rect? boundingBox,
    int? revision,
    DateTime? createdAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    StrokeStyle? strokeStyle,
    ShapeType? shapeType,
    bool clearShapeType = false,
    int? fillColorValue,
    bool clearFillColorValue = false,
    double? fillOpacity,
    bool? isFilled,
    double? rotation,
  }) {
    return Stroke(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      tool: tool ?? this.tool,
      colorValue: colorValue ?? this.colorValue,
      width: width ?? this.width,
      opacity: opacity ?? this.opacity,
      points: points ?? this.points,
      boundingBox: boundingBox ?? this.boundingBox,
      revision: revision ?? this.revision,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      strokeStyle: strokeStyle ?? this.strokeStyle,
      shapeType: clearShapeType ? null : (shapeType ?? this.shapeType),
      fillColorValue: clearFillColorValue
          ? null
          : (fillColorValue ?? this.fillColorValue),
      fillOpacity: fillOpacity ?? this.fillOpacity,
      isFilled: isFilled ?? this.isFilled,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'tool': tool.id,
      'colorValue': colorValue,
      'width': width,
      'opacity': opacity,
      'points': points.map((p) => p.toJson()).toList(),
      'boundingBox': {
        'left': boundingBox.left,
        'top': boundingBox.top,
        'right': boundingBox.right,
        'bottom': boundingBox.bottom,
      },
      'revision': revision,
      'createdAt': createdAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'strokeStyle': strokeStyle.id,
      'shapeType': shapeType?.id,
      'fillColorValue': fillColorValue,
      'fillOpacity': fillOpacity,
      'isFilled': isFilled,
      'rotation': rotation,
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List<dynamic>?) ?? [];
    final pts = rawPoints
        .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
        .toList();

    Rect? bbox;
    if (json['boundingBox'] is Map<String, dynamic>) {
      final b = json['boundingBox'] as Map<String, dynamic>;
      bbox = Rect.fromLTRB(
        (b['left'] as num).toDouble(),
        (b['top'] as num).toDouble(),
        (b['right'] as num).toDouble(),
        (b['bottom'] as num).toDouble(),
      );
    }

    return Stroke(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      tool: ToolType.fromId(json['tool'] as String? ?? 'ballpoint_pen'),
      colorValue: json['colorValue'] as int? ?? 0xFF000000,
      width: (json['width'] as num?)?.toDouble() ?? 2.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      points: pts,
      boundingBox: bbox,
      revision: json['revision'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
      strokeStyle: StrokeStyle.fromId(json['strokeStyle'] as String?),
      shapeType: json['shapeType'] != null
          ? ShapeType.fromId(json['shapeType'] as String)
          : null,
      fillColorValue: json['fillColorValue'] as int?,
      fillOpacity: (json['fillOpacity'] as num?)?.toDouble() ?? 1.0,
      isFilled: json['isFilled'] as bool? ?? false,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }

  String pointsToJsonString() =>
      jsonEncode(points.map((p) => p.toJson()).toList());

  String boundingBoxToJsonString() => jsonEncode({
    'left': boundingBox.left,
    'top': boundingBox.top,
    'right': boundingBox.right,
    'bottom': boundingBox.bottom,
  });

  static double _distanceToSegment(Offset p, Offset a, Offset b) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final l2 = (dx * dx) + (dy * dy);
    if (l2 == 0) return (p - a).distance;

    final t = (((p.dx - a.dx) * dx) + ((p.dy - a.dy) * dy)) / l2;
    final clampedT = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + (clampedT * dx), a.dy + (clampedT * dy));
    return (p - proj).distance;
  }

  static bool _pointInPolygon(Offset p, List<Offset> poly) {
    bool inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      final xi = poly[i].dx, yi = poly[i].dy;
      final xj = poly[j].dx, yj = poly[j].dy;

      final intersect =
          ((yi > p.dy) != (yj > p.dy)) &&
          (p.dx < (xj - xi) * (p.dy - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }
}
