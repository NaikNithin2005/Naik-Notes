import 'package:flutter/material.dart';

/// Premium paper-inspired color palette for Naik Notes.
class AppColors {
  AppColors._();

  // Stationery / Paper Canvas Colors
  static const Color paperIvory = Color(0xFFFBF9F4);
  static const Color paperCream = Color(0xFFF5EFEB);
  static const Color paperWarmWhite = Color(0xFFFAF7F2);
  static const Color paperDark = Color(0xFF1E1E1E);
  static const Color paperDarkSurface = Color(0xFF262626);

  // Primary Leather & Ink Accents
  static const Color leatherTerracotta = Color(0xFF9E4731);
  static const Color leatherCognac = Color(0xFF8B4513);
  static const Color inkNavy = Color(0xFF1E2A38);
  static const Color inkCharcoal = Color(0xFF2B2B2B);
  static const Color sageGreen = Color(0xFF4A6B53);
  static const Color brassGold = Color(0xFFC29B38);

  // Ink Writing Colors (Writing Toolbar Palette)
  static const Color inkBlack = Color(0xFF1A1A1A);
  static const Color inkBlue = Color(0xFF1D4ED8);
  static const Color inkRed = Color(0xFFB91C1C);
  static const Color inkGreen = Color(0xFF15803D);
  static const Color inkPurple = Color(0xFF6B21A8);
  static const Color inkTeal = Color(0xFF0F766E);
  static const Color inkAmber = Color(0xFFB45309);

  // Highlighter Inks (with transparency)
  static const Color highlightYellow = Color(0x66FFEB3B);
  static const Color highlightGreen = Color(0x6681C784);
  static const Color highlightPink = Color(0x66F48FB1);
  static const Color highlightBlue = Color(0x6664B5F6);
  static const Color highlightOrange = Color(0x66FFB74D);

  // Status & Sync Badges
  static const Color syncSuccess = Color(0xFF2E7D32);
  static const Color syncPending = Color(0xFFE65100);
  static const Color syncError = Color(0xFFC62828);
  static const Color syncOffline = Color(0xFF757575);

  // Light Color Scheme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: leatherTerracotta,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFDBCF),
    onPrimaryContainer: Color(0xFF3B0A01),
    secondary: inkNavy,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD6E3F8),
    onSecondaryContainer: Color(0xFF0B1D30),
    tertiary: sageGreen,
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFCCE8D2),
    onTertiaryContainer: Color(0xFF0A2012),
    error: Color(0xFFBA1A1A),
    onError: Colors.white,
    surface: paperIvory,
    onSurface: inkCharcoal,
    surfaceContainerHighest: paperCream,
    outline: Color(0xFFD5CBC4),
    shadow: Color(0x1F000000),
  );

  // Dark Color Scheme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFFFB59D),
    onPrimary: Color(0xFF5E1705),
    primaryContainer: Color(0xFF7D2F1B),
    onPrimaryContainer: Color(0xFFFFDBCF),
    secondary: Color(0xFFA6C8FF),
    onSecondary: Color(0xFF003060),
    secondaryContainer: Color(0xFF1E4378),
    onSecondaryContainer: Color(0xFFD6E3F8),
    tertiary: Color(0xFFB1CCB7),
    onTertiary: Color(0xFF1D3523),
    tertiaryContainer: Color(0xFF334F3A),
    onTertiaryContainer: Color(0xFFCCE8D2),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    surface: paperDark,
    onSurface: Color(0xFFEDE8E3),
    surfaceContainerHighest: paperDarkSurface,
    outline: Color(0xFF4C4742),
    shadow: Color(0x40000000),
  );
}
