import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/stroke_model.dart';
import '../../data/stroke_provider.dart';
import '../../rendering/stroke_path_builder.dart';

/// Modal bottom sheet / popover allowing real-time customization of pen, pencil, and brush tools
/// with an immediate live stroke preview, thickness slider, color picker, and stroke styles.
class ToolCustomizerSheet extends ConsumerStatefulWidget {
  final ToolType tool;

  const ToolCustomizerSheet({super.key, required this.tool});

  @override
  ConsumerState<ToolCustomizerSheet> createState() =>
      _ToolCustomizerSheetState();
}

class _ToolCustomizerSheetState extends ConsumerState<ToolCustomizerSheet> {
  final _hexController = TextEditingController();

  static const List<double> _presetWidths = [
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    4.0,
    5.0,
    7.0,
    10.0,
    15.0,
    20.0,
  ];

  static const List<Color> _extendedPalette = [
    Color(0xFF0F172A), // Black
    Color(0xFF1E293B), // Slate
    Color(0xFF475569), // Grey
    Color(0xFF1D4ED8), // Royal Blue
    Color(0xFF0284C7), // Sky Blue
    Color(0xFF0D9488), // Teal
    Color(0xFF047857), // Emerald Green
    Color(0xFF16A34A), // Green
    Color(0xFFCA8A04), // Amber
    Color(0xFFEA580C), // Orange
    Color(0xFFDC2626), // Red
    Color(0xFFBE123C), // Rose
    Color(0xFF7C3AED), // Violet
    Color(0xFF9333EA), // Purple
    Color(0xFF78350F), // Sepia Brown
  ];

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    final configs = ref.watch(toolConfigsProvider);
    final config =
        configs[tool] ??
        ToolConfig(
          tool: tool,
          width: tool.defaultWidth,
          color: PenColors.inkSlate,
          opacity: tool.defaultOpacity,
        );

    final activeColor = config.color;
    final activeWidth = config.width;
    final activeOpacity = config.opacity;
    final activeStyle = config.strokeStyle;

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getToolIcon(tool),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  '${tool.displayName} Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Live Stroke Preview Box
            Container(
              height: 70,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.black26
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CustomPaint(
                  painter: _SampleStrokePreviewPainter(
                    tool: tool,
                    color: activeColor,
                    width: activeWidth,
                    opacity: activeOpacity,
                    style: activeStyle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stroke Thickness Slider & Quick Presets
            Row(
              children: [
                Text(
                  'Thickness: ${activeWidth.toStringAsFixed(1)} pt',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  activeWidth < 2.0
                      ? 'Fine'
                      : activeWidth < 6.0
                      ? 'Standard'
                      : 'Bold',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Slider(
              value: activeWidth.clamp(0.5, 20.0),
              min: 0.5,
              max: 20.0,
              divisions: 39,
              onChanged: (val) {
                ref
                    .read(strokeWidthProvider.notifier)
                    .setWidth(val, syncConfig: true);
                ref
                    .read(toolConfigsProvider.notifier)
                    .updateConfig(tool, width: val);
              },
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presetWidths.map((w) {
                  final isSelected = (activeWidth - w).abs() < 0.25;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        '${w.toStringAsFixed(w % 1 == 0 ? 0 : 1)} pt',
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        ref
                            .read(strokeWidthProvider.notifier)
                            .setWidth(w, syncConfig: true);
                        ref
                            .read(toolConfigsProvider.notifier)
                            .updateConfig(tool, width: w);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Stroke Style (Solid, Dashed, Dotted)
            Text(
              'Stroke Style',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<StrokeStyle>(
              segments: const [
                ButtonSegment(
                  value: StrokeStyle.solid,
                  label: Text('Solid'),
                  icon: Icon(Icons.horizontal_rule),
                ),
                ButtonSegment(
                  value: StrokeStyle.dashed,
                  label: Text('Dashed'),
                  icon: Icon(Icons.more_horiz),
                ),
                ButtonSegment(
                  value: StrokeStyle.dotted,
                  label: Text('Dotted'),
                  icon: Icon(Icons.scatter_plot),
                ),
              ],
              selected: {activeStyle},
              onSelectionChanged: (selected) {
                final newStyle = selected.first;
                ref
                    .read(strokeStyleProvider.notifier)
                    .setStyle(newStyle, syncConfig: true);
                ref
                    .read(toolConfigsProvider.notifier)
                    .updateConfig(tool, strokeStyle: newStyle);
              },
            ),
            const SizedBox(height: 16),

            // Opacity Slider (especially for pencil / highlighter)
            Row(
              children: [
                Text(
                  'Ink Opacity: ${(activeOpacity * 100).toInt()}%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: activeOpacity.clamp(0.1, 1.0),
              min: 0.1,
              max: 1.0,
              divisions: 18,
              onChanged: (val) {
                ref
                    .read(strokeOpacityProvider.notifier)
                    .setOpacity(val, syncConfig: true);
                ref
                    .read(toolConfigsProvider.notifier)
                    .updateConfig(tool, opacity: val);
              },
            ),
            const SizedBox(height: 12),

            // Color Palette
            Text(
              'Color Palette',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _extendedPalette.map((col) {
                final isSelected = activeColor.toARGB32() == col.toARGB32();
                return InkWell(
                  onTap: () {
                    ref
                        .read(strokeColorProvider.notifier)
                        .setColor(col, syncConfig: true);
                    ref
                        .read(toolConfigsProvider.notifier)
                        .updateConfig(tool, color: col);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                        width: isSelected ? 3.0 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: col.withValues(alpha: 0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Custom HEX color input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: InputDecoration(
                      hintText: '#RRGGBB (e.g. #3B82F6)',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    final text = _hexController.text.trim();
                    final parsed = _parseHexColor(text);
                    if (parsed != null) {
                      ref
                          .read(strokeColorProvider.notifier)
                          .setColor(parsed, syncConfig: true);
                      ref
                          .read(toolConfigsProvider.notifier)
                          .updateConfig(tool, color: parsed);
                    }
                  },
                  child: const Text('Apply HEX'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Color? _parseHexColor(String hex) {
    String clean = hex.replaceAll('#', '').trim();
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    final val = int.tryParse(clean, radix: 16);
    if (val != null) {
      return Color(val);
    }
    return null;
  }

  IconData _getToolIcon(ToolType tool) {
    switch (tool) {
      case ToolType.fountainPen:
        return Icons.edit;
      case ToolType.ballpointPen:
        return Icons.border_color;
      case ToolType.pencil:
        return Icons.mode_edit_outline;
      case ToolType.brushPen:
        return Icons.brush;
      case ToolType.highlighter:
        return Icons.highlight;
      case ToolType.marker:
        return Icons.draw;
      case ToolType.calligraphyPen:
        return Icons.brush_outlined;
      case ToolType.technicalPen:
        return Icons.architecture_rounded;
      case ToolType.customBrush:
        return Icons.auto_fix_high_rounded;
      case ToolType.fillBucket:
        return Icons.format_color_fill_rounded;
      case ToolType.eraser:
        return Icons.cleaning_services_outlined;
      case ToolType.lasso:
        return Icons.gesture;
      case ToolType.shape:
        return Icons.crop_square;
      case ToolType.text:
        return Icons.title;
      case ToolType.laserPointer:
        return Icons.gps_fixed;
      case ToolType.pan:
        return Icons.pan_tool;
    }
  }
}

/// CustomPainter generating a smooth sample S-curve preview for the tool.
class _SampleStrokePreviewPainter extends CustomPainter {
  final ToolType tool;
  final Color color;
  final double width;
  final double opacity;
  final StrokeStyle style;
  final StrokePathBuilder _builder = const StrokePathBuilder();

  _SampleStrokePreviewPainter({
    required this.tool,
    required this.color,
    required this.width,
    required this.opacity,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Generate smooth sample S-curve points
    final pts = <StrokePoint>[];
    const steps = 30;
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = 20.0 + (w - 40.0) * t;
      final y = (h / 2.0) + (h * 0.28) * math.sin(t * math.pi * 2.0);
      final pressure = 0.3 + 0.7 * math.sin(t * math.pi);
      pts.add(StrokePoint(x: x, y: y, pressure: pressure, timestamp: i * 10));
    }

    final sampleStroke = Stroke(
      id: 'preview',
      pageId: 'preview-page',
      tool: tool,
      colorValue: color.toARGB32(),
      width: width,
      opacity: opacity,
      points: pts,
      createdAt: DateTime.now(),
      strokeStyle: style,
    );

    final rendered = _builder.build(sampleStroke);
    canvas.drawPath(rendered.path, rendered.paint);
  }

  @override
  bool shouldRepaint(covariant _SampleStrokePreviewPainter oldDelegate) {
    return oldDelegate.tool != tool ||
        oldDelegate.color != color ||
        oldDelegate.width != width ||
        oldDelegate.opacity != opacity ||
        oldDelegate.style != style;
  }
}
