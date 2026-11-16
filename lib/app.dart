import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root application widget for Naik Notes.
///
/// Features strictly two visual modes: Dark Mode (Dark Charcoal) and
/// Reading Mode (Warm Paper Sepia).
class NaikNotesApp extends ConsumerWidget {
  const NaikNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeSettings = ref.watch(themeControllerProvider);

    final ThemeData activeTheme =
        themeSettings.themeMode == AppThemeMode.reading
        ? AppTheme.readingTheme
        : AppTheme.darkTheme;

    final ThemeMode activeMode = themeSettings.themeMode == AppThemeMode.reading
        ? ThemeMode.light
        : ThemeMode.dark;

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: activeMode,
      routerConfig: router,
    );
  }
}
