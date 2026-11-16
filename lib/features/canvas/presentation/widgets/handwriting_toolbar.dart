import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/stroke_model.dart';
import '../../data/stroke_provider.dart';
import 'eraser_customizer_sheet.dart';
import 'shape_picker_sheet.dart';
import 'tool_customizer_sheet.dart';

/// Top floating or docked toolbar for handwriting tool selection, in-place tool customization,
/// geometric shapes library, stroke styling, undo/redo history, and stylus controls.
class HandwritingToolbar extends ConsumerWidget {
  final String pageId;

  const HandwritingToolbar({super.key, required this.pageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final activeColor = ref.watch(strokeColorProvider);
    final activeWidth = ref.watch(strokeWidthProvider);
    final activeStyle = ref.watch(strokeStyleProvider);
    final canUndo = ref.watch(canUndoProvider(pageId));
    final canRedo = ref.watch(canRedoProvider(pageId));
    final palmRejection = ref.watch(palmRejectionEnabledProvider);
    final isSnapping = ref.watch(snappingEnabledProvider);

    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface.withValues(alpha: 0.96),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- 1. Writing Tools Group ---
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.fountainPen,
                activeTool: activeTool,
                icon: Icons.edit,
                tooltip: 'Fountain Pen (Calligraphic)',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.ballpointPen,
                activeTool: activeTool,
                icon: Icons.border_color,
                tooltip: 'Ballpoint Pen',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.pencil,
                activeTool: activeTool,
                icon: Icons.mode_edit_outline,
                tooltip: 'Pencil (Textured)',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.brushPen,
                activeTool: activeTool,
                icon: Icons.brush,
                tooltip: 'Brush Pen (Organic)',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.highlighter,
                activeTool: activeTool,
                icon: Icons.highlight,
                tooltip: 'Highlighter',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.marker,
                activeTool: activeTool,
                icon: Icons.draw,
                tooltip: 'Marker (Bold)',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.calligraphyPen,
                activeTool: activeTool,
                icon: Icons.brush_outlined,
                tooltip: 'Calligraphy Pen (45° Chisel)',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.technicalPen,
                activeTool: activeTool,
                icon: Icons.architecture_rounded,
                tooltip: 'Technical Pen (Monoline Precision)',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.customBrush,
                activeTool: activeTool,
                icon: Icons.auto_fix_high_rounded,
                tooltip: 'Custom Artistic Brush',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.fillBucket,
                activeTool: activeTool,
                icon: Icons.format_color_fill_rounded,
                tooltip: 'Fill Bucket (Color Fill)',
              ),

              const SizedBox(width: 4),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 14, thickness: 1),
              ),
              const SizedBox(width: 4),

              // --- 2. Active Tool Quick Customizer Pill ---
              if (activeTool != ToolType.eraser &&
                  activeTool != ToolType.lasso &&
                  activeTool != ToolType.pan)
                Tooltip(
                  message: 'Customize active tool',
                  child: InkWell(
                    onTap: () => _openToolCustomizer(context, ref, activeTool),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Color dot
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: activeColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${activeWidth.toStringAsFixed(1)}pt',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (activeStyle != StrokeStyle.solid) ...[
                            const SizedBox(width: 4),
                            Icon(
                              activeStyle == StrokeStyle.dashed
                                  ? Icons.more_horiz
                                  : Icons.scatter_plot,
                              size: 14,
                            ),
                          ],
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(width: 4),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 14, thickness: 1),
              ),
              const SizedBox(width: 4),

              // --- 3. Geometric Shapes & Snapping Group ---
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.shape,
                activeTool: activeTool,
                icon: Icons.category_outlined,
                tooltip: 'Geometric Shapes Library (27 shapes)',
              ),
              Tooltip(
                message: isSnapping
                    ? 'Shape Snapping: ON'
                    : 'Shape Snapping: OFF',
                child: IconButton(
                  icon: Icon(
                    isSnapping ? Icons.grid_4x4 : Icons.grid_off,
                    size: 20,
                    color: isSnapping ? theme.colorScheme.primary : null,
                  ),
                  onPressed: () {
                    ref.read(snappingEnabledProvider.notifier).toggle();
                  },
                ),
              ),

              const SizedBox(width: 4),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 14, thickness: 1),
              ),
              const SizedBox(width: 4),

              // --- 4. Editing Tools (Eraser & Selection) ---
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.eraser,
                activeTool: activeTool,
                icon: Icons.cleaning_services_outlined,
                tooltip: 'Eraser (Stroke / Partial / Object)',
              ),
              _buildToolButton(
                context: context,
                ref: ref,
                tool: ToolType.lasso,
                activeTool: activeTool,
                icon: Icons.gesture,
                tooltip: 'Selection Tool (Lasso, Move, Rotate, Scale)',
              ),

              const SizedBox(width: 4),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 14, thickness: 1),
              ),
              const SizedBox(width: 4),

              // --- 5. Undo and Redo History ---
              IconButton(
                icon: const Icon(Icons.undo, size: 20),
                tooltip: 'Undo',
                onPressed: canUndo
                    ? () {
                        ref.read(strokesNotifierProvider.notifier).undo(pageId);
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.redo, size: 20),
                tooltip: 'Redo',
                onPressed: canRedo
                    ? () {
                        ref.read(strokesNotifierProvider.notifier).redo(pageId);
                      }
                    : null,
              ),

              const SizedBox(width: 4),

              // --- 6. Clear Page Ink ---
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                tooltip: 'Clear Page Ink',
                onPressed: () => _showClearConfirmation(context, ref),
              ),

              // --- 7. Palm Rejection Toggle ---
              IconButton(
                icon: Icon(
                  palmRejection ? Icons.pan_tool_alt : Icons.pan_tool_outlined,
                  size: 20,
                  color: palmRejection ? theme.colorScheme.primary : null,
                ),
                tooltip: palmRejection
                    ? 'Palm Rejection: ON'
                    : 'Palm Rejection: OFF',
                onPressed: () {
                  ref.read(palmRejectionEnabledProvider.notifier).toggle();
                },
              ),

              // --- 8. Stylus-Only Inking Toggle ---
              Consumer(
                builder: (context, ref, _) {
                  final stylusOnly = ref.watch(stylusOnlyModeProvider);
                  return IconButton(
                    icon: Icon(
                      stylusOnly ? Icons.edit_note : Icons.touch_app,
                      size: 20,
                      color: stylusOnly ? theme.colorScheme.primary : null,
                    ),
                    tooltip: stylusOnly
                        ? 'Stylus-Only Mode: ON (Finger pans)'
                        : 'Stylus-Only Mode: OFF (Finger inks)',
                    onPressed: () {
                      ref.read(stylusOnlyModeProvider.notifier).toggle();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required WidgetRef ref,
    required ToolType tool,
    required ToolType activeTool,
    required IconData icon,
    required String tooltip,
  }) {
    final isSelected = activeTool == tool;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            if (isSelected) {
              _openToolCustomizer(context, ref, tool);
            } else {
              ref.read(activeToolProvider.notifier).setTool(tool);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0x1F0284C7) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF0284C7), width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF0284C7) : null,
            ),
          ),
        ),
      ),
    );
  }

  void _openToolCustomizer(BuildContext context, WidgetRef ref, ToolType tool) {
    if (tool == ToolType.eraser) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const EraserCustomizerSheet(),
      );
    } else if (tool == ToolType.shape) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ShapePickerSheet(),
      );
    } else if (tool != ToolType.lasso &&
        tool != ToolType.pan &&
        tool != ToolType.laserPointer) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ToolCustomizerSheet(tool: tool),
      );
    }
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Ink?'),
        content: const Text(
          'Are you sure you want to clear all handwriting strokes and shapes on this page? This action can be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(strokesNotifierProvider.notifier).clearPage(pageId);
            },
            child: const Text('Clear Ink'),
          ),
        ],
      ),
    );
  }
}
