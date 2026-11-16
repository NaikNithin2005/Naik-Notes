import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/notebook_model.dart';
import '../../../data/models/page_model.dart';
import '../../../data/models/paper_template_model.dart';
import '../../../data/models/sticky_note_model.dart';
import '../../../data/models/stroke_model.dart';
import '../../../data/repositories/notebook_repository.dart';
import '../../../data/repositories/page_repository.dart';
import '../../../data/repositories/sticky_note_repository.dart';
import '../../../data/repositories/stroke_repository.dart';

/// Service responsible for provisioning and managing the Interactive Welcome Notebook.
/// Includes 9 guided tutorial activities, offline-first generation, duplicate protection,
/// and tutorial progress tracking.
class WelcomeNotebookService {
  final NotebookRepository _notebookRepo;
  final PageRepository _pageRepo;
  final StrokeRepository _strokeRepo;
  final StickyNoteRepository _stickyNoteRepo;
  final _uuid = const Uuid();

  WelcomeNotebookService(
    this._notebookRepo,
    this._pageRepo,
    this._strokeRepo,
    this._stickyNoteRepo,
  );

  /// Checks if a Welcome Notebook already exists for the given user.
  Future<bool> hasWelcomeNotebook(String userId) async {
    final notebooks = await _notebookRepo.getAllNotebooks(
      includeArchived: true,
    );
    final welcomeId = 'welcome_notebook_$userId';
    return notebooks.any(
      (nb) =>
          nb.id == welcomeId ||
          (nb.ownerId == userId && nb.title == 'Welcome to Naik Notes'),
    );
  }

  /// Ensures the Welcome Notebook is created once per user in an offline-first manner.
  Future<Notebook?> ensureWelcomeNotebookCreated(String userId) async {
    if (await hasWelcomeNotebook(userId)) {
      final notebooks = await _notebookRepo.getAllNotebooks(
        includeArchived: true,
      );
      return notebooks.firstWhere(
        (nb) =>
            nb.id == 'welcome_notebook_$userId' ||
            (nb.ownerId == userId && nb.title == 'Welcome to Naik Notes'),
      );
    }

    return await createWelcomeNotebook(userId);
  }

  /// Creates the full 9-page interactive tutorial notebook with guided activities.
  Future<Notebook> createWelcomeNotebook(String userId) async {
    final now = DateTime.now();
    final notebookId = 'welcome_notebook_$userId';

    final notebook = Notebook(
      id: notebookId,
      ownerId: userId,
      title: 'Welcome to Naik Notes',
      description:
          'Interactive guided tutorial & walkthrough of Naik Notes features',
      coverId: 'dark_academia_leather',
      coverColorHex: '#1E293B',
      paperTemplateId: 'college_ruled',
      orientation: 'portrait',
      pageSize: 'A4',
      pageCount: 9,
      isFavorite: true,
      isArchived: false,
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );

    await _notebookRepo.saveNotebook(notebook);

    // Provisions all 9 tutorial pages with specific templates, instructions, and sample vector strokes
    await _provisionPage1(notebookId, now);
    await _provisionPage2(notebookId, now);
    await _provisionPage3(notebookId, now);
    await _provisionPage4(notebookId, now);
    await _provisionPage5(notebookId, now);
    await _provisionPage6(notebookId, now);
    await _provisionPage7(notebookId, now);
    await _provisionPage8(notebookId, now);
    await _provisionPage9(notebookId, now);

    return notebook;
  }

  // --- Page 1: Pen Writing Activity ---
  Future<void> _provisionPage1(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-1';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 1,
      templateId: 'college_ruled',
      properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '👋 Welcome to Naik Notes!\n\nActivity 1: The Pen Tool\nGrab your stylus or finger, select the Fountain Pen or Ballpoint Pen from the toolbar, and write your signature or a greeting on the ruled lines below!',
        colorHex: '#FEF08A',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Pre-rendered sample welcoming flourish stroke
    final points = <StrokePoint>[];
    for (int i = 0; i <= 30; i++) {
      final t = i / 30.0;
      final x = 80.0 + t * 240.0;
      final y = 260.0 + math.sin(t * math.pi * 3) * 20.0;
      points.add(
        StrokePoint(
          x: x,
          y: y,
          pressure: 0.4 + 0.5 * math.sin(t * math.pi),
          timestamp: now.millisecondsSinceEpoch + i * 10,
        ),
      );
    }
    await _strokeRepo.saveStroke(
      Stroke(
        id: _uuid.v4(),
        pageId: pageId,
        tool: ToolType.fountainPen,
        colorValue: 0xFF0284C7,
        width: 3.5,
        opacity: 1.0,
        points: points,
        createdAt: now,
      ),
    );
  }

  // --- Page 2: Pen Thickness & Color Customization ---
  Future<void> _provisionPage2(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-2';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 2,
      templateId: 'college_ruled',
      properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '🎨 Activity 2: Stroke Customization\n\nTap the active Pen tool or the Quick Customizer pill in the toolbar to change stroke width, opacity, and choose from vibrant color palettes. Try drawing three lines with different colors!',
        colorHex: '#BBF7D0',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Sample stroke 1: Thin Emerald
    await _strokeRepo.saveStroke(
      _createLineStroke(
        pageId: pageId,
        startX: 60,
        startY: 230,
        endX: 300,
        endY: 230,
        width: 1.5,
        color: 0xFF10B981,
        now: now,
      ),
    );

    // Sample stroke 2: Medium Indigo
    await _strokeRepo.saveStroke(
      _createLineStroke(
        pageId: pageId,
        startX: 60,
        startY: 280,
        endX: 300,
        endY: 280,
        width: 3.5,
        color: 0xFF6366F1,
        now: now,
      ),
    );

    // Sample stroke 3: Bold Crimson
    await _strokeRepo.saveStroke(
      _createLineStroke(
        pageId: pageId,
        startX: 60,
        startY: 330,
        endX: 300,
        endY: 330,
        width: 6.0,
        color: 0xFFE11D48,
        now: now,
      ),
    );
  }

  // --- Page 3: Highlighter & Annotations ---
  Future<void> _provisionPage3(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-3';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 3,
      templateId: 'college_ruled',
      properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '🖍️ Activity 3: Highlighter & Contrast\n\nSelect the Highlighter tool. Notice how the semi-transparent ink smoothly blends under text and handwriting without obscuring your writing. Try highlighting this sample text below!',
        colorHex: '#FED7AA',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Base text stroke
    await _strokeRepo.saveStroke(
      _createLineStroke(
        pageId: pageId,
        startX: 60,
        startY: 240,
        endX: 280,
        endY: 240,
        width: 3.0,
        color: 0xFF0F172A,
        now: now,
      ),
    );

    // Translucent highlighter stroke over it
    await _strokeRepo.saveStroke(
      Stroke(
        id: _uuid.v4(),
        pageId: pageId,
        tool: ToolType.highlighter,
        colorValue: 0xFFFACC15,
        width: 20.0,
        opacity: 0.35,
        points: [
          StrokePoint(x: 50, y: 240, timestamp: now.millisecondsSinceEpoch),
          StrokePoint(
            x: 290,
            y: 240,
            timestamp: now.millisecondsSinceEpoch + 50,
          ),
        ],
        createdAt: now,
      ),
    );
  }

  // --- Page 4: Vector Eraser ---
  Future<void> _provisionPage4(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-4';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 4,
      templateId: 'blank_paper',
      properties: PaperProperties.defaultFor(PaperTemplateType.blankPaper),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '✨ Activity 4: Vector Eraser\n\nSelect the Eraser. Switch between Stroke Eraser (which erases the entire stroke with a single tap) and Partial Eraser. Try erasing the scribble below!',
        colorHex: '#FBCFE8',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Scribble for user to erase
    final pts = <StrokePoint>[];
    for (int i = 0; i <= 20; i++) {
      pts.add(
        StrokePoint(
          x: 80.0 + (i % 2 == 0 ? 0.0 : 160.0),
          y: 220.0 + i * 8.0,
          timestamp: now.millisecondsSinceEpoch + i * 10,
        ),
      );
    }
    await _strokeRepo.saveStroke(
      Stroke(
        id: _uuid.v4(),
        pageId: pageId,
        tool: ToolType.marker,
        colorValue: 0xFFEF4444,
        width: 4.0,
        opacity: 0.9,
        points: pts,
        createdAt: now,
      ),
    );
  }

  // --- Page 5: Lasso Selection & Rotation ---
  Future<void> _provisionPage5(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-5';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 5,
      templateId: 'square_grid',
      properties: PaperProperties.defaultFor(PaperTemplateType.squareGrid),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '✂️ Activity 5: Lasso Selection & Transform\n\nChoose the Lasso tool and draw a loop around the shape below. You can drag to move it, resize it, duplicate it, or recolor it!',
        colorHex: '#BAE6FD',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Draw a box shape
    final rectPoints = [
      StrokePoint(x: 100, y: 220, timestamp: now.millisecondsSinceEpoch),
      StrokePoint(x: 220, y: 220, timestamp: now.millisecondsSinceEpoch + 10),
      StrokePoint(x: 220, y: 340, timestamp: now.millisecondsSinceEpoch + 20),
      StrokePoint(x: 100, y: 340, timestamp: now.millisecondsSinceEpoch + 30),
      StrokePoint(x: 100, y: 220, timestamp: now.millisecondsSinceEpoch + 40),
    ];
    await _strokeRepo.saveStroke(
      Stroke(
        id: _uuid.v4(),
        pageId: pageId,
        tool: ToolType.ballpointPen,
        colorValue: 0xFF0D9488,
        width: 3.0,
        opacity: 1.0,
        points: rectPoints,
        createdAt: now,
      ),
    );
  }

  // --- Page 6: Page Navigation & Scrubber ---
  Future<void> _provisionPage6(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-6';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 6,
      templateId: 'dotted_paper',
      properties: PaperProperties.defaultFor(PaperTemplateType.dottedPaper),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '📖 Activity 6: Page Scrubber & Navigation\n\nUse the bottom page indicator to scrub between pages, tap the Thumbnail Sidebar in the top app bar to see all pages, or swipe left/right to flip pages like a real book!',
        colorHex: '#DDD6FE',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // --- Page 7: Paper Templates ---
  Future<void> _provisionPage7(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-7';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 7,
      templateId: 'cornell_notes',
      properties: PaperProperties.defaultFor(PaperTemplateType.cornellNotes),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '📐 Activity 7: Professional Stationery Templates\n\nNaik Notes includes College Ruled, Wide Ruled, Grid, Dot Grid, Cornell Notes, Isometric, and Music Staves. Tap the Paper Settings icon in the top app bar to switch templates anytime.',
        colorHex: '#E2E8F0',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // --- Page 8: Gestures, Tilt & Palm Rejection ---
  Future<void> _provisionPage8(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-8';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 8,
      templateId: 'blank_paper',
      properties: PaperProperties.defaultFor(PaperTemplateType.blankPaper),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 140.0,
        content:
            '🖐️ Activity 8: Stylus & Palm Rejection\n\nToggle Stylus-Only Mode or Palm Rejection from the toolbar. Pinch with two fingers to zoom up to 500% and pan seamlessly across the canvas without accidental marks.',
        colorHex: '#FEF08A',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  // --- Page 9: PDF Export & Cloud Sync ---
  Future<void> _provisionPage9(String notebookId, DateTime now) async {
    final pageId = '$notebookId-page-9';
    final page = NotebookPage(
      id: pageId,
      notebookId: notebookId,
      pageNumber: 9,
      templateId: 'college_ruled',
      properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
      createdAt: now,
      updatedAt: now,
    );
    await _pageRepo.savePage(page);

    await _stickyNoteRepo.saveStickyNote(
      StickyNote(
        id: _uuid.v4(),
        pageId: pageId,
        x: 40.0,
        y: 40.0,
        width: 320.0,
        height: 150.0,
        content:
            '🚀 Activity 9: PDF Export & Cloud Sync\n\nTap the Export icon in the top app bar to generate high-fidelity vector PDFs or PNG snapshots of single pages or the entire notebook. Your work auto-syncs across Android, iPadOS, and Windows!',
        colorHex: '#BBF7D0',
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Stroke _createLineStroke({
    required String pageId,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required double width,
    required int color,
    required DateTime now,
  }) {
    return Stroke(
      id: _uuid.v4(),
      pageId: pageId,
      tool: ToolType.ballpointPen,
      colorValue: color,
      width: width,
      opacity: 1.0,
      points: [
        StrokePoint(
          x: startX,
          y: startY,
          pressure: 0.5,
          timestamp: now.millisecondsSinceEpoch,
        ),
        StrokePoint(
          x: endX,
          y: endY,
          pressure: 0.5,
          timestamp: now.millisecondsSinceEpoch + 50,
        ),
      ],
      createdAt: now,
    );
  }
}

/// Global Riverpod provider for the WelcomeNotebookService.
final welcomeNotebookServiceProvider = Provider<WelcomeNotebookService>((ref) {
  final notebookRepo = ref.watch(notebookRepositoryProvider);
  final pageRepo = ref.watch(pageRepositoryProvider);
  final strokeRepo = ref.watch(strokeRepositoryProvider);
  final stickyRepo = ref.watch(stickyNoteRepositoryProvider);
  return WelcomeNotebookService(notebookRepo, pageRepo, strokeRepo, stickyRepo);
});
