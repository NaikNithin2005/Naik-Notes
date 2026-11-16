import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stroke_provider.dart';

/// Modal bottom sheet allowing precision customization of eraser modes and circular size.
///
/// Features strictly:
/// A. Complete Stroke Eraser (Whole stroke removal)
/// B. Partial Stroke Eraser (Segment split)
/// Circular eraser cursor preview.
class EraserCustomizerSheet extends ConsumerWidget {
  const EraserCustomizerSheet({super.key});

  static const List<double> _presetSizes = [
    5.0,
    10.0,
    15.0,
    20.0,
    30.0,
    40.0,
    50.0,
    75.0,
    100.0,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMode = ref.watch(eraserModeProvider);
    final activeRadius = ref.watch(eraserRadiusProvider);
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
                  Icons.cleaning_services_outlined,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Text(
                  'Eraser Settings',
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

            // Live Circular Eraser Cursor Visual Preview Box
            Center(
              child: Container(
                height: 110,
                width: 110,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.black26
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Container(
                  width: (activeRadius * 2.0).clamp(10.0, 96.0),
                  height: (activeRadius * 2.0).clamp(10.0, 96.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.error,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Eraser Mode Selector (Complete Stroke vs Partial Stroke)
            Text(
              'Eraser Mode',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<EraserMode>(
              segments: const [
                ButtonSegment(
                  value: EraserMode.stroke,
                  label: Text('Complete Stroke'),
                  icon: Icon(Icons.gesture),
                ),
                ButtonSegment(
                  value: EraserMode.partial,
                  label: Text('Partial Stroke'),
                  icon: Icon(Icons.content_cut),
                ),
              ],
              selected: {
                activeMode == EraserMode.partial
                    ? EraserMode.partial
                    : EraserMode.stroke,
              },
              onSelectionChanged: (selected) {
                ref.read(eraserModeProvider.notifier).setMode(selected.first);
              },
            ),
            const SizedBox(height: 6),
            Text(
              activeMode == EraserMode.partial
                  ? 'Partial Stroke Eraser: Erases only the touched section, preserving unaffected segments.'
                  : 'Complete Stroke Eraser: Removes the whole stroke when touched without disturbing neighbors.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            // Eraser Size Slider & Quick Presets
            Row(
              children: [
                Text(
                  'Size: ${(activeRadius * 2).toInt()} px',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${activeRadius.toInt()}px radius',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Slider(
              value: activeRadius,
              min: 2.5,
              max: 60.0,
              divisions: 23,
              label: '${(activeRadius * 2).toInt()} px',
              onChanged: (val) {
                ref.read(eraserRadiusProvider.notifier).setRadius(val);
              },
            ),
            const SizedBox(height: 6),

            // Quick Size Preset Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _presetSizes.map((sz) {
                  final radius = sz / 2.0;
                  final isSelected = (activeRadius - radius).abs() < 1.0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text('${sz.toInt()}'),
                      selected: isSelected,
                      onSelected: (_) {
                        ref
                            .read(eraserRadiusProvider.notifier)
                            .setRadius(radius);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
