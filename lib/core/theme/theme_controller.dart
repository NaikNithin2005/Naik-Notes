import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dark_theme.dart';
import 'reading_theme.dart';

/// Available global theme modes in Naik Notes: Strictly Dark Mode and Reading Mode.
enum AppThemeMode {
  dark(
    'dark',
    'Dark Mode',
    'Dark charcoal surface (#121212) comfortable for nighttime',
  ),
  reading(
    'reading',
    'Reading Mode',
    'Warm paper appearance (#F3EEDC) optimized for study',
  );

  final String id;
  final String label;
  final String description;

  const AppThemeMode(this.id, this.label, this.description);

  static AppThemeMode fromId(String? id) {
    if (id == 'reading') return AppThemeMode.reading;
    return AppThemeMode.dark;
  }
}

/// User appearance and reading settings.
class ThemeSettings {
  final AppThemeMode themeMode;
  final double readingFontSize;
  final double readingLineSpacing;
  final String readingMargins; // 'compact', 'comfortable', 'wide'

  const ThemeSettings({
    this.themeMode = AppThemeMode.dark,
    this.readingFontSize = 16.0,
    this.readingLineSpacing = 1.5,
    this.readingMargins = 'comfortable',
  });

  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    double? readingFontSize,
    double? readingLineSpacing,
    String? readingMargins,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      readingFontSize: readingFontSize ?? this.readingFontSize,
      readingLineSpacing: readingLineSpacing ?? this.readingLineSpacing,
      readingMargins: readingMargins ?? this.readingMargins,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.id,
      'readingFontSize': readingFontSize,
      'readingLineSpacing': readingLineSpacing,
      'readingMargins': readingMargins,
    };
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: AppThemeMode.fromId(json['themeMode'] as String?),
      readingFontSize: (json['readingFontSize'] as num?)?.toDouble() ?? 16.0,
      readingLineSpacing:
          (json['readingLineSpacing'] as num?)?.toDouble() ?? 1.5,
      readingMargins: json['readingMargins'] as String? ?? 'comfortable',
    );
  }
}

/// State notifier managing the application theme and appearance preferences.
class ThemeController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    return const ThemeSettings(themeMode: AppThemeMode.dark);
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleTheme() {
    state = state.copyWith(
      themeMode: state.themeMode == AppThemeMode.dark
          ? AppThemeMode.reading
          : AppThemeMode.dark,
    );
  }

  void setReadingFontSize(double size) {
    state = state.copyWith(readingFontSize: size);
  }

  void setReadingLineSpacing(double spacing) {
    state = state.copyWith(readingLineSpacing: spacing);
  }

  void setReadingMargins(String margins) {
    state = state.copyWith(readingMargins: margins);
  }

  void syncWithRemoteProfile(Map<String, dynamic> appearanceMap) {
    try {
      final remote = ThemeSettings.fromJson(appearanceMap);
      state = remote;
    } catch (_) {}
  }
}

/// Global provider for application theme settings.
final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);

/// Computed provider that resolves the active [ThemeData] (Dark or Reading).
final activeThemeDataProvider = Provider<ThemeData>((ref) {
  final settings = ref.watch(themeControllerProvider);

  switch (settings.themeMode) {
    case AppThemeMode.reading:
      return buildReadingTheme(
        fontScale: settings.readingFontSize / 16.0,
        lineSpacingMultiplier: settings.readingLineSpacing / 1.5 * 1.2,
      );
    case AppThemeMode.dark:
      return buildDarkTheme();
  }
});
