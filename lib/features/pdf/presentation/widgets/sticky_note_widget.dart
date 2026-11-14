import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/features/pdf/data/sticky_note_provider.dart';

/// Draggable, editable sticky note annotation rendered over notebook & PDF pages.
class StickyNoteWidget extends ConsumerStatefulWidget {
  final StickyNote note;
  final VoidCallback? onDelete;

  const StickyNoteWidget({super.key, required this.note, this.onDelete});

  @override
  ConsumerState<StickyNoteWidget> createState() => _StickyNoteWidgetState();
}

class _StickyNoteWidgetState extends ConsumerState<StickyNoteWidget> {
  late TextEditingController _textController;
  late double _x;
  late double _y;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.note.content);
    _x = widget.note.x;
    _y = widget.note.y;
  }

  @override
  void didUpdateWidget(covariant StickyNoteWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.content != widget.note.content && !_isEditing) {
      _textController.text = widget.note.content;
    }
    if (oldWidget.note.x != widget.note.x ||
        oldWidget.note.y != widget.note.y) {
      _x = widget.note.x;
      _y = widget.note.y;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final note = widget.note;

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x += details.delta.dx;
            _y += details.delta.dy;
          });
        },
        onPanEnd: (_) {
          ref
              .read(stickyNotesProvider.notifier)
              .updatePosition(note.pageId, note.id, _x, _y);
        },
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          color: note.color,
          child: Container(
            width: note.width,
            height: note.height,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Handle / Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Color swatches menu
                    PopupMenuButton<String>(
                      tooltip: 'Change Color',
                      icon: const Icon(Icons.palette_outlined, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (colorHex) {
                        ref
                            .read(stickyNotesProvider.notifier)
                            .updateColor(note.pageId, note.id, colorHex);
                      },
                      itemBuilder: (ctx) => StickyNoteColors.all.map((hex) {
                        final color = Color(
                          int.parse(
                            'FF${hex.replaceFirst('#', '')}',
                            radix: 16,
                          ),
                        );
                        return PopupMenuItem(
                          value: hex,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black26),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(hex),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                    // Drag Indicator
                    Icon(
                      Icons.drag_indicator,
                      size: 16,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),

                    // Delete Button
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Sticky Note',
                      onPressed: () {
                        ref
                            .read(stickyNotesProvider.notifier)
                            .deleteStickyNote(note.pageId, note.id);
                        widget.onDelete?.call();
                      },
                    ),
                  ],
                ),
                const Divider(height: 8, thickness: 0.5),

                // Note Body
                Expanded(
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                      fontFamily: 'Roboto',
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Type your note here...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.black38),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onTap: () => setState(() => _isEditing = true),
                    onChanged: (text) {
                      ref
                          .read(stickyNotesProvider.notifier)
                          .updateContent(note.pageId, note.id, text);
                    },
                    onSubmitted: (_) => setState(() => _isEditing = false),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
