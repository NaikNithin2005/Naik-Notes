import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/notebook_model.dart';
import '../../../folders/data/folder_provider.dart';
import '../../data/notebook_provider.dart';
import '../../data/notebook_selection_provider.dart';

/// Contextual selection toolbar for gallery-style notebook multi-selection.
/// Adapts gracefully across Mobile, Tablet, and Windows Desktop.
class NotebookSelectionToolbar extends ConsumerWidget {
  final List<Notebook> visibleNotebooks;

  const NotebookSelectionToolbar({
    super.key,
    required this.visibleNotebooks,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectionState = ref.watch(notebookSelectionProvider);
    final selectedCount = selectionState.count;
    final allVisibleIds = visibleNotebooks.map((n) => n.id).toList();
    final isAllSelected = selectedCount > 0 &&
        allVisibleIds.isNotEmpty &&
        allVisibleIds.every((id) => selectionState.isSelected(id));

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;

    final selectedNotebooks = visibleNotebooks
        .where((n) => selectionState.isSelected(n.id))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Close / Cancel Selection
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel Selection (Esc)',
            onPressed: () {
              ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
            },
          ),
          const SizedBox(width: 8),

          // Selection Count
          Expanded(
            child: Row(
              children: [
                Text(
                  '$selectedCount Selected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),

                // Select All / Deselect All Toggle Button
                TextButton.icon(
                  icon: Icon(
                    isAllSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 18,
                  ),
                  label: Text(isAllSelected ? 'Deselect All' : 'Select All'),
                  onPressed: () {
                    if (isAllSelected) {
                      ref
                          .read(notebookSelectionProvider.notifier)
                          .deselectAll();
                    } else {
                      ref
                          .read(notebookSelectionProvider.notifier)
                          .selectAll(allVisibleIds);
                    }
                  },
                ),
              ],
            ),
          ),

          // Primary Actions
          if (isMobile) ...[
            // Mobile: Delete + Overflow Menu
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              tooltip: 'Delete Selected',
              onPressed: selectedCount > 0
                  ? () => _confirmBulkDelete(context, ref, selectedNotebooks)
                  : null,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More Actions',
              onSelected: (val) {
                _handleAction(context, ref, val, selectedNotebooks);
              },
              itemBuilder: (ctx) => [
                if (selectedCount == 1) ...[
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Rename Notebook'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Duplicate Notebook'),
                      ],
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'color',
                  child: Row(
                    children: [
                      Icon(Icons.palette_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Change Cover Color'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'folder',
                  child: Row(
                    children: [
                      Icon(Icons.folder_open_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Move to Folder'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(Icons.archive_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Archive Notebooks'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(Icons.star_outline_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Add to Favorites'),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Tablet & Desktop Toolbar
            if (selectedCount == 1) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Rename (F2)',
                onPressed: () => _showRenameDialog(
                  context,
                  ref,
                  selectedNotebooks.first,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Duplicate',
                onPressed: () async {
                  await ref
                      .read(notebooksProvider.notifier)
                      .duplicateNotebook(selectedNotebooks.first.id);
                  ref
                      .read(notebookSelectionProvider.notifier)
                      .exitSelectionMode();
                },
              ),
            ],
            IconButton(
              icon: const Icon(Icons.palette_outlined),
              tooltip: 'Change Cover Color',
              onPressed: () => _showColorPickerDialog(
                context,
                ref,
                selectedNotebooks,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.folder_open_rounded),
              tooltip: 'Move to Folder',
              onPressed: () => _showMoveFolderDialog(
                context,
                ref,
                selectedNotebooks,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive',
              onPressed: () {
                final ids = selectedNotebooks.map((n) => n.id);
                ref.read(notebooksProvider.notifier).bulkArchive(ids, true);
                ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Archived ${ids.length} notebooks'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.star_outline_rounded),
              tooltip: 'Favorite',
              onPressed: () {
                final ids = selectedNotebooks.map((n) => n.id);
                ref.read(notebooksProvider.notifier).bulkFavorite(ids, true);
                ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${ids.length} notebooks to Favorites'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            if (isDesktop)
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                ),
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete (Del)'),
                onPressed: selectedCount > 0
                    ? () => _confirmBulkDelete(context, ref, selectedNotebooks)
                    : null,
              )
            else
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Delete Selected (Del)',
                onPressed: selectedCount > 0
                    ? () => _confirmBulkDelete(context, ref, selectedNotebooks)
                    : null,
              ),
          ],
        ],
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    List<Notebook> notebooks,
  ) {
    switch (action) {
      case 'rename':
        if (notebooks.isNotEmpty) {
          _showRenameDialog(context, ref, notebooks.first);
        }
        break;
      case 'duplicate':
        if (notebooks.isNotEmpty) {
          ref
              .read(notebooksProvider.notifier)
              .duplicateNotebook(notebooks.first.id);
          ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
        }
        break;
      case 'color':
        _showColorPickerDialog(context, ref, notebooks);
        break;
      case 'folder':
        _showMoveFolderDialog(context, ref, notebooks);
        break;
      case 'archive':
        final ids = notebooks.map((n) => n.id);
        ref.read(notebooksProvider.notifier).bulkArchive(ids, true);
        ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Archived ${ids.length} notebooks')),
        );
        break;
      case 'favorite':
        final ids = notebooks.map((n) => n.id);
        ref.read(notebooksProvider.notifier).bulkFavorite(ids, true);
        ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${ids.length} notebooks to Favorites')),
        );
        break;
    }
  }

  void _confirmBulkDelete(
    BuildContext context,
    WidgetRef ref,
    List<Notebook> notebooks,
  ) {
    final count = notebooks.length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text('Delete $count Notebook${count == 1 ? '' : 's'}?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${count == 1 ? 'this notebook' : 'these $count notebooks'}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'The selected notebook${count == 1 ? '' : 's'} and all note pages inside will be safely moved to Trash. You can restore them anytime from the Trash view.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: notebooks
                      .take(5)
                      .map(
                        (n) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.book_rounded, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  n.title.isEmpty ? 'Untitled Notebook' : n.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            if (count > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${count - 5} more',
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final ids = notebooks.map((n) => n.id).toList();
              ref.read(notebooksProvider.notifier).bulkDelete(ids);
              ref.read(notebookSelectionProvider.notifier).exitSelectionMode();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Moved $count notebook${count == 1 ? '' : 's'} to Trash'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(notebooksProvider.notifier).bulkRestore(ids);
                    },
                  ),
                ),
              );
            },
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
  ) {
    final controller = TextEditingController(text: notebook.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Notebook'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Notebook Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            final trimmed = val.trim();
            if (trimmed.isNotEmpty) {
              ref.read(notebooksProvider.notifier).renameNotebook(notebook.id, trimmed);
              ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                ref.read(notebooksProvider.notifier).renameNotebook(notebook.id, trimmed);
                ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    WidgetRef ref,
    List<Notebook> notebooks,
  ) {
    final colors = [
      '#8B4513', // Classic Leather Brown
      '#1E2A38', // Deep Oxford Navy
      '#2D5A27', // Forest British Racing Green
      '#4A0E17', // Vintage Crimson Burgundy
      '#1C1C1C', // Midnight Charcoal Black
      '#7C3AED', // Royal Amethyst Violet
      '#0284C7', // Oceanic Cerulean Blue
      '#D97706', // Terracotta Amber
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          notebooks.length == 1
              ? 'Change Cover Color'
              : 'Change Color (${notebooks.length} Notebooks)',
        ),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((hex) {
            Color c;
            try {
              c = Color(int.parse(hex.replaceFirst('#', '0xFF')));
            } catch (_) {
              c = const Color(0xFF8B4513);
            }
            return InkWell(
              onTap: () {
                final ids = notebooks.map((n) => n.id);
                ref.read(notebooksProvider.notifier).bulkUpdateCoverColor(ids, hex);
                ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated cover color for ${notebooks.length} notebooks')),
                );
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showMoveFolderDialog(
    BuildContext context,
    WidgetRef ref,
    List<Notebook> notebooks,
  ) {
    final folders = ref.read(foldersProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Move ${notebooks.length} Notebook${notebooks.length == 1 ? '' : 's'} to Folder'),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: const Text('No Folder (Unfiled)'),
                onTap: () {
                  final ids = notebooks.map((n) => n.id);
                  ref.read(notebooksProvider.notifier).bulkMoveToFolder(ids, null);
                  ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
                  Navigator.pop(ctx);
                },
              ),
              const Divider(),
              if (folders.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No custom folders created yet.'),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    itemBuilder: (c, idx) {
                      final f = folders[idx];
                      return ListTile(
                        leading: const Icon(Icons.folder_outlined),
                        title: Text(f.name),
                        onTap: () {
                          final ids = notebooks.map((n) => n.id);
                          ref.read(notebooksProvider.notifier).bulkMoveToFolder(ids, f.id);
                          ref.read(notebookSelectionProvider.notifier).exitSelectionMode();
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

