import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/note_model.dart';
import '../../data/note_provider.dart';
import '../../services/note_auto_save_coordinator.dart';
import '../widgets/note_editor_view.dart';
import '../widgets/note_shortcuts.dart';

/// Dedicated Mobile Editor screen pushed when a note is tapped in 1-Pane layout.
class MobileNoteEditorScreen extends ConsumerStatefulWidget {
  final Note note;

  const MobileNoteEditorScreen({
    super.key,
    required this.note,
  });

  @override
  ConsumerState<MobileNoteEditorScreen> createState() =>
      _MobileNoteEditorScreenState();
}

class _MobileNoteEditorScreenState
    extends ConsumerState<MobileNoteEditorScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure active note is selected in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedNoteProvider.notifier).selectNote(widget.note);
    });
  }

  Future<void> _handleBackPress() async {
    // Flush pending save before popping
    await ref.read(noteAutoSaveCoordinatorProvider.notifier).flushPendingSave(
          noteId: widget.note.id,
        );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBackPress();
      },
      child: NoteKeyboardShortcuts(
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: _handleBackPress,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  widget.note.isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: widget.note.isFavorite ? Colors.amber : null,
                ),
                tooltip: widget.note.isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
                onPressed: () {
                  ref
                      .read(notesProvider.notifier)
                      .toggleFavorite(widget.note.id);
                },
              ),
              IconButton(
                icon: Icon(
                  widget.note.isPinned
                      ? Icons.push_pin_rounded
                      : Icons.push_pin_outlined,
                  color: widget.note.isPinned
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: widget.note.isPinned ? 'Unpin' : 'Pin to Top',
                onPressed: () {
                  ref.read(notesProvider.notifier).togglePin(widget.note.id);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: NoteEditorView(
              key: ValueKey(widget.note.id),
              note: widget.note,
              isMobile: true,
            ),
          ),
        ),
      ),
    );
  }
}
