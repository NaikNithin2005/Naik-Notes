import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/features/authentication/presentation/screens/login_screen.dart';
import 'package:naik_notes/features/authentication/presentation/screens/register_screen.dart';
import 'package:naik_notes/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:naik_notes/features/dashboard/presentation/widgets/app_shell.dart';
import 'package:naik_notes/features/notebooks/presentation/screens/notebook_view_screen.dart';
import 'package:naik_notes/features/settings/presentation/screens/settings_screen.dart';
import 'package:naik_notes/features/templates/presentation/screens/template_gallery_screen.dart';

import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

/// Riverpod provider for application router configuration.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.dashboard,
    routes: [
      // Authentication Routes (Root level fullscreen)
      GoRoute(
        path: RouteNames.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),

      // Primary Shell with NavigationRail / NavigationBar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: RouteNames.templateGallery,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TemplateGalleryScreen()),
          ),
          GoRoute(
            path: RouteNames.settings,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),

      // Fullscreen Notebook Editor / Reader
      GoRoute(
        path: RouteNames.notebookView,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'default';
          return NotebookViewScreen(notebookId: id);
        },
      ),
    ],
  );
});
