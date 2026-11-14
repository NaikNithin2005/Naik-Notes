import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/models/paper_template_model.dart';

/// High-performance vector CustomPainter that renders all 19 paper templates
/// with sub-millimeter precision in document coordinates.
class PaperTemplatePainter extends CustomPainter {
  final PaperTemplateType type;
  final PaperProperties properties;

  const PaperTemplatePainter({required this.type, required this.properties});

  Color _parseColor(String hex, {Color fallback = const Color(0xFFD2D6DC)}) {
    if (hex == 'transparent') return Colors.transparent;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Paper Background
    final bgColor = _parseColor(
      properties.backgroundColorHex,
      fallback: const Color(0xFFFDFBF7),
    );
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final lineColor = _parseColor(
      properties.lineColorHex,
      fallback: const Color(0xFFD2D6DC),
    );
    final accentColor = _parseColor(
      properties.accentColorHex,
      fallback: const Color(0xFFE57373),
    );

    // 2. Draw Specific Vector Template
    switch (type) {
      case PaperTemplateType.blankPaper:
        _drawBlank(canvas, size);
        break;
      case PaperTemplateType.narrowRuled:
      case PaperTemplateType.collegeRuled:
      case PaperTemplateType.wideRuled:
        _drawRuled(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.dottedPaper:
        _drawDotted(canvas, size, lineColor);
        break;
      case PaperTemplateType.squareGrid:
        _drawSquareGrid(canvas, size, lineColor);
        break;
      case PaperTemplateType.graphPaper:
        _drawGraphPaper(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.cornellNotes:
        _drawCornellNotes(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.meetingNotes:
        _drawMeetingNotes(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.dailyPlanner:
        _drawDailyPlanner(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.weeklyPlanner:
        _drawWeeklyPlanner(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.monthlyPlanner:
        _drawMonthlyPlanner(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.studyPlanner:
        _drawStudyPlanner(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.engineeringPaper:
        _drawEngineeringPaper(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.isometricPaper:
        _drawIsometricPaper(canvas, size, lineColor);
        break;
      case PaperTemplateType.musicManuscript:
        _drawMusicManuscript(canvas, size, lineColor);
        break;
      case PaperTemplateType.checklist:
        _drawChecklist(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.journalPages:
        _drawJournalPages(canvas, size, lineColor, accentColor);
        break;
      case PaperTemplateType.customTemplate:
        _drawCustom(canvas, size, lineColor, accentColor);
        break;
    }

    // 3. Draw Page Number in Footer if enabled
    if (properties.showPageNumber && properties.hasFooterArea) {
      _drawFooter(canvas, size);
    }
  }

  void _drawBlank(Canvas canvas, Size size) {
    // Elegant subtle page boundary margin guide (barely perceptible)
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(
      Rect.fromLTRB(
        properties.marginLeft,
        properties.marginTop,
        size.width - properties.marginRight,
        size.height - properties.marginBottom,
      ),
      borderPaint,
    );
  }

  void _drawRuled(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.8;

    final marginPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;

    final top = properties.marginTop;
    final bottom = size.height - properties.marginBottom;
    final spacing = properties.lineSpacing;

    // Horizontal writing lines
    for (double y = top; y <= bottom; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Left vertical margin line (classic stationery red margin)
    if (properties.marginLeft > 0) {
      canvas.drawLine(
        Offset(properties.marginLeft, 0),
        Offset(properties.marginLeft, size.height),
        marginPaint,
      );
    }
  }

  void _drawDotted(Canvas canvas, Size size, Color dotColor) {
    final dotPaint = Paint()
      ..color = dotColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final step = properties.gridSize;
    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop;
    final endY = size.height - properties.marginBottom;

    const radius = 0.95;

    for (double x = startX; x <= endX; x += step) {
      for (double y = startY; y <= endY; y += step) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }
  }

  void _drawSquareGrid(Canvas canvas, Size size, Color gridColor) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.7)
      ..strokeWidth = 0.6;

    final step = properties.gridSize;
    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop;
    final endY = size.height - properties.marginBottom;

    // Vertical lines
    for (double x = startX; x <= endX; x += step) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), gridPaint);
    }

    // Horizontal lines
    for (double y = startY; y <= endY; y += step) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), gridPaint);
    }
  }

  void _drawGraphPaper(
    Canvas canvas,
    Size size,
    Color minorColor,
    Color majorColor,
  ) {
    final minorPaint = Paint()
      ..color = minorColor.withValues(alpha: 0.5)
      ..strokeWidth = 0.4;

    final majorPaint = Paint()
      ..color = majorColor.withValues(alpha: 0.8)
      ..strokeWidth = 0.9;

    final majorStep = properties.gridSize; // 5mm
    final minorStep = majorStep / 5.0; // 1mm
    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop;
    final endY = size.height - properties.marginBottom;

    int colIndex = 0;
    for (double x = startX; x <= endX; x += minorStep, colIndex++) {
      final isMajor = (colIndex % 5 == 0);
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, endY),
        isMajor ? majorPaint : minorPaint,
      );
    }

    int rowIndex = 0;
    for (double y = startY; y <= endY; y += minorStep, rowIndex++) {
      final isMajor = (rowIndex % 5 == 0);
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  void _drawCornellNotes(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    final separatorPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..strokeWidth = 1.6;

    final cueX = properties.marginLeft; // 150 pt
    final summaryY = size.height - properties.marginBottom; // bottom summary
    final headerY = properties.marginTop; // header boundary

    // 1. Header Line
    canvas.drawLine(
      Offset(0, headerY),
      Offset(size.width, headerY),
      separatorPaint,
    );

    // 2. Left Cue Vertical Line (from header to summary)
    canvas.drawLine(
      Offset(cueX, headerY),
      Offset(cueX, summaryY),
      separatorPaint,
    );

    // 3. Summary Horizontal Line
    canvas.drawLine(
      Offset(0, summaryY),
      Offset(size.width, summaryY),
      separatorPaint,
    );

    // 4. Ruled lines in the notes section (from cueX to right margin)
    final spacing = properties.lineSpacing;
    for (double y = headerY + spacing; y < summaryY; y += spacing) {
      canvas.drawLine(
        Offset(cueX, y),
        Offset(size.width - properties.marginRight, y),
        linePaint,
      );
    }

    // 5. Ruled lines in summary section
    for (double y = summaryY + spacing; y < size.height - 16; y += spacing) {
      canvas.drawLine(
        Offset(properties.marginRight, y),
        Offset(size.width - properties.marginRight, y),
        linePaint,
      );
    }

    // 6. Section Labels
    _drawLabel(canvas, Offset(24, headerY + 12), 'CUES / QUESTIONS');
    _drawLabel(canvas, Offset(cueX + 16, headerY + 12), 'NOTES');
    _drawLabel(canvas, Offset(24, summaryY + 8), 'SUMMARY');
  }

  void _drawMeetingNotes(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final top = properties.marginTop;

    // Header info box
    final headerRect = Rect.fromLTRB(startX, top, endX, top + 64);
    canvas.drawRect(headerRect, borderPaint);

    // Header inner dividing lines
    canvas.drawLine(
      Offset(startX, top + 32),
      Offset(endX, top + 32),
      borderPaint,
    );
    canvas.drawLine(
      Offset(startX + (endX - startX) * 0.5, top),
      Offset(startX + (endX - startX) * 0.5, top + 64),
      borderPaint,
    );

    _drawLabel(canvas, Offset(startX + 8, top + 8), 'MEETING:');
    _drawLabel(
      canvas,
      Offset(startX + (endX - startX) * 0.5 + 8, top + 8),
      'DATE & TIME:',
    );
    _drawLabel(canvas, Offset(startX + 8, top + 40), 'ATTENDEES:');
    _drawLabel(
      canvas,
      Offset(startX + (endX - startX) * 0.5 + 8, top + 40),
      'LOCATION:',
    );

    // Agenda & Discussion header
    final notesTop = top + 84;
    _drawLabel(canvas, Offset(startX, notesTop), 'AGENDA & DISCUSSION');

    // Action Items Section at Bottom (180 pt high)
    final actionTop = size.height - 180;
    canvas.drawLine(
      Offset(startX, actionTop),
      Offset(endX, actionTop),
      borderPaint,
    );
    _drawLabel(canvas, Offset(startX, actionTop + 8), 'ACTION ITEMS & OWNERS');

    // Ruled lines for discussion notes
    final spacing = properties.lineSpacing;
    for (double y = notesTop + 24; y < actionTop - 12; y += spacing) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);
    }

    // Action item checklist rows
    for (double y = actionTop + 36; y < size.height - 30; y += 32) {
      // Checkbox circle
      canvas.drawCircle(Offset(startX + 10, y + 4), 6, borderPaint);
      canvas.drawLine(
        Offset(startX + 26, y + 4),
        Offset(endX - 100, y + 4),
        linePaint,
      );
      // Owner line
      canvas.drawLine(Offset(endX - 80, y + 4), Offset(endX, y + 4), linePaint);
    }
  }

  void _drawDailyPlanner(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final top = properties.marginTop;
    final midX = startX + (endX - startX) * 0.52;

    // Header Date Banner
    canvas.drawLine(
      Offset(startX, top + 24),
      Offset(endX, top + 24),
      borderPaint,
    );
    _drawLabel(canvas, Offset(startX, top), 'DAILY PLANNER & TIME BLOCKS');

    // Left Column: Hourly Schedule (6:00 to 21:00)
    final scheduleTop = top + 40;
    const hourSpacing = 36.0;
    int hour = 6;
    for (
      double y = scheduleTop;
      hour <= 21 && y < size.height - 40;
      y += hourSpacing, hour++
    ) {
      final hourStr = '${hour.toString().padLeft(2, '0')}:00';
      _drawLabel(canvas, Offset(startX, y - 2), hourStr, size: 9);
      canvas.drawLine(
        Offset(startX + 38, y + 4),
        Offset(midX - 12, y + 4),
        linePaint,
      );
    }

    // Middle separator line
    canvas.drawLine(
      Offset(midX, scheduleTop),
      Offset(midX, size.height - 40),
      borderPaint,
    );

    // Right Column: Top Priorities Box
    final priorityBox = Rect.fromLTRB(
      midX + 16,
      scheduleTop,
      endX,
      scheduleTop + 140,
    );
    canvas.drawRect(priorityBox, borderPaint);
    _drawLabel(canvas, Offset(midX + 24, scheduleTop + 8), 'TOP 3 PRIORITIES');

    for (int i = 1; i <= 3; i++) {
      final y = scheduleTop + 24.0 + (i * 32.0);
      _drawLabel(canvas, Offset(midX + 24, y), '$i.');
      canvas.drawLine(
        Offset(midX + 42, y + 8),
        Offset(endX - 12, y + 8),
        linePaint,
      );
    }

    // Right Column: To-Do Checklist below priorities
    final todoTop = scheduleTop + 160;
    _drawLabel(canvas, Offset(midX + 16, todoTop), 'TO-DO CHECKLIST');
    for (double y = todoTop + 24; y < size.height - 40; y += 26) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(midX + 16, y, 10, 10),
          const Radius.circular(2),
        ),
        borderPaint,
      );
      canvas.drawLine(Offset(midX + 34, y + 8), Offset(endX, y + 8), linePaint);
    }
  }

  void _drawWeeklyPlanner(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop + 16;
    final endY = size.height - properties.marginBottom;

    final colWidth = (endX - startX) / 7.0;
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    _drawLabel(
      canvas,
      Offset(startX, properties.marginTop - 10),
      'WEEKLY OVERVIEW',
    );

    // 7 Day Columns
    for (int i = 0; i < 7; i++) {
      final x1 = startX + (i * colWidth);
      final x2 = x1 + colWidth;
      final dayRect = Rect.fromLTRB(x1, startY, x2, endY);
      canvas.drawRect(dayRect, borderPaint);

      // Day header banner
      final headerRect = Rect.fromLTRB(x1, startY, x2, startY + 28);
      canvas.drawRect(headerRect, borderPaint);
      _drawLabel(canvas, Offset(x1 + (colWidth / 2) - 12, startY + 8), days[i]);

      // Inner faint ruled lines
      for (double y = startY + 46; y < endY - 12; y += 22) {
        canvas.drawLine(Offset(x1 + 4, y), Offset(x2 - 4, y), linePaint);
      }
    }
  }

  void _drawMonthlyPlanner(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop + 24;
    final endY = size.height - properties.marginBottom;

    final days = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final colWidth = (endX - startX) / 7.0;
    final rowHeight = (endY - startY) / 5.0;

    _drawLabel(
      canvas,
      Offset(startX, properties.marginTop),
      'MONTHLY CALENDAR',
    );

    // Day Header Row
    for (int i = 0; i < 7; i++) {
      final x1 = startX + (i * colWidth);
      _drawLabel(
        canvas,
        Offset(x1 + (colWidth / 2) - 12, properties.marginTop + 10),
        days[i],
      );
    }

    // 5 Rows x 7 Columns Grid
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 7; col++) {
        final cell = Rect.fromLTWH(
          startX + (col * colWidth),
          startY + (row * rowHeight),
          colWidth,
          rowHeight,
        );
        canvas.drawRect(cell, borderPaint);
      }
    }
  }

  void _drawStudyPlanner(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final top = properties.marginTop;

    // Header Exam Tracker
    final trackerRect = Rect.fromLTRB(startX, top, endX, top + 50);
    canvas.drawRect(trackerRect, borderPaint);
    _drawLabel(canvas, Offset(startX + 12, top + 16), 'SUBJECT / MODULE:');
    _drawLabel(
      canvas,
      Offset(startX + (endX - startX) * 0.5, top + 16),
      'EXAM DATE / TARGET:',
    );

    // Revision Topics Table
    final tableTop = top + 70;
    _drawLabel(
      canvas,
      Offset(startX, tableTop),
      'REVISION CHECKLIST & KEY CONCEPTS',
    );

    // Table Header
    final headerY = tableTop + 18;
    canvas.drawLine(
      Offset(startX, headerY),
      Offset(endX, headerY),
      borderPaint,
    );
    canvas.drawLine(
      Offset(startX, headerY + 24),
      Offset(endX, headerY + 24),
      borderPaint,
    );

    final statusX = endX - 120;
    canvas.drawLine(
      Offset(statusX, headerY),
      Offset(statusX, size.height - 40),
      borderPaint,
    );

    _drawLabel(canvas, Offset(startX + 8, headerY + 6), 'TOPIC / CHAPTER');
    _drawLabel(canvas, Offset(statusX + 16, headerY + 6), 'STATUS (R/Y/G)');

    for (double y = headerY + 48; y < size.height - 40; y += 26) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), linePaint);
      // Status pill circles
      canvas.drawCircle(Offset(statusX + 30, y - 8), 4, linePaint);
      canvas.drawCircle(Offset(statusX + 55, y - 8), 4, linePaint);
      canvas.drawCircle(Offset(statusX + 80, y - 8), 4, linePaint);
    }
  }

  void _drawEngineeringPaper(
    Canvas canvas,
    Size size,
    Color gridColor,
    Color accentColor,
  ) {
    final borderPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final top = properties.marginTop;
    final bottom = size.height - properties.marginBottom;

    // Outer Engineering Border
    canvas.drawRect(Rect.fromLTRB(startX, top, endX, bottom), borderPaint);

    // Top Engineering Title Block
    final blockHeight = properties.headerHeight;
    canvas.drawLine(
      Offset(startX, top + blockHeight),
      Offset(endX, top + blockHeight),
      borderPaint,
    );

    // Title Block Fields
    final col1 = startX + (endX - startX) * 0.4;
    final col2 = startX + (endX - startX) * 0.7;
    canvas.drawLine(
      Offset(col1, top),
      Offset(col1, top + blockHeight),
      borderPaint,
    );
    canvas.drawLine(
      Offset(col2, top),
      Offset(col2, top + blockHeight),
      borderPaint,
    );

    _drawLabel(
      canvas,
      Offset(startX + 8, top + 12),
      'PROJECT / ASSIGNMENT:',
      size: 8,
    );
    _drawLabel(canvas, Offset(col1 + 8, top + 12), 'DATE:', size: 8);
    _drawLabel(canvas, Offset(col2 + 8, top + 12), 'PAGE / ENGINEER:', size: 8);

    // Inner 5x5 Quad Grid
    final step = properties.gridSize;
    final gridTop = top + blockHeight;

    for (double x = startX + step; x < endX; x += step) {
      canvas.drawLine(Offset(x, gridTop), Offset(x, bottom), gridPaint);
    }
    for (double y = gridTop + step; y < bottom; y += step) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), gridPaint);
    }
  }

  void _drawIsometricPaper(Canvas canvas, Size size, Color gridColor) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.5;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop;
    final endY = size.height - properties.marginBottom;

    final s = properties.gridSize; // spacing
    final h = s * math.sqrt(3) / 2.0; // triangle altitude

    // Horizontal lines
    for (double y = startY; y <= endY; y += h) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), gridPaint);
    }

    // 60-degree diagonal lines (slope +tan(60°) = +sqrt(3))
    final tan60 = math.sqrt(3);
    for (double x0 = startX - (endY - startY) / tan60; x0 <= endX; x0 += s) {
      final p1 = Offset(x0, startY);
      final p2 = Offset(x0 + (endY - startY) / tan60, endY);
      canvas.drawLine(p1, p2, gridPaint);
    }

    // -60-degree diagonal lines
    for (double x0 = startX; x0 <= endX + (endY - startY) / tan60; x0 += s) {
      final p1 = Offset(x0, startY);
      final p2 = Offset(x0 - (endY - startY) / tan60, endY);
      canvas.drawLine(p1, p2, gridPaint);
    }
  }

  void _drawMusicManuscript(Canvas canvas, Size size, Color staffColor) {
    final staffPaint = Paint()
      ..color = staffColor.withValues(alpha: 0.85)
      ..strokeWidth = 0.8;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop;
    final lineSpacing = properties.lineSpacing; // 8 pt between staff lines
    final staffHeight = lineSpacing * 4.0; // 5 lines = 4 intervals
    const interStaffGap = 42.0;

    double y = startY;
    while (y + staffHeight <= size.height - properties.marginBottom) {
      // Draw 5 staff lines
      for (int i = 0; i < 5; i++) {
        final lineY = y + (i * lineSpacing);
        canvas.drawLine(Offset(startX, lineY), Offset(endX, lineY), staffPaint);
      }

      // Vertical bar lines at start and end of staff
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX, y + staffHeight),
        staffPaint,
      );
      canvas.drawLine(
        Offset(endX, y),
        Offset(endX, y + staffHeight),
        staffPaint,
      );

      y += staffHeight + interStaffGap;
    }
  }

  void _drawChecklist(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.7)
      ..strokeWidth = 0.8;

    final boxPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final startY = properties.marginTop;
    final spacing = properties.lineSpacing;

    for (
      double y = startY;
      y <= size.height - properties.marginBottom;
      y += spacing
    ) {
      // Checkbox square
      final boxRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, y - 6, 12, 12),
        const Radius.circular(3),
      );
      canvas.drawRRect(boxRect, boxPaint);

      // Writing line
      canvas.drawLine(
        Offset(startX + 22, y + 4),
        Offset(endX, y + 4),
        linePaint,
      );
    }
  }

  void _drawJournalPages(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.8)
      ..strokeWidth = 0.7;

    final startX = properties.marginLeft;
    final endX = size.width - properties.marginRight;
    final top = properties.marginTop;
    final bottom = size.height - properties.marginBottom;

    // Ornate double perimeter border
    canvas.drawRect(Rect.fromLTRB(startX, top, endX, bottom), borderPaint);
    canvas.drawRect(
      Rect.fromLTRB(startX + 4, top + 4, endX - 4, bottom - 4),
      borderPaint,
    );

    // Header Date / Mood Prompt
    _drawLabel(
      canvas,
      Offset(startX + 16, top + 14),
      'DATE: ___________________',
    );
    _drawLabel(
      canvas,
      Offset(endX - 160, top + 14),
      'WEATHER: ☼ ☁ ☂ ❄   MOOD: ★★★',
    );

    // Horizontal body lines
    final spacing = properties.lineSpacing;
    for (double y = top + 48; y <= bottom - 20; y += spacing) {
      canvas.drawLine(Offset(startX + 16, y), Offset(endX - 16, y), linePaint);
    }
  }

  void _drawCustom(
    Canvas canvas,
    Size size,
    Color lineColor,
    Color accentColor,
  ) {
    if (properties.gridSize > 0) {
      _drawSquareGrid(canvas, size, lineColor);
    } else {
      _drawRuled(canvas, size, lineColor, accentColor);
    }
  }

  void _drawFooter(Canvas canvas, Size size) {
    final footerY = size.height - (properties.footerHeight / 2);
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(properties.marginLeft, footerY - 8),
      Offset(size.width - properties.marginRight, footerY - 8),
      paint,
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset offset,
    String text, {
    double size = 9.0,
    FontWeight weight = FontWeight.w600,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black.withValues(alpha: 0.45),
          fontSize: size,
          fontWeight: weight,
          letterSpacing: 0.8,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant PaperTemplatePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.properties != properties;
  }
}
