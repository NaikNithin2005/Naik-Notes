import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/note_model.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../data/note_provider.dart';
import '../../services/note_auto_save_coordinator.dart';
import 'note_shortcuts.dart';

/// Full-featured rich-text note editor view powered by flutter_quill.
class NoteEditorView extends ConsumerStatefulWidget {
  final Note note;
  final bool isMobile;
  final VoidCallback? onBack;

  const NoteEditorView({
    super.key,
    required this.note,
    this.isMobile = false,
    this.onBack,
  });

  @override
  ConsumerState<NoteEditorView> createState() => _NoteEditorViewState();
}

class _NoteEditorViewState extends ConsumerState<NoteEditorView> {
  late QuillController _controller;
  late TextEditingController _titleController;
  late NoteAutoSaveCoordinator _coordinator;
  final FocusNode _editorFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _coordinator = ref.read(noteAutoSaveCoordinatorProvider.notifier);
    _titleController = TextEditingController(text: widget.note.title);
    _initQuillController(widget.note.contentDelta);

    _titleController.addListener(_onTitleChanged);
  }

  void _initQuillController(String deltaJson) {
    Document doc;
    try {
      final decoded = jsonDecode(deltaJson);
      doc = Document.fromJson(decoded);
    } catch (_) {
      doc = Document()..insert(0, '\n');
    }

    _controller = QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _controller.document.changes.listen((_) {
      if (!_isDisposed) {
        _onContentChanged();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NoteEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      // Flush previous note saves
      _coordinator.flushPendingSave(noteId: oldWidget.note.id);

      _titleController.removeListener(_onTitleChanged);
      _titleController.text = widget.note.title;
      _titleController.addListener(_onTitleChanged);

      _controller.dispose();
      _initQuillController(widget.note.contentDelta);
    } else if (oldWidget.note.title != widget.note.title &&
        _titleController.text != widget.note.title) {
      _titleController.text = widget.note.title;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _titleController.removeListener(_onTitleChanged);
    _titleController.dispose();
    _editorFocusNode.dispose();
    _titleFocusNode.dispose();
    _editorScrollController.dispose();

    // Flush any pending unsaved text
    _coordinator.flushPendingSave(noteId: widget.note.id);

    _controller.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    final title = _titleController.text;
    final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
    ref.read(noteAutoSaveCoordinatorProvider.notifier).onNoteChanged(
          note: widget.note,
          deltaJson: deltaJson,
          title: title,
        );
  }

  void _onContentChanged() {
    final title = _titleController.text;
    final deltaJson = jsonEncode(_controller.document.toDelta().toJson());
    ref.read(noteAutoSaveCoordinatorProvider.notifier).onNoteChanged(
          note: widget.note,
          deltaJson: deltaJson,
          title: title,
        );
    setState(() {}); // Updates word/char counts
  }

  int get _wordCount {
    final text = _controller.document.toPlainText().trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  int get _charCount => _controller.document.toPlainText().trim().length;

  void _showAddTagDialog(BuildContext context) {
    final tagCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Tag Name',
            hintText: 'e.g. work, ideas, urgent',
            prefixIcon: Icon(Icons.label_outline_rounded),
          ),
          onSubmitted: (val) {
            if (val.trim().isNotEmpty) {
              ref
                  .read(notesProvider.notifier)
                  .addTag(widget.note.id, val.trim());
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (tagCtrl.text.trim().isNotEmpty) {
                ref
                    .read(notesProvider.notifier)
                    .addTag(widget.note.id, tagCtrl.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveStatusIndicator(NoteSaveState saveState, ThemeData theme) {
    switch (saveState.status) {
      case SaveStatus.saving:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 6),
            Text(
              'Saving...',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      case SaveStatus.saved:
        final timeStr = saveState.lastSavedAt != null
            ? DateFormat('HH:mm:ss').format(saveState.lastSavedAt!)
            : 'Saved';
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Saved $timeStr',
              style: const TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        );
      case SaveStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              saveState.errorMessage ?? 'Saved locally',
              style: const TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        );
      case SaveStatus.idle:
        return Text(
          'Last modified ${DateFormat('MMM d, HH:mm').format(widget.note.updatedAt)}',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final saveState = ref.watch(noteAutoSaveCoordinatorProvider);
    final notebooks = ref.watch(notebooksProvider);

    // Toolbar config
    const toolbarConfig = QuillSimpleToolbarConfig(
      showFontFamily: false,
      showFontSize: true,
      showBoldButton: true,
      showItalicButton: true,
      showUnderLineButton: true,
      showStrikeThrough: true,
      showColorButton: true,
      showBackgroundColorButton: true,
      showHeaderStyle: true,
      showListNumbers: true,
      showListBullets: true,
      showListCheck: true,
      showIndent: true,
      showAlignmentButtons: true,
      showLink: true,
      showUndo: true,
      showRedo: true,
      showClearFormat: true,
      showSubscript: false,
      showSuperscript: false,
      showInlineCode: true,
      showCodeBlock: true,
      showQuote: true,
      showSearchButton: false,
    );

    return NoteShortcuts(
      onBold: () {
        final isBold = _controller.getSelectionStyle().attributes[Attribute.bold.key] != null;
        _controller.formatSelection(isBold ? Attribute.clone(Attribute.bold, null) : Attribute.bold);
      },
      onItalic: () {
        final isItalic = _controller.getSelectionStyle().attributes[Attribute.italic.key] != null;
        _controller.formatSelection(isItalic ? Attribute.clone(Attribute.italic, null) : Attribute.italic);
      },
      onUnderline: () {
        final isUnder = _controller.getSelectionStyle().attributes[Attribute.underline.key] != null;
        _controller.formatSelection(isUnder ? Attribute.clone(Attribute.underline, null) : Attribute.underline);
      },
      onUndo: () => _controller.undo(),
      onRedo: () => _controller.redo(),
      onSelectAll: () {
        _controller.updateSelection(
          TextSelection(baseOffset: 0, extentOffset: _controller.document.length - 1),
          ChangeSource.local,
        );
      },
      child: Scaffold(
        backgroundColor: isDark
            ? theme.colorScheme.surface
            : const Color(0xFFFAF7F2), // Warm ivory stationery paper tone
        appBar: widget.isMobile
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                ),
                title: _buildSaveStatusIndicator(saveState, theme),
                actions: [
                  IconButton(
                    icon: Icon(
                      widget.note.isPinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      color: widget.note.isPinned
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    tooltip: widget.note.isPinned ? 'Unpin Note' : 'Pin Note',
                    onPressed: () => ref
                        .read(notesProvider.notifier)
                        .togglePin(widget.note.id),
                  ),
                  IconButton(
                    icon: Icon(
                      widget.note.isFavorite
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: widget.note.isFavorite ? Colors.amber : null,
                    ),
                    tooltip: widget.note.isFavorite ? 'Unfavorite' : 'Favorite',
                    onPressed: () => ref
                        .read(notesProvider.notifier)
                        .toggleFavorite(widget.note.id),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (val) {
                      switch (val) {
                        case 'duplicate':
                          ref
                              .read(notesProvider.notifier)
                              .duplicateNote(widget.note.id);
                          break;
                        case 'archive':
                          ref
                              .read(notesProvider.notifier)
                              .archiveNote(widget.note.id);
                          widget.onBack?.call();
                          break;
                        case 'delete':
                          ref
                              .read(notesProvider.notifier)
                              .deleteNote(widget.note.id);
                          widget.onBack?.call();
                          break;
                      }
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Duplicate Note'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Archive Note'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Move to Trash',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : null,
        body: Column(
          children: [
            // Top Toolbar (Windows Desktop & iPad)
            if (!widget.isMobile) ...[
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainer
                      : theme.colorScheme.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // Metadata & Status Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Notebook dropdown
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: notebooks.any((nb) => nb.id == widget.note.notebookId)
                                  ? widget.note.notebookId
                                  : (notebooks.isNotEmpty ? notebooks.first.id : null),
                              hint: const Text('Select Notebook'),
                              icon: const Icon(Icons.arrow_drop_down, size: 18),
                              items: notebooks.map((nb) {
                                return DropdownMenuItem<String>(
                                  value: nb.id,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.book_outlined, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        nb.title,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newNbId) {
                                if (newNbId != null) {
                                  ref
                                      .read(notesProvider.notifier)
                                      .moveNoteToNotebook(widget.note.id, newNbId);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildSaveStatusIndicator(saveState, theme),
                          const SizedBox(width: 24),
                          // Word & Character count chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$_wordCount words • $_charCount chars',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Pin toggle
                          IconButton(
                            iconSize: 20,
                            icon: Icon(
                              widget.note.isPinned
                                  ? Icons.push_pin_rounded
                                  : Icons.push_pin_outlined,
                              color: widget.note.isPinned
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                            tooltip: widget.note.isPinned ? 'Unpin' : 'Pin',
                            onPressed: () => ref
                                .read(notesProvider.notifier)
                                .togglePin(widget.note.id),
                          ),
                          // Favorite toggle
                          IconButton(
                            iconSize: 20,
                            icon: Icon(
                              widget.note.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: widget.note.isFavorite ? Colors.amber : null,
                            ),
                            tooltip:
                                widget.note.isFavorite ? 'Unfavorite' : 'Favorite',
                            onPressed: () => ref
                                .read(notesProvider.notifier)
                                .toggleFavorite(widget.note.id),
                          ),
                          // Duplicate
                          IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Duplicate',
                            onPressed: () => ref
                                .read(notesProvider.notifier)
                                .duplicateNote(widget.note.id),
                          ),
                          // Archive
                          IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.archive_outlined),
                            tooltip: 'Archive',
                            onPressed: () => ref
                                .read(notesProvider.notifier)
                                .archiveNote(widget.note.id),
                          ),
                          // Delete
                          IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            tooltip: 'Move to Trash',
                            onPressed: () => ref
                                .read(notesProvider.notifier)
                                .deleteNote(widget.note.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                    const Divider(height: 1, thickness: 1),
                    // Quill Toolbar at Top
                    QuillSimpleToolbar(
                      controller: _controller,
                      config: toolbarConfig,
                    ),
                  ],
                ),
              ),
            ],

            // Note Content Canvas (Title, Tags, Quill Editor)
            if (widget.note.title.contains('(Conflict Copy'))
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 16 : 48,
                  vertical: 8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.call_split_rounded, size: 20, color: Colors.deepOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conflicting Edits Preserved',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This conflict copy was preserved to prevent overwriting edits from another device.',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      onPressed: () {
                        final cleanTitle = widget.note.title
                            .replaceAll(RegExp(r'\s*\(Conflict Copy[^\)]*\)'), '')
                            .trim();
                        ref.read(notesProvider.notifier).renameNote(widget.note.id, cleanTitle);
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Keep This Copy', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                controller: _editorScrollController,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isMobile ? 16 : 48,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Note Title
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Note Title...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tags Bar
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tag in widget.note.tags)
                          Chip(
                            label: Text(
                              '#$tag',
                              style: const TextStyle(fontSize: 12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            deleteIcon: const Icon(Icons.close_rounded, size: 14),
                            onDeleted: () => ref
                                .read(notesProvider.notifier)
                                .removeTag(widget.note.id, tag),
                          ),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 14),
                          label: const Text('Tag', style: TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _showAddTagDialog(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Quill Editor
                    QuillEditor.basic(
                      controller: _controller,
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      config: const QuillEditorConfig(
                        placeholder: 'Start writing your notes here...',
                        autoFocus: false,
                        expands: false,
                        padding: EdgeInsets.zero,
                        scrollable: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Docked Bottom Toolbar for Mobile (Android / compact screens)
            if (widget.isMobile)
              SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: QuillSimpleToolbar(
                    controller: _controller,
                    config: toolbarConfig,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
