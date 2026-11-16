import 'package:flutter/material.dart';

/// Unified typography system for Naik Notes across Light, Dark, and Reading modes.
class ThemeTypography {
  ThemeTypography._();

  static const String serifFamily = 'Georgia';

  /// Generates a complete Material 3 TextTheme styled with the provided text and secondary colors.
  static TextTheme buildTextTheme({
    required Color primaryColor,
    required Color secondaryColor,
    double scaleFactor = 1.0,
    double lineSpacingMultiplier = 1.0,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: serifFamily,
        fontSize: 34 * scaleFactor,
        fontWeight: FontWeight.w700,
        color: primaryColor,
        letterSpacing: -0.5,
        height: 1.25 * lineSpacingMultiplier,
      ),
      displayMedium: TextStyle(
        fontFamily: serifFamily,
        fontSize: 28 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.25 * lineSpacingMultiplier,
      ),
      displaySmall: TextStyle(
        fontFamily: serifFamily,
        fontSize: 22 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.3 * lineSpacingMultiplier,
      ),
      headlineMedium: TextStyle(
        fontFamily: serifFamily,
        fontSize: 18 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        height: 1.3 * lineSpacingMultiplier,
      ),
      titleLarge: TextStyle(
        fontSize: 17 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.1,
      ),
      titleMedium: TextStyle(
        fontSize: 15 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleSmall: TextStyle(
        fontSize: 13 * scaleFactor,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * scaleFactor,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.45 * lineSpacingMultiplier,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w400,
        color: primaryColor,
        height: 1.4 * lineSpacingMultiplier,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * scaleFactor,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        height: 1.35 * lineSpacingMultiplier,
      ),
      labelLarge: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: FontWeight.w600,
        color: primaryColor,
        letterSpacing: 0.2,
      ),
      labelMedium: TextStyle(
        fontSize: 12 * scaleFactor,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      labelSmall: TextStyle(
        fontSize: 10 * scaleFactor,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.4,
      ),
    );
  }
}
