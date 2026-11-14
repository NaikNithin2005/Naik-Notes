import 'package:flutter/material.dart';

import '../../../../data/models/paper_template_model.dart';
import '../painters/paper_template_painter.dart';

/// Interactive rendering canvas for any of the 19 paper templates.
class PaperTemplateView extends StatelessWidget {
  final PaperTemplateType type;
  final PaperProperties properties;
  final double? width;
  final double? height;
  final Widget? child;

  const PaperTemplateView({
    super.key,
    required this.type,
    required this.properties,
    this.width,
    this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dims = PaperProperties.getDimensions(
      properties.pageSize,
      properties.orientation,
    );
    final targetWidth = width ?? dims.width;
    final targetHeight = height ?? dims.height;

    return Center(
      child: Container(
        width: targetWidth,
        height: targetHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(
            size: Size(targetWidth, targetHeight),
            painter: PaperTemplatePainter(type: type, properties: properties),
            child: child,
          ),
        ),
      ),
    );
  }
}
