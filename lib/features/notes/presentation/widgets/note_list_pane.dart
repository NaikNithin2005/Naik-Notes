import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/naik_empty_state.dart';
import '../../../../data/models/note_model.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../data/note_provider.dart';
import '../../data/note_selection_provider.dart';
import 'note_selection_toolbar.dart';

/// Middle pane displaying the searchable, sortable list of notes.
class NoteListPane extends ConsumerStatefulWidget {
  final ValueChanged<Note>? onNoteSelected;
  final VoidCallback? onToggleSidebar;
  final bool showSidebarToggle;

  const NoteListPane({
    super.key,
    this.onNoteSelected,
    this.onToggleSidebar,
    this.showSidebarToggle = false,
  });

  @override
  ConsumerState<NoteListPane> createState() => _NoteListPaneState();
}

class _NoteListPaneState extends ConsumerState<NoteListPane> {
  late final TextEditingController _searchController;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(noteSearchProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final noteDate = DateTime(dt.year, dt.month, dt.day);

    if (noteDate == today) {
      return _timeFormat.format(dt);
    } else if (noteDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(dt).inDays < 7) {
      return DateFormat('EEEE').format(dt);
    }
    return _dateFormat.format(dt);
  }

  String _getHeaderTitle(NoteFilterState filter) {
    switch (filter.type) {
      case NoteFilterType.all:
        return 'All Notes';
      case NoteFilterType.pinned:
        return 'Pinned Notes';
      case NoteFilterType.favorites:
        return 'Favorites';
      case NoteFilterType.recent:
        return 'Recent Notes';
      case NoteFilterType.archive:
        return 'Archive';
      case NoteFilterType.trash:
        return 'Trash';
      case NoteFilterType.tag:
        return '#${filter.tag ?? 'Tag'}';
      case NoteFilterType.notebook:
        final notebooks = ref.watch(notebooksProvider);
        final nb = notebooks.where((n) => n.id == filter.notebookId).firstOrNull;
        return nb?.title ?? 'Notebook';
    }
  }

  Future<void> _createNewNote() async {
    final filter = ref.read(noteFilterProvider);
    String targetNotebookId = '';

    if (filter.type == NoteFilterType.notebook && filter.notebookId != null) {
      targetNotebookId = filter.notebookId!;
    } else {
      final notebooks = ref.read(notebooksProvider);
      targetNotebookId = notebooks.isNotEmpty ? notebooks.first.id : 'default';
    }

    final newNote = await ref.read(notesProvider.notifier).createNote(
          notebookId: targetNotebookId,
          title: 'Untitled Note',
          tags: filter.type == NoteFilterType.tag && filter.tag != null
              ? [filter.tag!]
              : const [],
        );

    if (widget.onNoteSelected != null) {
      widget.onNoteSelected!(newNote);
    }
  }

  void _showSortMenu(BuildContext context) {
    final currentSort = ref.read(noteSortOrderProvider);

    showMenu<NoteSortOrder>(
      context: context,
      position: const RelativeRect.fromLTRB(100, 100, 16, 0),
      items: [
        PopupMenuItem(
          value: NoteSortOrder.modifiedDesc,
          child: Row(
            children: [
              Icon(
                currentSort == NoteSortOrder.modifiedDesc
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Date Modified (Newest)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: NoteSortOrder.createdDesc,
          child: Row(
            children: [
              Icon(
                currentSort == NoteSortOrder.createdDesc
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Date Created (Newest)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: NoteSortOrder.titleAsc,
          child: Row(
            children: [
              Icon(
                currentSort == NoteSortOrder.titleAsc
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text('Title (A to Z)'),
            ],
          ),
        ),
      ],
    ).then((selected) {
      if (selected != null) {
        ref.read(noteSortOrderProvider.notifier).setSortOrder(selected);
      }
    });
  }

  void _showNoteOptions(BuildContext context, Note note) {
    final isTrash = note.isDeleted;
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  note.title.isEmpty ? 'Untitled Note' : note.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(),
                if (isTrash) ...[
                  ListTile(
                    leading: const Icon(Icons.restore_from_trash_rounded),
                    title: const Text('Restore Note'),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(notesProvider.notifier).restoreNote(note.id);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Delete Permanently',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmPermanentDelete(context, note);
                    },
                  ),
                ] else ...[
                  ListTile(
                    leading: Icon(
                      note.isPinned
                          ? Icons.push_pin_outlined
                          : Icons.push_pin_rounded,
                    ),
                    title: Text(note.isPinned ? 'Unpin Note' : 'Pin to Top'),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(notesProvider.notifier).togglePin(note.id);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      note.isFavorite
                          ? Icons.star_border_rounded
                          : Icons.star_rounded,
                    ),
                    title: Text(
                      note.isFavorite
                          ? 'Remove from Favorites'
                          : 'Add to Favorites',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(notesProvider.notifier).toggleFavorite(note.id);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: const Text('Duplicate Note'),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(notesProvider.notifier).duplicateNote(note.id);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      note.isArchived
                          ? Icons.unarchive_outlined
                          : Icons.archive_outlined,
                    ),
                    title: Text(
                      note.isArchived ? 'Unarchive Note' : 'Archive Note',
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (note.isArchived) {
                        ref.read(notesProvider.notifier).unarchiveNote(note.id);
                      } else {
                        ref.read(notesProvider.notifier).archiveNote(note.id);
                      }
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Move to Trash',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref.read(notesProvider.notifier).deleteNote(note.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Note moved to Trash'),
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              ref
                                  .read(notesProvider.notifier)
                                  .restoreNote(note.id);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmPermanentDelete(BuildContext context, Note note) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permanently Delete Note?'),
        content: Text(
          'Are you sure you want to permanently delete "${note.title.isEmpty ? 'Untitled Note' : note.title}"? This action cannot be undone.',
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
              ref.read(notesProvider.notifier).permanentlyDeleteNote(note.id);
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All notes in Trash will be permanently deleted. This action cannot be undone.',
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
              ref.read(notesProvider.notifier).emptyTrash();
            },
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = ref.watch(noteFilterProvider);
    final searchQuery = ref.watch(noteSearchProvider);
    final filteredNotes = ref.watch(filteredNotesProvider);
    final selectedNote = ref.watch(selectedNoteProvider);
    final noteSelection = ref.watch(noteSelectionProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (ref.read(noteSelectionProvider).isSelectionMode) {
            ref.read(noteSelectionProvider.notifier).exitSelectionMode();
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () {
          ref
              .read(noteSelectionProvider.notifier)
              .selectAll(filteredNotes.map((n) => n.id));
        },
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true): () {
          ref
              .read(noteSelectionProvider.notifier)
              .selectAll(filteredNotes.map((n) => n.id));
        },
      },
      child: Focus(
        autofocus: true,
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              right: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Column(
            children: [
              if (noteSelection.isSelectionMode)
                NoteSelectionToolbar(visibleNotes: filteredNotes)
              else ...[
                // Top Bar: Search and Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      if (widget.showSidebarToggle)
                        IconButton(
                          icon: const Icon(Icons.menu_rounded),
                          tooltip: 'Toggle Sidebar',
                          onPressed: widget.onToggleSidebar,
                        ),
                      Expanded(
                        child: SearchBar(
                          controller: _searchController,
                          hintText: 'Search notes, tags...',
                          elevation: const WidgetStatePropertyAll(0),
                          backgroundColor: WidgetStatePropertyAll(
                            theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.45),
                          ),
                          leading: const Icon(Icons.search_rounded, size: 20),
                          trailing: [
                            if (searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(noteSearchProvider.notifier).clear();
                                },
                              ),
                          ],
                          onChanged: (val) {
                            ref.read(noteSearchProvider.notifier).setQuery(val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.sort_rounded),
                        tooltip: 'Sort notes',
                        onPressed: () => _showSortMenu(context),
                      ),
                      if (filter.type != NoteFilterType.trash)
                        IconButton.filled(
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'New note (Ctrl/Cmd+N)',
                          onPressed: _createNewNote,
                        ),
                    ],
                  ),
                ),

                // Header summary info
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        _getHeaderTitle(filter),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${filteredNotes.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (filter.type == NoteFilterType.trash &&
                          filteredNotes.isNotEmpty)
                        TextButton.icon(
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(
                            'Empty Trash',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          onPressed: () => _confirmEmptyTrash(context),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],

          // Note List Canvas
          Expanded(
            child: filteredNotes.isEmpty
                ? _buildEmptyState(filter, searchQuery)
                : ListView.builder(
                    itemCount: filteredNotes.length,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final isSelected = selectedNote?.id == note.id;
                      final isMultiSelected = noteSelection.isSelected(note.id);

                      return _NoteCard(
                        note: note,
                        isSelected: isSelected,
                        isSelectionMode: noteSelection.isSelectionMode,
                        isMultiSelected: isMultiSelected,
                        formattedDate: _formatDate(note.updatedAt),
                        onTap: () {
                          if (noteSelection.isSelectionMode) {
                            if (HardwareKeyboard.instance.isShiftPressed) {
                              ref
                                  .read(noteSelectionProvider.notifier)
                                  .rangeSelect(
                                    note.id,
                                    filteredNotes.map((n) => n.id).toList(),
                                  );
                            } else {
                              ref
                                  .read(noteSelectionProvider.notifier)
                                  .toggle(note.id);
                            }
                          } else {
                            if (HardwareKeyboard.instance.isControlPressed ||
                                HardwareKeyboard.instance.isMetaPressed) {
                              ref
                                  .read(noteSelectionProvider.notifier)
                                  .enterSelectionMode(note.id);
                            } else {
                              ref
                                  .read(selectedNoteProvider.notifier)
                                  .selectNote(note);
                              if (widget.onNoteSelected != null) {
                                widget.onNoteSelected!(note);
                              }
                            }
                          }
                        },
                        onLongPress: () {
                          if (noteSelection.isSelectionMode) {
                            ref
                                .read(noteSelectionProvider.notifier)
                                .toggle(note.id);
                          } else {
                            ref
                                .read(noteSelectionProvider.notifier)
                                .enterSelectionMode(note.id);
                          }
                        },
                        onSecondaryTap: () {
                          if (noteSelection.isSelectionMode) {
                            ref
                                .read(noteSelectionProvider.notifier)
                                .toggle(note.id);
                          } else {
                            ref
                                .read(noteSelectionProvider.notifier)
                                .enterSelectionMode(note.id);
                          }
                        },
                        onMorePressed: () => _showNoteOptions(context, note),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  ),
);
}

  Widget _buildEmptyState(NoteFilterState filter, String query) {
    if (query.isNotEmpty) {
      return NaikEmptyState.search(
        query: query,
        onClearSearch: () {
          _searchController.clear();
          ref.read(noteSearchProvider.notifier).clear();
        },
      );
    }

    if (filter.type == NoteFilterType.trash) {
      return const NaikEmptyState(
        icon: Icons.delete_outline_rounded,
        title: 'Trash is Empty',
        description:
            'Deleted notes will appear here. You can restore or permanently delete them.',
      );
    }

    if (filter.type == NoteFilterType.archive) {
      return const NaikEmptyState(
        icon: Icons.archive_outlined,
        title: 'No Archived Notes',
        description: 'Completed or reference notes you archive will be stored here.',
      );
    }

    if (filter.type == NoteFilterType.favorites) {
      return const NaikEmptyState(
        icon: Icons.star_border_rounded,
        title: 'No Favorite Notes',
        description: 'Star essential notes to view them quickly in this list.',
      );
    }

    if (filter.type == NoteFilterType.pinned) {
      return const NaikEmptyState(
        icon: Icons.push_pin_outlined,
        title: 'No Pinned Notes',
        description: 'Pin important notes so they stay at the top of your list.',
      );
    }

    return NaikEmptyState(
      icon: Icons.note_alt_outlined,
      title: 'No Notes Yet',
      description: 'Create your first note to start writing with rich text, lists, and formatting.',
      actionLabel: 'Create Note',
      actionIcon: Icons.add,
      onAction: _createNewNote,
    );
  }
}

/// Note preview card inside the note list.
class _NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isMultiSelected;
  final String formattedDate;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onSecondaryTap;
  final VoidCallback onMorePressed;

  const _NoteCard({
    required this.note,
    required this.isSelected,
    this.isSelectionMode = false,
    this.isMultiSelected = false,
    required this.formattedDate,
    required this.onTap,
    required this.onLongPress,
    this.onSecondaryTap,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final selectedBg = isDark
        ? theme.colorScheme.primary.withValues(alpha: 0.16)
        : theme.colorScheme.primary.withValues(alpha: 0.10);

    final cardBg = isMultiSelected
        ? (isDark
            ? theme.colorScheme.primary.withValues(alpha: 0.22)
            : theme.colorScheme.primary.withValues(alpha: 0.14))
        : (isSelected ? selectedBg : theme.cardColor);

    final cardBorder = isMultiSelected
        ? theme.colorScheme.primary
        : (isSelected
            ? theme.colorScheme.primary
            : theme.dividerColor.withValues(alpha: 0.12));

    final borderWidth = (isMultiSelected || isSelected) ? 1.8 : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: cardBorder,
          width: borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          onLongPress: onLongPress,
          onSecondaryTap: onSecondaryTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Pin/Star icons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gallery Selection Checkbox
                    if (isSelectionMode) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10, top: 1),
                        decoration: BoxDecoration(
                          color: isMultiSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isMultiSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: isMultiSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                    if (note.isPinned) ...[
                      Icon(
                        Icons.push_pin_rounded,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (note.isFavorite) ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        note.title.trim().isEmpty ? 'Untitled Note' : note.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: (isSelected || isMultiSelected)
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontStyle: note.title.trim().isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: note.title.trim().isEmpty
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6)
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isSelectionMode)
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 16,
                        onPressed: onMorePressed,
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Preview Snippet
                Text(
                  note.preview.isEmpty ? 'No additional text' : note.preview,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Footer: Date and Tags
                Row(
                  children: [
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (note.tags.isNotEmpty)
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: [
                            for (final tag in note.tags.take(2))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            if (note.tags.length > 2)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${note.tags.length - 2}',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

