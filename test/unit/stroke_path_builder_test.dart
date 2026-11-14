import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/rendering/stroke_path_builder.dart';

void main() {
  const builder = StrokePathBuilder();

  final testPoints = [
    const StrokePoint(x: 10, y: 10, pressure: 0.2, timestamp: 1000),
    const StrokePoint(x: 50, y: 30, pressure: 0.5, timestamp: 1010),
    const StrokePoint(x: 90, y: 70, pressure: 0.8, timestamp: 1020),
    const StrokePoint(x: 130, y: 100, pressure: 0.4, timestamp: 1030),
  ];

  group('StrokePathBuilder Rendering Tests', () {
    test('renders Ballpoint Pen with smooth centerline and round cap', () {
      final stroke = Stroke(
        id: 's-ballpoint',
        pageId: 'p-1',
        tool: ToolType.ballpointPen,
        colorValue: 0xFF1E293B,
        width: 2.0,
        opacity: 1.0,
        points: testPoints,
        createdAt: DateTime.now(),
      );

      final rendered = builder.build(stroke);

      expect(rendered.path, isNotNull);
      expect(rendered.paint.style, PaintingStyle.stroke);
      expect(rendered.paint.strokeCap, StrokeCap.round);
      expect(rendered.paint.strokeWidth, 2.0);
    });

    test('renders Fountain Pen with dynamic width extruded outline fill', () {
      final stroke = Stroke(
        id: 's-fountain',
        pageId: 'p-1',
        tool: ToolType.fountainPen,
        colorValue: 0xFF1D4ED8,
        width: 3.0,
        opacity: 1.0,
        points: testPoints,
        createdAt: DateTime.now(),
      );

      final rendered = builder.build(stroke);

      expect(rendered.path, isNotNull);
      expect(rendered.paint.style, PaintingStyle.fill);
      // Closed outline path has non-empty bounds
      final bounds = rendered.path.getBounds();
      expect(bounds.width, greaterThan(100));
      expect(bounds.height, greaterThan(80));
    });

    test('renders Brush Pen with wide dynamic range extruded outline fill', () {
      final stroke = Stroke(
        id: 's-brush',
        pageId: 'p-1',
        tool: ToolType.brushPen,
        colorValue: 0xFF047857,
        width: 4.5,
        opacity: 1.0,
        points: testPoints,
        createdAt: DateTime.now(),
      );

      final rendered = builder.build(stroke);

      expect(rendered.path, isNotNull);
      expect(rendered.paint.style, PaintingStyle.fill);
    });

    test('renders Highlighter with square cap and chisel profile', () {
      final stroke = Stroke(
        id: 's-highlighter',
        pageId: 'p-1',
        tool: ToolType.highlighter,
        colorValue: 0xFFFFEB3B,
        width: 16.0,
        opacity: 0.35,
        points: testPoints,
        createdAt: DateTime.now(),
      );

      final rendered = builder.build(stroke);

      expect(rendered.path, isNotNull);
      expect(rendered.paint.style, PaintingStyle.stroke);
      expect(rendered.paint.strokeCap, StrokeCap.square);
      expect(rendered.paint.strokeWidth, 16.0);
    });

    test('renders Pencil with pressure-adjusted opacity', () {
      final stroke = Stroke(
        id: 's-pencil',
        pageId: 'p-1',
        tool: ToolType.pencil,
        colorValue: 0xFF0F172A,
        width: 2.5,
        opacity: 0.85,
        points: testPoints,
        createdAt: DateTime.now(),
      );

      final rendered = builder.build(stroke);

      expect(rendered.path, isNotNull);
      expect(rendered.paint.style, PaintingStyle.stroke);
      expect(rendered.paint.strokeCap, StrokeCap.round);
    });

    test('renders Laser Pointer with solid blur mask filter', () {
      final stroke = Stroke(
        id: 's-laser',
        pageId: 'p-1',
        tool: ToolType.laserPointer,
        colorValue: 0xFFFF0000,
        width: 8.0,
        opacity: 0.9,
        points: testPoints,
        createdAt: DateTime.now(),
      );

      final rendered = builder.build(stroke);

      expect(rendered.path, isNotNull);
      expect(rendered.paint.maskFilter, isNotNull);
    });

    test('handles single point stroke gracefully', () {
      final singlePointStroke = Stroke(
        id: 's-single',
        pageId: 'p-1',
        tool: ToolType.fountainPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: [const StrokePoint(x: 50, y: 50, timestamp: 1)],
        createdAt: DateTime.now(),
      );

      final rendered = builder.build(singlePointStroke);
      expect(rendered.path, isNotNull);
      expect(rendered.path.getBounds().isEmpty, isFalse);
    });
  });
}
