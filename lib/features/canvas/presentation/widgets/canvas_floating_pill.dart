import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable glassmorphic floating pill container following Nayak Notes design tokens.
///
/// Features:
/// - Light surface: #FFFFFF at 88% opacity (Color(0xE0FFFFFF))
/// - Dark surface: #1E1E22 at 88% opacity (Color(0xE01E1E22))
/// - BackdropFilter 12px Gaussian blur
/// - 1px border: rgba(0,0,0,0.08) in light mode, rgba(255,255,255,0.10) in dark mode
/// - 999px pill border radius for docks, custom radius for cards/popovers
/// - Soft ambient shadow: 0 8px 24px rgba(0,0,0,0.08)
class CanvasFloatingPill extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final double? elevation;
  final Color? customSurfaceColor;

  const CanvasFloatingPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.margin,
    this.borderRadius = 999.0,
    this.onTap,
    this.elevation,
    this.customSurfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surfaceColor = customSurfaceColor ??
        (isDark ? const Color(0xE01E1E22) : const Color(0xE0FFFFFF));
    final borderColor = isDark
        ? const Color(0x1AFFFFFF) // rgba(255,255,255,0.10)
        : const Color(0x14000000); // rgba(0,0,0,0.08)

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (margin != null) {
      return Padding(
        padding: margin!,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(borderRadius),
                child: content,
              )
            : content,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}

