import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/canvas_element_model.dart';
import 'package:naik_notes/features/canvas/data/canvas_elements_provider.dart';
import 'math_formula_dialog.dart';

/// Interactive Canvas Element widget supporting drag-to-move, corner resize,
/// top rotation handle, floating context bar, and double-tap editing for:
/// - Text Boxes (auto-focused inline editing & formatting bar)
/// - Sticky Notes (colored cards with folded corner & collapsing)
/// - Images (move, resize, rotate, lock to background)
/// - LaTeX Math Equations (Math.tex rendering & formula dialog)
class CanvasElementWidget extends ConsumerStatefulWidget {
  final CanvasElement element;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDeselect;

  const CanvasElementWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onSelect,
    required this.onDeselect,
  });

  @override
  ConsumerState<CanvasElementWidget> createState() => _CanvasElementWidgetState();
}

class _CanvasElementWidgetState extends ConsumerState<CanvasElementWidget> {
  bool _isEditing = false;
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.element.content);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _commitText();
      }
    });

    // Auto-focus if it's a newly spawned text element with empty content
    if (widget.element.type == CanvasElementType.text && widget.element.content.isEmpty) {
      _isEditing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CanvasElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.content != widget.element.content && !_isEditing) {
      _textController.text = widget.element.content;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _commitText() {
    setState(() => _isEditing = false);
    ref.read(canvasElementsProvider.notifier).updateElement(
      widget.element.copyWith(content: _textController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elem = widget.element;
    final isSelected = widget.isSelected;

    return Positioned(
      left: elem.x,
      top: elem.y,
      width: elem.width,
      height: elem.height,
      child: Transform.rotate(
        angle: elem.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main Element Body
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  widget.onSelect();
                },
                onDoubleTap: () async {
                  if (elem.type == CanvasElementType.text || elem.type == CanvasElementType.stickyNote) {
                    setState(() => _isEditing = true);
                    _focusNode.requestFocus();
                  } else if (elem.type == CanvasElementType.mathFormula) {
                    final newFormula = await MathFormulaDialog.show(
                      context,
                      initialFormula: elem.content,
                    );
                    if (newFormula != null && mounted) {
                      ref.read(canvasElementsProvider.notifier).updateElement(
                        elem.copyWith(content: newFormula),
                      );
                    }
                  }
                },
                onPanUpdate: elem.isLocked
                    ? null
                    : (details) {
                        ref.read(canvasElementsProvider.notifier).updateElement(
                          elem.copyWith(
                            x: elem.x + details.delta.dx,
                            y: elem.y + details.delta.dy,
                          ),
                        );
                      },
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected && !elem.isLocked
                        ? Border.all(color: const Color(0xFF0284C7), width: 1.5)
                        : null,
                    borderRadius: BorderRadius.circular(
                      elem.type == CanvasElementType.stickyNote ? 12 : 6,
                    ),
                  ),
                  child: _buildElementContent(context, elem),
                ),
              ),
            ),

            // Selection Controls: Corner Resize Handle & Floating Action Bar
            if (isSelected && !elem.isLocked) ...[
              // Corner Resize Handle (Bottom-Right)
              Positioned(
                right: -8,
                bottom: -8,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final newWidth = (elem.width + details.delta.dx).clamp(60.0, 900.0);
                    final newHeight = (elem.height + details.delta.dy).clamp(30.0, 900.0);
                    ref.read(canvasElementsProvider.notifier).updateElement(
                      elem.copyWith(width: newWidth, height: newHeight),
                    );
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0284C7), width: 2),
                    ),
                  ),
                ),
              ),

              // Top Rotation Handle
              Positioned(
                top: -30,
                left: (elem.width / 2) - 8,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    // Calculate angle relative to element center
                    final center = Offset(elem.x + (elem.width / 2), elem.y + (elem.height / 2));
                    final pointer = Offset(elem.x + (elem.width / 2) + details.delta.dx, elem.y - 30 + details.delta.dy);
                    final angle = math.atan2(pointer.dy - center.dy, pointer.dx - center.dx) + (math.pi / 2);
                    ref.read(canvasElementsProvider.notifier).updateElement(
                      elem.copyWith(rotation: angle),
                    );
                  },
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0284C7), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.refresh_rounded, size: 10, color: Color(0xFF0284C7)),
                    ),
                  ),
                ),
              ),

              // Floating Context / Formatting Bar Above Element
              Positioned(
                bottom: elem.height + 8,
                left: 0,
                child: _buildFloatingFormattingBar(context, elem),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildElementContent(BuildContext context, CanvasElement elem) {
    switch (elem.type) {
      case CanvasElementType.text:
        return _buildTextContent(elem);
      case CanvasElementType.stickyNote:
        return _buildStickyNoteContent(elem);
      case CanvasElementType.image:
        return _buildImageContent(elem);
      case CanvasElementType.mathFormula:
        return _buildMathContent(elem);
    }
  }

  Widget _buildTextContent(CanvasElement elem) {
    if (_isEditing) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _textController,
          focusNode: _focusNode,
          maxLines: null,
          expands: true,
          style: TextStyle(
            fontSize: elem.fontSize,
            fontWeight: elem.isBold ? FontWeight.bold : FontWeight.normal,
            fontStyle: elem.isItalic ? FontStyle.italic : FontStyle.normal,
            color: elem.color,
          ),
          textAlign: elem.textAlign,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
            hintText: 'Type text here...',
          ),
          onSubmitted: (_) => _commitText(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.topLeft,
      child: Text(
        elem.content.isEmpty ? 'Tap to edit text' : elem.content,
        textAlign: elem.textAlign,
        style: TextStyle(
          fontSize: elem.fontSize,
          fontWeight: elem.isBold ? FontWeight.bold : FontWeight.normal,
          fontStyle: elem.isItalic ? FontStyle.italic : FontStyle.normal,
          color: elem.color,
        ),
      ),
    );
  }

  Widget _buildStickyNoteContent(CanvasElement elem) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elem.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Folded corner / header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.push_pin_rounded, size: 14, color: Colors.black45),
              IconButton(
                icon: Icon(
                  elem.isCollapsed ? Icons.unfold_more_rounded : Icons.unfold_less_rounded,
                  size: 14,
                  color: Colors.black45,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  ref.read(canvasElementsProvider.notifier).updateElement(
                    elem.copyWith(
                      isCollapsed: !elem.isCollapsed,
                      height: elem.isCollapsed ? 150 : 40,
                    ),
                  );
                },
              ),
            ],
          ),
          if (!elem.isCollapsed) ...[
            const SizedBox(height: 4),
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        elem.content.isEmpty ? 'Empty sticky note' : elem.content,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent(CanvasElement elem) {
    if (elem.imagePath == null) {
      return const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.grey));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(elem.imagePath!),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMathContent(CanvasElement elem) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Math.tex(
            elem.content.isEmpty ? r'\text{Empty}' : elem.content,
            textStyle: TextStyle(
              fontSize: elem.fontSize.clamp(14.0, 48.0),
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingFormattingBar(BuildContext context, CanvasElement elem) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (elem.type == CanvasElementType.text) ...[
              // Bold toggle
              IconButton(
                icon: const Icon(Icons.format_bold, size: 16),
                color: elem.isBold ? Colors.blue : null,
                tooltip: 'Bold',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  ref.read(canvasElementsProvider.notifier).updateElement(
                    elem.copyWith(isBold: !elem.isBold),
                  );
                },
              ),
              // Italic toggle
              IconButton(
                icon: const Icon(Icons.format_italic, size: 16),
                color: elem.isItalic ? Colors.blue : null,
                tooltip: 'Italic',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  ref.read(canvasElementsProvider.notifier).updateElement(
                    elem.copyWith(isItalic: !elem.isItalic),
                  );
                },
              ),
              // Font Size (-)
              IconButton(
                icon: const Icon(Icons.remove, size: 14),
                tooltip: 'Decrease font size',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 28),
                onPressed: () {
                  ref.read(canvasElementsProvider.notifier).updateElement(
                    elem.copyWith(fontSize: (elem.fontSize - 2).clamp(10.0, 72.0)),
                  );
                },
              ),
              Text(
                '${elem.fontSize.toInt()}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              // Font Size (+)
              IconButton(
                icon: const Icon(Icons.add, size: 14),
                tooltip: 'Increase font size',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 28),
                onPressed: () {
                  ref.read(canvasElementsProvider.notifier).updateElement(
                    elem.copyWith(fontSize: (elem.fontSize + 2).clamp(10.0, 72.0)),
                  );
                },
              ),
              const VerticalDivider(width: 8, thickness: 1),
            ],

            if (elem.type == CanvasElementType.stickyNote) ...[
              // Color swatches: Yellow, Pink, Blue, Green
              _buildColorDot(const Color(0xFFFEF08A), '#FEF08A', elem),
              _buildColorDot(const Color(0xFFFBCFE8), '#FBCFE8', elem),
              _buildColorDot(const Color(0xFFBAE6FD), '#BAE6FD', elem),
              _buildColorDot(const Color(0xFFBBF7D0), '#BBF7D0', elem),
              const VerticalDivider(width: 8, thickness: 1),
            ],

            if (elem.type == CanvasElementType.image) ...[
              // Lock to Background
              IconButton(
                icon: Icon(
                  elem.isLocked ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: elem.isLocked ? Colors.amber : null,
                ),
                tooltip: elem.isLocked ? 'Unlock Image' : 'Lock to Background',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  ref.read(canvasElementsProvider.notifier).updateElement(
                    elem.copyWith(isLocked: !elem.isLocked),
                  );
                },
              ),
              const VerticalDivider(width: 8, thickness: 1),
            ],

            if (elem.type == CanvasElementType.mathFormula) ...[
              // Re-edit formula
              IconButton(
                icon: const Icon(Icons.edit, size: 16),
                tooltip: 'Edit Equation',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () async {
                  final newFormula = await MathFormulaDialog.show(
                    context,
                    initialFormula: elem.content,
                  );
                  if (newFormula != null && mounted) {
                    ref.read(canvasElementsProvider.notifier).updateElement(
                      elem.copyWith(content: newFormula),
                    );
                  }
                },
              ),
              const VerticalDivider(width: 8, thickness: 1),
            ],

            // Duplicate Action
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Duplicate',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                ref.read(canvasElementsProvider.notifier).duplicateElement(elem.pageId, elem.id);
              },
            ),

            // Delete Action
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                ref.read(canvasElementsProvider.notifier).deleteElement(elem.pageId, elem.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color, String hex, CanvasElement elem) {
    final isSelected = elem.colorHex.toUpperCase() == hex.toUpperCase();
    return GestureDetector(
      onTap: () {
        ref.read(canvasElementsProvider.notifier).updateElement(elem.copyWith(colorHex: hex));
      },
      child: Container(
        width: 16,
        height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black87 : Colors.black26,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

