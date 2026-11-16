import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/core/widgets/naik_notes_logo.dart';
import 'package:naik_notes/core/widgets/social_auth_icons.dart';
import 'package:naik_notes/features/authentication/data/auth_error_handler.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/authentication/presentation/widgets/auth_error_banner.dart';

/// Professional Landing & Welcome screen for Naik Notes.
///
/// Features responsive LayoutBuilder, overflow-free scrolling, authentic branding,
/// and platform-aware authentication provider buttons (Windows, Android, iPadOS).
class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) {
      context.go(RouteNames.dashboard);
    }
  }

  Future<void> _signInWithApple() async {
    final success = await ref.read(authProvider.notifier).signInWithApple();
    if (success && mounted) {
      context.go(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background decorative subtle grid
          Positioned.fill(
            child: CustomPaint(
              painter: _LandingBackgroundPainter(
                primaryColor: theme.colorScheme.primary,
                brightness: theme.brightness,
              ),
            ),
          ),

          SafeArea(
            maintainBottomViewPadding: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktopOrTablet = constraints.maxWidth >= 768;

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktopOrTablet ? 32 : 20,
                    vertical: isDesktopOrTablet ? 36 : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - (isDesktopOrTablet ? 72 : 40)).clamp(0.0, double.infinity),
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktopOrTablet ? 1040 : 480,
                            ),
                            child: isDesktopOrTablet
                                ? _buildDesktopLayout(theme, authState)
                                : _buildMobileLayout(theme, authState),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Two-column layout for desktop and tablet screens.
  Widget _buildDesktopLayout(ThemeData theme, AuthState authState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Branding and Feature Overview
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.only(right: 48, top: 12),
            child: _buildHeroNarrative(theme, isCompact: false),
          ),
        ),

        // Right Column: Auth Card
        Expanded(
          flex: 5,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildAuthCard(theme, authState),
          ),
        ),
      ],
    );
  }

  /// Single-column layout for mobile phones.
  Widget _buildMobileLayout(ThemeData theme, AuthState authState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeroNarrative(theme, isCompact: true),
        const SizedBox(height: 24),
        _buildAuthCard(theme, authState),
        const SizedBox(height: 32),
        _buildFeatureHighlights(theme),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeroNarrative(ThemeData theme, {required bool isCompact}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NaikNotesLogo(size: isCompact ? 56 : 68, showText: true),
        SizedBox(height: isCompact ? 16 : 24),
        Text(
          'Your thoughts.\nYour pages.\nYour creativity.',
          style: (isCompact
                  ? theme.textTheme.headlineMedium
                  : theme.textTheme.displayMedium)
              ?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 18),
        Text(
          'The cross-platform creative notebook engineered for natural handwriting, '
          'rich Adobe Fresco-inspired vector tools, and seamless synchronization '
          'across Android, iPad, and Windows.',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: isCompact ? 14 : 16,
          ),
        ),
        if (!isCompact) ...[
          const SizedBox(height: 32),
          _buildFeatureHighlights(theme),
        ],
      ],
    );
  }

  Widget _buildFeatureHighlights(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFeatureItem(
          icon: Icons.draw_outlined,
          title: '9 Dynamic Writing Tools',
          subtitle:
              'Fountain, Ballpoint, Pencil, Brush, Chisel, and Technical pens.',
          theme: theme,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.cleaning_services_outlined,
          title: 'Pure Vector Dual-Mode Eraser',
          subtitle: 'Complete stroke elimination or precise segment splitting.',
          theme: theme,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.auto_stories_outlined,
          title: 'Realistic Reading Mode',
          subtitle:
              'Smooth 3D page turn physics and comfortable study typography.',
          theme: theme,
        ),
        const SizedBox(height: 12),
        _buildFeatureItem(
          icon: Icons.cloud_done_outlined,
          title: 'Real Device Cloud Sync',
          subtitle:
              'Automatic Firestore synchronization and active device sessions.',
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthCard(ThemeData theme, AuthState authState) {
    final isGoogleAvailable = AuthErrorHandler.isGoogleSupported();
    final isAppleAvailable = AuthErrorHandler.isAppleSupported();
    final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Get Started',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in or register your account to begin writing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Dismissible error banner
            if (authState.errorMessage != null)
              AuthErrorBanner(
                message: authState.errorMessage!,
                onDismiss: () =>
                    ref.read(authProvider.notifier).clearMessages(),
              ),

            // Primary: Sign In with Email
            FilledButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () {
                      ref.read(authProvider.notifier).clearMessages();
                      context.push(RouteNames.login);
                    },
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign In with Email'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Secondary: Create Account
            FilledButton.tonalIcon(
              onPressed: authState.isLoading
                  ? null
                  : () {
                      ref.read(authProvider.notifier).clearMessages();
                      context.push(RouteNames.register);
                    },
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Create New Account'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // Fast Connect Section (Only displayed when OAuth providers are supported)
            if (isGoogleAvailable || isAppleAvailable) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR FAST CONNECT',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 14),

              // Google Sign-In (Android & iOS)
              if (isGoogleAvailable) ...[
                OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _signInWithGoogle,
                  icon: const GoogleLogo(size: 20),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Apple Sign-In (iPadOS / iOS / macOS only)
              if (isAppleAvailable) ...[
                OutlinedButton.icon(
                  onPressed: authState.isLoading ? null : _signInWithApple,
                  icon: const AppleLogo(size: 20),
                  label: const Text('Continue with Apple'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],

            // Windows Desktop Edition subtle footer badge
            if (isWindows) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_sync_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Windows Edition • Cloud Sync Enabled',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LandingBackgroundPainter extends CustomPainter {
  final Color primaryColor;
  final Brightness brightness;

  _LandingBackgroundPainter({
    required this.primaryColor,
    required this.brightness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final isDark = brightness == Brightness.dark;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.black.withValues(alpha: 0.04);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    const double step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LandingBackgroundPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.brightness != brightness;
  }
}
