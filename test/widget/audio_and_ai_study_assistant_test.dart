import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/features/ai_assistant/presentation/widgets/ai_study_assistant_sheet.dart';
import 'package:naik_notes/features/audio/presentation/widgets/audio_recording_bar.dart';

void main() {
  group('Audio & AI Study Assistant Widget Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('AudioRecordingBar renders recording and playback states', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool closed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: AudioRecordingBar(
                  notebookId: 'nb-test',
                  onClose: () => closed = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In initial idle/playback mode: Play button and Speed pill should be visible
      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);

      // Tap speed pill to cycle speed
      await tester.tap(find.text('1.0x'));
      await tester.pumpAndSettle();
      expect(find.text('1.25x'), findsOneWidget);

      // Tap close
      await tester.tap(find.byTooltip('Close audio controller'));
      await tester.pumpAndSettle();
      expect(closed, true);
    });

    testWidgets('AiStudyAssistantSheet renders tabs and handles navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(
            home: Scaffold(
              body: AiStudyAssistantSheet(
                notebookId: 'nb-ai-test',
                notebookTitle: 'Advanced Physics',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & tabs
      expect(find.text('AI Study Assistant'), findsOneWidget);
      expect(find.text('Advanced Physics'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
      expect(find.text('Flashcards'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Ask Notes'), findsOneWidget);

      // Switch to Flashcards Tab
      await tester.tap(find.text('Flashcards'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Card 1 of'), findsOneWidget);

      // Tap to reveal answer on flashcard
      await tester.tap(find.text('Tap to reveal answer'));
      await tester.pumpAndSettle();
      expect(find.text('ANSWER:'), findsOneWidget);

      // Switch to Quiz Tab
      await tester.tap(find.text('Quiz'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Question 1 of'), findsOneWidget);

      // Switch to Ask Notes Tab
      await tester.tap(find.text('Ask Notes'));
      await tester.pumpAndSettle();
      expect(find.text('Explain main formula'), findsOneWidget);
    });
  });
}
