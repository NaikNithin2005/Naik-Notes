import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/attachment_model.dart';
import '../../../../data/models/note_model.dart';
import '../../../../services/storage/attachment_picker_service.dart';
import '../../../authentication/data/auth_provider.dart';
import '../../../notebooks/data/notebook_provider.dart';
import '../../../pdf/presentation/widgets/pdf_attachment_card.dart';
import '../../../sketch/presentation/widgets/sketch_canvas_dialog.dart';
import '../../../storage/data/google_drive_provider.dart';
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
  StreamSubscription? _docSub;
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

    _docSub?.cancel();
    _docSub = _controller.document.changes.listen((_) {
      if (!_isDisposed) {
        _onContentChanged();
      }
    });
  }

  @override
  void didUpdateWidget(covariant NoteEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      // Flush previous note saves safely outside the build/update phase
      final oldNoteId = oldWidget.note.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _coordinator.flushPendingSave(noteId: oldNoteId);
      });

      _titleController.removeListener(_onTitleChanged);
      _titleController.text = widget.note.title;
      _titleController.addListener(_onTitleChanged);

      _docSub?.cancel();
      _docSub = null;
      _controller.dispose();
      _initQuillController(widget.note.contentDelta);
    } else {
      if (oldWidget.note.title != widget.note.title &&
          _titleController.text != widget.note.title) {
        _titleController.removeListener(_onTitleChanged);
        _titleController.text = widget.note.title;
        _titleController.addListener(_onTitleChanged);
      }

      // Safe hydration when remote note was updated on another device
      final autoSaveState = ref.read(noteAutoSaveCoordinatorProvider);
      final isLocalDirty =
          autoSaveState.isDirty && autoSaveState.activeNoteId == widget.note.id;
      if (!isLocalDirty &&
          oldWidget.note.contentDelta != widget.note.contentDelta &&
          widget.note.updatedAt.isAfter(oldWidget.note.updatedAt)) {
        _docSub?.cancel();
        Document doc;
        try {
          final decoded = jsonDecode(widget.note.contentDelta);
          doc = Document.fromJson(decoded);
        } catch (_) {
          doc = Document()..insert(0, '\n');
        }
        _controller.document = doc;
        _docSub = _controller.document.changes.listen((_) {
          if (!_isDisposed) {
            _onContentChanged();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _docSub?.cancel();
    _docSub = null;
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

  Future<void> _pickAndInsertImage() async {
    final picker = ref.read(attachmentPickerServiceProvider);
    final picked = await picker.pickSingleAttachment(
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (picked == null) return;

    final auth = ref.read(authProvider);
    final uid = auth.user?.id ?? 'local_user';
    final coordinator = ref.read(attachmentSyncCoordinatorProvider);

    try {
      final attachment = await coordinator.addAttachment(
        uid: uid,
        noteId: widget.note.id,
        sourceFile: picked.file,
        fileName: picked.fileName,
        mimeType: picked.mimeType,
      );

      final offset = _controller.selection.baseOffset >= 0
          ? _controller.selection.baseOffset
          : _controller.document.length - 1;
      _controller.document.insert(
        offset,
        BlockEmbed.image(attachment.localPath ?? picked.file.path),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to insert image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _pickFiles() async {
    final picker = ref.read(attachmentPickerServiceProvider);
    final pickedList = await picker.pickAttachments(allowMultiple: true);
    if (pickedList.isEmpty) return;

    final auth = ref.read(authProvider);
    final uid = auth.user?.id ?? 'local_user';
    final coordinator = ref.read(attachmentSyncCoordinatorProvider);

    for (final picked in pickedList) {
      try {
        await coordinator.addAttachment(
          uid: uid,
          noteId: widget.note.id,
          sourceFile: picked.file,
          fileName: picked.fileName,
          mimeType: picked.mimeType,
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to attach ${picked.fileName}: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  Future<void> _takePhoto() async {
    final picker = ref.read(attachmentPickerServiceProvider);
    final picked = await picker.capturePhotoFromCamera();
    if (picked == null) return;

    final auth = ref.read(authProvider);
    final uid = auth.user?.id ?? 'local_user';
    final coordinator = ref.read(attachmentSyncCoordinatorProvider);

    try {
      final attachment = await coordinator.addAttachment(
        uid: uid,
        noteId: widget.note.id,
        sourceFile: picked.file,
        fileName: picked.fileName,
        mimeType: picked.mimeType,
      );

      final offset = _controller.selection.baseOffset >= 0
          ? _controller.selection.baseOffset
          : _controller.document.length - 1;
      _controller.document.insert(
        offset,
        BlockEmbed.image(attachment.localPath ?? picked.file.path),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera capture failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _openSketchCanvas(BuildContext context) async {
    final sketchAttachment = await SketchCanvasDialog.show(context, widget.note.id);
    if (sketchAttachment != null && sketchAttachment.localPath != null) {
      final offset = _controller.selection.baseOffset >= 0
          ? _controller.selection.baseOffset
          : _controller.document.length - 1;
      _controller.document.insert(
        offset,
        BlockEmbed.image(sketchAttachment.localPath!),
      );
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.upload_file_rounded, color: Colors.blueAccent),
                ),
                title: const Text('Attach File / PDF / Document'),
                subtitle: const Text('PDF, DOC, DOCX, TXT, images'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickFiles();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFDF2F8),
                  child: Icon(Icons.image_outlined, color: Colors.pinkAccent),
                ),
                title: const Text('Insert Image into Note'),
                subtitle: const Text('Pick and embed inline at cursor'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndInsertImage();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDF4),
                  child: Icon(Icons.camera_alt_outlined, color: Colors.green),
                ),
                title: const Text('Take Photo (Camera)'),
                subtitle: const Text('Capture with device camera'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _takePhoto();
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFFBEB),
                  child: Icon(Icons.draw_rounded, color: Colors.amber),
                ),
                title: const Text('Draw Sketch (Apple Pencil)'),
                subtitle: const Text('Draw handwritten diagrams and sketches'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openSketchCanvas(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteAttachment(BuildContext context, NoteAttachment attachment, String uid) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Attachment?'),
        content: Text(
          'Are you sure you want to remove "${attachment.fileName}"? '
          'It will be deleted from this note and local storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(attachmentSyncCoordinatorProvider).deleteAttachment(
                    uid: uid,
                    noteId: widget.note.id,
                    attachmentId: attachment.attachmentId,
                  );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _previewImage(BuildContext context, NoteAttachment attachment) {
    if (attachment.localPath == null) return;
    final file = File(attachment.localPath!);
    if (!file.existsSync()) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(file),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsStrip(
    BuildContext context,
    List<NoteAttachment> attachments,
    String uid,
    ThemeData theme,
    bool isDark,
  ) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    final pdfs = attachments.where((a) => a.isPdf).toList();
    final imagesAndSketches = attachments.where((a) => !a.isPdf).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
            : Colors.brown.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attachment_rounded, size: 16),
              const SizedBox(width: 6),
              Text(
                'Attachments (${attachments.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                onPressed: () => _showAttachmentOptions(context),
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Render PDFs
          for (final pdf in pdfs)
            PdfAttachmentCard(
              attachment: pdf,
              onDelete: () => _confirmDeleteAttachment(context, pdf, uid),
            ),

          // Render Images and Sketches
          if (imagesAndSketches.isNotEmpty) ...[
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in imagesAndSketches)
                    _buildImageAttachmentCard(context, item, uid, theme, isDark),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageAttachmentCard(
    BuildContext context,
    NoteAttachment attachment,
    String uid,
    ThemeData theme,
    bool isDark,
  ) {
    final localExists = attachment.localPath != null && File(attachment.localPath!).existsSync();
    final isUploaded = attachment.uploadStatus == AttachmentUploadStatus.uploaded;
    final isFailed = attachment.uploadStatus == AttachmentUploadStatus.failed;

    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFailed ? Colors.redAccent : theme.dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: localExists ? () => _previewImage(context, attachment) : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    height: 70,
                    color: isDark ? Colors.black26 : Colors.grey.shade200,
                    child: localExists
                        ? Image.file(
                            File(attachment.localPath!),
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_outlined, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: InkWell(
                  onTap: () => _confirmDeleteAttachment(context, attachment, uid),
                  child: const CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close, size: 12, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? Colors.green.shade700
                        : (isFailed ? Colors.redAccent : Colors.blueGrey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isUploaded ? 'Synced' : (isFailed ? 'Failed' : 'Pending'),
                    style: const TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            attachment.fileName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            attachment.humanReadableSize,
            style: TextStyle(fontSize: 9.5, color: theme.colorScheme.onSurfaceVariant),
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
    final auth = ref.watch(authProvider);
    final uid = auth.user?.id ?? 'local_user';
    final attachmentsAsync = ref.watch(attachmentsForNoteProvider(widget.note.id));
    final attachments = attachmentsAsync.value ?? const [];

    // Toolbar config
    final toolbarConfig = QuillSimpleToolbarConfig(
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
      customButtons: [
        QuillToolbarCustomButtonOptions(
          icon: const Icon(Icons.image_outlined, size: 20),
          tooltip: 'Insert Image',
          onPressed: _pickAndInsertImage,
        ),
        QuillToolbarCustomButtonOptions(
          icon: const Icon(Icons.attach_file_rounded, size: 20),
          tooltip: 'Attach File / PDF',
          onPressed: () => _showAttachmentOptions(context),
        ),
        QuillToolbarCustomButtonOptions(
          icon: const Icon(Icons.draw_outlined, size: 20),
          tooltip: 'Apple Pencil Sketch',
          onPressed: () => _openSketchCanvas(context),
        ),
      ],
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
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded),
                    tooltip: 'Add Attachment',
                    onPressed: () => _showAttachmentOptions(context),
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
                          // Attach
                          IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.attach_file_rounded),
                            tooltip: 'Add Attachment',
                            onPressed: () => _showAttachmentOptions(context),
                          ),
                          // Sketch
                          IconButton(
                            iconSize: 20,
                            icon: const Icon(Icons.draw_rounded),
                            tooltip: 'Apple Pencil Sketch',
                            onPressed: () => _openSketchCanvas(context),
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

                    // Attachments Strip (PDFs, Images, Sketches)
                    _buildAttachmentsStrip(
                      context,
                      attachments,
                      uid,
                      theme,
                      isDark,
                    ),

                    // Quill Editor
                    QuillEditor.basic(
                      controller: _controller,
                      focusNode: _editorFocusNode,
                      scrollController: _editorScrollController,
                      config: QuillEditorConfig(
                        placeholder: 'Start writing your notes here...',
                        autoFocus: false,
                        expands: false,
                        padding: EdgeInsets.zero,
                        scrollable: false,
                        embedBuilders: FlutterQuillEmbeds.editorBuilders(
                          imageEmbedConfig: QuillEditorImageEmbedConfig(
                            imageProviderBuilder: (context, imageUrl) {
                              final file = File(imageUrl);
                              if (file.existsSync()) {
                                return FileImage(file);
                              }
                              if (imageUrl.startsWith('http://') ||
                                  imageUrl.startsWith('https://')) {
                                return NetworkImage(imageUrl);
                              }
                              return null;
                            },
                          ),
                        ),
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
