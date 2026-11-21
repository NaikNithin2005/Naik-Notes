import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/features/notes/presentation/widgets/note_shortcuts.dart';

void main() {
  group('NoteShortcuts Keyboard Shortcuts Widget Tests', () {
    testWidgets('Ctrl/Cmd + N triggers onNewNote callback', (tester) async {
      bool newNoteTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NoteShortcuts(
                onNewNote: () {
                  newNoteTriggered = true;
                },
                child: const TextField(
                  key: Key('shortcut_test_field'),
                ),
              ),
            ),
          ),
        ),
      );

      // Focus the field
      await tester.tap(find.byKey(const Key('shortcut_test_field')));
      await tester.pump();

      // Trigger Ctrl + N (or Meta + N on macOS)
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(newNoteTriggered, isTrue);
    });

    testWidgets('Ctrl/Cmd + F triggers onSearchFocus callback', (tester) async {
      bool searchTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NoteShortcuts(
                onSearchFocus: () {
                  searchTriggered = true;
                },
                child: const SizedBox(
                  key: Key('shortcut_test_box'),
                  width: 100,
                  height: 100,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(searchTriggered, isTrue);
    });

    testWidgets('Rich text formatting shortcuts (Ctrl+B, Ctrl+I, Ctrl+U) invoke callbacks',
        (tester) async {
      bool boldTriggered = false;
      bool italicTriggered = false;
      bool underlineTriggered = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NoteShortcuts(
                onBold: () => boldTriggered = true,
                onItalic: () => italicTriggered = true,
                onUnderline: () => underlineTriggered = true,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Test Bold: Ctrl + B
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(boldTriggered, isTrue);

      // Test Italic: Ctrl + I
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(italicTriggered, isTrue);

      // Test Underline: Ctrl + U
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(underlineTriggered, isTrue);
    });
  });
}

