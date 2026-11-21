import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/note_model.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../data/note_provider.dart';
import '../../data/note_selection_provider.dart';

/// Contextual selection toolbar for gallery-style note multi-selection.
/// Adapts responsively across Mobile, Tablet, and Windows Desktop.
class NoteSelectionToolbar extends ConsumerWidget {
  final List<Note> visibleNotes;

  const NoteSelectionToolbar({
    super.key,
    required this.visibleNotes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectionState = ref.watch(noteSelectionProvider);
    final filter = ref.watch(noteFilterProvider);
    final selectedCount = selectionState.count;
    final allVisibleIds = visibleNotes.map((n) => n.id).toList();
    final isAllSelected = selectedCount > 0 &&
        allVisibleIds.isNotEmpty &&
        allVisibleIds.every((id) => selectionState.isSelected(id));

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 1024;

    final selectedNotes =
        visibleNotes.where((n) => selectionState.isSelected(n.id)).toList();

    final allPinned = selectedNotes.isNotEmpty &&
        selectedNotes.every((n) => n.isPinned);
    final allFavorited = selectedNotes.isNotEmpty &&
        selectedNotes.every((n) => n.isFavorite);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Close / Cancel Selection Button
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Cancel Selection (Esc)',
            onPressed: () {
              ref.read(noteSelectionProvider.notifier).exitSelectionMode();
            },
          ),
          const SizedBox(width: 6),

          // Count & Select All
          Expanded(
            child: Row(
              children: [
                Text(
                  '$selectedCount Selected',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: Icon(
                    isAllSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                    size: 16,
                  ),
                  label: Text(
                    isAllSelected ? 'Deselect All' : 'Select All',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () {
                    if (isAllSelected) {
                      ref.read(noteSelectionProvider.notifier).deselectAll();
                    } else {
                      ref
                          .read(noteSelectionProvider.notifier)
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
                filter.type == NoteFilterType.trash
                    ? Icons.restore_from_trash_rounded
                    : Icons.delete_outline_rounded,
                color: filter.type == NoteFilterType.trash
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              tooltip: filter.type == NoteFilterType.trash
                  ? 'Restore Selected'
                  : 'Delete Selected',
              onPressed: selectedCount > 0
                  ? () {
                      if (filter.type == NoteFilterType.trash) {
                        final ids = selectedNotes.map((n) => n.id);
                        ref.read(notesProvider.notifier).bulkRestore(ids);
                        ref.read(noteSelectionProvider.notifier).exitSelectionMode();
                      } else {
                        _confirmDeleteNotes(context, ref, selectedNotes);
                      }
                    }
                  : null,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More Actions',
              onSelected: (val) {
                _handleAction(context, ref, val, selectedNotes);
              },
              itemBuilder: (ctx) => [
                if (selectedCount == 1) ...[
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 10),
                        Text('Rename Note'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 18),
                        SizedBox(width: 10),
                        Text('Duplicate Note'),
                      ],
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      Icon(
                        allPinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(allPinned ? 'Unpin Notes' : 'Pin Notes'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(
                        allFavorited
                            ? Icons.star_outline_rounded
                            : Icons.star_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(allFavorited
                          ? 'Remove from Favorites'
                          : 'Add to Favorites'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'move',
                  child: Row(
                    children: [
                      Icon(Icons.drive_file_move_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Move to Notebook'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'tag',
                  child: Row(
                    children: [
                      Icon(Icons.label_outline_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Add Tag'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(
                        filter.type == NoteFilterType.archive
                            ? Icons.unarchive_outlined
                            : Icons.archive_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(filter.type == NoteFilterType.archive
                          ? 'Restore from Archive'
                          : 'Archive Notes'),
                    ],
                  ),
                ),
              ],
            ),
          ] else ...[
            // Tablet & Desktop Toolbar
            if (selectedCount == 1) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Rename Note',
                onPressed: () =>
                    _showRenameDialog(context, ref, selectedNotes.first),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20),
                tooltip: 'Duplicate Note',
                onPressed: () {
                  ref
                      .read(notesProvider.notifier)
                      .duplicateNote(selectedNotes.first.id);
                  ref.read(noteSelectionProvider.notifier).exitSelectionMode();
                },
              ),
            ],
            IconButton(
              icon: Icon(
                allPinned
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                size: 20,
              ),
              tooltip: allPinned ? 'Unpin Notes' : 'Pin Notes',
              onPressed: () {
                final ids = selectedNotes.map((n) => n.id);
                ref.read(notesProvider.notifier).bulkTogglePin(ids, !allPinned);
                ref.read(noteSelectionProvider.notifier).exitSelectionMode();
              },
            ),
            IconButton(
              icon: Icon(
                allFavorited
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 20,
                color: allFavorited ? Colors.amber : null,
              ),
              tooltip: allFavorited
                  ? 'Remove from Favorites'
                  : 'Add to Favorites',
              onPressed: () {
                final ids = selectedNotes.map((n) => n.id);
                ref
                    .read(notesProvider.notifier)
                    .bulkToggleFavorite(ids, !allFavorited);
                ref.read(noteSelectionProvider.notifier).exitSelectionMode();
              },
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_move_outlined, size: 20),
              tooltip: 'Move to Notebook',
              onPressed: () => _showMoveDialog(context, ref, selectedNotes),
            ),
            IconButton(
              icon: const Icon(Icons.label_outline_rounded, size: 20),
              tooltip: 'Add Tag',
              onPressed: () => _showAddTagDialog(context, ref, selectedNotes),
            ),
            IconButton(
              icon: Icon(
                filter.type == NoteFilterType.archive
                    ? Icons.unarchive_outlined
                    : Icons.archive_outlined,
                size: 20,
              ),
              tooltip: filter.type == NoteFilterType.archive
                  ? 'Restore from Archive'
                  : 'Archive Notes',
              onPressed: () {
                final ids = selectedNotes.map((n) => n.id);
                final shouldArchive = filter.type != NoteFilterType.archive;
                ref
                    .read(notesProvider.notifier)
                    .bulkArchive(ids, shouldArchive);
                ref.read(noteSelectionProvider.notifier).exitSelectionMode();
              },
            ),
            const SizedBox(width: 4),
            if (filter.type == NoteFilterType.trash) ...[
              FilledButton.icon(
                icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                label: const Text('Restore'),
                onPressed: () {
                  final ids = selectedNotes.map((n) => n.id);
                  ref.read(notesProvider.notifier).bulkRestore(ids);
                  ref.read(noteSelectionProvider.notifier).exitSelectionMode();
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.delete_forever_rounded,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                tooltip: 'Permanently Delete',
                onPressed: () =>
                    _confirmPermanentDeleteNotes(context, ref, selectedNotes),
              ),
            ] else ...[
              if (isDesktop)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete (Del)'),
                  onPressed: () =>
                      _confirmDeleteNotes(context, ref, selectedNotes),
                )
              else
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error,
                    size: 20,
                  ),
                  tooltip: 'Delete Selected (Del)',
                  onPressed: () =>
                      _confirmDeleteNotes(context, ref, selectedNotes),
                ),
            ],
          ],
        ],
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    List<Note> notes,
  ) {
    switch (action) {
      case 'rename':
        if (notes.isNotEmpty) {
          _showRenameDialog(context, ref, notes.first);
        }
        break;
      case 'duplicate':
        if (notes.isNotEmpty) {
          ref.read(notesProvider.notifier).duplicateNote(notes.first.id);
          ref.read(noteSelectionProvider.notifier).exitSelectionMode();
        }
        break;
      case 'pin':
        final allPinned = notes.every((n) => n.isPinned);
        ref
            .read(notesProvider.notifier)
            .bulkTogglePin(notes.map((n) => n.id), !allPinned);
        ref.read(noteSelectionProvider.notifier).exitSelectionMode();
        break;
      case 'favorite':
        final allFavorited = notes.every((n) => n.isFavorite);
        ref
            .read(notesProvider.notifier)
            .bulkToggleFavorite(notes.map((n) => n.id), !allFavorited);
        ref.read(noteSelectionProvider.notifier).exitSelectionMode();
        break;
      case 'move':
        _showMoveDialog(context, ref, notes);
        break;
      case 'tag':
        _showAddTagDialog(context, ref, notes);
        break;
      case 'archive':
        final filter = ref.read(noteFilterProvider);
        final shouldArchive = filter.type != NoteFilterType.archive;
        ref
            .read(notesProvider.notifier)
            .bulkArchive(notes.map((n) => n.id), shouldArchive);
        ref.read(noteSelectionProvider.notifier).exitSelectionMode();
        break;
    }
  }

  void _confirmDeleteNotes(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
  ) {
    final count = notes.length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Move $count Note${count == 1 ? '' : 's'} to Trash?'),
        content: Text(
          'Are you sure you want to delete ${count == 1 ? 'this note' : 'these $count notes'}? You can restore them from the Trash view.',
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
              final ids = notes.map((n) => n.id).toList();
              ref.read(notesProvider.notifier).bulkDelete(ids);
              ref.read(noteSelectionProvider.notifier).exitSelectionMode();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Moved $count note${count == 1 ? '' : 's'} to Trash'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref.read(notesProvider.notifier).bulkRestore(ids);
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

  void _confirmPermanentDeleteNotes(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
  ) {
    final count = notes.length;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permanently Delete $count Note${count == 1 ? '' : 's'}?'),
        content: const Text(
          'This action cannot be undone. The selected notes will be completely removed.',
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
              final ids = notes.map((n) => n.id).toList();
              ref.read(notesProvider.notifier).bulkPermanentDelete(ids);
              ref.read(noteSelectionProvider.notifier).exitSelectionMode();
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) {
    final controller = TextEditingController(text: note.title);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Note Title',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (val) {
            final trimmed = val.trim();
            if (trimmed.isNotEmpty) {
              ref.read(notesProvider.notifier).renameNote(note.id, trimmed);
              ref.read(noteSelectionProvider.notifier).exitSelectionMode();
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
                ref.read(notesProvider.notifier).renameNote(note.id, trimmed);
                ref.read(noteSelectionProvider.notifier).exitSelectionMode();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showMoveDialog(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
  ) {
    final notebooks = ref.read(notebooksProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Move ${notes.length} Note${notes.length == 1 ? '' : 's'} to Notebook'),
        content: SizedBox(
          width: 320,
          child: notebooks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No notebooks available.'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: notebooks.length,
                  itemBuilder: (c, idx) {
                    final nb = notebooks[idx];
                    return ListTile(
                      leading: const Icon(Icons.book_outlined),
                      title: Text(nb.title),
                      onTap: () {
                        final ids = notes.map((n) => n.id);
                        ref.read(notesProvider.notifier).bulkMoveToNotebook(ids, nb.id);
                        ref.read(noteSelectionProvider.notifier).exitSelectionMode();
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Moved ${notes.length} notes to "${nb.title}"'),
                          ),
                        );
                      },
                    );
                  },
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

  void _showAddTagDialog(
    BuildContext context,
    WidgetRef ref,
    List<Note> notes,
  ) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Tag to ${notes.length} Note${notes.length == 1 ? '' : 's'}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. project, lecture, idea',
            prefixText: '#',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final tag = controller.text.trim();
              if (tag.isNotEmpty) {
                final ids = notes.map((n) => n.id);
                ref.read(notesProvider.notifier).bulkAddTag(ids, tag);
                ref.read(noteSelectionProvider.notifier).exitSelectionMode();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added tag "#$tag" to ${notes.length} notes')),
                );
              }
            },
            child: const Text('Add Tag'),
          ),
        ],
      ),
    );
  }
}

