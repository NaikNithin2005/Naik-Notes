import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/core/widgets/naik_notes_logo.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';

/// Professional Landing & Welcome screen for Naik Notes.
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
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
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
    final size = MediaQuery.of(context).size;
    final isDesktopOrTablet = size.width >= 768;
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background decorative subtle gradient and grid canvas
          Positioned.fill(
            child: CustomPaint(
              painter: _LandingBackgroundPainter(
                primaryColor: theme.colorScheme.primary,
                brightness: theme.brightness,
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktopOrTablet ? 980 : 480,
                      ),
                      child: isDesktopOrTablet
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(child: _buildHeroNarrative(theme)),
                                const SizedBox(width: 48),
                                SizedBox(
                                  width: 400,
                                  child: _buildAuthCard(theme, authState),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeroNarrative(theme),
                                const SizedBox(height: 32),
                                _buildAuthCard(theme, authState),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroNarrative(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const NaikNotesLogo(size: 72, showText: true),
        const SizedBox(height: 28),
        Text(
          'Your thoughts.\nYour pages.\nYour creativity.',
          style: theme.textTheme.displayMedium?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w800,
            height: 1.15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'The cross-platform creative notebook engineered for natural handwriting, '
          'rich Adobe Fresco-inspired vector tools, and seamless synchronization '
          'across Android, iPad, and Windows.',
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 28),

        // Key Feature highlights
        _buildFeatureItem(
          icon: Icons.draw_outlined,
          title: '9 Dynamic Writing Tools',
          subtitle:
              'Fountain, Ballpoint, Pencil, Brush, Chisel, and Technical pens.',
          theme: theme,
        ),
        const SizedBox(height: 14),
        _buildFeatureItem(
          icon: Icons.cleaning_services_outlined,
          title: 'Pure Vector Dual-Mode Eraser',
          subtitle: 'Complete stroke elimination or precise segment splitting.',
          theme: theme,
        ),
        const SizedBox(height: 14),
        _buildFeatureItem(
          icon: Icons.auto_stories_outlined,
          title: 'Realistic Reading Mode',
          subtitle:
              'Smooth 3D page turn physics and comfortable study typography.',
          theme: theme,
        ),
        const SizedBox(height: 14),
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
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
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
            const SizedBox(height: 24),

            if (authState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  authState.errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sign In with Email
            FilledButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () => context.push(RouteNames.login),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: const Text('Sign In with Email'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Create Account
            FilledButton.tonalIcon(
              onPressed: authState.isLoading
                  ? null
                  : () => context.push(RouteNames.register),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Create New Account'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Divider
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
            const SizedBox(height: 16),

            // Google Sign In
            OutlinedButton.icon(
              onPressed: authState.isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Apple Sign In
            OutlinedButton.icon(
              onPressed: authState.isLoading ? null : _signInWithApple,
              icon: const Icon(Icons.apple, size: 20),
              label: const Text('Continue with Apple'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Phone & OTP Sign In
            OutlinedButton.icon(
              onPressed: authState.isLoading
                  ? null
                  : () => context.push(RouteNames.phoneAuth),
              icon: const Icon(Icons.phone_iphone_rounded, size: 18),
              label: const Text('Sign In with Phone & OTP'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
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

    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Subtle ambient color glow in top-right
    final glowPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
              primaryColor.withValues(alpha: 0.0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.85, size.height * 0.2),
              radius: math.min(size.width, size.height) * 0.6,
            ),
          );
    canvas.drawPaint(glowPaint);
  }

  @override
  bool shouldRepaint(covariant _LandingBackgroundPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.brightness != brightness;
  }
}
