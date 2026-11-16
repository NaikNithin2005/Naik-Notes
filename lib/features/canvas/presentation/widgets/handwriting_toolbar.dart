import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/stroke_model.dart';
import '../../data/stroke_provider.dart';
import '../../data/toolbar_preferences.dart';
import 'eraser_customizer_sheet.dart';
import 'shape_picker_sheet.dart';
import 'tool_customizer_sheet.dart';
import 'toolbar_customizer_dialog.dart';

/// Top floating or docked toolbar for handwriting tool selection, in-place tool customization,
/// geometric shapes library, stroke styling, undo/redo history, and stylus controls.
/// Supports collapsible primary/secondary tools and WCAG-compliant 48x48 minimum touch targets.
class HandwritingToolbar extends ConsumerStatefulWidget {
  final String pageId;

  const HandwritingToolbar({super.key, required this.pageId});

  @override
  ConsumerState<HandwritingToolbar> createState() => _HandwritingToolbarState();
}

class _HandwritingToolbarState extends ConsumerState<HandwritingToolbar> {
  bool? _manuallyExpanded;

  @override
  Widget build(BuildContext context) {
    final activeTool = ref.watch(activeToolProvider);
    final activeColor = ref.watch(strokeColorProvider);
    final activeWidth = ref.watch(strokeWidthProvider);
    final activeStyle = ref.watch(strokeStyleProvider);
    final canUndo = ref.watch(canUndoProvider(widget.pageId));
    final canRedo = ref.watch(canRedoProvider(widget.pageId));
    final palmRejection = ref.watch(palmRejectionEnabledProvider);
    final isSnapping = ref.watch(snappingEnabledProvider);
    final toolbarPrefs = ref.watch(toolbarPreferencesProvider);

    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Default to expanded on tablet/desktop viewports (>= 800), collapsed on narrow mobile
    final isExpanded = _manuallyExpanded ?? (screenWidth >= 800);
    final isCompact = toolbarPrefs.isCompact;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface.withValues(alpha: 0.96),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              // ========================================================
              // --- 1. PRIMARY WRITING TOOLS ---
              // ========================================================
              if (toolbarPrefs.isToolVisible('fountainPen'))
                _buildToolButton(
                  context: context,
                  tool: ToolType.fountainPen,
                  activeTool: activeTool,
                  icon: Icons.edit,
                  tooltip: 'Fountain Pen (Calligraphic)',
                  isCompact: isCompact,
                ),
              if (toolbarPrefs.isToolVisible('ballpointPen'))
                _buildToolButton(
                  context: context,
                  tool: ToolType.ballpointPen,
                  activeTool: activeTool,
                  icon: Icons.border_color,
                  tooltip: 'Ballpoint Pen',
                  isCompact: isCompact,
                ),
              if (toolbarPrefs.isToolVisible('pencil'))
                _buildToolButton(
                  context: context,
                  tool: ToolType.pencil,
                  activeTool: activeTool,
                  icon: Icons.mode_edit_outline,
                  tooltip: 'Pencil (Textured)',
                  isCompact: isCompact,
                ),
              if (toolbarPrefs.isToolVisible('brushPen'))
                _buildToolButton(
                  context: context,
                  tool: ToolType.brushPen,
                  activeTool: activeTool,
                  icon: Icons.brush,
                  tooltip: 'Brush Pen (Organic)',
                  isCompact: isCompact,
                ),
              if (toolbarPrefs.isToolVisible('highlighter'))
                _buildToolButton(
                  context: context,
                  tool: ToolType.highlighter,
                  activeTool: activeTool,
                  icon: Icons.highlight,
                  tooltip: 'Highlighter',
                  isCompact: isCompact,
                ),

              const SizedBox(width: 2),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 10, thickness: 1),
              ),
              const SizedBox(width: 2),

              // ========================================================
              // --- 2. PRIMARY QUICK STYLE CUSTOMIZER PILL ---
              // ========================================================
              if (toolbarPrefs.isToolVisible('styleCustomizer') &&
                  activeTool != ToolType.eraser &&
                  activeTool != ToolType.lasso &&
                  activeTool != ToolType.pan)
                Tooltip(
                  message: 'Customize active tool',
                  child: InkWell(
                    onTap: () => _openToolCustomizer(context, activeTool),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Swatch dot
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
                ),

              const SizedBox(width: 2),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 10, thickness: 1),
              ),
              const SizedBox(width: 2),

              // ========================================================
              // --- 3. PRIMARY EDITING TOOLS (Eraser & Lasso) ---
              // ========================================================
              if (toolbarPrefs.isToolVisible('eraser'))
                _buildToolButton(
                  context: context,
                  tool: ToolType.eraser,
                  activeTool: activeTool,
                  icon: Icons.cleaning_services_outlined,
                  tooltip: 'Eraser (Stroke / Partial / Object)',
                  isCompact: isCompact,
                ),
              if (toolbarPrefs.isToolVisible('lasso'))
                _buildToolButton(
                  context: context,
                  tool: ToolType.lasso,
                  activeTool: activeTool,
                  icon: Icons.gesture,
                  tooltip: 'Selection Tool (Lasso, Move, Rotate, Scale)',
                  isCompact: isCompact,
                ),

              const SizedBox(width: 2),
              const SizedBox(
                height: 28,
                child: VerticalDivider(width: 10, thickness: 1),
              ),
              const SizedBox(width: 2),

              // ========================================================
              // --- 4. PRIMARY UNDO & REDO HISTORY ---
              // ========================================================
              if (toolbarPrefs.isToolVisible('undoRedo')) ...[
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.undo, size: 20),
                  tooltip: 'Undo',
                  onPressed: canUndo
                      ? () => ref
                            .read(strokesNotifierProvider.notifier)
                            .undo(widget.pageId)
                      : null,
                ),
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.redo, size: 20),
                  tooltip: 'Redo',
                  onPressed: canRedo
                      ? () => ref
                            .read(strokesNotifierProvider.notifier)
                            .redo(widget.pageId)
                      : null,
                ),
              ],

              // ========================================================
              // --- 5. COLLAPSIBLE TOGGLE PILL FOR SECONDARY TOOLS ---
              // ========================================================
              Tooltip(
                message: isExpanded
                    ? 'Hide secondary tools'
                    : 'Show extra tools (Shapes, Fill, Palm Rejection)',
                child: InkWell(
                  onTap: () => setState(() => _manuallyExpanded = !isExpanded),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isExpanded
                            ? theme.colorScheme.primaryContainer.withValues(
                                alpha: 0.6,
                              )
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isExpanded
                              ? theme.colorScheme.primary.withValues(alpha: 0.4)
                              : theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.4,
                                ),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpanded
                                ? Icons.chevron_left_rounded
                                : Icons.more_horiz_rounded,
                            size: 18,
                            color: isExpanded
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isExpanded ? 'Less' : 'More',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isExpanded
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ========================================================
              // --- 6. SECONDARY TOOLS GROUP (Shown when Expanded) ---
              // ========================================================
              if (isExpanded) ...[
                const SizedBox(width: 2),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(width: 10, thickness: 1),
                ),
                const SizedBox(width: 2),

                // Secondary Writing Tools
                if (toolbarPrefs.isToolVisible('marker'))
                  _buildToolButton(
                    context: context,
                    tool: ToolType.marker,
                    activeTool: activeTool,
                    icon: Icons.draw,
                    tooltip: 'Marker (Bold)',
                    isCompact: isCompact,
                  ),
                if (toolbarPrefs.isToolVisible('calligraphyPen'))
                  _buildToolButton(
                    context: context,
                    tool: ToolType.calligraphyPen,
                    activeTool: activeTool,
                    icon: Icons.brush_outlined,
                    tooltip: 'Calligraphy Pen (45° Chisel)',
                    isCompact: isCompact,
                  ),
                if (toolbarPrefs.isToolVisible('technicalPen'))
                  _buildToolButton(
                    context: context,
                    tool: ToolType.technicalPen,
                    activeTool: activeTool,
                    icon: Icons.architecture_rounded,
                    tooltip: 'Technical Pen (Monoline Precision)',
                    isCompact: isCompact,
                  ),
                if (toolbarPrefs.isToolVisible('customBrush'))
                  _buildToolButton(
                    context: context,
                    tool: ToolType.customBrush,
                    activeTool: activeTool,
                    icon: Icons.auto_fix_high_rounded,
                    tooltip: 'Custom Artistic Brush',
                    isCompact: isCompact,
                  ),
                if (toolbarPrefs.isToolVisible('fillBucket'))
                  _buildToolButton(
                    context: context,
                    tool: ToolType.fillBucket,
                    activeTool: activeTool,
                    icon: Icons.format_color_fill_rounded,
                    tooltip: 'Fill Bucket (Color Fill)',
                    isCompact: isCompact,
                  ),

                const SizedBox(width: 2),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(width: 10, thickness: 1),
                ),
                const SizedBox(width: 2),

                // Geometric Shapes & Snapping
                if (toolbarPrefs.isToolVisible('shape'))
                  _buildToolButton(
                    context: context,
                    tool: ToolType.shape,
                    activeTool: activeTool,
                    icon: Icons.category_outlined,
                    tooltip: 'Geometric Shapes Library (27 shapes)',
                    isCompact: isCompact,
                  ),
                if (toolbarPrefs.isToolVisible('snapping'))
                  Tooltip(
                    message: isSnapping
                        ? 'Shape Snapping: ON'
                        : 'Shape Snapping: OFF',
                    child: IconButton(
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
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

                const SizedBox(width: 2),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(width: 10, thickness: 1),
                ),
                const SizedBox(width: 2),

                // Clear Page Ink
                if (toolbarPrefs.isToolVisible('clearPage'))
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                    tooltip: 'Clear Page Ink',
                    onPressed: () => _showClearConfirmation(context),
                  ),

                // Palm Rejection Toggle
                if (toolbarPrefs.isToolVisible('palmRejection'))
                  IconButton(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    icon: Icon(
                      palmRejection
                          ? Icons.pan_tool_alt
                          : Icons.pan_tool_outlined,
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

                // Stylus-Only Inking Toggle
                if (toolbarPrefs.isToolVisible('stylusOnly'))
                  Consumer(
                    builder: (context, ref, _) {
                      final stylusOnly = ref.watch(stylusOnlyModeProvider);
                      return IconButton(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
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

                const SizedBox(width: 2),
                const SizedBox(
                  height: 28,
                  child: VerticalDivider(width: 10, thickness: 1),
                ),
                const SizedBox(width: 2),

                // Toolbar Customization Shortcut
                IconButton(
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 20,
                  ),
                  tooltip: 'Customize Toolbar (Tools, Position, Layout)',
                  onPressed: () => ToolbarCustomizerDialog.show(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required ToolType tool,
    required ToolType activeTool,
    required IconData icon,
    required String tooltip,
    bool isCompact = false,
  }) {
    final isSelected = activeTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          if (isSelected) {
            _openToolCustomizer(context, tool);
          } else {
            ref.read(activeToolProvider.notifier).setTool(tool);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 4),
          child: Container(
            padding: EdgeInsets.all(isCompact ? 6 : 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0x1F0284C7) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFF0284C7), width: 1.5)
                  : null,
            ),
            child: Icon(
              icon,
              size: isCompact ? 18 : 20,
              color: isSelected ? const Color(0xFF0284C7) : null,
            ),
          ),
        ),
      ),
    );
  }

  void _openToolCustomizer(BuildContext context, ToolType tool) {
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

  void _showClearConfirmation(BuildContext context) {
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
              ref
                  .read(strokesNotifierProvider.notifier)
                  .clearPage(widget.pageId);
            },
            child: const Text('Clear Ink'),
          ),
        ],
      ),
    );
  }
}
