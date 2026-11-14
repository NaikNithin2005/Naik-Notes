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

  const PdfThumbnailSidebar({
    super.key,
    required this.notebookId,
    required this.pages,
    required this.currentPageIndex,
    required this.onSelectPage,
    required this.onClose,
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

          // 3. Thumbnails Grid / List
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
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: displayedPages.length,
                    itemBuilder: (context, index) {
                      final page = displayedPages[index];
                      final isSelected =
                          page.pageNumber == widget.currentPageIndex;

                      return InkWell(
                        onTap: () => widget.onSelectPage(page.pageNumber),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Page number & Bookmark button
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Page ${page.pageNumber}',
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 12,
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
                                          .toggleBookmark(
                                            widget.notebookId,
                                            page.id,
                                          );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Miniature Paper Representation
                              Container(
                                height: 110,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.05,
                                      ),
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
                                        color: Colors.grey.withValues(
                                          alpha: 0.6,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        page.templateType.displayName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
