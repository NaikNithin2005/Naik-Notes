import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:naik_notes/core/presentation/responsive_layout.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/data/models/page_model.dart';
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
import 'package:naik_notes/features/notebooks/presentation/widgets/reading_mode_page_flip_view.dart';
import 'package:naik_notes/features/template_store/presentation/widgets/template_store_sheet.dart';
import 'package:naik_notes/features/templates/presentation/widgets/template_customizer_sheet.dart';
import 'package:naik_notes/features/version_history/presentation/widgets/version_history_sheet.dart';
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
  bool _isReadingMode = false;
  String _searchQuery = '';
  int _activeMatchIndex = 0;
  late final TransformationController _transformationController =
      TransformationController();
  final ScrollController _continuousScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notebooks = ref.read(notebooksProvider);
      final nb = notebooks.where((n) => n.id == widget.notebookId).firstOrNull;
      if (nb != null) {
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
      } else {
        ref
            .read(notebookPagesProvider.notifier)
            .loadPages(widget.notebookId, count: 1)
            .then((_) {
              final loaded =
                  ref.read(notebookPagesProvider)[widget.notebookId] ?? [];
              for (final p in loaded) {
                ref.read(stickyNotesProvider.notifier).loadStickyNotes(p.id);
              }
            });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _continuousScrollController.dispose();
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
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.40,
              maxChildSize: 0.90,
              expand: false,
              builder: (innerCtx, scrollController) {
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
                      const SizedBox(height: 12),
                      // Insertion Position Selector
                      Text(
                        'Page Placement',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: SegmentedButton<String>(
                          segments: [
                            const ButtonSegment<String>(
                              value: 'end',
                              label: Text('At End'),
                              icon: Icon(Icons.last_page_rounded, size: 16),
                            ),
                            if (activePage != null)
                              ButtonSegment<String>(
                                value: 'before',
                                label: Text(
                                  'Before P.${activePage.pageNumber}',
                                ),
                                icon: const Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 16,
                                ),
                              ),
                            if (activePage != null)
                              ButtonSegment<String>(
                                value: 'after',
                                label: Text('After P.${activePage.pageNumber}'),
                                icon: const Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                ),
                              ),
                          ],
                          selected: {selectedPosition},
                          onSelectionChanged: (newSelection) {
                            setSheetState(
                              () => selectedPosition = newSelection.first,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Choose a paper template for this new page:',
                        style: Theme.of(sheetCtx).textTheme.bodyMedium
                            ?.copyWith(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 12),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
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
                                NotebookPage newPage;
                                String actionDescription;

                                if (selectedPosition == 'before' &&
                                    activePage != null) {
                                  newPage = await ref
                                      .read(notebookPagesProvider.notifier)
                                      .insertPageBefore(
                                        widget.notebookId,
                                        activePage.id,
                                        templateId: type.id,
                                      );
                                  actionDescription =
                                      'Inserted Page ${newPage.pageNumber} before Page ${activePage.pageNumber}';
                                } else if (selectedPosition == 'after' &&
                                    activePage != null) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notebooks = ref.watch(notebooksProvider);
    final notebook = notebooks
        .where((nb) => nb.id == widget.notebookId)
        .firstOrNull;

    if (notebook == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notebook'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(RouteNames.dashboard),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Loading notebook...'),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Library'),
                onPressed: () => context.go(RouteNames.dashboard),
              ),
            ],
          ),
        ),
      );
    }

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
      backgroundColor: _isReadingMode
          ? const Color(0xFFF3EEDC)
          : const Color(0xFFE8E4DF),
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

                // Reading Mode Toggle
                IconButton(
                  icon: Icon(
                    _isReadingMode
                        ? Icons.auto_stories
                        : Icons.auto_stories_outlined,
                  ),
                  tooltip: _isReadingMode
                      ? 'Exit Reading Mode'
                      : 'Reading Mode',
                  color: _isReadingMode ? theme.colorScheme.primary : null,
                  onPressed: () {
                    setState(() => _isReadingMode = !_isReadingMode);
                    if (_isReadingMode) {
                      ref
                          .read(activeToolProvider.notifier)
                          .setTool(ToolType.pan);
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
                    if (activePage != null)
                      const PopupMenuItem(
                        value: 'history',
                        child: Row(
                          children: [
                            Icon(Icons.history_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Page Version History'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'templateStore',
                      child: Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Community Template Store'),
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

                // Reading Mode Toggle
                IconButton(
                  icon: Icon(
                    _isReadingMode
                        ? Icons.auto_stories
                        : Icons.auto_stories_outlined,
                  ),
                  tooltip: _isReadingMode
                      ? 'Exit Reading Mode'
                      : 'Reading Mode',
                  color: _isReadingMode ? theme.colorScheme.primary : null,
                  onPressed: () {
                    setState(() => _isReadingMode = !_isReadingMode);
                    if (_isReadingMode) {
                      ref
                          .read(activeToolProvider.notifier)
                          .setTool(ToolType.pan);
                    }
                  },
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

                // Version History shortcut
                if (activePage != null)
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    tooltip: 'Page Version History',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => VersionHistorySheet(
                          pageId: activePage.id,
                          notebookId: widget.notebookId,
                        ),
                      );
                    },
                  ),

                // Template Store shortcut
                IconButton(
                  icon: const Icon(Icons.storefront_outlined),
                  tooltip: 'Community Template Store',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => const TemplateStoreSheet(),
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
                onInsertPage: (pageId, pos) {
                  _showAddPageDialog(
                    referencePageId: pageId,
                    initialPosition: pos,
                  );
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

                  // Reading Mode Info Banner
                  if (_isReadingMode)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0E6D2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD8C7AB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_stories,
                            size: 18,
                            color: Color(0xFF5C4033),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Reading Mode Active • Tools hidden for comfortable reading.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5C4033),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.edit_note, size: 16),
                            label: const Text(
                              'Exit Reading Mode',
                              style: TextStyle(fontSize: 12),
                            ),
                            onPressed: () =>
                                setState(() => _isReadingMode = false),
                          ),
                        ],
                      ),
                    ),

                  // Dynamic Vector Handwriting & Inking Toolbar (Hidden in Reading Mode)
                  if (!_isReadingMode && activePage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: HandwritingToolbar(pageId: activePage.id),
                    ),

                  // Workspace: Reading Mode 3D Flip vs. Continuous Scroll vs. Interactive Single Page
                  Expanded(
                    child: activePage == null
                        ? const Center(child: CircularProgressIndicator())
                        : _isReadingMode
                        ? ReadingModePageFlipView(
                            notebookId: widget.notebookId,
                            pages: pages,
                            initialPage: clampedIndex,
                            onExitReadingMode: () =>
                                setState(() => _isReadingMode = false),
                          )
                        : _isContinuousScroll
                        ? Scrollbar(
                            controller: _continuousScrollController,
                            thumbVisibility: true,
                            child: ListView.builder(
                              controller: _continuousScrollController,
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
                                      color: _isReadingMode
                                          ? const Color(0xFFFFFDF5)
                                          : Colors.white,
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
                                              _isReadingMode ||
                                              ref.watch(activeToolProvider) ==
                                                  ToolType.pan,
                                        ),
                                        ...stickyNotes.map(
                                          (note) =>
                                              StickyNoteWidget(note: note),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.4,
                            maxScale: 3.5,
                            boundaryMargin: const EdgeInsets.all(80),
                            panEnabled:
                                _isReadingMode ||
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
                                    color: _isReadingMode
                                        ? const Color(0xFFFFFDF5)
                                        : Colors.white,
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
                                            _isReadingMode ||
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

                  // Bottom Page Navigation & Management Bar (Visible in Editing Mode)
                  if (!_isReadingMode)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
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
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
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
                                            .read(
                                              currentPageIndexProvider.notifier,
                                            )
                                            .prevPage();
                                      }
                                    : null,
                              ),
                              const SizedBox(width: 8),

                              // Page indicator & Template summary (Tap for overview / reorder)
                              Tooltip(
                                message:
                                    'Tap to view thumbnails & reorder pages',
                                child: InkWell(
                                  onTap: () => setState(
                                    () => _showThumbnails = !_showThumbnails,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Page $clampedIndex / ${pages.isEmpty ? 1 : pages.length}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .primaryContainer,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            activeType.displayName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.view_sidebar_rounded,
                                          size: 14,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Next Page Button
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
                              const SizedBox(width: 16),

                              // Duplicate Current Page
                              if (activePage != null)
                                IconButton.outlined(
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    size: 16,
                                  ),
                                  tooltip: 'Duplicate Current Page',
                                  onPressed: () =>
                                      _duplicateCurrentPage(activePage),
                                ),
                              const SizedBox(width: 6),

                              // Delete Current Page
                              if (activePage != null)
                                IconButton.outlined(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 16,
                                  ),
                                  tooltip: 'Delete Current Page',
                                  onPressed: pages.length > 1
                                      ? () => _deleteCurrentPage(
                                          activePage,
                                          pages.length,
                                        )
                                      : null,
                                ),
                              const SizedBox(width: 12),

                              // Add Page Button
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
                        ),
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
