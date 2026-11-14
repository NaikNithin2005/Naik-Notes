import 'dart:convert';
import 'dart:ui';

/// Tools supported by the Naik Notes handwriting engine.
enum ToolType {
  ballpointPen('ballpoint_pen', 'Ballpoint Pen', 2.0, 1.0),
  fountainPen('fountain_pen', 'Fountain Pen', 3.0, 1.0),
  pencil('pencil', 'Pencil', 2.5, 0.85),
  brushPen('brush_pen', 'Brush Pen', 4.5, 1.0),
  highlighter('highlighter', 'Highlighter', 16.0, 0.35),
  eraser('eraser', 'Eraser', 20.0, 1.0),
  lasso('lasso', 'Lasso Select', 1.0, 1.0),
  shape('shape', 'Shape Tool', 2.5, 1.0),
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

  static ToolType fromId(String id) {
    return ToolType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => ToolType.ballpointPen,
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
