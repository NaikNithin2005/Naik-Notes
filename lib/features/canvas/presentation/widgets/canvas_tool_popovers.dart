import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/shape_model.dart';
import '../../../../data/models/stroke_model.dart';
import '../../data/stroke_provider.dart';

/// Compact anchored popover dialogs for the 2nd tap progressive disclosure on tools.
class CanvasToolPopovers {
  static const List<Color> palette = [
    Color(0xFF0F172A), // Pure Black / Slate 900
    Color(0xFF1E293B), // Slate 800
    Color(0xFF2563EB), // Royal Blue
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF059669), // Emerald
    Color(0xFFDC2626), // Crimson Red
    Color(0xFFD97706), // Amber
    Color(0xFF7C3AED), // Violet
    Color(0xFF78350F), // Sepia Brown
    Color(0xFFFFFFFF), // White (for dark mode)
  ];

  static const List<double> penSizes = [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, 6.0, 8.0, 12.0, 20.0];

  /// Opens the Pen Customizer Popover
  static void showPenPopover(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          alignment: Alignment.topCenter,
          child: _PenPopoverContent(),
        );
      },
    );
  }

  /// Opens the Highlighter Customizer Popover
  static void showHighlighterPopover(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          alignment: Alignment.topCenter,
          child: _HighlighterPopoverContent(),
        );
      },
    );
  }

  /// Opens the Eraser Customizer Popover
  static void showEraserPopover(BuildContext context, WidgetRef ref, {required String pageId}) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          alignment: Alignment.topCenter,
          child: _EraserPopoverContent(pageId: pageId),
        );
      },
    );
  }

  /// Opens the Shapes Customizer Popover
  static void showShapesPopover(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          alignment: Alignment.topCenter,
          child: _ShapesPopoverContent(),
        );
      },
    );
  }

  /// Opens the Insert (+) Popover
  static void showInsertPopover(
    BuildContext context, {
    required VoidCallback onAddSticky,
    required VoidCallback onImportImage,
    VoidCallback? onTakePhoto,
    required VoidCallback onInsertMath,
    required VoidCallback onToggleLaser,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          alignment: Alignment.topCenter,
          child: _InsertPopoverContent(
            onAddSticky: onAddSticky,
            onImportImage: onImportImage,
            onTakePhoto: onTakePhoto,
            onInsertMath: onInsertMath,
            onToggleLaser: onToggleLaser,
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// PEN POPOVER CONTENT
// ---------------------------------------------------------------------------
class _PenPopoverContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(activeToolProvider);
    final activeColor = ref.watch(strokeColorProvider);
    final activeWidth = ref.watch(strokeWidthProvider);
    final isPressure = ref.watch(pressureSensitivityEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 340,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF01E1E22) : const Color(0xF8FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x2AFFFFFF) : const Color(0x18000000),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pen Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pen Variant Switcher
          const Text('Pen Type', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Row(
            children: [
              _buildTypeChip(
                context,
                ref,
                title: 'Ballpoint',
                tool: ToolType.ballpointPen,
                activeTool: activeTool,
              ),
              const SizedBox(width: 6),
              _buildTypeChip(
                context,
                ref,
                title: 'Fountain',
                tool: ToolType.fountainPen,
                activeTool: activeTool,
              ),
              const SizedBox(width: 6),
              _buildTypeChip(
                context,
                ref,
                title: 'Brush',
                tool: ToolType.brushPen,
                activeTool: activeTool,
              ),
              const SizedBox(width: 6),
              _buildTypeChip(
                context,
                ref,
                title: 'Pencil',
                tool: ToolType.pencil,
                activeTool: activeTool,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Thickness Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Thickness', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                '${activeWidth.toStringAsFixed(1)} pt',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: activeWidth.clamp(0.5, 20.0),
              min: 0.5,
              max: 20.0,
              divisions: 39,
              onChanged: (val) => ref.read(strokeWidthProvider.notifier).setWidth(val),
            ),
          ),
          const SizedBox(height: 10),

          // Color Swatches
          const Text('Color Palette', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CanvasToolPopovers.palette.map((c) {
              final isSelected = c.value == activeColor.value;
              return GestureDetector(
                onTap: () => ref.read(strokeColorProvider.notifier).setColor(c),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.4),
                      width: isSelected ? 2.5 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6)]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: ThemeData.estimateBrightnessForColor(c) == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Pressure Sensitivity Toggle
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Pressure Sensitivity', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Dynamic stroke width based on stylus pressure', style: TextStyle(fontSize: 11)),
            value: isPressure,
            onChanged: (val) => ref.read(pressureSensitivityEnabledProvider.notifier).setEnabled(val),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required ToolType tool,
    required ToolType activeTool,
  }) {
    final isSelected = activeTool == tool;
    final primary = Theme.of(context).colorScheme.primary;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(activeToolProvider.notifier).setTool(tool),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primary : Colors.grey.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? primary : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HIGHLIGHTER POPOVER CONTENT
// ---------------------------------------------------------------------------
class _HighlighterPopoverContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeColor = ref.watch(strokeColorProvider);
    final activeWidth = ref.watch(strokeWidthProvider);
    final activeOpacity = ref.watch(strokeOpacityProvider);
    final isSnapping = ref.watch(snappingEnabledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final highlightColors = [
      const Color(0xFFFDE047), // Yellow
      const Color(0xFF86EFAC), // Green
      const Color(0xFF93C5FD), // Light Blue
      const Color(0xFFFCA5A5), // Coral Pink
      const Color(0xFFD8B4FE), // Lavender
      const Color(0xFFFDBA74), // Orange
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF01E1E22) : const Color(0xF8FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x2AFFFFFF) : const Color(0x18000000),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Highlighter Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Color Swatches
          const Text('Highlighter Color', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: highlightColors.map((c) {
              final isSelected = c.value == activeColor.value;
              return GestureDetector(
                onTap: () {
                  ref.read(strokeColorProvider.notifier).setColor(c);
                  ref.read(activeToolProvider.notifier).setTool(ToolType.highlighter);
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black87 : Colors.grey.withValues(alpha: 0.3),
                      width: isSelected ? 3.0 : 1.0,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.black87)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Width Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Width', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${activeWidth.toStringAsFixed(0)} pt',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 4),
            child: Slider(
              value: activeWidth.clamp(8.0, 36.0),
              min: 8.0,
              max: 36.0,
              divisions: 28,
              onChanged: (val) => ref.read(strokeWidthProvider.notifier).setWidth(val),
            ),
          ),

          // Opacity Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Opacity', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${(activeOpacity * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 3),
            child: Slider(
              value: activeOpacity.clamp(0.1, 0.8),
              min: 0.1,
              max: 0.8,
              divisions: 14,
              onChanged: (val) => ref.read(strokeOpacityProvider.notifier).setOpacity(val),
            ),
          ),
          const SizedBox(height: 8),

          // Auto-Straighten Toggle
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-Straighten', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Snap hand-drawn highlights to straight ruler lines',
                style: TextStyle(fontSize: 11)),
            value: isSnapping,
            onChanged: (val) => ref.read(snappingEnabledProvider.notifier).setEnabled(val),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ERASER POPOVER CONTENT
// ---------------------------------------------------------------------------
class _EraserPopoverContent extends ConsumerWidget {
  final String pageId;

  const _EraserPopoverContent({required this.pageId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eraserMode = ref.watch(eraserModeProvider);
    final eraserRadius = ref.watch(eraserRadiusProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF01E1E22) : const Color(0xF8FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x2AFFFFFF) : const Color(0x18000000),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Eraser Settings',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Eraser Mode (Stroke vs. Precision)
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Stroke Eraser'),
                  selected: eraserMode == EraserMode.stroke,
                  onSelected: (val) {
                    if (val) ref.read(eraserModeProvider.notifier).setMode(EraserMode.stroke);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Precision'),
                  selected: eraserMode == EraserMode.partial,
                  onSelected: (val) {
                    if (val) ref.read(eraserModeProvider.notifier).setMode(EraserMode.partial);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Size Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Eraser Radius', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('${eraserRadius.toStringAsFixed(0)} pt',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 3),
            child: Slider(
              value: eraserRadius.clamp(5.0, 80.0),
              min: 5.0,
              max: 80.0,
              divisions: 15,
              onChanged: (val) => ref.read(eraserRadiusProvider.notifier).setRadius(val),
            ),
          ),
          const SizedBox(height: 12),

          // Clear Page Action with Confirmation
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 18),
              label: const Text('Clear All Strokes on Page', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Page?'),
                    content: const Text('This will delete all ink strokes on this page. You can undo this action.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear Page'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(strokesNotifierProvider.notifier).clearPage(pageId);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHAPES POPOVER CONTENT
// ---------------------------------------------------------------------------
class _ShapesPopoverContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedShape = ref.watch(selectedShapeTypeProvider);
    final isSnapping = ref.watch(snappingEnabledProvider);
    final isFilled = ref.watch(shapeIsFilledProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shapes = [
      (ShapeType.straightLine, Icons.horizontal_rule_rounded, 'Line'),
      (ShapeType.arrow, Icons.arrow_right_alt_rounded, 'Arrow'),
      (ShapeType.rectangle, Icons.crop_square_rounded, 'Rectangle'),
      (ShapeType.circle, Icons.circle_outlined, 'Circle / Ellipse'),
      (ShapeType.triangle, Icons.change_history_rounded, 'Triangle'),
      (ShapeType.star, Icons.star_border_rounded, 'Star'),
    ];

    return Container(
      width: 320,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF01E1E22) : const Color(0xF8FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x2AFFFFFF) : const Color(0x18000000),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Geometric Shapes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Shape Grid
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: shapes.map((s) {
              final isSel = selectedShape == s.$1;
              return InkWell(
                onTap: () {
                  ref.read(selectedShapeTypeProvider.notifier).setShapeType(s.$1);
                  ref.read(activeToolProvider.notifier).setTool(ToolType.shape);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSel
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSel
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withValues(alpha: 0.25),
                      width: isSel ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(s.$2, size: 24, color: isSel ? Theme.of(context).colorScheme.primary : null),
                      const SizedBox(height: 4),
                      Text(
                        s.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? Theme.of(context).colorScheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Fill Toggle
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Fill Shape', style: TextStyle(fontSize: 13)),
            value: isFilled,
            onChanged: (val) => ref.read(shapeIsFilledProvider.notifier).setFilled(val),
          ),

          // Auto-Snap Toggle
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Draw & Hold Auto-Snap', style: TextStyle(fontSize: 13)),
            subtitle: const Text('Snap hand-drawn loops to perfect shapes on hold', style: TextStyle(fontSize: 11)),
            value: isSnapping,
            onChanged: (val) => ref.read(snappingEnabledProvider.notifier).setEnabled(val),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// INSERT (+) POPOVER CONTENT
// ---------------------------------------------------------------------------
class _InsertPopoverContent extends StatelessWidget {
  final VoidCallback onAddSticky;
  final VoidCallback onImportImage;
  final VoidCallback? onTakePhoto;
  final VoidCallback onInsertMath;
  final VoidCallback onToggleLaser;

  const _InsertPopoverContent({
    required this.onAddSticky,
    required this.onImportImage,
    this.onTakePhoto,
    required this.onInsertMath,
    required this.onToggleLaser,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF01E1E22) : const Color(0xF8FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0x2AFFFFFF) : const Color(0x18000000),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 28, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.note_add_outlined),
            title: const Text('Sticky Note', style: TextStyle(fontSize: 14)),
            onTap: () {
              Navigator.of(context).pop();
              onAddSticky();
            },
          ),
          ListTile(
            leading: const Icon(Icons.image_outlined),
            title: const Text('Import Image', style: TextStyle(fontSize: 14)),
            onTap: () {
              Navigator.of(context).pop();
              onImportImage();
            },
          ),
          if (Platform.isAndroid || Platform.isIOS || onTakePhoto != null)
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.of(context).pop();
                onTakePhoto?.call();
              },
            ),
          ListTile(
            leading: const Icon(Icons.functions_rounded),
            title: const Text('Math / LaTeX Formula', style: TextStyle(fontSize: 14)),
            onTap: () {
              Navigator.of(context).pop();
              onInsertMath();
            },
          ),
          ListTile(
            leading: const Icon(Icons.highlight_alt_rounded),
            title: const Text('Laser Pointer', style: TextStyle(fontSize: 14)),
            onTap: () {
              Navigator.of(context).pop();
              onToggleLaser();
            },
          ),
        ],
      ),
    );
  }
}

