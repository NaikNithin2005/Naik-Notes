import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/authentication/presentation/screens/login_screen.dart';
import 'package:naik_notes/features/authentication/presentation/screens/register_screen.dart';
import 'package:naik_notes/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:naik_notes/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:naik_notes/features/dashboard/presentation/widgets/app_shell.dart';
import 'package:naik_notes/features/landing/presentation/screens/landing_screen.dart';
import 'package:naik_notes/features/notebooks/presentation/screens/notebook_view_screen.dart';
import 'package:naik_notes/features/notes/presentation/screens/notes_screen.dart';
import 'package:naik_notes/features/profile/presentation/screens/profile_screen.dart';
import 'package:naik_notes/features/settings/presentation/screens/settings_screen.dart';
import 'package:naik_notes/features/templates/presentation/screens/template_gallery_screen.dart';
import 'package:naik_notes/features/trash/presentation/screens/trash_screen.dart';

import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

/// Reactive notifier that signals [GoRouter] to re-evaluate routes without reconstructing
/// the entire GoRouter instance on state changes, eliminating screen blink and routing latency.
class _RouterAuthNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterAuthNotifier(this._ref) {
    _ref.listen<bool>(
      authProvider.select((s) => s.isAuthenticated),
      (_, _) => notifyListeners(),
    );
  }

  bool get isAuthenticated => _ref.read(authProvider).isAuthenticated;
}

final _routerAuthNotifierProvider = Provider<_RouterAuthNotifier>((ref) {
  return _RouterAuthNotifier(ref);
});

/// Riverpod provider for application router configuration.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(_routerAuthNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    refreshListenable: authNotifier,
    initialLocation: authNotifier.isAuthenticated
        ? RouteNames.dashboard
        : RouteNames.landing,
    redirect: (context, state) {
      final isAuth = authNotifier.isAuthenticated;
      final location = state.matchedLocation;
      final isPublicAuthRoute =
          location == RouteNames.landing ||
          location == RouteNames.login ||
          location == RouteNames.register ||
          location == RouteNames.phoneAuth;

      // Unauthenticated users are redirected to landing (except password reset)
      if (!isAuth && !isPublicAuthRoute && location != RouteNames.resetPassword) {
        return RouteNames.landing;
      }
      // Authenticated users on login/landing/register are redirected to dashboard
      // (Password reset remains accessible for authenticated users changing passwords)
      if (isAuth && isPublicAuthRoute) {
        return RouteNames.dashboard;
      }
      return null;
    },
    routes: [
      // Landing & Introduction (Fullscreen)
      GoRoute(
        path: RouteNames.landing,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LandingScreen(),
      ),

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
      GoRoute(
        path: RouteNames.resetPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ResetPasswordScreen(
          code: state.uri.queryParameters['oobCode'] ??
              state.uri.queryParameters['code'],
        ),
      ),
      GoRoute(
        path: RouteNames.phoneAuth,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => RouteNames.login,
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
            path: RouteNames.notes,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotesScreen()),
          ),
          GoRoute(
            path: RouteNames.templateGallery,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TemplateGalleryScreen()),
          ),
          GoRoute(
            path: RouteNames.trash,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TrashScreen()),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
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
