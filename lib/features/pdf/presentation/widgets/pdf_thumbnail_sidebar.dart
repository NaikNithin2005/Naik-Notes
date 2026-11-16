import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';

/// Collapsible thumbnail sidebar for fast visual page jumping, bookmark filtering,
/// and document structure inspection.
class PdfThumbnailSidebar extends ConsumerStatefulWidget {
  final String notebookId;
  final List<NotebookPage> pages;
  final int currentPageIndex;
  final ValueChanged<int> onSelectPage;
  final VoidCallback onClose;
  final void Function(String pageId, String position)? onInsertPage;

  const PdfThumbnailSidebar({
    super.key,
    required this.notebookId,
    required this.pages,
    required this.currentPageIndex,
    required this.onSelectPage,
    required this.onClose,
    this.onInsertPage,
  });

  @override
  ConsumerState<PdfThumbnailSidebar> createState() =>
      _PdfThumbnailSidebarState();
}

class _PdfThumbnailSidebarState extends ConsumerState<PdfThumbnailSidebar> {
  bool _filterBookmarkedOnly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedPages = _filterBookmarkedOnly
        ? widget.pages.where((p) => p.isBookmarked).toList()
        : widget.pages;

    final bookmarkedCount = widget.pages.where((p) => p.isBookmarked).length;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Sidebar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thumbnails',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Close Sidebar',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // 2. Filter Tabs (All vs Bookmarked)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: Text('All (${widget.pages.length})'),
                    selected: !_filterBookmarkedOnly,
                    onSelected: (val) {
                      if (val) setState(() => _filterBookmarkedOnly = false);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: Text('Bookmarks ($bookmarkedCount)'),
                    selected: _filterBookmarkedOnly,
                    onSelected: (val) {
                      if (val) setState(() => _filterBookmarkedOnly = true);
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. Thumbnails Grid / List with Reordering
          Expanded(
            child: displayedPages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 40,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _filterBookmarkedOnly
                                ? 'No bookmarked pages yet'
                                : 'No pages found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filterBookmarkedOnly
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: displayedPages.length,
                    itemBuilder: (context, index) => _buildThumbnailCard(
                      context,
                      displayedPages[index],
                      index,
                      false,
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: displayedPages.length,
                    onReorder: (oldIndex, newIndex) async {
                      await ref
                          .read(notebookPagesProvider.notifier)
                          .reorderPages(widget.notebookId, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) => _buildThumbnailCard(
                      context,
                      displayedPages[index],
                      index,
                      true,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailCard(
    BuildContext context,
    NotebookPage page,
    int index,
    bool isReorderable,
  ) {
    final theme = Theme.of(context);
    final isSelected = page.pageNumber == widget.currentPageIndex;

    return Container(
      key: ValueKey(page.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 2.0 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => widget.onSelectPage(page.pageNumber),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Page number, bookmark, and action menu
              Row(
                children: [
                  if (isReorderable)
                    ReorderableDragStartListener(
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(
                          Icons.drag_indicator_rounded,
                          size: 18,
                          color: Colors.grey[500],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'Page ${page.pageNumber}',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      page.isBookmarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 18,
                      color: page.isBookmarked
                          ? Colors.amber[700]
                          : Colors.grey,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: page.isBookmarked
                        ? 'Remove Bookmark'
                        : 'Bookmark Page',
                    onPressed: () {
                      ref
                          .read(notebookPagesProvider.notifier)
                          .toggleBookmark(widget.notebookId, page.id);
                    },
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'Page actions',
                    onSelected: (action) async {
                      if (action == 'before') {
                        widget.onInsertPage?.call(page.id, 'before');
                      } else if (action == 'after') {
                        widget.onInsertPage?.call(page.id, 'after');
                      } else if (action == 'duplicate') {
                        final newPage = await ref
                            .read(notebookPagesProvider.notifier)
                            .duplicatePage(widget.notebookId, page.id);
                        if (newPage != null && context.mounted) {
                          widget.onSelectPage(newPage.pageNumber);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Duplicated Page ${page.pageNumber} as Page ${newPage.pageNumber}',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else if (action == 'delete') {
                        if (widget.pages.length <= 1) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cannot delete the only page in the notebook.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                        await ref
                            .read(notebookPagesProvider.notifier)
                            .deletePage(widget.notebookId, page.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Deleted Page ${page.pageNumber}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'before',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Insert Page Before',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'after',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward_rounded, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Insert Page After',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Duplicate Page',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (widget.pages.length > 1)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete Page',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Miniature Paper Representation
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 24,
                        color: Colors.grey.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        page.templateType.displayName,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
