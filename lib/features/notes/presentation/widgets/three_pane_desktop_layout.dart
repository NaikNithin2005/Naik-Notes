import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/naik_empty_state.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../data/note_provider.dart';
import 'note_editor_view.dart';
import 'note_list_pane.dart';
import 'note_shortcuts.dart';
import 'notebook_sidebar.dart';

/// 3-Pane Desktop Layout (>= 1024px) for Windows and iPad Landscape.
/// Left: Notebooks & Navigation Sidebar
/// Middle: Note List & Search
/// Right: Active Note Rich Text Editor
class ThreePaneDesktopLayout extends ConsumerStatefulWidget {
  const ThreePaneDesktopLayout({super.key});

  @override
  ConsumerState<ThreePaneDesktopLayout> createState() =>
      _ThreePaneDesktopLayoutState();
}

class _ThreePaneDesktopLayoutState extends ConsumerState<ThreePaneDesktopLayout> {
  bool _isSidebarVisible = true;

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
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
        body: Row(
          children: [
            // Left Pane: Notebooks Sidebar (Collapsible)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _isSidebarVisible ? 260.0 : 0.0,
              child: ClipRect(
                child: OverflowBox(
                  minWidth: 260.0,
                  maxWidth: 260.0,
                  alignment: Alignment.centerLeft,
                  child: NotebookSidebar(
                    onToggleCollapse: _toggleSidebar,
                  ),
                ),
              ),
            ),

            // Middle Pane: Search & Note List
            SizedBox(
              width: 320,
              child: NoteListPane(
                showSidebarToggle: !_isSidebarVisible,
                onToggleSidebar: _toggleSidebar,
              ),
            ),

            // Vertical separator
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),

            // Right Pane: Active Rich Text Editor
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
    );
  }

  Widget _buildNoNoteSelected(BuildContext context) {
    return Center(
      child: NaikEmptyState(
        icon: Icons.edit_note_rounded,
        title: 'Select a Note',
        description:
            'Choose a note from the list on the left to start reading or editing, or create a new note.',
        actionLabel: 'Create Note',
        actionIcon: Icons.add,
        onAction: _createNewNote,
      ),
    );
  }
}
