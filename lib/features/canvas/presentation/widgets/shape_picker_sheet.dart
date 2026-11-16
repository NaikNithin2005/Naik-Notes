import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/shape_model.dart';
import '../../../../data/models/stroke_model.dart';
import '../../data/stroke_provider.dart';

/// Modal bottom sheet allowing selection from all 27 geometric shapes with
/// live vector previews, fill/outline styling controls, and precision snapping assistance.
class ShapePickerSheet extends ConsumerStatefulWidget {
  const ShapePickerSheet({super.key});

  @override
  ConsumerState<ShapePickerSheet> createState() => _ShapePickerSheetState();
}

class _ShapePickerSheetState extends ConsumerState<ShapePickerSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  static const List<Color> _shapeColors = [
    Color(0xFF0F172A), // Slate Black
    Color(0xFF1E293B), // Navy Slate
    Color(0xFF2563EB), // Blue
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF059669), // Emerald
    Color(0xFFD97706), // Amber
    Color(0xFFDC2626), // Red
    Color(0xFF7C3AED), // Purple
  ];

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeShape = ref.watch(selectedShapeTypeProvider);
    final activeStrokeColor = ref.watch(strokeColorProvider);
    final activeStrokeWidth = ref.watch(strokeWidthProvider);
    final activeStrokeStyle = ref.watch(shapeStrokeStyleProvider);
    final isFilled = ref.watch(shapeIsFilledProvider);
    final activeFillColor =
        ref.watch(shapeFillColorProvider) ?? activeStrokeColor;
    final activeFillOpacity = ref.watch(shapeFillOpacityProvider);
    final isSnappingEnabled = ref.watch(snappingEnabledProvider);

    final theme = Theme.of(context);

    final basicShapes = ShapeType.values
        .where((s) => s.category == ShapeCategory.basic)
        .toList();
    final advancedShapes = ShapeType.values
        .where((s) => s.category == ShapeCategory.advanced)
        .toList();

    return Container(
      height: 540,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Snapping Toggle
          Row(
            children: [
              Icon(Icons.category_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Geometric Shapes Library (27)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Snapping toggle chip
              FilterChip(
                label: const Text('Snapping'),
                avatar: Icon(
                  isSnappingEnabled ? Icons.grid_4x4 : Icons.grid_off,
                  size: 16,
                ),
                selected: isSnappingEnabled,
                onSelected: (val) {
                  ref.read(snappingEnabledProvider.notifier).setEnabled(val);
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Tabs: Basic vs Advanced
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Basic Shapes (${basicShapes.length})'),
              Tab(text: 'Advanced Shapes (${advancedShapes.length})'),
            ],
          ),
          const SizedBox(height: 10),

          // Shape Grid View
          SizedBox(
            height: 140,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildShapeGrid(basicShapes, activeShape, theme),
                _buildShapeGrid(advancedShapes, activeShape, theme),
              ],
            ),
          ),
          const Divider(),

          // Shape Styling Controls
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outline Thickness & Style
                  Row(
                    children: [
                      Text(
                        'Outline: ${activeStrokeWidth.toStringAsFixed(1)} pt',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      SegmentedButton<StrokeStyle>(
                        segments: const [
                          ButtonSegment(
                            value: StrokeStyle.solid,
                            label: Text('Solid'),
                          ),
                          ButtonSegment(
                            value: StrokeStyle.dashed,
                            label: Text('Dashed'),
                          ),
                          ButtonSegment(
                            value: StrokeStyle.dotted,
                            label: Text('Dotted'),
                          ),
                        ],
                        selected: {activeStrokeStyle},
                        onSelectionChanged: (selected) {
                          ref
                              .read(shapeStrokeStyleProvider.notifier)
                              .setStyle(selected.first);
                          ref
                              .read(strokeStyleProvider.notifier)
                              .setStyle(selected.first, syncConfig: true);
                        },
                      ),
                    ],
                  ),
                  Slider(
                    value: activeStrokeWidth.clamp(1.0, 16.0),
                    min: 1.0,
                    max: 16.0,
                    divisions: 30,
                    onChanged: (val) {
                      ref
                          .read(strokeWidthProvider.notifier)
                          .setWidth(val, syncConfig: true);
                      ref
                          .read(toolConfigsProvider.notifier)
                          .updateConfig(ToolType.shape, width: val);
                    },
                  ),

                  // Outline Color
                  Row(
                    children: [
                      Text(
                        'Outline Color',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: 6,
                        children: _shapeColors.map((col) {
                          final isSelected =
                              activeStrokeColor.toARGB32() == col.toARGB32();
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(strokeColorProvider.notifier)
                                  .setColor(col, syncConfig: true);
                              ref
                                  .read(toolConfigsProvider.notifier)
                                  .updateConfig(ToolType.shape, color: col);
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: col,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(
                                        color: theme.colorScheme.primary,
                                        width: 2.5,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Fill Toggle & Controls (for closed shapes)
                  if (!activeShape.isLineLike) ...[
                    Row(
                      children: [
                        Checkbox(
                          value: isFilled,
                          onChanged: (val) {
                            ref
                                .read(shapeIsFilledProvider.notifier)
                                .setFilled(val ?? false);
                          },
                        ),
                        Text(
                          'Fill Shape',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (isFilled)
                          Wrap(
                            spacing: 6,
                            children: _shapeColors.map((col) {
                              final isSelected =
                                  activeFillColor.toARGB32() == col.toARGB32();
                              return InkWell(
                                onTap: () {
                                  ref
                                      .read(shapeFillColorProvider.notifier)
                                      .setColor(col);
                                },
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: col.withValues(
                                      alpha: activeFillOpacity,
                                    ),
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: theme.colorScheme.primary,
                                            width: 2.5,
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                    if (isFilled) ...[
                      Row(
                        children: [
                          Text(
                            'Fill Opacity: ${(activeFillOpacity * 100).toInt()}%',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Slider(
                        value: activeFillOpacity.clamp(0.1, 1.0),
                        min: 0.1,
                        max: 1.0,
                        divisions: 18,
                        onChanged: (val) {
                          ref
                              .read(shapeFillOpacityProvider.notifier)
                              .setOpacity(val);
                        },
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeGrid(
    List<ShapeType> shapes,
    ShapeType activeShape,
    ThemeData theme,
  ) {
    return GridView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: shapes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (ctx, idx) {
        final shape = shapes[idx];
        final isSelected = activeShape == shape;

        return Tooltip(
          message: shape.displayName,
          child: InkWell(
            onTap: () {
              ref.read(selectedShapeTypeProvider.notifier).setShapeType(shape);
              ref.read(activeToolProvider.notifier).setTool(ToolType.shape);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.4,
                      ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: CustomPaint(
                        size: const Size(28, 28),
                        painter: _ShapeIconPainter(
                          shape: shape,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    shape.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Mini CustomPainter generating miniature vector previews of each shape for the picker buttons.
class _ShapeIconPainter extends CustomPainter {
  final ShapeType shape;
  final Color color;

  _ShapeIconPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = ShapeGeometry.buildPath(shape, rect.deflate(2.0));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShapeIconPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.color != color;
  }
}
