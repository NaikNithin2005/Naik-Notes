import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme_colors.dart';
import 'theme_typography.dart';

/// Production Reading Mode Theme definition for Naik Notes (#F3EEDC warm cream, #332F29 warm grey text).
ThemeData buildReadingTheme({
  double fontScale = 1.0,
  double lineSpacingMultiplier = 1.2,
}) {
  const scheme = ThemeColors.readingScheme;
  final textTheme = ThemeTypography.buildTextTheme(
    primaryColor: ThemeColors.readingMainText,
    secondaryColor: ThemeColors.readingSecondaryText,
    scaleFactor: fontScale,
    lineSpacingMultiplier: lineSpacingMultiplier,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: ThemeColors.readingBackground,
    canvasColor: ThemeColors.readingBackground,
    cardColor: ThemeColors.readingCard,
    textTheme: textTheme,
    iconTheme: const IconThemeData(
      color: ThemeColors.readingSecondaryText,
      size: 22,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ThemeColors.readingBackground,
      foregroundColor: ThemeColors.readingMainText,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: const IconThemeData(color: ThemeColors.readingSecondaryText),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: ThemeColors.readingCard,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ThemeColors.readingBorder, width: 1.0),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: ThemeColors.readingCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: ThemeColors.readingBorder, width: 1.0),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ThemeColors.readingCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: ThemeColors.readingElevated,
      selectedIconTheme: IconThemeData(color: scheme.primary),
      unselectedIconTheme: const IconThemeData(
        color: ThemeColors.readingSecondaryText,
      ),
      indicatorColor: scheme.primaryContainer,
      labelType: NavigationRailLabelType.all,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: ThemeColors.readingElevated,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.all(textTheme.labelSmall),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ThemeColors.readingMainText,
        side: const BorderSide(color: ThemeColors.readingBorder, width: 1.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ThemeColors.readingNotebookPage,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.readingBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ThemeColors.readingBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.8),
      ),
      hintStyle: TextStyle(
        color: ThemeColors.readingSecondaryText.withValues(alpha: 0.8),
        fontSize: 14,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: const DividerThemeData(
      color: ThemeColors.readingBorder,
      thickness: 1,
      space: 1,
    ),
    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStateProperty.all(ThemeColors.readingNotebookPage),
      surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
      elevation: WidgetStateProperty.all(0),
      side: WidgetStateProperty.all(
        const BorderSide(color: ThemeColors.readingBorder),
      ),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textStyle: WidgetStateProperty.all(
        const TextStyle(color: ThemeColors.readingMainText),
      ),
    ),
  );
}
