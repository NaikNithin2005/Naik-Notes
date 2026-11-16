import 'package:flutter/material.dart';

/// Centralized design tokens and color schemes for Light, Dark, and Reading modes.
class ThemeColors {
  ThemeColors._();

  // Naik Notes Signature Accents
  static const Color accentTerracotta = Color(0xFF9E4731);
  static const Color accentTerracottaLight = Color(0xFFE06D53);
  static const Color inkNavy = Color(0xFF1E2A38);
  static const Color sageGreen = Color(0xFF4A6B53);

  // Status & Sync Colors
  static const Color statusSuccess = Color(0xFF2E7D32);
  static const Color statusPending = Color(0xFFE65100);
  static const Color statusError = Color(0xFFC62828);
  static const Color statusOffline = Color(0xFF757575);

  // -------------------------------------------------------------
  // LIGHT MODE COLORS (#FFFFFF Pure White, #171717 Near Black)
  // -------------------------------------------------------------
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightSecondarySurface = Color(0xFFF7F7F7);
  static const Color lightPrimaryText = Color(0xFF171717);
  static const Color lightSecondaryText = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightInputBackground = Color(0xFFFFFFFF);
  static const Color lightIcon = Color(0xFF333333);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: accentTerracotta,
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
    surface: lightBackground,
    onSurface: lightPrimaryText,
    surfaceContainerHighest: lightSecondarySurface,
    outline: lightBorder,
    outlineVariant: Color(0xFFEDEDED),
    shadow: Color(0x14000000),
  );

  // -------------------------------------------------------------
  // DARK MODE COLORS (#121212 Charcoal, #F5F5F5 Text)
  // -------------------------------------------------------------
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSecondaryBackground = Color(0xFF1B1B1B);
  static const Color darkCard = Color(0xFF242424);
  static const Color darkElevated = Color(0xFF2C2C2C);
  static const Color darkPrimaryText = Color(0xFFF5F5F5);
  static const Color darkSecondaryText = Color(0xFFBDBDBD);
  static const Color darkBorder = Color(0xFF383838);
  static const Color darkInputBackground = Color(0xFF242424);
  static const Color darkIcon = Color(0xFFE0E0E0);

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: accentTerracottaLight,
    onPrimary: Color(0xFF3B0A01),
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
    surface: darkBackground,
    onSurface: darkPrimaryText,
    surfaceContainerHighest: darkCard,
    outline: darkBorder,
    outlineVariant: Color(0xFF2F2F2F),
    shadow: Color(0x40000000),
  );

  // -------------------------------------------------------------
  // READING MODE COLORS (#F3EEDC Warm Cream, #332F29 Dark Warm Grey)
  // -------------------------------------------------------------
  static const Color readingBackground = Color(0xFFF3EEDC);
  static const Color readingNotebookPage = Color(0xFFFFFDF5);
  static const Color readingMainText = Color(0xFF332F29);
  static const Color readingSecondaryText = Color(0xFF71695E);
  static const Color readingBorder = Color(0xFFDED5C3);
  static const Color readingCard = Color(0xFFFAF6EB);
  static const Color readingElevated = Color(0xFFF1E9D2);
  static const Color readingAccent = Color(0xFF7C5335);

  static const ColorScheme readingScheme = ColorScheme(
    brightness: Brightness.light,
    primary: readingAccent,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEADCCB),
    onPrimaryContainer: Color(0xFF2C1A0E),
    secondary: Color(0xFF5A4D41),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE8DFC8),
    onSecondaryContainer: Color(0xFF201B15),
    tertiary: Color(0xFF6B664B),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE6E2C6),
    onTertiaryContainer: Color(0xFF222013),
    error: Color(0xFF9E2A2B),
    onError: Colors.white,
    surface: readingBackground,
    onSurface: readingMainText,
    surfaceContainerHighest: readingCard,
    outline: readingBorder,
    outlineVariant: Color(0xFFE8E0CE),
    shadow: Color(0x10332F29),
  );
}
