import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_canvas.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/handwriting_toolbar.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';
import 'package:naik_notes/features/templates/presentation/widgets/template_customizer_sheet.dart';

/// Notebook reader & writing canvas workspace.
class NotebookViewScreen extends ConsumerStatefulWidget {
  final String notebookId;

  const NotebookViewScreen({super.key, required this.notebookId});

  @override
  ConsumerState<NotebookViewScreen> createState() => _NotebookViewScreenState();
}

class _NotebookViewScreenState extends ConsumerState<NotebookViewScreen> {
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
          );
    });
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
              notebook.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Page $clampedIndex of ${pages.isEmpty ? 1 : pages.length} • ${activeType.displayName}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          // Template / Paper Customizer Button
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Paper Template & Style',
            onPressed: () {
              if (activePage != null) {
                _openTemplateSettings(activePage.id, activeType, activeProps);
              }
            },
          ),

          // Undo & Redo
          IconButton(
            icon: const Icon(Icons.undo_rounded),
            tooltip: 'Undo',
            onPressed:
                activePage != null && ref.watch(canUndoProvider(activePage.id))
                ? () => ref
                      .read(strokesNotifierProvider.notifier)
                      .undo(activePage.id)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded),
            tooltip: 'Redo',
            onPressed:
                activePage != null && ref.watch(canRedoProvider(activePage.id))
                ? () => ref
                      .read(strokesNotifierProvider.notifier)
                      .redo(activePage.id)
                : null,
          ),
          const VerticalDivider(width: 16, indent: 12, endIndent: 12),

          // Audio Recording shortcut
          IconButton(
            icon: const Icon(Icons.mic_none_rounded),
            tooltip: 'Record Lecture Audio',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Audio recording module active in Phase 10'),
                ),
              );
            },
          ),

          // AI Study Assistant shortcut
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: 'AI Study Assistant',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('AI Study Assistant active in Phase 10'),
                ),
              );
            },
          ),

          // Export
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export Notebook',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting notebook to PDF...')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Dynamic Vector Handwriting & Inking Toolbar
          if (activePage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: HandwritingToolbar(pageId: activePage.id),
            ),

          // Paper Page Canvas with Vector Strokes & Interactive Zoom & Pan
          Expanded(
            child: activePage == null
                ? const Center(child: CircularProgressIndicator())
                : InteractiveViewer(
                    minScale: 0.4,
                    maxScale: 3.5,
                    boundaryMargin: const EdgeInsets.all(80),
                    panEnabled: ref.watch(activeToolProvider) == ToolType.pan,
                    scaleEnabled: true,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: HandwritingCanvas(
                            pageId: activePage.id,
                            type: activeType,
                            properties: activeProps,
                            width: activePage.width,
                            height: activePage.height,
                            readOnly:
                                ref.watch(activeToolProvider) == ToolType.pan,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),

          // Bottom Page Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
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
                                  .read(currentPageIndexProvider.notifier)
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
    );
  }
}
