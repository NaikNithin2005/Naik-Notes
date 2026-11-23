import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';

void main() {
  group('Page & Stroke Content Serialization Tests', () {
    test('NotebookPage JSON serialization preserves properties and dimensions', () {
      final now = DateTime(2026, 11, 23, 14, 0, 0);
      final page = NotebookPage(
        id: 'page-101',
        notebookId: 'nb-202',
        sectionId: 'sec-303',
        pageNumber: 2,
        templateId: 'dot_grid',
        properties: const PaperProperties(
          lineSpacing: 28.0,
          gridSize: 18.0,
          lineColorHex: '#E0E0E0',
          backgroundColorHex: '#FAFAFA',
          accentColorHex: '#FF5252',
          marginLeft: 64.0,
          orientation: 'portrait',
          pageSize: 'A4',
        ),
        width: 595.28,
        height: 841.89,
        isBookmarked: true,
        revision: 4,
        createdAt: now,
        updatedAt: now,
      );

      final json = page.toJson();
      expect(json['id'], 'page-101');
      expect(json['notebookId'], 'nb-202');
      expect(json['sectionId'], 'sec-303');
      expect(json['pageNumber'], 2);
      expect(json['templateId'], 'dot_grid');
      expect(json['isBookmarked'], true);
      expect(json['revision'], 4);

      final restored = NotebookPage.fromJson(json);
      expect(restored.id, page.id);
      expect(restored.notebookId, page.notebookId);
      expect(restored.properties.lineSpacing, 28.0);
      expect(restored.properties.gridSize, 18.0);
      expect(restored.properties.backgroundColorHex, '#FAFAFA');
      expect(restored.width, 595.28);
      expect(restored.height, 841.89);
    });

    test('Stroke vector serialization preserves points, pressure, and bounding box', () {
      final now = DateTime(2026, 11, 23, 15, 0, 0);
      final points = [
        const StrokePoint(x: 10.5, y: 20.5, pressure: 0.8, tilt: 0.1, timestamp: 100),
        const StrokePoint(x: 15.0, y: 25.0, pressure: 0.9, tilt: 0.2, timestamp: 116),
        const StrokePoint(x: 20.0, y: 30.0, pressure: 0.7, tilt: 0.1, timestamp: 133),
      ];

      final stroke = Stroke(
        id: 'stroke-abc-123',
        pageId: 'page-101',
        tool: ToolType.fountainPen,
        colorValue: 0xFF1E88E5,
        width: 3.5,
        opacity: 0.95,
        points: points,
        boundingBox: const Rect.fromLTRB(10.5, 20.5, 20.0, 30.0),
        revision: 2,
        createdAt: now,
      );

      final pointsJsonStr = stroke.pointsToJsonString();
      final bboxJsonStr = stroke.boundingBoxToJsonString();

      expect(pointsJsonStr.contains('"pressure":0.8'), isTrue);
      expect(bboxJsonStr.contains('"left":10.5'), isTrue);

      final jsonMap = stroke.toJson();
      expect(jsonMap['id'], 'stroke-abc-123');
      expect(jsonMap['tool'], 'fountain_pen');
      expect(jsonMap['colorValue'], 0xFF1E88E5);
      expect(jsonMap['width'], 3.5);
      expect(jsonMap['opacity'], 0.95);

      final deserialized = Stroke.fromJson(jsonMap);
      expect(deserialized.id, stroke.id);
      expect(deserialized.points.length, 3);
      expect(deserialized.points.first.pressure, 0.8);
      expect(deserialized.points.last.y, 30.0);
      expect(deserialized.tool, ToolType.fountainPen);
      expect(deserialized.boundingBox.left, 10.5);
    });

    test('Rich-text Note serialization extracts plainText and preview', () {
      const sampleDelta =
          '[{"insert":"Meeting Notes\\n"},{"insert":"Action items for Q4 launch.\\n"}]';
      final note = Note.createBlank(
        ownerId: 'user-77',
        notebookId: 'nb-99',
        title: 'Project Roadmap',
      ).copyWith(
        contentDelta: sampleDelta,
      );

      expect(note.plainText.contains('Meeting Notes'), isTrue);
      expect(note.preview.contains('Meeting Notes'), isTrue);

      final json = note.toJson();
      expect(json['title'], 'Project Roadmap');
      expect(json['contentDelta'], sampleDelta);

      final restored = Note.fromJson(json);
      expect(restored.title, 'Project Roadmap');
      expect(restored.plainText, note.plainText);
      expect(restored.preview, note.preview);
    });
  });
}
