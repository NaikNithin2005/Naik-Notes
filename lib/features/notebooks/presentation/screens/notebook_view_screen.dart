import 'dart:async';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/canvas_element_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/data/canvas_elements_provider.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/canvas_floating_pill.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/canvas_minimal_toolbar.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/canvas_page_pill.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/canvas_top_nav_bar.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_canvas.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_shortcuts.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/math_formula_dialog.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';
import 'package:naik_notes/features/ai_assistant/presentation/widgets/ai_study_assistant_sheet.dart';
import 'package:naik_notes/features/audio/presentation/widgets/audio_recording_bar.dart';
import 'package:naik_notes/features/pdf/data/sticky_note_provider.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_document_search_bar.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_thumbnail_sidebar.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/sticky_note_widget.dart';
import 'package:naik_notes/features/search/data/search_provider.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/reading_mode_page_flip_view.dart';
import 'package:naik_notes/features/template_store/presentation/widgets/template_store_sheet.dart';
import 'package:naik_notes/features/templates/presentation/widgets/template_customizer_sheet.dart';
import 'package:naik_notes/features/version_history/presentation/widgets/version_history_sheet.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/note_attachments_sheet.dart';
import '../widgets/export_notebook_dialog.dart';
import '../widgets/rename_notebook_dialog.dart';

/// Clean, minimal, canvas-first workspace for Naik Notes.
/// Dedicates ~90% of screen to the writing surface with floating glassmorphic pills.
class NotebookViewScreen extends ConsumerStatefulWidget {
  final String notebookId;

  const NotebookViewScreen({super.key, required this.notebookId});

  @override
  ConsumerState<NotebookViewScreen> createState() => _NotebookViewScreenState();
}

class _NotebookViewScreenState extends ConsumerState<NotebookViewScreen> {
  bool _showThumbnails = false;
  bool _showSearch = false;
  bool _showAudioBar = false;
  bool _isContinuousScroll = true; // Top-to-Bottom Vertical Scroll is Default!
  bool _isReadingMode = false;
  bool _isWriting = false;
  Timer? _writingFadeTimer;
  String _searchQuery = '';
  int _activeMatchIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Notebook? _fallbackNotebook;
  late final TransformationController _transformationController =
      TransformationController();
  final ScrollController _continuousScrollController = ScrollController();
  late final PageController _horizontalPageController;
  double _lastAvailableWidth = 0.0;
  double _lastAvailableHeight = 0.0;
  StrokesNotifier? _strokesNotifier;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    _strokesNotifier = ref.read(strokesNotifierProvider.notifier);
    _horizontalPageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentPageIndexProvider.notifier).setPage(1);
      _loadNotebookData();
    });
  }

  void _onTransformationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _writingFadeTimer?.cancel();
    _transformationController.removeListener(_onTransformationChanged);
    _horizontalPageController.dispose();
    _strokesNotifier?.flushPendingStrokes();
    _transformationController.dispose();
    _continuousScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotebookData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final notebooks = ref.read(notebooksProvider);
      var nb = notebooks.where((n) => n.id == widget.notebookId).firstOrNull;
      if (nb == null) {
        nb = await ref
            .read(notebookRepositoryProvider)
            .getNotebookById(widget.notebookId);
        if (mounted && nb != null) {
          setState(() => _fallbackNotebook = nb);
        }
      }
      if (nb != null) {
        await ref
            .read(notebookPagesProvider.notifier)
            .loadPages(
              widget.notebookId,
              templateId: nb.paperTemplateId,
              pageSize: nb.pageSize,
              orientation: nb.orientation,
              count: nb.pageCount,
            );
      } else {
        await ref
            .read(notebookPagesProvider.notifier)
            .loadPages(widget.notebookId, count: 1);
      }
      final loaded =
          ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
      for (final p in loaded) {
        ref.read(stickyNotesProvider.notifier).loadStickyNotes(p.id);
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load notebook: $e';
        });
      }
    }
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 5.0) {
      _transformationController.value =
          Matrix4.copy(_transformationController.value)..scale(1.2, 1.2, 1.0);
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.4) {
      _transformationController.value =
          Matrix4.copy(_transformationController.value)..scale(0.8, 0.8, 1.0);
    }
  }

  void _resetZoom() {
    _fitToWidth();
  }

  NotebookPage? _getActivePage(List<NotebookPage> pageList) {
    if (pageList.isEmpty) return null;
    final currentIdx = ref.read(currentPageIndexProvider);
    final clamped = currentIdx.clamp(1, pageList.length);
    return pageList[clamped - 1];
  }

  Future<void> _handleQuickAddPage() async {
    final allPages = ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
    final activePage = _getActivePage(allPages);
    final templateId = activePage?.templateId ?? _fallbackNotebook?.paperTemplateId ?? 'college_ruled';
    final properties = activePage?.properties;

    await ref.read(notebookPagesProvider.notifier).addPage(
      widget.notebookId,
      templateId: templateId,
      properties: properties,
    );

    final updatedPages = ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
    final newPageNumber = updatedPages.length;
    ref.read(currentPageIndexProvider.notifier).setPage(newPageNumber);

    if (_isContinuousScroll && _continuousScrollController.hasClients) {
      _continuousScrollController.animateTo(
        _continuousScrollController.position.maxScrollExtent + 900,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else if (!_isContinuousScroll && _horizontalPageController.hasClients) {
      _horizontalPageController.animateToPage(
        newPageNumber - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _handleTakePhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera);
      if (photo != null && mounted) {
        final allPages = ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
        final activePage = _getActivePage(allPages);
        if (activePage != null) {
          final newElement = CanvasElement(
            id: 'elem-${const Uuid().v4()}',
            pageId: activePage.id,
            type: CanvasElementType.image,
            x: 80.0,
            y: 120.0,
            width: 300.0,
            height: 220.0,
            imagePath: photo.path,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          ref.read(canvasElementsProvider.notifier).addElement(newElement);
        }
      }
    } catch (e) {
      debugPrint('Camera not available or permitted: $e');
    }
  }

  Future<void> _handleImportImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isNotEmpty && result.first.path != null && mounted) {
        final path = result.first.path!;
        final allPages = ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
        final activePage = _getActivePage(allPages);
        if (activePage != null) {
          final newElement = CanvasElement(
            id: 'elem-${const Uuid().v4()}',
            pageId: activePage.id,
            type: CanvasElementType.image,
            x: 80.0,
            y: 120.0,
            width: 300.0,
            height: 220.0,
            imagePath: path,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          ref.read(canvasElementsProvider.notifier).addElement(newElement);
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  Future<void> _handleInsertMath() async {
    final formula = await MathFormulaDialog.show(context);
    if (formula != null && mounted) {
      final allPages = ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
      final activePage = _getActivePage(allPages);
      if (activePage != null) {
        final newElement = CanvasElement(
          id: 'elem-${const Uuid().v4()}',
          pageId: activePage.id,
          type: CanvasElementType.mathFormula,
          x: 120.0,
          y: 150.0,
          width: 240.0,
          height: 80.0,
          content: formula,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        ref.read(canvasElementsProvider.notifier).addElement(newElement);
      }
    }
  }

  Future<void> _handleAddStickyNote() async {
    final allPages = ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
    final activePage = _getActivePage(allPages);
    if (activePage != null) {
      final newElement = CanvasElement(
        id: 'elem-${const Uuid().v4()}',
        pageId: activePage.id,
        type: CanvasElementType.stickyNote,
        x: 80.0,
        y: 100.0,
        width: 180.0,
        height: 150.0,
        content: '',
        colorHex: '#FEF08A',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      ref.read(canvasElementsProvider.notifier).addElement(newElement);
    }
  }

  void _fitToWidth({
    double? availableWidth,
    double? availableHeight,
    double? pageWidth,
    double? pageHeight,
  }) {
    final pagesMap = ref.read(notebookPagesProvider);
    final pages = pagesMap[widget.notebookId] ?? [];
    final currentPageIndex = ref.read(currentPageIndexProvider);
    final clampedIndex = currentPageIndex.clamp(
      1,
      pages.isEmpty ? 1 : pages.length,
    );
    final activePage = pages.isNotEmpty && clampedIndex <= pages.length
        ? pages[clampedIndex - 1]
        : null;

    final pWidth = pageWidth ?? activePage?.width ?? 841.89;
    final pHeight = pageHeight ?? activePage?.height ?? 595.28;
    if (pWidth <= 0) return;

    final screenW = availableWidth != null && availableWidth > 0
        ? availableWidth
        : (_lastAvailableWidth > 0
            ? _lastAvailableWidth
            : MediaQuery.of(context).size.width);
    final screenH = availableHeight != null && availableHeight > 0
        ? availableHeight
        : (_lastAvailableHeight > 0
            ? _lastAvailableHeight
            : MediaQuery.of(context).size.height);

    // Fit-to-Width: Fill 80–85% of viewport width on Desktop/Tablet Landscape, capped at 1150px
    double targetContentWidth = screenW * 0.85;
    if (targetContentWidth > 1150.0) {
      targetContentWidth = 1150.0;
    }
    if (screenW < 600) {
      targetContentWidth = (screenW - 24).clamp(300.0, 700.0);
    }
    final targetScale = (targetContentWidth / pWidth).clamp(0.4, 5.0);

    // Center horizontally in viewport
    final tx = (screenW - (pWidth * targetScale)) / 2.0;

    // Center vertically if it fits, otherwise align top with 72px clearance for floating pills
    final scaledHeight = pHeight * targetScale;
    final double ty;
    if (scaledHeight + 120 <= screenH) {
      ty = (screenH - scaledHeight) / 2.0;
    } else {
      ty = 72.0;
    }

    final matrix = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(targetScale, targetScale, 1.0);

    setState(() {
      _transformationController.value = matrix;
    });
  }

  void _openRenameDialog(Notebook notebook) {
    showDialog<void>(
      context: context,
      builder: (ctx) => RenameNotebookDialog(notebook: notebook),
    );
  }

  void _openTemplateSettings(
    String pageId,
    PaperTemplateType currentType,
    PaperProperties currentProps,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => TemplateCustomizerSheet(
        initialType: currentType,
        initialProperties: currentProps,
        onApply: (type, properties, applyToAll) async {
          final pagesNotifier = ref.read(notebookPagesProvider.notifier);
          if (applyToAll) {
            final allPages =
                ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
            for (final p in allPages) {
              await pagesNotifier.changePageTemplate(
                widget.notebookId,
                p.id,
                type.id,
                properties,
              );
            }
          } else {
            await pagesNotifier.changePageTemplate(
              widget.notebookId,
              pageId,
              type.id,
              properties,
            );
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                applyToAll
                    ? 'Applied ${type.displayName} to all pages'
                    : 'Updated page to ${type.displayName}',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _duplicateCurrentPage(NotebookPage activePage) async {
    final newPage = await ref
        .read(notebookPagesProvider.notifier)
        .duplicatePage(widget.notebookId, activePage.id);
    if (newPage != null) {
      final strokes =
          ref.read(strokesNotifierProvider).pageStrokes[activePage.id] ?? [];
      for (final s in strokes) {
        final clonedStroke = s.copyWith(
          id: const Uuid().v4(),
          pageId: newPage.id,
        );
        await ref
            .read(strokesNotifierProvider.notifier)
            .addStroke(newPage.id, clonedStroke);
      }
      ref.read(currentPageIndexProvider.notifier).setPage(newPage.pageNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Duplicated Page ${activePage.pageNumber} as Page ${newPage.pageNumber}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _deleteCurrentPage(NotebookPage activePage, int totalPages) async {
    if (totalPages <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the only page in the notebook.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page?'),
        content: Text(
          'Are you sure you want to delete Page ${activePage.pageNumber}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(notebookPagesProvider.notifier)
          .deletePage(widget.notebookId, activePage.id);
      ref
          .read(currentPageIndexProvider.notifier)
          .setPage((activePage.pageNumber - 1).clamp(1, totalPages - 1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted Page ${activePage.pageNumber}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAddPageDialog({
    String? referencePageId,
    String initialPosition = 'end',
  }) {
    final pages = ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
    final currentPageIndex = ref.read(currentPageIndexProvider);
    final clampedIndex = currentPageIndex.clamp(
      1,
      pages.isEmpty ? 1 : pages.length,
    );
    final activePage = referencePageId != null
        ? pages.where((p) => p.id == referencePageId).firstOrNull
        : (pages.isNotEmpty && clampedIndex <= pages.length
              ? pages[clampedIndex - 1]
              : null);

    String selectedPosition = initialPosition;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.55,
              minChildSize: 0.35,
              maxChildSize: 0.85,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Insert New Page',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('At End'),
                            selected: selectedPosition == 'end',
                            onSelected: (val) {
                              if (val) setSheetState(() => selectedPosition = 'end');
                            },
                          ),
                          const SizedBox(width: 8),
                          if (activePage != null) ...[
                            ChoiceChip(
                              label: Text('Before P${activePage.pageNumber}'),
                              selected: selectedPosition == 'before',
                              onSelected: (val) {
                                if (val) setSheetState(() => selectedPosition = 'before');
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: Text('After P${activePage.pageNumber}'),
                              selected: selectedPosition == 'after',
                              onSelected: (val) {
                                if (val) setSheetState(() => selectedPosition = 'after');
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Paper Template',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          itemCount: PaperTemplateType.values.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (c, idx) {
                            final type = PaperTemplateType.values[idx];
                            return ListTile(
                              title: Text(
                                type.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                type.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: const Icon(Icons.add_circle_outline, size: 20),
                              onTap: () async {
                                Navigator.of(sheetCtx).pop();
                                NotebookPage newPage;
                                String actionDescription;

                                if (selectedPosition == 'before' && activePage != null) {
                                  newPage = await ref
                                      .read(notebookPagesProvider.notifier)
                                      .insertPageBefore(
                                        widget.notebookId,
                                        activePage.id,
                                        templateId: type.id,
                                      );
                                  actionDescription =
                                      'Inserted Page ${newPage.pageNumber} before Page ${activePage.pageNumber}';
                                } else if (selectedPosition == 'after' && activePage != null) {
                                  newPage = await ref
                                      .read(notebookPagesProvider.notifier)
                                      .insertPageAfter(
                                        widget.notebookId,
                                        activePage.id,
                                        templateId: type.id,
                                      );
                                  actionDescription =
                                      'Inserted Page ${newPage.pageNumber} after Page ${activePage.pageNumber}';
                                } else {
                                  newPage = await ref
                                      .read(notebookPagesProvider.notifier)
                                      .addPage(
                                        widget.notebookId,
                                        templateId: type.id,
                                      );
                                  actionDescription =
                                      'Added Page ${newPage.pageNumber} at end';
                                }

                                ref
                                    .read(currentPageIndexProvider.notifier)
                                    .setPage(newPage.pageNumber);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '$actionDescription (${type.displayName})',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onOverflowAction(
    String action,
    Notebook notebook,
    List<NotebookPage> pages,
    NotebookPage? activePage,
  ) {
    switch (action) {
      case 'readingMode':
        setState(() => _isReadingMode = !_isReadingMode);
        if (_isReadingMode) {
          ref.read(activeToolProvider.notifier).setTool(ToolType.pan);
        }
        break;
      case 'search':
        setState(() => _showSearch = !_showSearch);
        break;
      case 'attachments':
        NoteAttachmentsSheet.show(context, widget.notebookId);
        break;
      case 'audio':
        setState(() => _showAudioBar = !_showAudioBar);
        break;
      case 'aiAssistant':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => AiStudyAssistantSheet(
            notebookId: widget.notebookId,
            notebookTitle: notebook.title,
          ),
        );
        break;
      case 'history':
        if (activePage != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (ctx) => VersionHistorySheet(
              pageId: activePage.id,
              notebookId: widget.notebookId,
            ),
          );
        }
        break;
      case 'templateStore':
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => const TemplateStoreSheet(),
        );
        break;
      case 'bookmark':
        if (activePage != null) {
          ref
              .read(notebookPagesProvider.notifier)
              .toggleBookmark(widget.notebookId, activePage.id);
        }
        break;
      case 'export':
        ExportNotebookDialog.show(
          context,
          notebook: notebook,
          pages: pages,
          activePage: activePage,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final notebooks = ref.watch(notebooksProvider);
    final notebook = notebooks
        .where((nb) => nb.id == widget.notebookId)
        .firstOrNull ?? _fallbackNotebook;

    if (notebook == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Loading notebook...'),
              ] else ...[
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Notebook not found in library.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Library'),
                  onPressed: () => context.go(RouteNames.dashboard),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final pagesMap = ref.watch(notebookPagesProvider);
    final pages = pagesMap[widget.notebookId] ?? [];
    final currentPageIndex = ref.watch(currentPageIndexProvider);

    final clampedIndex = currentPageIndex.clamp(
      1,
      pages.isEmpty ? 1 : pages.length,
    );
    final activePage = pages.isNotEmpty && clampedIndex <= pages.length
        ? pages[clampedIndex - 1]
        : null;

    final activeType =
        activePage?.templateType ?? PaperTemplateType.collegeRuled;
    final activeProps =
        activePage?.properties ?? PaperProperties.defaultFor(activeType);

    final searchResultsAsync = ref.watch(
      inDocumentSearchResultsProvider(widget.notebookId),
    );
    final allMatches =
        <({String pageId, int pageNumber, WordBoundingBox box})>[];
    searchResultsAsync.whenData((items) {
      for (final item in items) {
        if (item.pageId != null && item.pageNumber != null) {
          for (final b in item.matchingBoxes) {
            allMatches.add((
              pageId: item.pageId!,
              pageNumber: item.pageNumber!,
              box: b,
            ));
          }
        }
      }
    });

    final totalMatches = allMatches.length;
    final currentMatchDisplay = totalMatches == 0 ? 0 : (_activeMatchIndex + 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _strokesNotifier?.flushPendingStrokes();
          if (context.mounted) {
            context.go(RouteNames.dashboard);
          }
        }
      },
      child: Scaffold(
        backgroundColor: _isReadingMode
            ? const Color(0xFFF3EEDC)
            : (isDark ? const Color(0xFF141416) : const Color(0xFFE8E4DF)),
        body: HandwritingShortcuts(
          pageId: activePage?.id ?? '',
          onToggleSearch: () => setState(() => _showSearch = !_showSearch),
          onZoomIn: _zoomIn,
          onZoomOut: _zoomOut,
          onResetZoom: _resetZoom,
          onAddPage: _showAddPageDialog,
          onAddStickyNote: activePage != null
              ? () async {
                  await ref
                      .read(stickyNotesProvider.notifier)
                      .addStickyNote(activePage.id, x: 80.0, y: 100.0);
                }
              : null,
          child: Listener(
            onPointerDown: (_) {
              _writingFadeTimer?.cancel();
              if (!_isWriting) {
                setState(() => _isWriting = true);
              }
            },
            onPointerUp: (_) {
              _writingFadeTimer?.cancel();
              _writingFadeTimer = Timer(const Duration(milliseconds: 300), () {
                if (mounted && _isWriting) {
                  setState(() => _isWriting = false);
                }
              });
            },
            child: Stack(
              children: [
                // ========================================================
                // LAYER 1: WRITING CANVAS SURFACE (~90% Screen Workspace)
                // ========================================================
                Positioned.fill(
                  child: activePage == null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoading) ...[
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                const Text('Loading pages...'),
                              ] else ...[
                                const Icon(
                                  Icons.note_add_outlined,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                const Text('No pages found in this notebook.'),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Page'),
                                  onPressed: () async {
                                    await ref
                                        .read(notebookPagesProvider.notifier)
                                        .addPage(
                                          widget.notebookId,
                                          templateId: notebook.paperTemplateId,
                                        );
                                  },
                                ),
                              ],
                            ],
                          ),
                        )
                      : _isReadingMode
                          ? ReadingModePageFlipView(
                              notebookId: widget.notebookId,
                              pages: pages,
                              initialPage: clampedIndex,
                              onExitReadingMode: () =>
                                  setState(() => _isReadingMode = false),
                            )
                          : _isContinuousScroll
                              // ----------------------------------------------------
                              // MODE 1: TOP-TO-BOTTOM VERTICAL SCROLL (DEFAULT)
                              // ----------------------------------------------------
                              ? LayoutBuilder(
                                  builder: (context, constraints) {
                                    _lastAvailableWidth = constraints.maxWidth;
                                    _lastAvailableHeight = constraints.maxHeight;
                                    final isPhone = constraints.maxWidth < 600;

                                    // Fit-to-Width default: fill 80-85% of viewport width on desktop (max 1150px)
                                    final targetWidth = isPhone
                                        ? (constraints.maxWidth - 24).clamp(300.0, 750.0)
                                        : math.min(1150.0, constraints.maxWidth * 0.85);

                                    return Scrollbar(
                                      controller: _continuousScrollController,
                                      thumbVisibility: true,
                                      child: ListView.builder(
                                        controller: _continuousScrollController,
                                        padding: const EdgeInsets.only(top: 72, bottom: 96),
                                        itemCount: pages.length + 1,
                                        itemBuilder: (ctx, idx) {
                                          if (idx == pages.length) {
                                            // Pull-past-last-page / Add Page Card
                                            return Center(
                                              child: Container(
                                                width: targetWidth,
                                                margin: const EdgeInsets.symmetric(vertical: 24),
                                                padding: const EdgeInsets.all(28),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0x20FFFFFF)
                                                      : Colors.white.withValues(alpha: 0.65),
                                                  borderRadius: BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.grey.withValues(alpha: 0.25),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.add_circle_outline_rounded,
                                                      size: 36,
                                                      color: Colors.blueAccent,
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      'End of Document (Page ${pages.length} of ${pages.length})',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    FilledButton.icon(
                                                      icon: const Icon(Icons.add, size: 18),
                                                      label: const Text('Add Page'),
                                                      onPressed: _showAddPageDialog,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          }

                                          final p = pages[idx];
                                          final pType = p.templateType;
                                          final pProps = p.properties;
                                          final stickyNotes = ref.watch(pageStickyNotesProvider(p.id));
                                          final pMatches = allMatches
                                              .where((m) => m.pageId == p.id)
                                              .map((m) => m.box)
                                              .toList();
                                          final pActiveBoxIdx = (allMatches.isNotEmpty &&
                                                  _activeMatchIndex < allMatches.length &&
                                                  allMatches[_activeMatchIndex].pageId == p.id)
                                              ? pMatches.indexOf(allMatches[_activeMatchIndex].box)
                                              : -1;

                                          final pageScale = targetWidth / p.width;
                                          final targetHeight = p.height * pageScale;

                                          return Center(
                                            child: Container(
                                              width: targetWidth,
                                              height: targetHeight,
                                              margin: const EdgeInsets.symmetric(vertical: 14),
                                              decoration: BoxDecoration(
                                                color: _isReadingMode
                                                    ? const Color(0xFFFFFDF5)
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.12),
                                                    blurRadius: 18,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.contain,
                                                alignment: Alignment.topLeft,
                                                child: SizedBox(
                                                  width: p.width,
                                                  height: p.height,
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      HandwritingCanvas(
                                                        pageId: p.id,
                                                        type: pType,
                                                        properties: pProps,
                                                        width: p.width,
                                                        height: p.height,
                                                        searchMatches: pMatches,
                                                        activeSearchIndex: pActiveBoxIdx,
                                                        readOnly: _isReadingMode ||
                                                            ref.watch(activeToolProvider) == ToolType.pan,
                                                      ),
                                                      ...stickyNotes.map(
                                                        (note) => StickyNoteWidget(note: note),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                )
                              // ----------------------------------------------------
                              // MODE 2: LEFT-TO-RIGHT HORIZONTAL PAGE FLIP
                              // ----------------------------------------------------
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    _lastAvailableWidth = constraints.maxWidth;
                                    _lastAvailableHeight = constraints.maxHeight;
                                    final isPhone = constraints.maxWidth < 600;

                                    final targetWidth = isPhone
                                        ? (constraints.maxWidth - 24).clamp(300.0, 750.0)
                                        : math.min(1150.0, constraints.maxWidth * 0.85);

                                    return PageView.builder(
                                      controller: _horizontalPageController,
                                      itemCount: pages.length + 1,
                                      onPageChanged: (idx) {
                                        if (idx < pages.length) {
                                          ref
                                              .read(currentPageIndexProvider.notifier)
                                              .setPage(idx + 1);
                                        }
                                      },
                                      itemBuilder: (ctx, idx) {
                                        if (idx == pages.length) {
                                          return Center(
                                            child: Container(
                                              width: targetWidth,
                                              margin: const EdgeInsets.only(top: 72, bottom: 96),
                                              padding: const EdgeInsets.all(32),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? const Color(0x20FFFFFF)
                                                    : Colors.white.withValues(alpha: 0.65),
                                                borderRadius: BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.grey.withValues(alpha: 0.25),
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.add_circle_outline_rounded,
                                                    size: 48,
                                                    color: Colors.blueAccent,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    'Swipe Past Last Page to Add Page',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  FilledButton.icon(
                                                    icon: const Icon(Icons.add),
                                                    label: const Text('Add Page'),
                                                    onPressed: _showAddPageDialog,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }

                                        final p = pages[idx];
                                        final pageScale = targetWidth / p.width;
                                        final targetHeight = p.height * pageScale;
                                        final stickyNotes = ref.watch(pageStickyNotesProvider(p.id));
                                        final pMatches = allMatches
                                            .where((m) => m.pageId == p.id)
                                            .map((m) => m.box)
                                            .toList();
                                        final pActiveBoxIdx = (allMatches.isNotEmpty &&
                                                _activeMatchIndex < allMatches.length &&
                                                allMatches[_activeMatchIndex].pageId == p.id)
                                            ? pMatches.indexOf(allMatches[_activeMatchIndex].box)
                                            : -1;

                                        return Center(
                                          child: SingleChildScrollView(
                                            padding: const EdgeInsets.only(top: 72, bottom: 96),
                                            child: Container(
                                              width: targetWidth,
                                              height: targetHeight,
                                              decoration: BoxDecoration(
                                                color: _isReadingMode
                                                    ? const Color(0xFFFFFDF5)
                                                    : Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.12),
                                                    blurRadius: 18,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: FittedBox(
                                                fit: BoxFit.contain,
                                                alignment: Alignment.topLeft,
                                                child: SizedBox(
                                                  width: p.width,
                                                  height: p.height,
                                                  child: Stack(
                                                    clipBehavior: Clip.none,
                                                    children: [
                                                      HandwritingCanvas(
                                                        pageId: p.id,
                                                        type: p.templateType,
                                                        properties: p.properties,
                                                        width: p.width,
                                                        height: p.height,
                                                        searchMatches: pMatches,
                                                        activeSearchIndex: pActiveBoxIdx,
                                                        readOnly: _isReadingMode ||
                                                            ref.watch(activeToolProvider) == ToolType.pan,
                                                      ),
                                                      ...stickyNotes.map(
                                                        (note) => StickyNoteWidget(note: note),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                ),

                // ========================================================
                // LAYER 2: THUMBNAILS SIDEBAR (When Opened)
                // ========================================================
                if (_showThumbnails)
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    child: SafeArea(
                      child: PdfThumbnailSidebar(
                        notebookId: widget.notebookId,
                        pages: pages,
                        currentPageIndex: clampedIndex,
                        onSelectPage: (idx) {
                          ref.read(currentPageIndexProvider.notifier).setPage(idx);
                        },
                        onInsertPage: (pageId, pos) {
                          _showAddPageDialog(
                            referencePageId: pageId,
                            initialPosition: pos,
                          );
                        },
                        onClose: () => setState(() => _showThumbnails = false),
                      ),
                    ),
                  ),

                // ========================================================
                // LAYER 3: IN-DOCUMENT SEARCH BAR OVERLAY
                // ========================================================
                if (_showSearch)
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: PdfDocumentSearchBar(
                            currentMatchIndex: currentMatchDisplay,
                            totalMatches: totalMatches,
                            onSearch: (q) {
                              setState(() {
                                _searchQuery = q;
                                _activeMatchIndex = 0;
                              });
                              ref
                                  .read(inDocumentSearchQueryProvider.notifier)
                                  .setQuery(q);
                              if (q.isNotEmpty && allMatches.isNotEmpty) {
                                ref
                                    .read(currentPageIndexProvider.notifier)
                                    .setPage(allMatches[0].pageNumber);
                              }
                            },
                            onNextMatch: () {
                              if (allMatches.isEmpty) return;
                              setState(() {
                                _activeMatchIndex =
                                    (_activeMatchIndex + 1) % allMatches.length;
                                final targetPage =
                                    allMatches[_activeMatchIndex].pageNumber;
                                if (targetPage != clampedIndex) {
                                  ref
                                      .read(currentPageIndexProvider.notifier)
                                      .setPage(targetPage);
                                }
                              });
                            },
                            onPreviousMatch: () {
                              if (allMatches.isEmpty) return;
                              setState(() {
                                _activeMatchIndex =
                                    (_activeMatchIndex - 1 + allMatches.length) %
                                    allMatches.length;
                                final targetPage =
                                    allMatches[_activeMatchIndex].pageNumber;
                                if (targetPage != clampedIndex) {
                                  ref
                                      .read(currentPageIndexProvider.notifier)
                                      .setPage(targetPage);
                                }
                              });
                            },
                            onClose: () {
                              setState(() {
                                _showSearch = false;
                                _searchQuery = '';
                                _activeMatchIndex = 0;
                              });
                              ref
                                  .read(inDocumentSearchQueryProvider.notifier)
                                  .clear();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                // ========================================================
                // LAYER 4: AUDIO RECORDING BAR OVERLAY
                // ========================================================
                if (_showAudioBar)
                  Positioned(
                    top: 60,
                    left: 20,
                    right: 20,
                    child: SafeArea(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: AudioRecordingBar(
                            notebookId: widget.notebookId,
                            activePageId: activePage?.id,
                            onClose: () => setState(() => _showAudioBar = false),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ========================================================
                // LAYER 5: FLOATING CHROME WITH AUTO-FADE WHILE WRITING
                // ========================================================
                AnimatedOpacity(
                  opacity: _isWriting ? 0.25 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _isWriting,
                    child: Stack(
                      children: [
                        // Focus / Reading Mode: Minimal Exit Button
                        if (_isReadingMode)
                          Positioned(
                            top: 14,
                            left: 16,
                            child: SafeArea(
                              child: CanvasFloatingPill(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                                  label: const Text('Exit Focus Mode'),
                                  onPressed: () =>
                                      setState(() => _isReadingMode = false),
                                ),
                              ),
                            ),
                          )
                        else ...[
                          // Top Navigation Bar (Top-Left Pill & Top-Right Pill)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: SafeArea(
                              bottom: false,
                              child: CanvasTopNavBar(
                                title: _searchQuery.isNotEmpty
                                    ? '${notebook.title} (Search: "$_searchQuery")'
                                    : notebook.title,
                                syncStatus: notebook.syncStatus,
                                isReadingMode: _isReadingMode,
                                canUndo: activePage != null &&
                                    ref.watch(canUndoProvider(activePage.id)),
                                canRedo: activePage != null &&
                                    ref.watch(canRedoProvider(activePage.id)),
                                currentZoomPercent: (_transformationController.value
                                            .getMaxScaleOnAxis() *
                                        100)
                                    .round(),
                                isContinuousScroll: _isContinuousScroll,
                                currentTemplate: activeType,
                                onBack: () async {
                                  await _strokesNotifier?.flushPendingStrokes();
                                  if (context.mounted) {
                                    context.go(RouteNames.dashboard);
                                  }
                                },
                                onEditTitle: () => _openRenameDialog(notebook),
                                onUndo: () {
                                  if (activePage != null) {
                                    ref
                                        .read(strokesNotifierProvider.notifier)
                                        .undo(activePage.id);
                                  }
                                },
                                onRedo: () {
                                  if (activePage != null) {
                                    ref
                                        .read(strokesNotifierProvider.notifier)
                                        .redo(activePage.id);
                                  }
                                },
                                onResetZoom: _resetZoom,
                                onToggleScrollMode: () {
                                  setState(
                                    () => _isContinuousScroll = !_isContinuousScroll,
                                  );
                                },
                                onSelectTemplate: (t) async {
                                  if (activePage != null) {
                                    await ref
                                        .read(notebookPagesProvider.notifier)
                                        .changePageTemplate(
                                          widget.notebookId,
                                          activePage.id,
                                          t.id,
                                          PaperProperties.defaultFor(t),
                                        );
                                  }
                                },
                                onOpenTemplateCustomizer: () {
                                  if (activePage != null) {
                                    _openTemplateSettings(
                                      activePage.id,
                                      activeType,
                                      activeProps,
                                    );
                                  }
                                },
                                onExport: () {
                                  ExportNotebookDialog.show(
                                    context,
                                    notebook: notebook,
                                    pages: pages,
                                    activePage: activePage,
                                  );
                                },
                                onOverflowAction: (act) => _onOverflowAction(
                                  act,
                                  notebook,
                                  pages,
                                  activePage,
                                ),
                              ),
                            ),
                          ),

                          // Top-Center Minimal Floating Toolbar (Desktop & Tablet >= 600px)
                          if (activePage != null &&
                              MediaQuery.of(context).size.width >= 600)
                            Positioned(
                              top: 8,
                              left: 0,
                              right: 0,
                              child: SafeArea(
                                bottom: false,
                                child: Center(
                                  child: CanvasMinimalToolbar(
                                    pageId: activePage.id,
                                    onAddStickyNote: _handleAddStickyNote,
                                    onImportImage: _handleImportImage,
                                    onTakePhoto: _handleTakePhoto,
                                    onInsertMath: _handleInsertMath,
                                  ),
                                ),
                              ),
                            ),

                          // Bottom Floating Toolbar (Phone < 600px)
                          if (activePage != null &&
                              MediaQuery.of(context).size.width < 600)
                            Positioned(
                              bottom: 16,
                              left: 0,
                              right: 0,
                              child: SafeArea(
                                top: false,
                                child: Center(
                                  child: CanvasMinimalToolbar(
                                    pageId: activePage.id,
                                    onAddStickyNote: _handleAddStickyNote,
                                    onImportImage: _handleImportImage,
                                    onTakePhoto: _handleTakePhoto,
                                    onInsertMath: _handleInsertMath,
                                  ),
                                ),
                              ),
                            ),

                          // Bottom-Right Page Pill: [ 1 / 3 | + ]
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: SafeArea(
                              top: false,
                              child: CanvasPagePill(
                                currentPage: clampedIndex,
                                totalPages: pages.length,
                                pages: pages,
                                onAddPage: _handleQuickAddPage,
                                onSelectPage: (idx) {
                                  ref
                                      .read(currentPageIndexProvider.notifier)
                                      .setPage(idx);
                                  if (!_isContinuousScroll &&
                                      _horizontalPageController.hasClients) {
                                    _horizontalPageController.jumpToPage(idx - 1);
                                  }
                                },
                                onDuplicatePage: (p) => _duplicateCurrentPage(p),
                                onDeletePage: (p) =>
                                    _deleteCurrentPage(p, pages.length),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
