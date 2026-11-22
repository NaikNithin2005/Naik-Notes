import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/naik_empty_state.dart';
import '../../../../data/models/note_model.dart';
import '../../../../data/models/notebook_model.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../../notes/data/note_provider.dart';

/// Dedicated Trash Management Screen with gallery-style multi-selection,
/// 30-day retention countdown, individual/bulk restoration, and irreversible permanent deletion.
class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSelectionMode = false;
  final Set<String> _selectedNotebookIds = {};
  final Set<String> _selectedNoteIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _isSelectionMode) {
        setState(() {
          _isSelectionMode = false;
          _selectedNotebookIds.clear();
          _selectedNoteIds.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isNotebookTab => _tabController.index == 0;
  int get _selectedCount =>
      _isNotebookTab ? _selectedNotebookIds.length : _selectedNoteIds.length;

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedNotebookIds.clear();
      _selectedNoteIds.clear();
    });
  }

  void _toggleNotebookSelection(String id) {
    setState(() {
      if (_selectedNotebookIds.contains(id)) {
        _selectedNotebookIds.remove(id);
        if (_selectedNotebookIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNotebookIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _toggleNoteSelection(String id) {
    setState(() {
      if (_selectedNoteIds.contains(id)) {
        _selectedNoteIds.remove(id);
        if (_selectedNoteIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedNoteIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<String> allIds) {
    setState(() {
      _isSelectionMode = true;
      if (_isNotebookTab) {
        _selectedNotebookIds.addAll(allIds);
      } else {
        _selectedNoteIds.addAll(allIds);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      if (_isNotebookTab) {
        _selectedNotebookIds.clear();
      } else {
        _selectedNoteIds.clear();
      }
      _isSelectionMode = false;
    });
  }

  String _formatRetention(DateTime? deletedAt) {
    if (deletedAt == null) return '30 days remaining';
    final daysPassed = DateTime.now().difference(deletedAt).inDays;
    final remaining = (30 - daysPassed).clamp(0, 30);
    final passedText = daysPassed == 0 ? 'today' : '$daysPassed days ago';
    return 'Deleted $passedText · $remaining days left';
  }

  Color _parseColor(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('0xFF$clean'));
    }
    return Colors.blueGrey;
  }

  Future<void> _restoreSelected() async {
    if (_isNotebookTab) {
      final ids = _selectedNotebookIds.toList();
      if (ids.isEmpty) return;
      await ref.read(notebooksProvider.notifier).bulkRestore(ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored ${ids.length} notebook(s)')),
        );
      }
    } else {
      final ids = _selectedNoteIds.toList();
      if (ids.isEmpty) return;
      await ref.read(notesProvider.notifier).bulkRestore(ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restored ${ids.length} note(s)')),
        );
      }
    }
    _exitSelectionMode();
  }

  Future<void> _permanentlyDeleteSelected() async {
    final count = _selectedCount;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Permanently Delete $count Item(s)?'),
        content: const Text(
          'This action is irreversible. The selected items will be permanently erased '
          'and removed from all synced devices and cloud storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_isNotebookTab) {
      final ids = _selectedNotebookIds.toList();
      await ref.read(notebooksProvider.notifier).bulkPermanentDelete(ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permanently deleted ${ids.length} notebook(s)')),
        );
      }
    } else {
      final ids = _selectedNoteIds.toList();
      await ref.read(notesProvider.notifier).bulkPermanentDelete(ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permanently deleted ${ids.length} note(s)')),
        );
      }
    }
    _exitSelectionMode();
  }

  Future<void> _emptyTrash(int totalCount) async {
    if (totalCount == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: Text(
          'Are you sure you want to permanently delete all $totalCount item(s) in Trash? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_isNotebookTab) {
      await ref.read(notebooksProvider.notifier).emptyTrash();
    } else {
      await ref.read(notesProvider.notifier).emptyTrash();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trash emptied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notebooksAsync = ref.watch(trashNotebooksProvider);
    final notesAsync = ref.watch(trashNotesProvider);

    final notebooks = notebooksAsync.asData?.value ?? [];
    final notes = notesAsync.asData?.value ?? [];

    final activeItemsCount = _isNotebookTab ? notebooks.length : notes.length;
    final allSelected = activeItemsCount > 0 && _selectedCount == activeItemsCount;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Cancel Selection',
                onPressed: _exitSelectionMode,
              ),
              title: Text('$_selectedCount Selected'),
              actions: [
                TextButton(
                  onPressed: () {
                    if (allSelected) {
                      _deselectAll();
                    } else {
                      final allIds = _isNotebookTab
                          ? notebooks.map((n) => n.id).toList()
                          : notes.map((n) => n.id).toList();
                      _selectAll(allIds);
                    }
                  },
                  child: Text(allSelected ? 'Deselect All' : 'Select All'),
                ),
                IconButton(
                  icon: const Icon(Icons.restore_from_trash_rounded),
                  tooltip: 'Restore Selected',
                  onPressed: _selectedCount > 0 ? _restoreSelected : null,
                ),
                IconButton(
                  icon: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
                  tooltip: 'Delete Permanently',
                  onPressed: _selectedCount > 0 ? _permanentlyDeleteSelected : null,
                ),
              ],
            )
          : AppBar(
              title: const Text('Trash'),
              actions: [
                if (activeItemsCount > 0)
                  TextButton.icon(
                    icon: Icon(Icons.delete_sweep_rounded, color: theme.colorScheme.error),
                    label: Text(
                      'Empty Trash',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    onPressed: () => _emptyTrash(activeItemsCount),
                  ),
              ],
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.book_outlined),
                    text: 'Notebooks (${notebooks.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.edit_note_outlined),
                    text: 'Notes (${notes.length})',
                  ),
                ],
              ),
            ),
      body: Column(
        children: [
          // 30-Day Retention Policy Banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Items in Trash are retained for 30 days before being permanently deleted automatically. '
                    'Restoring an item returns it to your active workspace.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Contents
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Notebooks
                notebooksAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return NaikEmptyState.trash();
                    }
                    return _buildNotebooksGrid(context, items);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading trash: $e')),
                ),

                // Tab 2: Notes
                notesAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return NaikEmptyState.trash();
                    }
                    return _buildNotesGrid(context, items);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error loading trash: $e')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotebooksGrid(BuildContext context, List<Notebook> items) {
    final width = MediaQuery.sizeOf(context).width;
    int crossAxisCount = 2;
    if (width >= 1200) {
      crossAxisCount = 4;
    } else if (width >= 900) {
      crossAxisCount = 3;
    } else if (width < AppConstants.mobileBreakpoint) {
      crossAxisCount = 1;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.35,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final nb = items[index];
        final isSelected = _selectedNotebookIds.contains(nb.id);
        return _buildNotebookTrashCard(context, nb, isSelected);
      },
    );
  }

  Widget _buildNotebookTrashCard(
    BuildContext context,
    Notebook nb,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final coverColor = _parseColor(nb.coverColorHex);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleNotebookSelection(nb.id);
          }
        },
        onLongPress: () => _toggleNotebookSelection(nb.id),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 48,
                        decoration: BoxDecoration(
                          color: coverColor,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.book_rounded,
                          size: 20,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nb.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${nb.pageCount} page(s)',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isSelectionMode)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => _toggleNotebookSelection(nb.id),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _formatRetention(nb.deletedAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_isSelectionMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                          label: const Text('Restore'),
                          onPressed: () async {
                            await ref
                                .read(notebooksProvider.notifier)
                                .restoreNotebook(nb.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Restored "${nb.title}"')),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(
                            Icons.delete_forever_rounded,
                            size: 18,
                            color: theme.colorScheme.error,
                          ),
                          tooltip: 'Delete Permanently',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Permanently Delete "${nb.title}"?'),
                                content: const Text(
                                  'This action cannot be undone. All notes and pages '
                                  'within this notebook will be permanently deleted.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                      foregroundColor: theme.colorScheme.onError,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('Delete Permanently'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await ref
                                  .read(notebooksProvider.notifier)
                                  .permanentlyDeleteNotebook(nb.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Permanently deleted "${nb.title}"'),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesGrid(BuildContext context, List<Note> items) {
    final width = MediaQuery.sizeOf(context).width;
    int crossAxisCount = 2;
    if (width >= 1200) {
      crossAxisCount = 4;
    } else if (width >= 900) {
      crossAxisCount = 3;
    } else if (width < AppConstants.mobileBreakpoint) {
      crossAxisCount = 1;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 3.0 : 1.35,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final note = items[index];
        final isSelected = _selectedNoteIds.contains(note.id);
        return _buildNoteTrashCard(context, note, isSelected);
      },
    );
  }

  Widget _buildNoteTrashCard(
    BuildContext context,
    Note note,
    bool isSelected,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleNoteSelection(note.id);
          }
        },
        onLongPress: () => _toggleNoteSelection(note.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (note.plainText.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            note.plainText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_isSelectionMode)
                    Checkbox(
                      value: isSelected,
                      onChanged: (_) => _toggleNoteSelection(note.id),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                _formatRetention(note.deletedAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (!_isSelectionMode)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
                      label: const Text('Restore'),
                      onPressed: () async {
                        await ref.read(notesProvider.notifier).restoreNote(note.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Restored "${note.title}"')),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(
                        Icons.delete_forever_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Delete Permanently',
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Permanently Delete "${note.title}"?'),
                            content: const Text(
                              'This action cannot be undone. This note will be permanently erased.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                ),
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete Permanently'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(notesProvider.notifier)
                              .permanentlyDeleteNote(note.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Permanently deleted "${note.title}"'),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

