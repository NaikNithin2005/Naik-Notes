import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/naik_notes_logo.dart';
import '../../data/auth_provider.dart';
import '../widgets/auth_error_banner.dart';

/// Professional branded password reset screen for Naik Notes.
///
/// Supports query parameter verification code (?oobCode=... or ?code=...)
/// or manual action code entry, password confirmation, and secure reset.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? code;

  const ResetPasswordScreen({super.key, this.code});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    if (widget.code != null && widget.code!.isNotEmpty) {
      _codeController.text = widget.code!;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;

    final code = _codeController.text.trim();
    final newPassword = _passwordController.text.trim();

    final success = await ref
        .read(authProvider.notifier)
        .confirmPasswordReset(code: code, newPassword: newPassword);

    if (mounted && success) {
      setState(() {
        _isSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFFE07A5F) : AppColors.leatherTerracotta;
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(RouteNames.login),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: _isSuccess
                    ? _buildSuccessView(context, theme, primaryColor)
                    : _buildFormView(context, theme, primaryColor, authState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
    AuthState authState,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: NaikNotesLogo(size: 52, showText: true)),
          const SizedBox(height: 18),

          Text(
            'Create New Password',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your verification code and choose a secure password for your Naik Notes account.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          if (authState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AuthErrorBanner(
                message: authState.errorMessage!,
                onDismiss: () =>
                    ref.read(authProvider.notifier).clearMessages(),
              ),
            ),

          // Action Code Field
          TextFormField(
            controller: _codeController,
            decoration: InputDecoration(
              labelText: 'Verification / Action Code',
              hintText: 'Paste code from email link',
              prefixIcon: const Icon(Icons.vpn_key_rounded, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter the reset code from your email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // New Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password',
              hintText: 'At least 6 characters',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password Field
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (val) {
              if (val != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          FilledButton(
            onPressed: authState.isLoading ? null : _submitReset,
            style: FilledButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Reset My Password',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => context.go(RouteNames.login),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0x1F22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF22C55E),
            size: 38,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Password Reset Successful!',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        Text(
          'Your Naik Notes account password has been updated securely. You can now sign in with your new credentials.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),

        FilledButton(
          onPressed: () => context.go(RouteNames.login),
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Sign In with New Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

