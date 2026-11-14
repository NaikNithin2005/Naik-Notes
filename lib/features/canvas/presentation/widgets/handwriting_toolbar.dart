import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';

/// Top floating or docked toolbar for handwriting tool selection, ink color palettes,
/// stroke width adjustment, undo/redo history, and stylus settings.
class HandwritingToolbar extends ConsumerWidget {
  final String pageId;

  const HandwritingToolbar({super.key, required this.pageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final activeColor = ref.watch(strokeColorProvider);
    final activeWidth = ref.watch(strokeWidthProvider);
    final canUndo = ref.watch(canUndoProvider(pageId));
    final canRedo = ref.watch(canRedoProvider(pageId));
    final palmRejection = ref.watch(palmRejectionEnabledProvider);

    final isHighlighter = activeTool == ToolType.highlighter;
    final colorPalette = isHighlighter
        ? PenColors.highlighterPalette
        : PenColors.penPalette;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant
                .withValues(alpha: 0.5),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Tool Selection Group
              _buildToolButton(
                ref: ref,
                tool: ToolType.fountainPen,
                activeTool: activeTool,
                icon: Icons.edit,
                tooltip: 'Fountain Pen (Calligraphic)',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.ballpointPen,
                activeTool: activeTool,
                icon: Icons.border_color,
                tooltip: 'Ballpoint Pen',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.pencil,
                activeTool: activeTool,
                icon: Icons.mode_edit_outline,
                tooltip: 'Pencil',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.brushPen,
                activeTool: activeTool,
                icon: Icons.brush,
                tooltip: 'Brush Pen',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.highlighter,
                activeTool: activeTool,
                icon: Icons.highlight,
                tooltip: 'Highlighter',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.eraser,
                activeTool: activeTool,
                icon: Icons.cleaning_services_outlined,
                tooltip: 'Eraser',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.lasso,
                activeTool: activeTool,
                icon: Icons.gesture,
                tooltip: 'Lasso Select & Move',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.shape,
                activeTool: activeTool,
                icon: Icons.crop_square,
                tooltip: 'Shape Detection',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.laserPointer,
                activeTool: activeTool,
                icon: Icons.flare,
                tooltip: 'Laser Pointer',
              ),
              _buildToolButton(
                ref: ref,
                tool: ToolType.pan,
                activeTool: activeTool,
                icon: Icons.pan_tool_outlined,
                tooltip: 'Pan & Scroll Mode',
              ),

              const SizedBox(width: 8),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 16, thickness: 1),
              ),

              // 2. Color Palette Selection (Visible for pen, pencil, brush, highlighter)
              if (activeTool != ToolType.eraser &&
                  activeTool != ToolType.lasso &&
                  activeTool != ToolType.pan) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: colorPalette.map((color) {
                    final isSelected = activeColor.value == color.value;
                    return InkWell(
                      onTap: () {
                        ref.read(strokeColorProvider.notifier).setColor(color);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.4),
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(width: 8),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(width: 16, thickness: 1),
                ),

                // 3. Stroke Width Presets
                _buildWidthChip(
                  ref: ref,
                  label: 'Fine',
                  width: isHighlighter ? 10.0 : 1.5,
                  isActive:
                      (activeWidth - (isHighlighter ? 10.0 : 1.5)).abs() < 0.5,
                ),
                _buildWidthChip(
                  ref: ref,
                  label: 'Med',
                  width: isHighlighter ? 16.0 : 3.0,
                  isActive:
                      (activeWidth - (isHighlighter ? 16.0 : 3.0)).abs() < 0.5,
                ),
                _buildWidthChip(
                  ref: ref,
                  label: 'Bold',
                  width: isHighlighter ? 24.0 : 5.0,
                  isActive:
                      (activeWidth - (isHighlighter ? 24.0 : 5.0)).abs() < 0.5,
                ),

                const SizedBox(width: 8),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(width: 16, thickness: 1),
                ),
              ],

              // 4. Undo and Redo History
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

              // 5. Clear Page Strokes
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                tooltip: 'Clear Page Ink',
                onPressed: () {
                  _showClearConfirmation(context, ref);
                },
              ),

              // 6. Palm Rejection Toggle
              IconButton(
                icon: Icon(
                  palmRejection ? Icons.pan_tool_alt : Icons.pan_tool_outlined,
                  size: 20,
                  color: palmRejection
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: palmRejection
                    ? 'Palm Rejection: ON'
                    : 'Palm Rejection: OFF',
                onPressed: () {
                  ref.read(palmRejectionEnabledProvider.notifier).toggle();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
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
            ref.read(activeToolProvider.notifier).setTool(tool);
            ref.read(strokeWidthProvider.notifier).setWidth(tool.defaultWidth);
            ref
                .read(strokeOpacityProvider.notifier)
                .setOpacity(tool.defaultOpacity);
            if (tool == ToolType.highlighter) {
              ref
                  .read(strokeColorProvider.notifier)
                  .setColor(PenColors.highlighterYellow);
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

  Widget _buildWidthChip({
    required WidgetRef ref,
    required String label,
    required double width,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () {
          ref.read(strokeWidthProvider.notifier).setWidth(width);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0x1F0284C7) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF0284C7)
                  : Colors.grey.withValues(alpha: 0.3),
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? const Color(0xFF0284C7) : null,
            ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Page Ink?'),
        content: const Text(
          'This will erase all handwriting strokes on the current page. You can undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(strokesNotifierProvider.notifier).clearPage(pageId);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
