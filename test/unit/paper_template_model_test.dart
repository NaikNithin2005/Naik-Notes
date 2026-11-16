import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';

void main() {
  group('Paper Template Catalog Tests', () {
    test('contains all 19 prompt-required paper template types', () {
      expect(PaperTemplateType.values.length, 34);

      final expectedIds = [
        'mathematics_notes',
        'physics_notes',
        'chemistry_notes',
        'cornell_notes',
        'lecture_notes',
        'daily_planner',
        'weekly_planner',
        'monthly_planner',
        'habit_tracker',
        'goal_planner',
        'sketchbook',
        'bullet_journal',
        'mind_mapping',
        'creative_journal',
        'idea_notebook',
        'meeting_notes',
        'project_planner',
        'research_journal',
        'business_notes',
        'project_documentation',
        'blank_paper',
        'narrow_ruled',
        'college_ruled',
        'wide_ruled',
        'dotted_paper',
        'square_grid',
        'graph_paper',
        'study_planner',
        'engineering_paper',
        'isometric_paper',
        'music_manuscript',
        'checklist',
        'journal_pages',
        'custom_template',
      ];

      for (final id in expectedIds) {
        final match = PaperTemplateType.fromId(id);
        expect(match.id, id, reason: 'Template $id should exist');
        expect(match.displayName.isNotEmpty, true);
        expect(match.description.isNotEmpty, true);
        expect(match.category.isNotEmpty, true);
      }
    });

    test('default properties correctly configure specific templates', () {
      // Narrow ruled
      final narrow = PaperProperties.defaultFor(PaperTemplateType.narrowRuled);
      expect(narrow.lineSpacing, 18.0); // 6.35 mm
      expect(narrow.marginLeft, 64.0);

      // College ruled
      final college = PaperProperties.defaultFor(
        PaperTemplateType.collegeRuled,
      );
      expect(college.lineSpacing, 20.13); // 7.1 mm

      // Wide ruled
      final wide = PaperProperties.defaultFor(PaperTemplateType.wideRuled);
      expect(wide.lineSpacing, 24.66); // 8.7 mm

      // Dotted & Square Grid
      final dotted = PaperProperties.defaultFor(PaperTemplateType.dottedPaper);
      expect(dotted.gridSize, 14.17); // 5 mm

      // Cornell Notes
      final cornell = PaperProperties.defaultFor(
        PaperTemplateType.cornellNotes,
      );
      expect(cornell.marginLeft, 150.0); // Cue column
      expect(cornell.marginBottom, 96.0); // Summary box

      // Engineering Paper
      final engineering = PaperProperties.defaultFor(
        PaperTemplateType.engineeringPaper,
      );
      expect(engineering.hasHeaderArea, true);
      expect(
        engineering.backgroundColorHex,
        '#F2F8F4',
      ); // Engineering green tint

      // Music Manuscript
      final music = PaperProperties.defaultFor(
        PaperTemplateType.musicManuscript,
      );
      expect(music.lineSpacing, 8.0); // 5-line staff pitch
    });

    test('serializes and deserializes PaperProperties to JSON', () {
      const original = PaperProperties(
        backgroundColorHex: '#FAF0F2',
        lineColorHex: '#A0AEC0',
        accentColorHex: '#E53E3E',
        lineSpacing: 22.5,
        gridSize: 15.0,
        marginTop: 64.0,
        marginBottom: 48.0,
        marginLeft: 70.0,
        marginRight: 45.0,
        pageSize: 'Letter',
        orientation: 'landscape',
        showPageNumber: false,
      );

      final json = original.toJson();
      expect(json['backgroundColorHex'], '#FAF0F2');
      expect(json['pageSize'], 'Letter');
      expect(json['orientation'], 'landscape');
      expect(json['showPageNumber'], false);

      final deserialized = PaperProperties.fromJson(json);
      expect(deserialized.backgroundColorHex, original.backgroundColorHex);
      expect(deserialized.lineSpacing, original.lineSpacing);
      expect(deserialized.gridSize, original.gridSize);
      expect(deserialized.pageSize, original.pageSize);
      expect(deserialized.orientation, original.orientation);
      expect(deserialized.showPageNumber, original.showPageNumber);
    });

    test('calculates correct document dimensions in points', () {
      final a4Portrait = PaperProperties.getDimensions('A4', 'portrait');
      expect(a4Portrait.width, closeTo(595.28, 0.01));
      expect(a4Portrait.height, closeTo(841.89, 0.01));

      final a4Landscape = PaperProperties.getDimensions('A4', 'landscape');
      expect(a4Landscape.width, closeTo(841.89, 0.01));
      expect(a4Landscape.height, closeTo(595.28, 0.01));

      final letterPortrait = PaperProperties.getDimensions(
        'Letter',
        'portrait',
      );
      expect(letterPortrait.width, closeTo(612.0, 0.01));
      expect(letterPortrait.height, closeTo(792.0, 0.01));
    });
  });
}
