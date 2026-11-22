import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/attachment_model.dart';
import '../../../../data/models/stroke_model.dart';
import '../../../authentication/data/auth_provider.dart';
import '../../../storage/data/google_drive_provider.dart';

/// Interactive sketching canvas modal supporting Apple Pencil, active styluses,
/// and finger drawing with pen, pencil, highlighter, eraser, undo/redo, and PNG export.
class SketchCanvasDialog extends ConsumerStatefulWidget {
  final String noteId;

  const SketchCanvasDialog({
    super.key,
    required this.noteId,
  });

  /// Opens the sketch dialog and returns the created [NoteAttachment] on completion.
  static Future<NoteAttachment?> show(BuildContext context, String noteId) {
    return showDialog<NoteAttachment?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SketchCanvasDialog(noteId: noteId),
    );
  }

  @override
  ConsumerState<SketchCanvasDialog> createState() => _SketchCanvasDialogState();
}

class _SketchCanvasDialogState extends ConsumerState<SketchCanvasDialog> {
  final List<Stroke> _strokes = [];
  final List<Stroke> _undoStack = [];
  Stroke? _currentStroke;

  ToolType _activeTool = ToolType.ballpointPen;
  Color _activeColor = const Color(0xFF1E293B); // Charcoal Slate
  double _strokeWidth = 3.0;
  bool _isSaving = false;

  final GlobalKey _canvasKey = GlobalKey();

  static const List<Color> _palette = [
    Color(0xFF0F172A), // Jet Black
    Color(0xFF334155), // Slate Gray
    Color(0xFF1D4ED8), // Royal Blue
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF059669), // Emerald Green
    Color(0xFFDC2626), // Crimson Red
    Color(0xFFD97706), // Warm Amber
    Color(0xFF7C3AED), // Deep Purple
    Color(0xFFE11D48), // Rose
  ];

  void _onPointerDown(PointerDownEvent event) {
    final point = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure > 0 ? event.pressure : 0.5,
      tilt: 0.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    if (_activeTool == ToolType.eraser) {
      _eraseAt(event.localPosition);
      return;
    }

    final double effectiveOpacity = _activeTool == ToolType.highlighter ? 0.35 : 1.0;
    final double effectiveWidth = _activeTool == ToolType.highlighter
        ? 18.0
        : (_strokeWidth * (point.pressure > 0 ? (point.pressure * 1.5).clamp(0.5, 2.0) : 1.0));

    final stroke = Stroke(
      id: 'sketch-stroke-${DateTime.now().microsecondsSinceEpoch}',
      pageId: widget.noteId,
      tool: _activeTool,
      colorValue: _activeColor.toARGB32(),
      width: effectiveWidth,
      opacity: effectiveOpacity,
      points: [point],
      createdAt: DateTime.now(),
    );

    setState(() {
      _currentStroke = stroke;
      _undoStack.clear();
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_activeTool == ToolType.eraser) {
      _eraseAt(event.localPosition);
      return;
    }

    if (_currentStroke == null) return;

    final point = StrokePoint(
      x: event.localPosition.dx,
      y: event.localPosition.dy,
      pressure: event.pressure > 0 ? event.pressure : 0.5,
      tilt: 0.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    setState(() {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, point],
      );
    });
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_currentStroke != null) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
      });
    }
  }

  void _eraseAt(Offset position) {
    const eraserRadius = 24.0;
    setState(() {
      _strokes.removeWhere((stroke) {
        return stroke.points.any((pt) => (pt.offset - position).distance < eraserRadius);
      });
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _undoStack.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_undoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_undoStack.removeLast());
      });
    }
  }

  void _clearCanvas() {
    if (_strokes.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Sketch?'),
        content: const Text('Are you sure you want to discard all drawn strokes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _strokes.clear();
                _undoStack.clear();
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAndSave() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot save an empty sketch.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final size = renderBox?.size ?? const Size(800, 600);

      // Render strokes onto offscreen picture recorder
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

      // White stationery background
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

      // Draw all strokes
      final painter = _SketchPainter(strokes: _strokes, activeStroke: null);
      painter.paint(canvas, size);

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Failed to encode sketch as PNG.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final auth = ref.read(authProvider);
      final uid = auth.user?.id ?? 'local_user';
      final fileName = 'sketch_${DateTime.now().millisecondsSinceEpoch}.png';

      final coordinator = ref.read(attachmentSyncCoordinatorProvider);
      final attachment = await coordinator.addAttachmentFromBytes(
        uid: uid,
        noteId: widget.noteId,
        bytes: pngBytes,
        fileName: fileName,
        mimeType: 'image/png',
        isSketch: true,
      );

      if (mounted) {
        Navigator.of(context).pop(attachment);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save sketch: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 900,
          height: 680,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          child: Column(
            children: [
              // Header Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.draw_rounded, color: Colors.blueAccent),
                      const SizedBox(width: 8),
                      const Text(
                        'Sketch & Apple Pencil',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 24),
                      // Undo
                      IconButton(
                        icon: const Icon(Icons.undo_rounded),
                        tooltip: 'Undo',
                        onPressed: _strokes.isNotEmpty ? _undo : null,
                      ),
                      // Redo
                      IconButton(
                        icon: const Icon(Icons.redo_rounded),
                        tooltip: 'Redo',
                        onPressed: _undoStack.isNotEmpty ? _redo : null,
                      ),
                      // Clear
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_rounded),
                        tooltip: 'Clear Canvas',
                        color: Colors.redAccent,
                        onPressed: _strokes.isNotEmpty ? _clearCanvas : null,
                      ),
                      const SizedBox(
                        height: 24,
                        child: VerticalDivider(width: 24, thickness: 1),
                      ),
                      // Cancel
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      // Save & Attach
                      FilledButton.icon(
                        onPressed: _isSaving ? null : _exportAndSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isSaving ? 'Saving...' : 'Attach to Note'),
                      ),
                    ],
                  ),
                ),
              ),

              // Tool & Palette Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Pen Tool
                      ChoiceChip(
                        avatar: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('Pen'),
                        selected: _activeTool == ToolType.ballpointPen,
                        onSelected: (val) {
                          if (val) setState(() => _activeTool = ToolType.ballpointPen);
                        },
                      ),
                      const SizedBox(width: 6),
                      // Pencil Tool
                      ChoiceChip(
                        avatar: const Icon(Icons.create_rounded, size: 16),
                        label: const Text('Pencil'),
                        selected: _activeTool == ToolType.pencil,
                        onSelected: (val) {
                          if (val) setState(() => _activeTool = ToolType.pencil);
                        },
                      ),
                      const SizedBox(width: 6),
                      // Highlighter Tool
                      ChoiceChip(
                        avatar: const Icon(Icons.brush_rounded, size: 16),
                        label: const Text('Highlighter'),
                        selected: _activeTool == ToolType.highlighter,
                        onSelected: (val) {
                          if (val) setState(() => _activeTool = ToolType.highlighter);
                        },
                      ),
                      const SizedBox(width: 6),
                      // Eraser Tool
                      ChoiceChip(
                        avatar: const Icon(Icons.auto_fix_normal_rounded, size: 16),
                        label: const Text('Eraser'),
                        selected: _activeTool == ToolType.eraser,
                        onSelected: (val) {
                          if (val) setState(() => _activeTool = ToolType.eraser);
                        },
                      ),
                      const SizedBox(width: 20),

                      // Thickness selector
                      if (_activeTool != ToolType.eraser) ...[
                        const Text('Thickness: ', style: TextStyle(fontSize: 12)),
                        for (final width in [2.0, 4.0, 6.0, 10.0])
                          InkWell(
                            onTap: () => setState(() => _strokeWidth = width),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _strokeWidth == width
                                    ? Colors.blue.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                border: _strokeWidth == width
                                    ? Border.all(color: Colors.blueAccent, width: 2)
                                    : null,
                              ),
                              child: Container(
                                width: width * 1.8,
                                height: width * 1.8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _activeColor,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 20),

                        // Palette colors
                        const Text('Color: ', style: TextStyle(fontSize: 12)),
                        for (final color in _palette)
                          InkWell(
                            onTap: () => setState(() => _activeColor = color),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: Border.all(
                                  color: _activeColor == color ? Colors.white : Colors.black26,
                                  width: _activeColor == color ? 2.5 : 1,
                                ),
                                boxShadow: _activeColor == color
                                    ? [const BoxShadow(color: Colors.black38, blurRadius: 4)]
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),

              // Drawing Surface
              Expanded(
                child: Container(
                  key: _canvasKey,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white, // Crisp white drawing pad
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Listener(
                      onPointerDown: _onPointerDown,
                      onPointerMove: _onPointerMove,
                      onPointerUp: _onPointerUp,
                      child: CustomPaint(
                        painter: _SketchPainter(
                          strokes: _strokes,
                          activeStroke: _currentStroke,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering vector strokes onto canvas.
class _SketchPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? activeStroke;

  _SketchPainter({
    required this.strokes,
    required this.activeStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (activeStroke != null) {
      _drawStroke(canvas, activeStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = Color(stroke.colorValue).withValues(alpha: stroke.opacity)
      ..strokeWidth = stroke.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (stroke.points.length == 1) {
      canvas.drawCircle(stroke.points.first.offset, stroke.width / 2, paint..style = PaintingStyle.fill);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.x, stroke.points.first.y);

    for (int i = 1; i < stroke.points.length; i++) {
      final p0 = stroke.points[i - 1];
      final p1 = stroke.points[i];
      final mid = Offset((p0.x + p1.x) / 2, (p0.y + p1.y) / 2);
      path.quadraticBezierTo(p0.x, p0.y, mid.dx, mid.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}
