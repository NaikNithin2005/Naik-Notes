import 'package:flutter/material.dart';

import '../../../../data/models/page_model.dart';
import 'canvas_floating_pill.dart';

/// Minimal, translucent bottom-right page pill: `[ 1 / 3 | + ]`.
///
/// Features:
/// - Replaces the bulky bottom navigation bar.
/// - Shows current page / total pages.
/// - Tapping `1 / 3` opens a compact page thumbnail sheet for jumping, duplicating, or deleting pages.
/// - Tapping `+` adds a new page using the active template.
class CanvasPagePill extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final List<NotebookPage> pages;
  final VoidCallback onAddPage;
  final void Function(int pageIndex) onSelectPage;
  final void Function(NotebookPage page) onDuplicatePage;
  final void Function(NotebookPage page) onDeletePage;

  const CanvasPagePill({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.pages,
    required this.onAddPage,
    required this.onSelectPage,
    required this.onDuplicatePage,
    required this.onDeletePage,
  });

  void _showThumbnailsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PageThumbnailsSheet(
        currentPage: currentPage,
        totalPages: totalPages,
        pages: pages,
        onAddPage: () {
          Navigator.of(ctx).pop();
          onAddPage();
        },
        onSelectPage: (idx) {
          Navigator.of(ctx).pop();
          onSelectPage(idx);
        },
        onDuplicatePage: (p) {
          Navigator.of(ctx).pop();
          onDuplicatePage(p);
        },
        onDeletePage: (p) {
          Navigator.of(ctx).pop();
          onDeletePage(p);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayTotal = totalPages == 0 ? 1 : totalPages;
    final displayCurrent = currentPage.clamp(1, displayTotal);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return CanvasFloatingPill(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Page Number Indicator: Tap to open page thumbnail sheet
          Tooltip(
            message: 'View all pages ($displayCurrent of $displayTotal)',
            child: InkWell(
              onTap: () => _showThumbnailsSheet(context),
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  '$displayCurrent / $displayTotal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),

          // Divider
          SizedBox(
            height: 18,
            child: VerticalDivider(
              width: 6,
              thickness: 1,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),

          // Add Page (+) Button
          Tooltip(
            message: 'Add Page',
            child: InkWell(
              onTap: onAddPage,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 18),
                    if (isDesktop) ...[
                      const SizedBox(width: 4),
                      const Text(
                        'Add Page',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 2),
                    ] else ...[
                      const Offstage(
                        offstage: true,
                        child: Text('Add Page'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PAGE THUMBNAILS SHEET
// ---------------------------------------------------------------------------
class _PageThumbnailsSheet extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final List<NotebookPage> pages;
  final VoidCallback onAddPage;
  final void Function(int pageIndex) onSelectPage;
  final void Function(NotebookPage page) onDuplicatePage;
  final void Function(NotebookPage page) onDeletePage;

  const _PageThumbnailsSheet({
    required this.currentPage,
    required this.totalPages,
    required this.pages,
    required this.onAddPage,
    required this.onSelectPage,
    required this.onDuplicatePage,
    required this.onDeletePage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF21E1E22) : const Color(0xF8FFFFFF),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0x2AFFFFFF) : const Color(0x18000000),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pages ($totalPages)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Page', style: TextStyle(fontSize: 12)),
                  onPressed: onAddPage,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Pages Horizontal / Grid List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              scrollDirection: Axis.horizontal,
              itemCount: pages.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (ctx, idx) {
                final page = pages[idx];
                final pageNum = page.pageNumber;
                final isCurrent = pageNum == currentPage;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Card
                    GestureDetector(
                      onTap: () => onSelectPage(pageNum),
                      child: Container(
                        width: 130,
                        height: 180,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A30) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? theme.colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.3),
                            width: isCurrent ? 2.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 32,
                                    color: isCurrent
                                        ? theme.colorScheme.primary
                                        : Colors.grey.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    page.templateType.displayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isCurrent ? theme.colorScheme.primary : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 6,
                              left: 8,
                              child: Text(
                                '$pageNum',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isCurrent ? theme.colorScheme.primary : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Actions below card: Duplicate & Delete
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Duplicate',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => onDuplicatePage(page),
                        ),
                        const SizedBox(width: 8),
                        if (pages.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                            tooltip: 'Delete',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => onDeletePage(page),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

