import 'package:flutter/material.dart';

import '../../../data/models/search_index_model.dart';

/// CustomPainter that renders visual search highlights over recognized words
/// on the canvas, with focused border decoration for the active search hit.
class SearchHighlightPainter extends CustomPainter {
  final List<WordBoundingBox> matchingBoxes;
  final int activeIndex;
  final double scale;

  SearchHighlightPainter({
    required this.matchingBoxes,
    this.activeIndex = 0,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (matchingBoxes.isEmpty) return;

    final highlightPaint = Paint()
      ..color =
          const Color(0x66FFD54F) // Soft amber/yellow highlighter
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xB3FFA000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final activeHighlightPaint = Paint()
      ..color =
          const Color(0x99FFB300) // Vibrant amber for active match
      ..style = PaintingStyle.fill;

    final activeBorderPaint = Paint()
      ..color =
          const Color(0xFFFF6F00) // Deep orange focus border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var i = 0; i < matchingBoxes.length; i++) {
      final box = matchingBoxes[i];
      final isActive = i == activeIndex;
      final rect = box.rect.inflate(3.0);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4.0));

      if (isActive) {
        // Draw focused match with glowing pulse outline
        canvas.drawRRect(rrect, activeHighlightPaint);
        canvas.drawRRect(rrect, activeBorderPaint);

        // Draw small corner accent ticks for active match
        final cornerPaint = Paint()
          ..color = const Color(0xFFD84315)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

        // Top-left tick
        canvas.drawLine(
          Offset(rect.left - 2, rect.top + 6),
          Offset(rect.left - 2, rect.top - 2),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(rect.left - 2, rect.top - 2),
          Offset(rect.left + 6, rect.top - 2),
          cornerPaint,
        );

        // Bottom-right tick
        canvas.drawLine(
          Offset(rect.right + 2, rect.bottom - 6),
          Offset(rect.right + 2, rect.bottom + 2),
          cornerPaint,
        );
        canvas.drawLine(
          Offset(rect.right + 2, rect.bottom + 2),
          Offset(rect.right - 6, rect.bottom + 2),
          cornerPaint,
        );
      } else {
        // Draw non-focused match
        canvas.drawRRect(rrect, highlightPaint);
        canvas.drawRRect(rrect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SearchHighlightPainter oldDelegate) {
    return oldDelegate.matchingBoxes != matchingBoxes ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.scale != scale;
  }
}
