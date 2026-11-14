import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/stroke_model.dart';

void main() {
  group('StrokePoint Tests', () {
    test('instantiates with default values and serialization works', () {
      const point = StrokePoint(
        x: 100.5,
        y: 200.5,
        pressure: 0.75,
        tilt: 0.1,
        timestamp: 1620000000,
      );

      expect(point.x, 100.5);
      expect(point.y, 200.5);
      expect(point.offset, const Offset(100.5, 200.5));
      expect(point.pressure, 0.75);
      expect(point.tilt, 0.1);
      expect(point.timestamp, 1620000000);

      final json = point.toJson();
      final deserialized = StrokePoint.fromJson(json);

      expect(deserialized.x, point.x);
      expect(deserialized.y, point.y);
      expect(deserialized.pressure, point.pressure);
      expect(deserialized.tilt, point.tilt);
      expect(deserialized.timestamp, point.timestamp);
    });

    test('copyWith updates properties accurately', () {
      const point = StrokePoint(x: 10, y: 20, timestamp: 100);
      final updated = point.copyWith(x: 30, pressure: 0.9);

      expect(updated.x, 30);
      expect(updated.y, 20);
      expect(updated.pressure, 0.9);
      expect(updated.timestamp, 100);
    });
  });

  group('Stroke Vector & Hit-Testing Tests', () {
    final samplePoints = [
      const StrokePoint(x: 50, y: 50, timestamp: 10),
      const StrokePoint(x: 100, y: 50, timestamp: 20),
      const StrokePoint(x: 100, y: 100, timestamp: 30),
      const StrokePoint(x: 50, y: 100, timestamp: 40),
    ];

    test('computes bounding box with appropriate padding', () {
      final bbox = Stroke.computeBoundingBox(samplePoints, 4.0);
      // Width is 4.0, pad is (4.0 / 2) + 4.0 = 6.0
      // x: 50..100 -> minX - 6 = 44, maxX + 6 = 106
      // y: 50..100 -> minY - 6 = 44, maxY + 6 = 106
      expect(bbox.left, 44.0);
      expect(bbox.top, 44.0);
      expect(bbox.right, 106.0);
      expect(bbox.bottom, 106.0);
    });

    test('containsPoint detects hit along segment', () {
      final stroke = Stroke(
        id: 's-1',
        pageId: 'p-1',
        tool: ToolType.fountainPen,
        colorValue: 0xFF000000,
        width: 4.0,
        opacity: 1.0,
        points: samplePoints,
        createdAt: DateTime.now(),
      );

      // (75, 50) is directly on the top segment (50, 50) -> (100, 50)
      expect(stroke.containsPoint(const Offset(75, 50)), isTrue);

      // (75, 55) is 5 points away, well within tolerance (12.0 + 2.0 = 14.0)
      expect(stroke.containsPoint(const Offset(75, 55)), isTrue);

      // (300, 300) is far away
      expect(stroke.containsPoint(const Offset(300, 300)), isFalse);
    });

    test('isInsidePolygon detects containment within lasso polygon', () {
      final stroke = Stroke(
        id: 's-1',
        pageId: 'p-1',
        tool: ToolType.fountainPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: samplePoints,
        createdAt: DateTime.now(),
      );

      // Enclosing polygon around 0..150
      final enclosingPolygon = [
        const Offset(0, 0),
        const Offset(150, 0),
        const Offset(150, 150),
        const Offset(0, 150),
      ];
      expect(stroke.isInsidePolygon(enclosingPolygon), isTrue);

      // Disjoint polygon at 200..300
      final outsidePolygon = [
        const Offset(200, 200),
        const Offset(300, 200),
        const Offset(300, 300),
        const Offset(200, 300),
      ];
      expect(stroke.isInsidePolygon(outsidePolygon), isFalse);
    });

    test('translated shifts all points and bounding box', () {
      final stroke = Stroke(
        id: 's-1',
        pageId: 'p-1',
        tool: ToolType.ballpointPen,
        colorValue: 0xFF1E293B,
        width: 2.0,
        opacity: 1.0,
        points: samplePoints,
        createdAt: DateTime.now(),
      );

      final moved = stroke.translated(const Offset(20, -10));

      expect(moved.points.first.x, 70.0);
      expect(moved.points.first.y, 40.0);
      expect(moved.boundingBox.left, stroke.boundingBox.left + 20.0);
      expect(moved.boundingBox.top, stroke.boundingBox.top - 10.0);
    });

    test('scaled transforms points relative to origin', () {
      final stroke = Stroke(
        id: 's-1',
        pageId: 'p-1',
        tool: ToolType.brushPen,
        colorValue: 0xFF1E293B,
        width: 2.0,
        opacity: 1.0,
        points: [
          const StrokePoint(x: 100, y: 100, timestamp: 1),
          const StrokePoint(x: 200, y: 100, timestamp: 2),
        ],
        createdAt: DateTime.now(),
      );

      final scaled = stroke.scaled(2.0, 2.0, const Offset(100, 100));

      expect(scaled.points[0].x, 100.0);
      expect(scaled.points[0].y, 100.0);
      expect(scaled.points[1].x, 300.0);
      expect(scaled.points[1].y, 100.0);
    });

    test('JSON serialization roundtrip preserves all attributes', () {
      final original = Stroke(
        id: 'stroke-test-123',
        pageId: 'page-abc',
        tool: ToolType.brushPen,
        colorValue: 0xFF1D4ED8,
        width: 3.5,
        opacity: 0.85,
        points: samplePoints,
        revision: 3,
        createdAt: DateTime.parse('2026-11-14T20:00:00.000Z'),
      );

      final json = original.toJson();
      final parsed = Stroke.fromJson(json);

      expect(parsed.id, original.id);
      expect(parsed.pageId, original.pageId);
      expect(parsed.tool, original.tool);
      expect(parsed.colorValue, original.colorValue);
      expect(parsed.width, original.width);
      expect(parsed.opacity, original.opacity);
      expect(parsed.points.length, original.points.length);
      expect(parsed.revision, 3);
      expect(parsed.boundingBox.left, original.boundingBox.left);
    });
  });
}
