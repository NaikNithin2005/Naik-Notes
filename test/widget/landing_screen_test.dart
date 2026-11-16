import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/features/landing/presentation/screens/landing_screen.dart';

void main() {
  group('LandingScreen UI & Layout Tests', () {
    testWidgets('renders desktop two-column layout on wide screens', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LandingScreen())),
      );

      await tester.pumpAndSettle();

      // Brand Title and Tagline
      expect(find.text('Naik Notes'), findsOneWidget);
      expect(
        find.text('Your thoughts.\nYour pages.\nYour creativity.'),
        findsOneWidget,
      );

      // Auth Card
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Sign In with Email'), findsOneWidget);
      expect(find.text('Create New Account'), findsOneWidget);
      expect(
        find.text('Windows Edition • Cloud Sync Enabled'),
        findsOneWidget,
      );

      // Features list visible on wide screen
      expect(find.text('9 Dynamic Writing Tools'), findsOneWidget);
      expect(find.text('Pure Vector Dual-Mode Eraser'), findsOneWidget);
    });

    testWidgets('renders mobile layout with Google option on Android phone size', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LandingScreen())),
      );

      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Sign In with Email'), findsOneWidget);
      expect(find.text('Create New Account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}

