import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/naik_empty_state.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../data/note_provider.dart';
import 'note_editor_view.dart';
import 'note_list_pane.dart';
import 'note_shortcuts.dart';
import 'notebook_sidebar.dart';

/// 2-Pane Tablet Layout (600px - 1023px) for iPad Portrait and Android tablets.
/// Left: Collapsible Note list and folder switcher
/// Right: Active Note Rich Text Editor
class TwoPaneTabletLayout extends ConsumerStatefulWidget {
  const TwoPaneTabletLayout({super.key});

  @override
  ConsumerState<TwoPaneTabletLayout> createState() => _TwoPaneTabletLayoutState();
}

class _TwoPaneTabletLayoutState extends ConsumerState<TwoPaneTabletLayout> {
  bool _isListVisible = true;

  void _toggleList() {
    setState(() {
      _isListVisible = !_isListVisible;
    });
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

    await ref.read(notesProvider.notifier).createNote(
          notebookId: targetNotebookId,
          title: 'Untitled Note',
          tags: filter.type == NoteFilterType.tag && filter.tag != null
              ? [filter.tag!]
              : const [],
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedNote = ref.watch(selectedNoteProvider);

    return NoteKeyboardShortcuts(
      child: Scaffold(
        drawer: const Drawer(
          child: NotebookSidebar(isDrawer: true),
        ),
        body: Builder(
          builder: (scaffoldContext) {
            return Row(
              children: [
                // Collapsible Note List Pane on the Left
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: _isListVisible ? 310.0 : 0.0,
                  child: ClipRect(
                    child: OverflowBox(
                      minWidth: 310.0,
                      maxWidth: 310.0,
                      alignment: Alignment.centerLeft,
                      child: NoteListPane(
                        showSidebarToggle: true,
                        onToggleSidebar: () {
                          Scaffold.of(scaffoldContext).openDrawer();
                        },
                      ),
                    ),
                  ),
                ),

                // Vertical Divider
                if (_isListVisible)
                  VerticalDivider(
                    thickness: 1,
                    width: 1,
                    color: theme.dividerColor.withValues(alpha: 0.15),
                  ),

                // Editor Pane on the Right
                Expanded(
                  child: Column(
                    children: [
                      // Top mini bar for Tablet: Quick toggle for note list
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border(
                            bottom: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isListVisible
                                    ? Icons.vertical_split_rounded
                                    : Icons.view_sidebar_rounded,
                                size: 20,
                              ),
                              tooltip: _isListVisible
                                  ? 'Collapse Notes List'
                                  : 'Expand Notes List',
                              onPressed: _toggleList,
                            ),
                            IconButton(
                              icon: const Icon(Icons.folder_outlined, size: 20),
                              tooltip: 'Open Notebooks Drawer',
                              onPressed: () {
                                Scaffold.of(scaffoldContext).openDrawer();
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: selectedNote == null
                            ? _buildNoNoteSelected(context)
                            : NoteEditorView(
                                key: ValueKey(selectedNote.id),
                                note: selectedNote,
                                isMobile: false,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoNoteSelected(BuildContext context) {
    return Center(
      child: NaikEmptyState(
        icon: Icons.edit_note_rounded,
        title: 'Select a Note',
        description:
            'Choose a note from the left to read or edit, or tap below to create a new note.',
        actionLabel: 'Create Note',
        actionIcon: Icons.add,
        onAction: _createNewNote,
      ),
    );
  }
}
