import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/note_auto_save_coordinator.dart';

/// Intent for creating a new note.
class CreateNoteIntent extends Intent {
  const CreateNoteIntent();
}

/// Intent for force-saving active note.
class ForceSaveNoteIntent extends Intent {
  const ForceSaveNoteIntent();
}

/// Intent for triggering note search focus.
class SearchNotesIntent extends Intent {
  const SearchNotesIntent();
}

/// Intent for rich-text bold formatting.
class FormatBoldIntent extends Intent {
  const FormatBoldIntent();
}

/// Intent for rich-text italic formatting.
class FormatItalicIntent extends Intent {
  const FormatItalicIntent();
}

/// Intent for rich-text underline formatting.
class FormatUnderlineIntent extends Intent {
  const FormatUnderlineIntent();
}

/// Intent for undo.
class UndoNoteIntent extends Intent {
  const UndoNoteIntent();
}

/// Intent for redo.
class RedoNoteIntent extends Intent {
  const RedoNoteIntent();
}

/// Intent for select all.
class SelectAllNoteIntent extends Intent {
  const SelectAllNoteIntent();
}

/// Cross-platform keyboard shortcuts wrapper for note workspace.
class NoteShortcuts extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onNewNote;
  final VoidCallback? onSearchFocus;
  final VoidCallback? onBold;
  final VoidCallback? onItalic;
  final VoidCallback? onUnderline;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onSelectAll;

  const NoteShortcuts({
    super.key,
    required this.child,
    this.onNewNote,
    this.onSearchFocus,
    this.onBold,
    this.onItalic,
    this.onUnderline,
    this.onUndo,
    this.onRedo,
    this.onSelectAll,
  });

  bool get _isApple {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  LogicalKeyboardKey get _modifierKey =>
      _isApple ? LogicalKeyboardKey.meta : LogicalKeyboardKey.control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mod = _modifierKey;

    final shortcuts = <ShortcutActivator, Intent>{
      // Ctrl/Cmd + N -> Create new note
      LogicalKeySet(mod, LogicalKeyboardKey.keyN): const CreateNoteIntent(),

      // Ctrl/Cmd + S -> Force save
      LogicalKeySet(mod, LogicalKeyboardKey.keyS): const ForceSaveNoteIntent(),

      // Ctrl/Cmd + F -> Search notes
      LogicalKeySet(mod, LogicalKeyboardKey.keyF): const SearchNotesIntent(),

      // Ctrl/Cmd + B -> Bold
      LogicalKeySet(mod, LogicalKeyboardKey.keyB): const FormatBoldIntent(),

      // Ctrl/Cmd + I -> Italic
      LogicalKeySet(mod, LogicalKeyboardKey.keyI): const FormatItalicIntent(),

      // Ctrl/Cmd + U -> Underline
      LogicalKeySet(mod, LogicalKeyboardKey.keyU): const FormatUnderlineIntent(),

      // Ctrl/Cmd + Z -> Undo
      LogicalKeySet(mod, LogicalKeyboardKey.keyZ): const UndoNoteIntent(),

      // Ctrl/Cmd + Shift + Z / Ctrl + Y -> Redo
      LogicalKeySet(mod, LogicalKeyboardKey.shift, LogicalKeyboardKey.keyZ):
          const RedoNoteIntent(),
      LogicalKeySet(mod, LogicalKeyboardKey.keyY): const RedoNoteIntent(),

      // Ctrl/Cmd + A -> Select all
      LogicalKeySet(mod, LogicalKeyboardKey.keyA): const SelectAllNoteIntent(),
    };

    final actions = <Type, Action<Intent>>{
      CreateNoteIntent: CallbackAction<CreateNoteIntent>(
        onInvoke: (_) {
          onNewNote?.call();
          return null;
        },
      ),
      ForceSaveNoteIntent: CallbackAction<ForceSaveNoteIntent>(
        onInvoke: (_) {
          ref.read(noteAutoSaveCoordinatorProvider.notifier).flushPendingSave();
          return null;
        },
      ),
      SearchNotesIntent: CallbackAction<SearchNotesIntent>(
        onInvoke: (_) {
          onSearchFocus?.call();
          return null;
        },
      ),
      FormatBoldIntent: CallbackAction<FormatBoldIntent>(
        onInvoke: (_) {
          onBold?.call();
          return null;
        },
      ),
      FormatItalicIntent: CallbackAction<FormatItalicIntent>(
        onInvoke: (_) {
          onItalic?.call();
          return null;
        },
      ),
      FormatUnderlineIntent: CallbackAction<FormatUnderlineIntent>(
        onInvoke: (_) {
          onUnderline?.call();
          return null;
        },
      ),
      UndoNoteIntent: CallbackAction<UndoNoteIntent>(
        onInvoke: (_) {
          onUndo?.call();
          return null;
        },
      ),
      RedoNoteIntent: CallbackAction<RedoNoteIntent>(
        onInvoke: (_) {
          onRedo?.call();
          return null;
        },
      ),
      SelectAllNoteIntent: CallbackAction<SelectAllNoteIntent>(
        onInvoke: (_) {
          onSelectAll?.call();
          return null;
        },
      ),
    };

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

/// Convenience alias for [NoteShortcuts].
typedef NoteKeyboardShortcuts = NoteShortcuts;
