import 'package:flutter/material.dart';

/// Clean, authentic vector icon representing the official Google 'G'.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final double scale = s / 24.0;

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Blue segment: horizontal bar and upper right arc
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path();
    bluePath.moveTo(23.75 * scale, 12.25 * scale);
    bluePath.cubicTo(
      23.75 * scale,
      11.45 * scale,
      23.68 * scale,
      10.7 * scale,
      23.55 * scale,
      10.0 * scale,
    );
    bluePath.lineTo(12.0 * scale, 10.0 * scale);
    bluePath.lineTo(12.0 * scale, 14.75 * scale);
    bluePath.lineTo(18.6 * scale, 14.75 * scale);
    bluePath.cubicTo(
      18.3 * scale,
      16.3 * scale,
      17.4 * scale,
      17.6 * scale,
      16.1 * scale,
      18.5 * scale,
    );
    bluePath.lineTo(16.1 * scale, 21.6 * scale);
    bluePath.lineTo(20.1 * scale, 21.6 * scale);
    bluePath.cubicTo(
      22.45 * scale,
      19.45 * scale,
      23.75 * scale,
      16.25 * scale,
      23.75 * scale,
      12.25 * scale,
    );
    bluePath.close();
    canvas.drawPath(bluePath, paint);

    // Green segment: bottom arc
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path();
    greenPath.moveTo(12.0 * scale, 24.0 * scale);
    greenPath.cubicTo(
      15.24 * scale,
      24.0 * scale,
      17.96 * scale,
      22.92 * scale,
      20.1 * scale,
      21.6 * scale,
    );
    greenPath.lineTo(16.1 * scale, 18.5 * scale);
    greenPath.cubicTo(
      15.0 * scale,
      19.25 * scale,
      13.6 * scale,
      19.7 * scale,
      12.0 * scale,
      19.7 * scale,
    );
    greenPath.cubicTo(
      8.88 * scale,
      19.7 * scale,
      6.24 * scale,
      17.6 * scale,
      5.28 * scale,
      14.75 * scale,
    );
    greenPath.lineTo(1.15 * scale, 14.75 * scale);
    greenPath.lineTo(1.15 * scale, 17.95 * scale);
    greenPath.cubicTo(
      3.24 * scale,
      22.1 * scale,
      7.28 * scale,
      24.0 * scale,
      12.0 * scale,
      24.0 * scale,
    );
    greenPath.close();
    canvas.drawPath(greenPath, paint);

    // Yellow segment: left bottom arc
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path();
    yellowPath.moveTo(5.28 * scale, 14.75 * scale);
    yellowPath.cubicTo(
      5.04 * scale,
      14.0 * scale,
      4.9 * scale,
      13.2 * scale,
      4.9 * scale,
      12.0 * scale,
    );
    yellowPath.cubicTo(
      4.9 * scale,
      10.8 * scale,
      5.04 * scale,
      10.0 * scale,
      5.28 * scale,
      9.25 * scale,
    );
    yellowPath.lineTo(5.28 * scale, 6.05 * scale);
    yellowPath.lineTo(1.15 * scale, 6.05 * scale);
    yellowPath.cubicTo(
      0.42 * scale,
      7.5 * scale,
      0.0 * scale,
      9.65 * scale,
      0.0 * scale,
      12.0 * scale,
    );
    yellowPath.cubicTo(
      0.0 * scale,
      14.35 * scale,
      0.42 * scale,
      16.5 * scale,
      1.15 * scale,
      17.95 * scale,
    );
    yellowPath.lineTo(5.28 * scale, 14.75 * scale);
    yellowPath.close();
    canvas.drawPath(yellowPath, paint);

    // Red segment: top arc
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path();
    redPath.moveTo(12.0 * scale, 4.3 * scale);
    redPath.cubicTo(
      13.76 * scale,
      4.3 * scale,
      15.34 * scale,
      4.9 * scale,
      16.6 * scale,
      6.1 * scale,
    );
    redPath.lineTo(20.2 * scale, 2.5 * scale);
    redPath.cubicTo(
      18.0 * scale,
      0.45 * scale,
      15.24 * scale,
      0.0 * scale,
      12.0 * scale,
      0.0 * scale,
    );
    redPath.cubicTo(
      7.28 * scale,
      0.0 * scale,
      3.24 * scale,
      2.9 * scale,
      1.15 * scale,
      6.05 * scale,
    );
    redPath.lineTo(5.28 * scale, 9.25 * scale);
    redPath.cubicTo(
      6.24 * scale,
      6.4 * scale,
      8.88 * scale,
      4.3 * scale,
      12.0 * scale,
      4.3 * scale,
    );
    redPath.close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clean Apple silhouette icon for Apple Sign-In.
class AppleLogo extends StatelessWidget {
  final double size;
  final Color? color;

  const AppleLogo({super.key, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;
    return Icon(
      Icons.apple,
      size: size,
      color: effectiveColor,
    );
  }
}

