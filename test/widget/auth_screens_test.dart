import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/features/authentication/presentation/screens/login_screen.dart';
import 'package:naik_notes/features/authentication/presentation/screens/register_screen.dart';

void main() {
  group('Authentication UI Screen Tests', () {
    testWidgets('renders LoginScreen with branding, fields and Google option on Android', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('Naik Notes'), findsOneWidget);
      expect(
        find.text('Sign in to synchronize your handwritten notebooks'),
        findsOneWidget,
      );
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('renders LoginScreen on Windows with Google and Email authentication', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('Naik Notes'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(
        find.text('Windows Edition • Google & Email Synchronization'),
        findsOneWidget,
      );
      // On Windows, Desktop OAuth 2.0 loopback flow is supported
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('validates empty inputs on LoginScreen submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      await tester.pumpAndSettle();

      // Tap Sign In without filling inputs
      final signInButton = find.widgetWithText(FilledButton, 'Sign In');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('renders RegisterScreen and validates password mismatch', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: RegisterScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('Join Naik Notes'), findsOneWidget);
      expect(find.text('Your Name'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Fill mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Nithin Naik');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'nithin@naiknotes.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'mismatched456');

      final createButton = find.widgetWithText(FilledButton, 'Create Account');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
