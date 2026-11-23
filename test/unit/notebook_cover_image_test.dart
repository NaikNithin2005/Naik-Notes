import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:naik_notes/core/widgets/notebook_cover_image.dart';
import 'package:naik_notes/data/models/notebook_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotebookCoverImage Widget Tests', () {
    late String validBase64;

    setUp(() {
      final image = img.Image(width: 40, height: 40);
      img.fill(image, color: img.ColorRgb8(50, 150, 50));
      final bytes = Uint8List.fromList(img.encodeJpg(image, quality: 75));
      validBase64 = base64Encode(bytes);
    });

    testWidgets('renders Image.memory when coverImageBase64 is valid', (tester) async {
      final nb = Notebook(
        id: 'nb-cover-valid',
        ownerId: 'user-1',
        title: 'Cover Test',
        coverId: 'custom',
        coverImageBase64: validBase64,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotebookCoverImage(
                notebook: nb,
                fallback: const Text('DefaultFallbackCover'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('DefaultFallbackCover'), findsNothing);
    });

    testWidgets('gracefully renders fallback without crashing on corrupted Base64', (tester) async {
      final nb = Notebook(
        id: 'nb-cover-corrupt',
        ownerId: 'user-1',
        title: 'Corrupted Cover Test',
        coverId: 'custom',
        coverImageBase64: 'this_is_not_valid_base64_!@#\$%',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotebookCoverImage(
                notebook: nb,
                fallback: const Text('DefaultFallbackCover'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('DefaultFallbackCover'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders fallback when coverImageBase64 is null or empty', (tester) async {
      final nb = Notebook(
        id: 'nb-cover-null',
        ownerId: 'user-1',
        title: 'Empty Cover Test',
        coverId: 'classic_leather',
        coverImageBase64: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: NotebookCoverImage(
                notebook: nb,
                fallback: const Text('DefaultFallbackCover'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('DefaultFallbackCover'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });
  });
}

