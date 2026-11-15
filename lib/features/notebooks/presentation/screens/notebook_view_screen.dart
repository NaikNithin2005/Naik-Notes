import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/core/presentation/responsive_layout.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_canvas.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_shortcuts.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_toolbar.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';
import 'package:naik_notes/features/ai_assistant/presentation/widgets/ai_study_assistant_sheet.dart';
import 'package:naik_notes/features/audio/data/audio_provider.dart';
import 'package:naik_notes/features/audio/presentation/widgets/audio_recording_bar.dart';
import 'package:naik_notes/features/pdf/data/sticky_note_provider.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_document_search_bar.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/pdf_thumbnail_sidebar.dart';
import 'package:naik_notes/features/pdf/presentation/widgets/sticky_note_widget.dart';
import 'package:naik_notes/features/search/data/search_provider.dart';
import 'package:naik_notes/features/templates/presentation/widgets/template_customizer_sheet.dart';
import 'package:naik_notes/services/pdf/pdf_service.dart';

/// Notebook reader & writing canvas workspace.
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
  bool _isContinuousScroll = false;
  String _searchQuery = '';
  int _activeMatchIndex = 0;
  late final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notebooks = ref.read(notebooksProvider);
      final nb = notebooks.firstWhere(
        (n) => n.id == widget.notebookId,
        orElse: () => notebooks.first,
      );
      ref
          .read(notebookPagesProvider.notifier)
          .loadPages(
            widget.notebookId,
            templateId: nb.paperTemplateId,
            pageSize: nb.pageSize,
            orientation: nb.orientation,
            count: nb.pageCount,
          )
          .then((_) {
            final loaded =
                ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
            for (final p in loaded) {
              ref.read(stickyNotesProvider.notifier).loadStickyNotes(p.id);
            }
          });
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 3.5) {
      _transformationController.value = _transformationController.value
        ..scale(1.2, 1.2, 1.0);
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.4) {
      _transformationController.value = _transformationController.value
        ..scale(0.8, 0.8, 1.0);
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
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

  void _showAddPageDialog() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (sheetCtx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Insert New Page',
                        style: Theme.of(sheetCtx).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a paper template for this new page:',
                    style: Theme.of(sheetCtx).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: PaperTemplateType.values.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (itemCtx, index) {
                        final type = PaperTemplateType.values[index];
                        return ListTile(
                          title: Text(
                            type.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            type.description,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                          ),
                          onTap: () async {
                            Navigator.of(sheetCtx).pop();
                            final newPage = await ref
                                .read(notebookPagesProvider.notifier)
                                .addPage(
                                  widget.notebookId,
                                  templateId: type.id,
                                );
                            ref
                                .read(currentPageIndexProvider.notifier)
                                .setPage(newPage.pageNumber);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added Page ${newPage.pageNumber} (${type.displayName})',
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notebooks = ref.watch(notebooksProvider);
    final notebook = notebooks.firstWhere(
      (nb) => nb.id == widget.notebookId,
      orElse: () => notebooks.first,
    );

    final pagesMap = ref.watch(notebookPagesProvider);
    final pages = pagesMap[widget.notebookId] ?? [];
    final currentPageIndex = ref.watch(currentPageIndexProvider);

    // Clamp current page to bounds
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

    final activeBoxesOnCurrentPage = activePage == null
        ? <WordBoundingBox>[]
        : allMatches
              .where((m) => m.pageId == activePage.id)
              .map((m) => m.box)
              .toList();
    final activeBoxIndexInPage =
        (allMatches.isNotEmpty &&
            _activeMatchIndex < allMatches.length &&
            allMatches[_activeMatchIndex].pageId == activePage?.id)
        ? activeBoxesOnCurrentPage.indexOf(allMatches[_activeMatchIndex].box)
        : -1;

    return Scaffold(
      backgroundColor: const Color(0xFFE8E4DF),
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Return to Library',
          onPressed: () => context.go(RouteNames.dashboard),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _searchQuery.isNotEmpty
                  ? '${notebook.title} (Search: "$_searchQuery")'
                  : notebook.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Page $clampedIndex of ${pages.isEmpty ? 1 : pages.length} • ${activeType.displayName}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: context.isCompact
            ? [
                // Thumbnail Sidebar Toggle
                IconButton(
                  icon: Icon(
                    _showThumbnails
                        ? Icons.view_sidebar
                        : Icons.view_sidebar_outlined,
                  ),
                  tooltip: 'Page Thumbnails',
                  onPressed: () =>
                      setState(() => _showThumbnails = !_showThumbnails),
                ),

                // Undo & Redo
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: 'Undo',
                  onPressed:
                      activePage != null &&
                          ref.watch(canUndoProvider(activePage.id))
                      ? () => ref
                            .read(strokesNotifierProvider.notifier)
                            .undo(activePage.id)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded),
                  tooltip: 'Redo',
                  onPressed:
                      activePage != null &&
                          ref.watch(canRedoProvider(activePage.id))
                      ? () => ref
                            .read(strokesNotifierProvider.notifier)
                            .redo(activePage.id)
                      : null,
                ),

                // Compact Overflow Menu
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More actions',
                  onSelected: (val) async {
                    switch (val) {
                      case 'search':
                        setState(() => _showSearch = !_showSearch);
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
                      case 'bookmark':
                        if (activePage != null) {
                          ref
                              .read(notebookPagesProvider.notifier)
                              .toggleBookmark(widget.notebookId, activePage.id);
                        }
                        break;
                      case 'sticky':
                        if (activePage != null) {
                          await ref
                              .read(stickyNotesProvider.notifier)
                              .addStickyNote(activePage.id, x: 80.0, y: 100.0);
                        }
                        break;
                      case 'viewMode':
                        setState(
                          () => _isContinuousScroll = !_isContinuousScroll,
                        );
                        break;
                      case 'template':
                        if (activePage != null) {
                          _openTemplateSettings(
                            activePage.id,
                            activeType,
                            activeProps,
                          );
                        }
                        break;
                      case 'export':
                        final pdfService = ref.read(pdfServiceProvider);
                        final strokesState = ref.read(strokesNotifierProvider);
                        final stickyNotesState = ref.read(stickyNotesProvider);
                        final bytes = await pdfService.exportFlattenedPdf(
                          notebook: notebook,
                          pages: pages,
                          strokesPerPage: strokesState.pageStrokes,
                          stickyNotesPerPage: stickyNotesState,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Flattened PDF generated (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB, ${pages.length} pages)!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'audio',
                      child: Row(
                        children: [
                          Icon(
                            _showAudioBar ? Icons.mic : Icons.mic_none_outlined,
                            size: 20,
                            color: _showAudioBar ? Colors.redAccent : null,
                          ),
                          const SizedBox(width: 12),
                          const Text('Lecture Audio'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'aiAssistant',
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 12),
                          Text('AI Study Assistant'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          const Text('Search Document'),
                        ],
                      ),
                    ),
                    if (activePage != null)
                      PopupMenuItem(
                        value: 'bookmark',
                        child: Row(
                          children: [
                            Icon(
                              activePage.isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color: activePage.isBookmarked
                                  ? Colors.amber[700]
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              activePage.isBookmarked
                                  ? 'Remove Bookmark'
                                  : 'Bookmark Page',
                            ),
                          ],
                        ),
                      ),
                    if (activePage != null)
                      const PopupMenuItem(
                        value: 'sticky',
                        child: Row(
                          children: [
                            Icon(Icons.note_add_outlined, size: 20),
                            SizedBox(width: 12),
                            Text('Add Sticky Note'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'viewMode',
                      child: Row(
                        children: [
                          Icon(
                            _isContinuousScroll
                                ? Icons.view_stream
                                : Icons.crop_portrait,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isContinuousScroll
                                ? 'Single Page View'
                                : 'Continuous Scroll View',
                          ),
                        ],
                      ),
                    ),
                    if (activePage != null)
                      const PopupMenuItem(
                        value: 'template',
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Paper Template & Style'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Export Flattened PDF'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ]
            : [
                // Thumbnail Sidebar Toggle
                IconButton(
                  icon: Icon(
                    _showThumbnails
                        ? Icons.view_sidebar
                        : Icons.view_sidebar_outlined,
                  ),
                  tooltip: 'Page Thumbnails',
                  onPressed: () =>
                      setState(() => _showThumbnails = !_showThumbnails),
                ),

                // Bookmark Page Toggle
                if (activePage != null)
                  IconButton(
                    icon: Icon(
                      activePage.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: activePage.isBookmarked ? Colors.amber[700] : null,
                    ),
                    tooltip: activePage.isBookmarked
                        ? 'Remove Bookmark'
                        : 'Bookmark Page',
                    onPressed: () {
                      ref
                          .read(notebookPagesProvider.notifier)
                          .toggleBookmark(widget.notebookId, activePage.id);
                    },
                  ),

                // Add Sticky Note
                if (activePage != null)
                  IconButton(
                    icon: const Icon(Icons.note_add_outlined),
                    tooltip: 'Add Sticky Note',
                    onPressed: () async {
                      await ref
                          .read(stickyNotesProvider.notifier)
                          .addStickyNote(activePage.id, x: 80.0, y: 100.0);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sticky Note added! Drag to move, tap to edit.',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),

                // View Mode Toggle (Single vs Continuous Scroll)
                IconButton(
                  icon: Icon(
                    _isContinuousScroll
                        ? Icons.view_stream
                        : Icons.crop_portrait,
                  ),
                  tooltip: _isContinuousScroll
                      ? 'Single Page View'
                      : 'Continuous Scroll View',
                  onPressed: () => setState(
                    () => _isContinuousScroll = !_isContinuousScroll,
                  ),
                ),

                // Search in Document
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search Document',
                  onPressed: () => setState(() => _showSearch = !_showSearch),
                ),

                // Template / Paper Customizer Button
                IconButton(
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Paper Template & Style',
                  onPressed: () {
                    if (activePage != null) {
                      _openTemplateSettings(
                        activePage.id,
                        activeType,
                        activeProps,
                      );
                    }
                  },
                ),

                // Undo & Redo
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  tooltip: 'Undo',
                  onPressed:
                      activePage != null &&
                          ref.watch(canUndoProvider(activePage.id))
                      ? () => ref
                            .read(strokesNotifierProvider.notifier)
                            .undo(activePage.id)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded),
                  tooltip: 'Redo',
                  onPressed:
                      activePage != null &&
                          ref.watch(canRedoProvider(activePage.id))
                      ? () => ref
                            .read(strokesNotifierProvider.notifier)
                            .redo(activePage.id)
                      : null,
                ),
                const VerticalDivider(width: 16, indent: 12, endIndent: 12),

                // Audio Recording shortcut
                IconButton(
                  icon: Icon(
                    _showAudioBar ? Icons.mic : Icons.mic_none_rounded,
                    color: _showAudioBar ? Colors.redAccent : null,
                  ),
                  tooltip: 'Record Lecture Audio',
                  onPressed: () {
                    setState(() => _showAudioBar = !_showAudioBar);
                    if (_showAudioBar) {
                      final audioService = ref.read(audioServiceProvider);
                      if (!audioService.recordState.isRecording &&
                          !audioService.playbackState.isPlaying) {
                        audioService.startRecording(
                          widget.notebookId,
                          pageId: activePage?.id,
                        );
                      }
                    }
                  },
                ),

                // AI Study Assistant shortcut
                IconButton(
                  icon: Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  tooltip: 'AI Study Assistant',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => AiStudyAssistantSheet(
                        notebookId: widget.notebookId,
                        notebookTitle: notebook.title,
                      ),
                    );
                  },
                ),

                // Export Flattened PDF
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Export Flattened PDF',
                  onPressed: () async {
                    final pdfService = ref.read(pdfServiceProvider);
                    final strokesState = ref.read(strokesNotifierProvider);
                    final stickyNotesState = ref.read(stickyNotesProvider);

                    final bytes = await pdfService.exportFlattenedPdf(
                      notebook: notebook,
                      pages: pages,
                      strokesPerPage: strokesState.pageStrokes,
                      stickyNotesPerPage: stickyNotesState,
                    );

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Flattened PDF generated (${(bytes.lengthInBytes / 1024).toStringAsFixed(1)} KB, ${pages.length} pages)!',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
      ),
      body: HandwritingShortcuts(
        pageId: activePage?.id ?? '',
        onToggleSearch: () => setState(() => _showSearch = !_showSearch),
        onZoomIn: _zoomIn,
        onZoomOut: _zoomOut,
        onResetZoom: _resetZoom,
        onAddPage: _showAddPageDialog,
        onAddStickyNote: activePage != null
            ? () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref
                    .read(stickyNotesProvider.notifier)
                    .addStickyNote(activePage.id, x: 80.0, y: 100.0);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Sticky Note added! Drag to move.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            : null,
        onTriggerSync: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Saving and synchronizing notebook...'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Row(
          children: [
            // Collapsible PDF / Document Thumbnail Sidebar
            if (_showThumbnails)
              PdfThumbnailSidebar(
                notebookId: widget.notebookId,
                pages: pages,
                currentPageIndex: clampedIndex,
                onSelectPage: (pageIndex) {
                  ref
                      .read(currentPageIndexProvider.notifier)
                      .setPage(pageIndex);
                },
                onClose: () => setState(() => _showThumbnails = false),
              ),

            Expanded(
              child: Column(
                children: [
                  // In-Document Search Bar
                  if (_showSearch)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
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

                  // Floating Audio Recording & Playback Bar
                  if (_showAudioBar)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: AudioRecordingBar(
                        notebookId: widget.notebookId,
                        activePageId: activePage?.id,
                        onClose: () => setState(() => _showAudioBar = false),
                      ),
                    ),

                  // Dynamic Vector Handwriting & Inking Toolbar
                  if (activePage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: HandwritingToolbar(pageId: activePage.id),
                    ),

                  // Workspace: Continuous Scroll vs. Interactive Single Page
                  Expanded(
                    child: activePage == null
                        ? const Center(child: CircularProgressIndicator())
                        : _isContinuousScroll
                        ? ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            itemCount: pages.length,
                            itemBuilder: (ctx, idx) {
                              final p = pages[idx];
                              final pType = p.templateType;
                              final pProps = p.properties;
                              final stickyNotes = ref.watch(
                                pageStickyNotesProvider(p.id),
                              );
                              final pMatches = allMatches
                                  .where((m) => m.pageId == p.id)
                                  .map((m) => m.box)
                                  .toList();
                              final pActiveBoxIdx =
                                  (allMatches.isNotEmpty &&
                                      _activeMatchIndex < allMatches.length &&
                                      allMatches[_activeMatchIndex].pageId ==
                                          p.id)
                                  ? pMatches.indexOf(
                                      allMatches[_activeMatchIndex].box,
                                    )
                                  : -1;

                              return Center(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
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
                                        readOnly:
                                            ref.watch(activeToolProvider) ==
                                            ToolType.pan,
                                      ),
                                      ...stickyNotes.map(
                                        (note) => StickyNoteWidget(note: note),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.4,
                            maxScale: 3.5,
                            boundaryMargin: const EdgeInsets.all(80),
                            panEnabled:
                                ref.watch(activeToolProvider) == ToolType.pan ||
                                ref.watch(stylusOnlyModeProvider),
                            scaleEnabled: true,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      HandwritingCanvas(
                                        pageId: activePage.id,
                                        type: activeType,
                                        properties: activeProps,
                                        width: activePage.width,
                                        height: activePage.height,
                                        searchMatches: activeBoxesOnCurrentPage,
                                        activeSearchIndex: activeBoxIndexInPage,
                                        readOnly:
                                            ref.watch(activeToolProvider) ==
                                            ToolType.pan,
                                      ),
                                      ...ref
                                          .watch(
                                            pageStickyNotesProvider(
                                              activePage.id,
                                            ),
                                          )
                                          .map(
                                            (note) =>
                                                StickyNoteWidget(note: note),
                                          ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),

                  // Bottom Page Navigation Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Previous Page Button
                        IconButton.filledTonal(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                          ),
                          tooltip: 'Previous Page',
                          onPressed: clampedIndex > 1
                              ? () {
                                  ref
                                      .read(currentPageIndexProvider.notifier)
                                      .prevPage();
                                }
                              : null,
                        ),

                        // Page indicator & Template summary
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Page $clampedIndex / ${pages.isEmpty ? 1 : pages.length}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                activeType.displayName,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Next Page & Add Page Buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton.filledTonal(
                              icon: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                              ),
                              tooltip: 'Next Page',
                              onPressed: clampedIndex < pages.length
                                  ? () {
                                      ref
                                          .read(
                                            currentPageIndexProvider.notifier,
                                          )
                                          .nextPage(pages.length);
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Page'),
                              onPressed: _showAddPageDialog,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
