import 'package:flutter/material.dart';

/// Reusable production-grade empty state widget for Naik Notes.
/// Provides consistent typography, theme-aware contrast, branded iconography,
/// and accessible 48x48 pt action buttons.
class NaikEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const NaikEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  /// Factory for empty notebook library.
  factory NaikEmptyState.notebooks({VoidCallback? onCreateNotebook}) {
    return NaikEmptyState(
      icon: Icons.menu_book_rounded,
      title: 'Your Library is Empty',
      description:
          'Create your first notebook to begin writing, sketching, and organizing your notes.',
      actionLabel: onCreateNotebook != null ? 'Create Notebook' : null,
      actionIcon: Icons.add,
      onAction: onCreateNotebook,
    );
  }

  /// Factory for empty folder.
  factory NaikEmptyState.folder({
    required String folderName,
    VoidCallback? onCreateNotebook,
  }) {
    return NaikEmptyState(
      icon: Icons.folder_open_rounded,
      title: 'No notebooks in "$folderName"',
      description:
          'This folder does not contain any notebooks yet. Create a notebook or move existing ones here.',
      actionLabel: onCreateNotebook != null ? 'Add Notebook to Folder' : null,
      actionIcon: Icons.add,
      onAction: onCreateNotebook,
    );
  }

  /// Factory for search with no results.
  factory NaikEmptyState.search({
    required String query,
    VoidCallback? onClearSearch,
  }) {
    return NaikEmptyState(
      icon: Icons.search_off_rounded,
      title: 'No results for "$query"',
      description:
          'We couldn\'t find any notebooks, pages, or handwritten text matching your query. Try different keywords.',
      actionLabel: onClearSearch != null ? 'Clear Search' : null,
      actionIcon: Icons.clear,
      onAction: onClearSearch,
    );
  }

  /// Factory for empty favorites tab.
  factory NaikEmptyState.favorites({VoidCallback? onBrowseNotebooks}) {
    return NaikEmptyState(
      icon: Icons.star_border_rounded,
      title: 'No Favorite Notebooks',
      description:
          'Star your essential notebooks to keep them pinned and easily accessible in your favorites view.',
      actionLabel: onBrowseNotebooks != null ? 'Browse Library' : null,
      actionIcon: Icons.library_books_rounded,
      onAction: onBrowseNotebooks,
    );
  }

  /// Factory for empty recent view.
  factory NaikEmptyState.recent({VoidCallback? onBrowseNotebooks}) {
    return NaikEmptyState(
      icon: Icons.history_rounded,
      title: 'No Recent Activity',
      description:
          'Notebooks you create, write in, or review will appear here in chronological order.',
      actionLabel: onBrowseNotebooks != null ? 'Browse Library' : null,
      actionIcon: Icons.library_books_rounded,
      onAction: onBrowseNotebooks,
    );
  }

  /// Factory for sync history / cloud queue empty state.
  factory NaikEmptyState.syncHistory({VoidCallback? onSyncNow}) {
    return NaikEmptyState(
      icon: Icons.cloud_done_outlined,
      title: 'Cloud Synchronization Up to Date',
      description:
          'All your notebooks, vector strokes, and audio files are securely synchronized across devices.',
      actionLabel: onSyncNow != null ? 'Sync Now' : null,
      actionIcon: Icons.sync,
      onAction: onSyncNow,
    );
  }

  /// Factory for empty archive tab.
  factory NaikEmptyState.archive() {
    return const NaikEmptyState(
      icon: Icons.archive_outlined,
      title: 'No Archived Notebooks',
      description:
          'Completed courses, projects, or reference notes you archive will be securely stored here.',
    );
  }

  /// Factory for empty trash tab.
  factory NaikEmptyState.trash() {
    return const NaikEmptyState(
      icon: Icons.delete_outline_rounded,
      title: 'Trash is Empty',
      description:
          'Notebooks and notes moved to trash will appear here. They are automatically permanently deleted after 30 days.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Decorative Branded Icon Container
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.35,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, size: 46, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),

            // Contextual Action Button (Min 48x48 hit target)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
                child: FilledButton.icon(
                  onPressed: onAction,
                  icon: actionIcon != null
                      ? Icon(actionIcon, size: 20)
                      : const SizedBox.shrink(),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
