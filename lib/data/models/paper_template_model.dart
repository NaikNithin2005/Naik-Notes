import 'dart:convert';

/// Complete catalog of supported paper template types in Naik Notes.
/// Features 20 distinct templates across Academic, Productivity, Creative, and Professional categories.
enum PaperTemplateType {
  // --- Academic (5) ---
  mathematicsNotes(
    'mathematics_notes',
    'Mathematics Notes',
    'Coordinate grid with formula margin and calculation zone',
    'Academic',
  ),
  physicsNotes(
    'physics_notes',
    'Physics Notes',
    'Graph layout with vector diagram box and laboratory constants column',
    'Academic',
  ),
  chemistryNotes(
    'chemistry_notes',
    'Chemistry Notes',
    'Hexagonal molecular lattice grid with reaction equation rows',
    'Academic',
  ),
  cornellNotes(
    'cornell_notes',
    'Cornell Notes',
    'Classic system with left cue column, note taking area, & bottom summary',
    'Academic',
  ),
  lectureNotes(
    'lecture_notes',
    'Lecture Notes',
    'Header block with topic, date, key takeaways, and split note columns',
    'Academic',
  ),

  // --- Productivity (5) ---
  dailyPlanner(
    'daily_planner',
    'Daily Planner',
    'Hourly schedule timetable, priorities, and to-do checklist',
    'Productivity',
  ),
  weeklyPlanner(
    'weekly_planner',
    'Weekly Planner',
    '7-day overview with weekly goals and tasks',
    'Productivity',
  ),
  monthlyPlanner(
    'monthly_planner',
    'Monthly Planner',
    'Full monthly calendar grid with notes sidebar',
    'Productivity',
  ),
  habitTracker(
    'habit_tracker',
    'Habit Tracker',
    '31-day habit checklist matrix for daily habit tracking',
    'Productivity',
  ),
  goalPlanner(
    'goal_planner',
    'Goal Planner',
    'Milestones, action items, target deadlines, and progress bars',
    'Productivity',
  ),

  // --- Creative (5) ---
  sketchbook(
    'sketchbook',
    'Sketchbook',
    'Unbounded artistic frame with subtle border margin and drawing guides',
    'Creative',
  ),
  bulletJournal(
    'bullet_journal',
    'Bullet Journal',
    '5mm dot grid matrix with key index legend',
    'Creative',
  ),
  mindMapping(
    'mind_mapping',
    'Mind Mapping',
    'Central idea node with radial branched guideline hubs',
    'Creative',
  ),
  creativeJournal(
    'creative_journal',
    'Creative Journal',
    'Split doodle sketch canvas with ruled reflective prose area',
    'Creative',
  ),
  ideaNotebook(
    'idea_notebook',
    'Idea Notebook',
    'Problem statement, concept sketch box, and execution notes',
    'Creative',
  ),

  // --- Professional (5) ---
  meetingNotes(
    'meeting_notes',
    'Meeting Notes',
    'Structured headers, agenda, attendees, and action items table',
    'Professional',
  ),
  projectPlanner(
    'project_planner',
    'Project Planner',
    'Project phases, deliverables checklist, and timeline roadmap',
    'Professional',
  ),
  researchJournal(
    'research_journal',
    'Research Journal',
    'Hypothesis, experimental methodology, observations, and findings',
    'Professional',
  ),
  businessNotes(
    'business_notes',
    'Business Notes',
    'Executive summary, KPI metrics, risk analysis, and decisions',
    'Professional',
  ),
  projectDocumentation(
    'project_documentation',
    'Project Documentation',
    'Technical architecture spec, component diagram box, and change log',
    'Professional',
  ),

  // --- Standard & Specialty Classics ---
  blankPaper(
    'blank_paper',
    'Blank Paper',
    'Clean canvas for freehand thinking',
    'Classic',
  ),
  narrowRuled(
    'narrow_ruled',
    'Narrow Ruled',
    '6.35mm compact line ruling for dense note-taking',
    'Classic',
  ),
  collegeRuled(
    'college_ruled',
    'College Ruled',
    '7.1mm standard university line ruling',
    'Classic',
  ),
  wideRuled(
    'wide_ruled',
    'Wide Ruled',
    '8.7mm spacious line ruling for larger handwriting',
    'Classic',
  ),
  dottedPaper(
    'dotted_paper',
    'Dotted Paper',
    '5mm dot grid matrix for bullet journaling',
    'Classic',
  ),
  squareGrid(
    'square_grid',
    'Square Grid',
    '5mm quad grid for math, diagrams and tables',
    'Classic',
  ),
  graphPaper(
    'graph_paper',
    'Graph Paper',
    'Precision 1mm minor lines with 5mm major grid',
    'Classic',
  ),
  studyPlanner(
    'study_planner',
    'Study Planner',
    'Subject breakdown, revision checklist and exam tracking',
    'Productivity',
  ),
  engineeringPaper(
    'engineering_paper',
    'Engineering Paper',
    'Top title block, border margins and 5x5 grid',
    'Classic',
  ),
  isometricPaper(
    'isometric_paper',
    'Isometric Paper',
    '60° triangular isometric grid for 3D sketching',
    'Classic',
  ),
  musicManuscript(
    'music_manuscript',
    'Music Manuscript',
    'Standard 5-line musical staves for composition',
    'Specialty',
  ),
  checklist(
    'checklist',
    'Checklist',
    'Checkbox circles and ruled lines for tasks & inventories',
    'Specialty',
  ),
  journalPages(
    'journal_pages',
    'Journal Pages',
    'Ornate stationery border with date, weather and lined body',
    'Specialty',
  ),
  customTemplate(
    'custom_template',
    'Custom Template',
    'User-defined line spacing, grid size, colors and margins',
    'Custom',
  );

  final String id;
  final String displayName;
  final String description;
  final String category;

  const PaperTemplateType(
    this.id,
    this.displayName,
    this.description,
    this.category,
  );

  static PaperTemplateType fromId(String id) {
    return PaperTemplateType.values.firstWhere(
      (t) => t.id == id,
      orElse: () => PaperTemplateType.collegeRuled,
    );
  }
}

/// Detailed configurable parameters for a page's paper template.
class PaperProperties {
  final String backgroundColorHex;
  final String lineColorHex;
  final String accentColorHex;
  final double lineSpacing; // in points (1 mm ≈ 2.83465 pt)
  final double gridSize; // in points
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final bool hasHeaderArea;
  final double headerHeight;
  final bool hasFooterArea;
  final double footerHeight;
  final String pageSize; // 'A4' | 'Letter' | 'A5'
  final String orientation; // 'portrait' | 'landscape'
  final bool showPageNumber;

  const PaperProperties({
    this.backgroundColorHex = '#FDFBF7', // Ivory cream paper
    this.lineColorHex = '#D2D6DC', // Muted slate rule
    this.accentColorHex = '#E57373', // Margin line / cue accent
    this.lineSpacing = 20.13, // 7.1mm standard college rule
    this.gridSize = 14.17, // 5mm grid
    this.marginTop = 56.0,
    this.marginBottom = 40.0,
    this.marginLeft = 56.0,
    this.marginRight = 40.0,
    this.hasHeaderArea = true,
    this.headerHeight = 44.0,
    this.hasFooterArea = true,
    this.footerHeight = 32.0,
    this.pageSize = 'A4',
    this.orientation = 'portrait',
    this.showPageNumber = true,
  });

  /// Factory producing recommended defaults tailored to each template type.
  factory PaperProperties.defaultFor(
    PaperTemplateType type, {
    String pageSize = 'A4',
    String orientation = 'portrait',
    String backgroundColorHex = '#FDFBF7',
  }) {
    switch (type) {
      case PaperTemplateType.mathematicsNotes:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#D2D6DC',
          accentColorHex: '#2563EB',
          gridSize: 14.17,
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 140.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.physicsNotes:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#CBD5E1',
          accentColorHex: '#4F46E5',
          gridSize: 14.17,
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 130.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.chemistryNotes:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#CBD5E1',
          accentColorHex: '#0D9488',
          gridSize: 18.0,
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.lectureNotes:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#64748B',
          lineSpacing: 22.0,
          marginTop: 64.0,
          marginBottom: 40.0,
          marginLeft: 140.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.habitTracker:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#10B981',
          lineSpacing: 24.0,
          marginTop: 60.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: 'landscape',
        );

      case PaperTemplateType.goalPlanner:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#F59E0B',
          lineSpacing: 24.0,
          marginTop: 60.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.sketchbook:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: 'transparent',
          accentColorHex: '#CBD5E1',
          marginTop: 32.0,
          marginBottom: 32.0,
          marginLeft: 32.0,
          marginRight: 32.0,
          hasHeaderArea: false,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.bulletJournal:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#94A3B8',
          gridSize: 14.17, // 5mm dot matrix
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.mindMapping:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#8B5CF6',
          marginTop: 40.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: 'landscape',
        );

      case PaperTemplateType.creativeJournal:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#EC4899',
          lineSpacing: 22.0,
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.ideaNotebook:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#F97316',
          lineSpacing: 22.0,
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.projectPlanner:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#0284C7',
          lineSpacing: 24.0,
          marginTop: 60.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: 'landscape',
        );

      case PaperTemplateType.researchJournal:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#475569',
          lineSpacing: 22.0,
          marginTop: 56.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.businessNotes:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#0F172A',
          lineSpacing: 22.0,
          marginTop: 60.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.projectDocumentation:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#2563EB',
          lineSpacing: 20.0,
          marginTop: 56.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.blankPaper:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: 'transparent',
          accentColorHex: 'transparent',
          marginTop: 40.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          hasHeaderArea: false,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.narrowRuled:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#D2D6DC',
          accentColorHex: '#E57373',
          lineSpacing: 18.0, // 6.35 mm
          marginTop: 56.0,
          marginLeft: 64.0, // Standard left margin red line
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.collegeRuled:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#D2D6DC',
          accentColorHex: '#E57373',
          lineSpacing: 20.13, // 7.1 mm
          marginTop: 56.0,
          marginLeft: 64.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.wideRuled:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#D2D6DC',
          accentColorHex: '#E57373',
          lineSpacing: 24.66, // 8.7 mm
          marginTop: 60.0,
          marginLeft: 64.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.dottedPaper:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#94A3B8', // subtle slate dots
          gridSize: 14.17, // 5 mm dot spacing
          marginTop: 40.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          hasHeaderArea: false,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.squareGrid:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0', // 5mm light grid lines
          gridSize: 14.17, // 5 mm
          marginTop: 40.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.graphPaper:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0', // 1mm minor lines
          accentColorHex: '#94A3B8', // 5mm major lines
          gridSize: 14.17, // 5mm major grid
          marginTop: 36.0,
          marginBottom: 36.0,
          marginLeft: 36.0,
          marginRight: 36.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.cornellNotes:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#CBD5E1',
          accentColorHex: '#64748B', // cue divider and summary separator
          lineSpacing: 20.13,
          marginTop: 56.0,
          marginBottom: 96.0, // bottom summary block height
          marginLeft: 150.0, // 2.5 inch left cue column
          marginRight: 36.0,
          hasHeaderArea: true,
          headerHeight: 48.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.meetingNotes:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#CBD5E1',
          accentColorHex: '#475569',
          lineSpacing: 22.0,
          marginTop: 90.0, // Header block for Title, Date, Attendees
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          hasHeaderArea: true,
          headerHeight: 80.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.dailyPlanner:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#CBD5E1',
          accentColorHex: '#334155',
          lineSpacing: 26.0,
          marginTop: 70.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.weeklyPlanner:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#475569',
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.monthlyPlanner:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#334155',
          marginTop: 60.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: 'landscape', // monthly calendars default to landscape
        );

      case PaperTemplateType.studyPlanner:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#E2E8F0',
          accentColorHex: '#1E293B',
          lineSpacing: 22.0,
          marginTop: 64.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.engineeringPaper:
        return PaperProperties(
          backgroundColorHex: '#F2F8F4', // classic engineering pale green-tint
          lineColorHex: '#C6E2D1',
          accentColorHex: '#2E7D32',
          gridSize: 14.17, // 5x5 quad
          marginTop: 50.0, // Top Engineering Header Block
          marginBottom: 36.0,
          marginLeft: 44.0,
          marginRight: 36.0,
          hasHeaderArea: true,
          headerHeight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.isometricPaper:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#CBD5E1',
          gridSize: 16.0, // triangular grid spacing
          marginTop: 40.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.musicManuscript:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#334155',
          lineSpacing: 8.0, // inter-staff line spacing (5 lines per staff)
          marginTop: 60.0,
          marginBottom: 50.0,
          marginLeft: 50.0,
          marginRight: 50.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.checklist:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          lineColorHex: '#CBD5E1',
          accentColorHex: '#94A3B8',
          lineSpacing: 24.0,
          marginTop: 50.0,
          marginBottom: 40.0,
          marginLeft: 40.0,
          marginRight: 40.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.journalPages:
        return PaperProperties(
          backgroundColorHex: '#FAF6ED', // Antique parchment
          lineColorHex: '#D8CBB5',
          accentColorHex: '#8C7355',
          lineSpacing: 22.0,
          marginTop: 64.0,
          marginBottom: 48.0,
          marginLeft: 48.0,
          marginRight: 48.0,
          hasHeaderArea: true,
          headerHeight: 52.0,
          pageSize: pageSize,
          orientation: orientation,
        );

      case PaperTemplateType.customTemplate:
        return PaperProperties(
          backgroundColorHex: backgroundColorHex,
          pageSize: pageSize,
          orientation: orientation,
        );
    }
  }

  /// Calculates page canvas dimensions in points for standard paper sizes.
  static ({double width, double height}) getDimensions(
    String pageSize,
    String orientation,
  ) {
    double w;
    double h;
    switch (pageSize.toUpperCase()) {
      case 'LETTER':
        w = 612.0;
        h = 792.0;
        break;
      case 'A5':
        w = 420.94;
        h = 595.28;
        break;
      case 'A4':
      default:
        w = 595.28;
        h = 841.89;
        break;
    }
    if (orientation.toLowerCase() == 'landscape') {
      return (width: h, height: w);
    }
    return (width: w, height: h);
  }

  PaperProperties copyWith({
    String? backgroundColorHex,
    String? lineColorHex,
    String? accentColorHex,
    double? lineSpacing,
    double? gridSize,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    bool? hasHeaderArea,
    double? headerHeight,
    bool? hasFooterArea,
    double? footerHeight,
    String? pageSize,
    String? orientation,
    bool? showPageNumber,
  }) {
    return PaperProperties(
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      lineColorHex: lineColorHex ?? this.lineColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      gridSize: gridSize ?? this.gridSize,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      hasHeaderArea: hasHeaderArea ?? this.hasHeaderArea,
      headerHeight: headerHeight ?? this.headerHeight,
      hasFooterArea: hasFooterArea ?? this.hasFooterArea,
      footerHeight: footerHeight ?? this.footerHeight,
      pageSize: pageSize ?? this.pageSize,
      orientation: orientation ?? this.orientation,
      showPageNumber: showPageNumber ?? this.showPageNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundColorHex': backgroundColorHex,
      'lineColorHex': lineColorHex,
      'accentColorHex': accentColorHex,
      'lineSpacing': lineSpacing,
      'gridSize': gridSize,
      'marginTop': marginTop,
      'marginBottom': marginBottom,
      'marginLeft': marginLeft,
      'marginRight': marginRight,
      'hasHeaderArea': hasHeaderArea,
      'headerHeight': headerHeight,
      'hasFooterArea': hasFooterArea,
      'footerHeight': footerHeight,
      'pageSize': pageSize,
      'orientation': orientation,
      'showPageNumber': showPageNumber,
    };
  }

  factory PaperProperties.fromJson(Map<String, dynamic> json) {
    return PaperProperties(
      backgroundColorHex: json['backgroundColorHex'] as String? ?? '#FDFBF7',
      lineColorHex: json['lineColorHex'] as String? ?? '#D2D6DC',
      accentColorHex: json['accentColorHex'] as String? ?? '#E57373',
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 20.13,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 14.17,
      marginTop: (json['marginTop'] as num?)?.toDouble() ?? 56.0,
      marginBottom: (json['marginBottom'] as num?)?.toDouble() ?? 40.0,
      marginLeft: (json['marginLeft'] as num?)?.toDouble() ?? 56.0,
      marginRight: (json['marginRight'] as num?)?.toDouble() ?? 40.0,
      hasHeaderArea: json['hasHeaderArea'] as bool? ?? true,
      headerHeight: (json['headerHeight'] as num?)?.toDouble() ?? 44.0,
      hasFooterArea: json['hasFooterArea'] as bool? ?? true,
      footerHeight: (json['footerHeight'] as num?)?.toDouble() ?? 32.0,
      pageSize: json['pageSize'] as String? ?? 'A4',
      orientation: json['orientation'] as String? ?? 'portrait',
      showPageNumber: json['showPageNumber'] as bool? ?? true,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static PaperProperties fromJsonString(
    String? jsonString,
    PaperTemplateType fallbackType,
  ) {
    if (jsonString == null || jsonString.isEmpty) {
      return PaperProperties.defaultFor(fallbackType);
    }
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return PaperProperties.fromJson(map);
    } catch (_) {
      return PaperProperties.defaultFor(fallbackType);
    }
  }
}
