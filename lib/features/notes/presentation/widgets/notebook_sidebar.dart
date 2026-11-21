import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/naik_notes_logo.dart';
import '../../../../data/models/notebook_model.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../../notebooks/presentation/widgets/create_notebook_dialog.dart';
import '../../../notebooks/presentation/widgets/rename_notebook_dialog.dart';
import '../../data/note_provider.dart';

/// Left sidebar displaying application navigation, notebooks, favorites, tags, archive, and trash.
class NotebookSidebar extends ConsumerWidget {
  final bool isDrawer;
  final VoidCallback? onToggleCollapse;

  const NotebookSidebar({
    super.key,
    this.isDrawer = false,
    this.onToggleCollapse,
  });

  void _showCreateNotebookDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => const CreateNotebookDialog(),
    );
  }

  void _showRenameDialog(BuildContext context, Notebook nb) {
    showDialog<void>(
      context: context,
      builder: (ctx) => RenameNotebookDialog(notebook: nb),
    );
  }

  Future<void> _confirmDeleteNotebook(
    BuildContext context,
    WidgetRef ref,
    Notebook nb,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notebook?'),
        content: Text(
          'Are you sure you want to move "${nb.title}" to Trash? Its notes will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notebooksProvider.notifier).deleteNotebook(nb.id);
    }
  }

  Future<void> _confirmEmptyTrash(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes in Trash will be permanently deleted. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notesProvider.notifier).emptyTrash();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeFilter = ref.watch(noteFilterProvider);
    final notebooks = ref.watch(notebooksProvider);
    final noteCounts = ref.watch(notebooksNoteCountProvider);
    final allNotes = ref.watch(notesProvider);
    final tags = ref.watch(allTagsWithCountProvider);

    final totalNotesCount = allNotes.where((n) => !n.isDeleted && !n.isArchived).length;
    final pinnedCount = allNotes.where((n) => !n.isDeleted && !n.isArchived && n.isPinned).length;
    final favCount = allNotes.where((n) => !n.isDeleted && !n.isArchived && n.isFavorite).length;
    final archiveCount = allNotes.where((n) => !n.isDeleted && n.isArchived).length;
    final trashCount = allNotes.where((n) => n.isDeleted).length;

    Widget buildNavItem({
      required IconData icon,
      required String title,
      int? count,
      required bool isSelected,
      required VoidCallback onTap,
      Color? iconColor,
      Widget? trailing,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Material(
          color: isSelected
              ? (isDark
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.primary.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : (iconColor ?? theme.colorScheme.onSurfaceVariant),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
          ),
          trailing: trailing ??
              (count != null && count > 0
                  ? Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : null),
          onTap: onTap,
        ),
      ),
    );
  }

    return Container(
      width: 270,
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.12),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
        children: [
          // Header Logo & Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Row(
              children: [
                const NaikNotesLogo(size: 28),
                const SizedBox(width: 10),
                Text(
                  'Naik Notes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Navigation & Lists
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Quick Filters
                buildNavItem(
                  icon: Icons.notes_rounded,
                  title: 'All Notes',
                  count: totalNotesCount,
                  isSelected: activeFilter.type == NoteFilterType.all,
                  onTap: () {
                    ref
                        .read(noteFilterProvider.notifier)
                        .setFilter(NoteFilterType.all);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                ),
                buildNavItem(
                  icon: Icons.push_pin_rounded,
                  title: 'Pinned Notes',
                  count: pinnedCount,
                  isSelected: activeFilter.type == NoteFilterType.pinned,
                  iconColor: Colors.deepOrange,
                  onTap: () {
                    ref
                        .read(noteFilterProvider.notifier)
                        .setFilter(NoteFilterType.pinned);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                ),
                buildNavItem(
                  icon: Icons.star_rounded,
                  title: 'Favorites',
                  count: favCount,
                  isSelected: activeFilter.type == NoteFilterType.favorites,
                  iconColor: Colors.amber,
                  onTap: () {
                    ref
                        .read(noteFilterProvider.notifier)
                        .setFilter(NoteFilterType.favorites);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                ),
                buildNavItem(
                  icon: Icons.history_rounded,
                  title: 'Recent Notes',
                  isSelected: activeFilter.type == NoteFilterType.recent,
                  onTap: () {
                    ref
                        .read(noteFilterProvider.notifier)
                        .setFilter(NoteFilterType.recent);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                ),

                const SizedBox(height: 16),
                // Notebooks Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'NOTEBOOKS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_rounded),
                        tooltip: 'New Notebook',
                        onPressed: () => _showCreateNotebookDialog(context),
                      ),
                    ],
                  ),
                ),

                // Notebooks List
                for (final nb in notebooks)
                  buildNavItem(
                    icon: Icons.book_rounded,
                    title: nb.title,
                    count: noteCounts[nb.id] ?? 0,
                    isSelected: activeFilter.type == NoteFilterType.notebook &&
                        activeFilter.notebookId == nb.id,
                    iconColor: _parseColor(nb.coverColorHex),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 16),
                      onSelected: (val) {
                        switch (val) {
                          case 'rename':
                            _showRenameDialog(context, nb);
                            break;
                          case 'delete':
                            _confirmDeleteNotebook(context, ref, nb);
                            break;
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 16, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      ref
                          .read(noteFilterProvider.notifier)
                          .selectNotebook(nb.id);
                      if (isDrawer) Navigator.of(context).pop();
                    },
                  ),

                const SizedBox(height: 16),
                // Tags Section Header
                if (tags.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'TAGS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final entry in tags.entries)
                    buildNavItem(
                      icon: Icons.label_outline_rounded,
                      title: '#${entry.key}',
                      count: entry.value,
                      isSelected: activeFilter.type == NoteFilterType.tag &&
                          activeFilter.tag == entry.key,
                      onTap: () {
                        ref.read(noteFilterProvider.notifier).selectTag(entry.key);
                        if (isDrawer) Navigator.of(context).pop();
                      },
                    ),
                  const SizedBox(height: 16),
                ],

                // Archive & Trash
                const Divider(height: 1),
                const SizedBox(height: 8),
                buildNavItem(
                  icon: Icons.archive_outlined,
                  title: 'Archive',
                  count: archiveCount,
                  isSelected: activeFilter.type == NoteFilterType.archive,
                  onTap: () {
                    ref
                        .read(noteFilterProvider.notifier)
                        .setFilter(NoteFilterType.archive);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                ),
                buildNavItem(
                  icon: Icons.delete_outline_rounded,
                  title: 'Trash',
                  count: trashCount,
                  isSelected: activeFilter.type == NoteFilterType.trash,
                  iconColor: Colors.redAccent,
                  trailing: trashCount > 0
                      ? IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, size: 16),
                          tooltip: 'Empty Trash',
                          onPressed: () => _confirmEmptyTrash(context, ref),
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(noteFilterProvider.notifier)
                        .setFilter(NoteFilterType.trash);
                    if (isDrawer) Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),

          // Bottom Settings Shortcut
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.settings_outlined, size: 20),
            title: const Text('Settings', style: TextStyle(fontSize: 13)),
            onTap: () => context.go(RouteNames.settings),
          ),
        ],
      ),
    ),
  );
  }

  Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.brown;
    }
  }
}
