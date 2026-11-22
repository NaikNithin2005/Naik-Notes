import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/attachment_model.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/repositories/attachment_repository.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/notes/presentation/widgets/note_editor_view.dart';
import 'package:naik_notes/features/pdf/presentation/screens/pdf_attachment_viewer_screen.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_attachment_card.dart';
import 'package:naik_notes/features/sketch/presentation/widgets/sketch_canvas_dialog.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';
import 'package:path/path.dart' as p;

class _TestNotebooksNotifier extends NotebooksNotifier {
  final List<Notebook> _notebooks;
  _TestNotebooksNotifier(this._notebooks);
  @override
  List<Notebook> build() => _notebooks;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late AttachmentRepository attachmentRepo;
  late Directory tempDir;
  late File samplePdfFile;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    attachmentRepo = AttachmentRepository(db);
    tempDir = await Directory.systemTemp.createTemp('naik_notes_widget_test_');

    // Create a minimal valid PDF file bytes for viewer testing
    samplePdfFile = File(p.join(tempDir.path, 'sample.pdf'));
    const minimalPdf =
        '%PDF-1.4\n1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj\n2 0 obj<</Type/Pages/Count 1/Kids[3 0 R]>>endobj\n3 0 obj<</Type/Page/MediaBox[0 0 612 792]/Parent 2 0 R/Resources<<>>>>endobj\nxref\n0 4\n0000000000 65535 f\n0000000009 00000 n\n0000000052 00000 n\n0000000101 00000 n\ntrailer<</Size 4/Root 1 0 R>>\nstartxref\n178\n%%EOF\n';
    await samplePdfFile.writeAsString(minimalPdf);
  });

  tearDown(() async {
    await db.close();
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 4: PDF Viewer & Attachment Card Widget Tests', () {
    testWidgets('PdfAttachmentCard renders title, size, and status badge', (tester) async {
      final attachment = NoteAttachment(
        attachmentId: 'att_card_01',
        ownerId: 'user_widget',
        noteId: 'note_card',
        fileName: 'Thermodynamics_Lecture.pdf',
        mimeType: 'application/pdf',
        fileSize: 2048576, // ~2 MB
        localPath: samplePdfFile.path,
        checksum: 'dummy_checksum',
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            attachmentRepositoryProvider.overrideWithValue(attachmentRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: PdfAttachmentCard(
                  attachment: attachment,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Thermodynamics_Lecture.pdf'), findsOneWidget);
      expect(find.text('2.0 MB'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
    });

    testWidgets('PdfAttachmentViewerScreen renders controls, zoom, and search toggle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PdfAttachmentViewerScreen(
            pdfFile: samplePdfFile,
            title: 'Test Document.pdf',
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      // Verify title is rendered
      expect(find.text('Test Document.pdf'), findsOneWidget);

      // Verify zoom icons
      expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out_rounded), findsOneWidget);

      // Verify search icon and toggle
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search in document...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  group('Phase 4: iPad Sketching & Apple Pencil Canvas Widget Tests', () {
    testWidgets('SketchCanvasDialog renders drawing tools, palette, undo/redo, and canvas', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            attachmentRepositoryProvider.overrideWithValue(attachmentRepo),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SketchCanvasDialog(noteId: 'note_sketch_test'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header and title
      expect(find.text('Sketch & Apple Pencil'), findsOneWidget);

      // Tools
      expect(find.text('Pen'), findsOneWidget);
      expect(find.text('Pencil'), findsOneWidget);
      expect(find.text('Highlighter'), findsOneWidget);
      expect(find.text('Eraser'), findsOneWidget);

      // Action buttons
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_sweep_rounded), findsOneWidget);
      expect(find.text('Attach to Note'), findsOneWidget);

      // Draw stroke on canvas
      final canvasFinder = find.byType(CustomPaint).last;
      expect(canvasFinder, findsOneWidget);

      final center = tester.getCenter(canvasFinder);
      await tester.dragFrom(center, const Offset(60, 40));
      await tester.pump();

      // Undo button becomes enabled and can be tapped
      final undoButton = find.byTooltip('Undo');
      expect(undoButton, findsOneWidget);
      await tester.tap(undoButton);
      await tester.pump();
    });
  });

  group('Phase 4: NoteEditorView Attachments Strip & Custom Buttons Tests', () {
    testWidgets('NoteEditorView renders attachment strip and custom toolbar buttons', (tester) async {
      final now = DateTime.now();
      final notebook = Notebook(
        id: 'nb_01',
        ownerId: 'local_user',
        title: 'Physics Notebook',
        description: 'Physics notes',
        coverId: 'classic_leather',
        coverColorHex: '#8B4513',
        paperTemplateId: 'blank_paper',
        createdAt: now,
        updatedAt: now,
      );

      final note = Note(
        id: 'note_p4_editor',
        ownerId: 'local_user',
        notebookId: 'nb_01',
        title: 'Quantum Electrodynamics',
        contentDelta: '[{"insert":"Welcome to quantum electrodynamics.\\n"}]',
        plainText: 'Welcome to quantum electrodynamics.',
        preview: 'Welcome to quantum electrodynamics.',
        createdAt: now,
        updatedAt: now,
      );

      // Add a test PDF attachment in database
      final pdfAtt = NoteAttachment(
        attachmentId: 'att_p4_01',
        ownerId: 'local_user',
        noteId: note.id,
        fileName: 'Feynman_Lectures.pdf',
        mimeType: 'application/pdf',
        fileSize: 1048576,
        localPath: samplePdfFile.path,
        checksum: 'hash_feynman',
        uploadStatus: AttachmentUploadStatus.uploaded,
        createdAt: now,
      );
      await attachmentRepo.saveAttachment(pdfAtt);

      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            attachmentRepositoryProvider.overrideWithValue(attachmentRepo),
            notebooksProvider.overrideWith(() => _TestNotebooksNotifier([notebook])),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              FlutterQuillLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: FlutterQuillLocalizations.supportedLocales,
            home: Scaffold(
              body: NoteEditorView(
                note: note,
                isMobile: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check note title
      expect(find.text('Quantum Electrodynamics'), findsOneWidget);

      // Check attachments strip renders the PDF card
      expect(find.text('Feynman_Lectures.pdf'), findsOneWidget);

      // Check custom toolbar buttons exist
      expect(find.byTooltip('Insert Image'), findsWidgets);
      expect(find.byTooltip('Attach File / PDF'), findsWidgets);
      expect(find.byTooltip('Apple Pencil Sketch'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
