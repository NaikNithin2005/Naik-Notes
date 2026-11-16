import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';
import 'reading_theme.dart';
import 'theme_controller.dart';

export 'app_colors.dart';
export 'app_typography.dart';
export 'dark_theme.dart';
export 'light_theme.dart';
export 'reading_theme.dart';
export 'theme_colors.dart';
export 'theme_controller.dart';
export 'theme_typography.dart';

/// Central facade for application theme access in Naik Notes.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => buildLightTheme();
  static ThemeData get darkTheme => buildDarkTheme();
  static ThemeData get readingTheme => buildReadingTheme();

  /// Resolves the specific ThemeData for an [AppThemeMode].
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return buildDarkTheme();
      case AppThemeMode.reading:
        return buildReadingTheme();
    }
  }
}
