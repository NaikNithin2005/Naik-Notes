import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';

// Intents for keyboard actions
class CanvasUndoIntent extends Intent {
  const CanvasUndoIntent();
}

class CanvasRedoIntent extends Intent {
  const CanvasRedoIntent();
}

class CanvasSaveSyncIntent extends Intent {
  const CanvasSaveSyncIntent();
}

class CanvasSearchIntent extends Intent {
  const CanvasSearchIntent();
}

class CanvasZoomInIntent extends Intent {
  const CanvasZoomInIntent();
}

class CanvasZoomOutIntent extends Intent {
  const CanvasZoomOutIntent();
}

class CanvasResetZoomIntent extends Intent {
  const CanvasResetZoomIntent();
}

class CanvasAddPageIntent extends Intent {
  const CanvasAddPageIntent();
}

class CanvasAddStickyNoteIntent extends Intent {
  const CanvasAddStickyNoteIntent();
}

class CanvasDuplicateIntent extends Intent {
  const CanvasDuplicateIntent();
}

class CanvasCopyIntent extends Intent {
  const CanvasCopyIntent();
}

class CanvasDeleteSelectionIntent extends Intent {
  const CanvasDeleteSelectionIntent();
}

class CanvasSelectToolIntent extends Intent {
  final ToolType tool;
  const CanvasSelectToolIntent(this.tool);
}

/// Comprehensive keyboard shortcut handler for desktop (Windows 10/11) and web workspaces.
/// Provides productivity key bindings for inking tools, page zoom, undo/redo,
/// and document operations, while smartly suppressing single-key tool activations
/// when text fields are actively focused.
class HandwritingShortcuts extends ConsumerWidget {
  final String pageId;
  final Widget child;
  final VoidCallback? onToggleSearch;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetZoom;
  final VoidCallback? onAddPage;
  final VoidCallback? onAddStickyNote;
  final VoidCallback? onTriggerSync;

  const HandwritingShortcuts({
    super.key,
    required this.pageId,
    required this.child,
    this.onToggleSearch,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetZoom,
    this.onAddPage,
    this.onAddStickyNote,
    this.onTriggerSync,
  });

  bool _isTextInputFocused() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null) return false;
    final widget = focus.context?.widget;
    return widget is EditableText;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        // Undo / Redo
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            const CanvasUndoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            const CanvasUndoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyY, control: true):
            const CanvasRedoIntent(),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): const CanvasRedoIntent(),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            const CanvasRedoIntent(),

        // Sync & Save
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            const CanvasSaveSyncIntent(),
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true):
            const CanvasSaveSyncIntent(),

        // Document Search
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            const CanvasSearchIntent(),
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            const CanvasSearchIntent(),

        // Zoom In / Out / Reset
        const SingleActivator(LogicalKeyboardKey.equal, control: true):
            const CanvasZoomInIntent(),
        const SingleActivator(LogicalKeyboardKey.add, control: true):
            const CanvasZoomInIntent(),
        const SingleActivator(LogicalKeyboardKey.minus, control: true):
            const CanvasZoomOutIntent(),
        const SingleActivator(LogicalKeyboardKey.digit0, control: true):
            const CanvasResetZoomIntent(),
        const SingleActivator(LogicalKeyboardKey.numpad0, control: true):
            const CanvasResetZoomIntent(),

        // Add Page
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            const CanvasAddPageIntent(),
        const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
            const CanvasAddPageIntent(),

        // Selection Actions
        const SingleActivator(LogicalKeyboardKey.keyD, control: true):
            const CanvasDuplicateIntent(),
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            const CanvasCopyIntent(),
        const SingleActivator(LogicalKeyboardKey.delete):
            const CanvasDeleteSelectionIntent(),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const CanvasDeleteSelectionIntent(),

        // Single-key Tool Shortcuts (P, H, E, L, S, N, V)
        const SingleActivator(LogicalKeyboardKey.keyP):
            const CanvasSelectToolIntent(ToolType.ballpointPen),
        const SingleActivator(LogicalKeyboardKey.keyH):
            const CanvasSelectToolIntent(ToolType.highlighter),
        const SingleActivator(LogicalKeyboardKey.keyE):
            const CanvasSelectToolIntent(ToolType.eraser),
        const SingleActivator(LogicalKeyboardKey.keyL):
            const CanvasSelectToolIntent(ToolType.lasso),
        const SingleActivator(LogicalKeyboardKey.keyS):
            const CanvasSelectToolIntent(ToolType.shape),
        const SingleActivator(LogicalKeyboardKey.keyV):
            const CanvasSelectToolIntent(ToolType.pan),
        const SingleActivator(LogicalKeyboardKey.space):
            const CanvasSelectToolIntent(ToolType.pan),
        const SingleActivator(LogicalKeyboardKey.keyT):
            const CanvasAddStickyNoteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          CanvasUndoIntent: CallbackAction<CanvasUndoIntent>(
            onInvoke: (_) {
              if (ref.read(canUndoProvider(pageId))) {
                ref.read(strokesNotifierProvider.notifier).undo(pageId);
              }
              return null;
            },
          ),
          CanvasRedoIntent: CallbackAction<CanvasRedoIntent>(
            onInvoke: (_) {
              if (ref.read(canRedoProvider(pageId))) {
                ref.read(strokesNotifierProvider.notifier).redo(pageId);
              }
              return null;
            },
          ),
          CanvasSaveSyncIntent: CallbackAction<CanvasSaveSyncIntent>(
            onInvoke: (_) {
              onTriggerSync?.call();
              return null;
            },
          ),
          CanvasSearchIntent: CallbackAction<CanvasSearchIntent>(
            onInvoke: (_) {
              onToggleSearch?.call();
              return null;
            },
          ),
          CanvasZoomInIntent: CallbackAction<CanvasZoomInIntent>(
            onInvoke: (_) {
              onZoomIn?.call();
              return null;
            },
          ),
          CanvasZoomOutIntent: CallbackAction<CanvasZoomOutIntent>(
            onInvoke: (_) {
              onZoomOut?.call();
              return null;
            },
          ),
          CanvasResetZoomIntent: CallbackAction<CanvasResetZoomIntent>(
            onInvoke: (_) {
              onResetZoom?.call();
              return null;
            },
          ),
          CanvasAddPageIntent: CallbackAction<CanvasAddPageIntent>(
            onInvoke: (_) {
              onAddPage?.call();
              return null;
            },
          ),
          CanvasAddStickyNoteIntent: CallbackAction<CanvasAddStickyNoteIntent>(
            onInvoke: (_) {
              if (_isTextInputFocused()) return null;
              onAddStickyNote?.call();
              return null;
            },
          ),
          CanvasDuplicateIntent: CallbackAction<CanvasDuplicateIntent>(
            onInvoke: (_) {
              ref
                  .read(strokesNotifierProvider.notifier)
                  .duplicateSelected(pageId);
              return null;
            },
          ),
          CanvasCopyIntent: CallbackAction<CanvasCopyIntent>(
            onInvoke: (_) {
              ref.read(strokesNotifierProvider.notifier).copySelected(pageId);
              return null;
            },
          ),
          CanvasDeleteSelectionIntent:
              CallbackAction<CanvasDeleteSelectionIntent>(
                onInvoke: (_) {
                  if (_isTextInputFocused()) return null;
                  ref
                      .read(strokesNotifierProvider.notifier)
                      .deleteSelected(pageId);
                  return null;
                },
              ),
          CanvasSelectToolIntent: CallbackAction<CanvasSelectToolIntent>(
            onInvoke: (intent) {
              if (_isTextInputFocused()) return null;
              ref.read(activeToolProvider.notifier).setTool(intent.tool);
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
