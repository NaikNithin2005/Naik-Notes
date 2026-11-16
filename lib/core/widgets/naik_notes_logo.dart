import 'package:flutter/material.dart';

/// Presentation variants for the official Naik Notes logo.
enum LogoVariant { primary, iconOnly, monochrome, dark, reading }

/// Official vector-rendered logo for Naik Notes.
///
/// Combines an elegant fountain pen quill seamlessly merging into open
/// notebook pages and an ink stroke forming the letter "N".
class NaikNotesLogo extends StatelessWidget {
  final double size;
  final LogoVariant variant;
  final bool showText;
  final TextStyle? textStyle;

  const NaikNotesLogo({
    super.key,
    this.size = 48.0,
    this.variant = LogoVariant.primary,
    this.showText = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget logoIcon = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _NaikNotesLogoPainter(variant: variant, isDarkTheme: isDark),
      ),
    );

    if (!showText) {
      return logoIcon;
    }

    final textColor = switch (variant) {
      LogoVariant.monochrome => isDark ? Colors.white : Colors.black87,
      LogoVariant.dark => Colors.white,
      LogoVariant.reading => const Color(0xFF3E2723),
      _ => isDark ? Colors.white : theme.colorScheme.primary,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        SizedBox(width: size * 0.25),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Naik Notes',
              style:
                  textStyle ??
                  TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: size * 0.48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: textColor,
                  ),
            ),
            Text(
              'CREATIVE HANDWRITING',
              style: TextStyle(
                fontSize: size * 0.16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NaikNotesLogoPainter extends CustomPainter {
  final LogoVariant variant;
  final bool isDarkTheme;

  _NaikNotesLogoPainter({required this.variant, required this.isDarkTheme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background squircle container
    final RRect containerRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(w * 0.26),
    );

    final bgPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;

    Color startGradient;
    Color endGradient;
    Color emblemColor1;
    Color emblemColor2;

    switch (variant) {
      case LogoVariant.monochrome:
        startGradient = isDarkTheme
            ? const Color(0xFF262626)
            : const Color(0xFFF5F5F5);
        endGradient = isDarkTheme
            ? const Color(0xFF171717)
            : const Color(0xFFE5E5E5);
        borderPaint.color = isDarkTheme
            ? const Color(0xFF404040)
            : const Color(0xFFD4D4D4);
        emblemColor1 = isDarkTheme ? Colors.white : const Color(0xFF171717);
        emblemColor2 = isDarkTheme
            ? const Color(0xFFA3A3A3)
            : const Color(0xFF525252);
        break;
      case LogoVariant.reading:
        startGradient = const Color(0xFFF5ECD7);
        endGradient = const Color(0xFFEADBBE);
        borderPaint.color = const Color(0xFFD7C29E);
        emblemColor1 = const Color(0xFF4E342E);
        emblemColor2 = const Color(0xFF8D6E63);
        break;
      case LogoVariant.dark:
        startGradient = const Color(0xFF1E293B);
        endGradient = const Color(0xFF0F172A);
        borderPaint.color = const Color(0xFF334155);
        emblemColor1 = const Color(0xFF38BDF8);
        emblemColor2 = const Color(0xFF818CF8);
        break;
      case LogoVariant.primary:
      case LogoVariant.iconOnly:
        startGradient = const Color(0xFF0284C7);
        endGradient = const Color(0xFF1E40AF);
        borderPaint.color = const Color(0xFF38BDF8).withValues(alpha: 0.6);
        emblemColor1 = Colors.white;
        emblemColor2 = const Color(0xFFE0F2FE);
        break;
    }

    bgPaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [startGradient, endGradient],
    ).createShader(containerRRect.outerRect);

    canvas.drawRRect(containerRRect, bgPaint);
    canvas.drawRRect(containerRRect, borderPaint);

    // Vector Emblem: Folded notebook page + Fountain pen quill "N" monogram
    final quillPath = Path();
    // Left vertical spine stroke of "N" / notebook margin
    quillPath.moveTo(w * 0.28, h * 0.74);
    quillPath.lineTo(w * 0.28, h * 0.28);
    quillPath.cubicTo(
      w * 0.28,
      h * 0.25,
      w * 0.32,
      h * 0.24,
      w * 0.35,
      h * 0.27,
    );

    // Diagonal ink stroke across "N"
    quillPath.lineTo(w * 0.65, h * 0.68);
    quillPath.cubicTo(
      w * 0.68,
      h * 0.72,
      w * 0.72,
      h * 0.71,
      w * 0.72,
      h * 0.66,
    );

    // Right vertical quill spine
    quillPath.lineTo(w * 0.72, h * 0.26);

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    strokePaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [emblemColor1, emblemColor2],
    ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(quillPath, strokePaint);

    // Quill nib tip accent at the top right of the "N"
    final nibPath = Path();
    nibPath.moveTo(w * 0.72, h * 0.22);
    nibPath.lineTo(w * 0.67, h * 0.30);
    nibPath.lineTo(w * 0.77, h * 0.30);
    nibPath.close();

    final nibPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = emblemColor1;
    canvas.drawPath(nibPath, nibPaint);

    // Subtle ink droplet accent below
    final dropletPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = emblemColor2.withValues(alpha: 0.9);
    canvas.drawCircle(Offset(w * 0.72, h * 0.78), w * 0.035, dropletPaint);
  }

  @override
  bool shouldRepaint(covariant _NaikNotesLogoPainter oldDelegate) {
    return oldDelegate.variant != variant ||
        oldDelegate.isDarkTheme != isDarkTheme;
  }
}
