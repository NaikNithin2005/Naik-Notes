import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/stroke_model.dart';
import '../../data/stroke_provider.dart';
import 'canvas_floating_pill.dart';
import 'canvas_tool_popovers.dart';

/// Clean, canvas-first floating glassmorphic toolbar for handwriting and inking.
/// Dedicates ~90% of screen to the writing surface by consolidating redundant controls.
/// Supports responsive breakpoints (Desktop >= 1024px, Tablet 600-1023px, Phone < 600px).
class CanvasMinimalToolbar extends ConsumerStatefulWidget {
  final String pageId;
  final VoidCallback onAddStickyNote;
  final VoidCallback onImportImage;
  final VoidCallback? onTakePhoto;
  final VoidCallback? onInsertMath;

  const CanvasMinimalToolbar({
    super.key,
    required this.pageId,
    required this.onAddStickyNote,
    required this.onImportImage,
    this.onTakePhoto,
    this.onInsertMath,
  });

  @override
  ConsumerState<CanvasMinimalToolbar> createState() => _CanvasMinimalToolbarState();
}

class _CanvasMinimalToolbarState extends ConsumerState<CanvasMinimalToolbar> {
  // Pinned quick-switch swatches for Desktop/Tablet
  static const List<Color> _pinnedColors = [
    Color(0xFF0F172A), // Slate / Black
    Color(0xFF2563EB), // Blue
    Color(0xFFDC2626), // Red
  ];

  static const List<double> _pinnedSizes = [
    1.5,
    3.0,
    6.0,
  ];

  void _handleToolTap(ToolType tool, ToolType activeTool) {
    if (activeTool == tool) {
      // 2nd Tap: Open anchored settings popover
      switch (tool) {
        case ToolType.ballpointPen:
        case ToolType.fountainPen:
        case ToolType.brushPen:
        case ToolType.pencil:
          CanvasToolPopovers.showPenPopover(context, ref);
          break;
        case ToolType.highlighter:
          CanvasToolPopovers.showHighlighterPopover(context, ref);
          break;
        case ToolType.eraser:
          CanvasToolPopovers.showEraserPopover(context, ref, pageId: widget.pageId);
          break;
        case ToolType.shape:
          CanvasToolPopovers.showShapesPopover(context, ref);
          break;
        default:
          break;
      }
    } else {
      // 1st Tap: Activate tool immediately
      ref.read(activeToolProvider.notifier).setTool(tool);
    }
  }

  bool _isPenTool(ToolType t) {
    return t == ToolType.ballpointPen ||
        t == ToolType.fountainPen ||
        t == ToolType.brushPen ||
        t == ToolType.pencil;
  }

  @override
  Widget build(BuildContext context) {
    final activeTool = ref.watch(activeToolProvider);
    final activeColor = ref.watch(strokeColorProvider);
    final activeWidth = ref.watch(strokeWidthProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    final isDesktop = screenWidth >= 1024;
    final isPhone = screenWidth < 600;

    return CanvasFloatingPill(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 8 : 12,
        vertical: isPhone ? 4 : 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Pen Tool (Unified: Ballpoint, Fountain, Brush, Pencil)
          _buildToolItem(
            context: context,
            icon: Icons.edit_rounded,
            tooltip: 'Pen (P) • Tap again for settings',
            isSelected: _isPenTool(activeTool),
            activeColor: activeColor,
            isPhone: isPhone,
            onTap: () {
              if (_isPenTool(activeTool)) {
                CanvasToolPopovers.showPenPopover(context, ref);
              } else {
                ref.read(activeToolProvider.notifier).setTool(ToolType.ballpointPen);
              }
            },
          ),
          const SizedBox(width: 2),

          // 2. Highlighter
          _buildToolItem(
            context: context,
            icon: Icons.highlight_rounded,
            tooltip: 'Highlighter (H) • Tap again for settings',
            isSelected: activeTool == ToolType.highlighter,
            activeColor: activeColor,
            isPhone: isPhone,
            onTap: () => _handleToolTap(ToolType.highlighter, activeTool),
          ),
          const SizedBox(width: 2),

          // 3. Eraser
          _buildToolItem(
            context: context,
            icon: Icons.cleaning_services_rounded,
            tooltip: 'Eraser (E) • Tap again for settings',
            isSelected: activeTool == ToolType.eraser,
            activeColor: activeColor,
            isPhone: isPhone,
            onTap: () => _handleToolTap(ToolType.eraser, activeTool),
          ),
          const SizedBox(width: 2),

          // 4. Lasso
          _buildToolItem(
            context: context,
            icon: Icons.gesture_rounded,
            tooltip: 'Lasso Selection (L)',
            isSelected: activeTool == ToolType.lasso,
            activeColor: activeColor,
            isPhone: isPhone,
            onTap: () => ref.read(activeToolProvider.notifier).setTool(ToolType.lasso),
          ),
          const SizedBox(width: 2),

          // 5. Shapes (Desktop & Tablet)
          if (!isPhone) ...[
            _buildToolItem(
              context: context,
              icon: Icons.category_rounded,
              tooltip: 'Shapes • Tap again to choose shape',
              isSelected: activeTool == ToolType.shape,
              activeColor: activeColor,
              isPhone: isPhone,
              onTap: () => _handleToolTap(ToolType.shape, activeTool),
            ),
            const SizedBox(width: 2),
          ],

          // 6. Text Tool
          _buildToolItem(
            context: context,
            icon: Icons.text_fields_rounded,
            tooltip: 'Text Tool (T)',
            isSelected: activeTool == ToolType.text,
            activeColor: activeColor,
            isPhone: isPhone,
            onTap: () => ref.read(activeToolProvider.notifier).setTool(ToolType.text),
          ),
          const SizedBox(width: 2),

          // 7. Insert (+)
          _buildToolItem(
            context: context,
            icon: Icons.add_circle_outline_rounded,
            tooltip: 'Insert (Sticky Note, Image, Laser)',
            isSelected: false,
            activeColor: activeColor,
            isPhone: isPhone,
            onTap: () {
              CanvasToolPopovers.showInsertPopover(
                context,
                onAddSticky: widget.onAddStickyNote,
                onImportImage: widget.onImportImage,
                onTakePhoto: widget.onTakePhoto,
                onInsertMath: widget.onInsertMath ?? () {},
                onToggleLaser: () {
                  ref.read(activeToolProvider.notifier).setTool(ToolType.laserPointer);
                },
              );
            },
          ),

          // Divider before Pinned Swatches
          if (!isPhone) ...[
            const SizedBox(width: 4),
            SizedBox(
              height: 22,
              child: VerticalDivider(
                width: 12,
                thickness: 1,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 4),

            // Pinned 3 Colors
            ..._pinnedColors.map((c) {
              final isCurrent = activeColor.value == c.value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Tooltip(
                  message: 'Color Swatch',
                  child: InkWell(
                    onTap: () => ref.read(strokeColorProvider.notifier).setColor(c),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: isDesktop ? 18 : 20,
                      height: isDesktop ? 18 : 20,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white.withValues(alpha: 0.8),
                          width: isCurrent ? 2.2 : 1.0,
                        ),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: c.withValues(alpha: 0.45),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Pinned 3 Sizes (Desktop only or spacious tablet)
            if (isDesktop) ...[
              const SizedBox(width: 4),
              SizedBox(
                height: 18,
                child: VerticalDivider(
                  width: 8,
                  thickness: 1,
                  color: Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(width: 2),
              ..._pinnedSizes.map((s) {
                final isCurrent = (activeWidth - s).abs() < 0.2;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Tooltip(
                    message: '${s.toStringAsFixed(1)}pt Thickness',
                    child: InkWell(
                      onTap: () => ref.read(strokeWidthProvider.notifier).setWidth(s),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                              : Colors.transparent,
                        ),
                        child: Container(
                          width: (s * 1.8).clamp(3.0, 12.0),
                          height: (s * 1.8).clamp(3.0, 12.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCurrent
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ] else ...[
            // Mobile: Compact Active Color/Size Indicator Dot
            const SizedBox(width: 4),
            SizedBox(
              height: 20,
              child: VerticalDivider(
                width: 8,
                thickness: 1,
                color: Colors.grey.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 2),
            InkWell(
              onTap: () => CanvasToolPopovers.showPenPopover(context, ref),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: activeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${activeWidth.toStringAsFixed(1)}pt',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolItem({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required Color activeColor,
    required bool isPhone,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final targetSize = isPhone ? 40.0 : 36.0;

    return Tooltip(
      message: tooltip,
      child: Transform.translate(
        offset: Offset(0, isSelected ? -2.0 : 0.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: targetSize,
          height: targetSize,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0x333B82F6) : const Color(0x222563EB))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: isSelected
                ? Border.all(
                    color: (isDark ? Colors.blueAccent : const Color(0xFF2563EB))
                        .withValues(alpha: 0.4),
                    width: 1.2,
                  )
                : null,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Icon(
              icon,
              size: isPhone ? 20 : 18,
              color: isSelected
                  ? (isDark ? Colors.blueAccent : const Color(0xFF2563EB))
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}

