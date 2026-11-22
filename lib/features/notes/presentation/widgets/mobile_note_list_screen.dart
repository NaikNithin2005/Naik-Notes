import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/note_model.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../data/note_provider.dart';
import '../screens/mobile_note_editor_screen.dart';
import 'note_list_pane.dart';
import 'notebook_sidebar.dart';

/// 1-Pane Mobile Layout (< 600px) for Android & iOS smartphones.
/// Primary screen: Note list with slide-out drawer for notebooks.
/// Tapping a note pushes the dedicated MobileNoteEditorScreen.
class MobileNoteListScreen extends ConsumerWidget {
  const MobileNoteListScreen({super.key});

  Future<void> _createNewNote(BuildContext context, WidgetRef ref) async {
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

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MobileNoteEditorScreen(note: newNote),
        ),
      );
    }
  }

  void _openNoteEditor(BuildContext context, Note note) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MobileNoteEditorScreen(note: note),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(noteFilterProvider);

    return Scaffold(
      drawer: const Drawer(
        child: NotebookSidebar(isDrawer: true),
      ),
      body: SafeArea(
        child: Builder(
          builder: (scaffoldContext) {
            return NoteListPane(
              showSidebarToggle: true,
              onToggleSidebar: () {
                Scaffold.of(scaffoldContext).openDrawer();
              },
              onNoteSelected: (note) => _openNoteEditor(context, note),
            );
          },
        ),
      ),
      floatingActionButton: filter.type != NoteFilterType.trash
          ? FloatingActionButton(
              heroTag: 'mobile_new_note_fab',
              tooltip: 'New Note',
              onPressed: () => _createNewNote(context, ref),
              child: const Icon(Icons.edit_note_rounded),
            )
          : null,
    );
  }
}

