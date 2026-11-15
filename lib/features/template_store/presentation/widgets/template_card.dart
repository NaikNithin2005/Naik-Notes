import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/template_store_model.dart';
import 'package:naik_notes/features/template_store/data/template_store_provider.dart';

/// Card widget showcasing a community paper template with vector styling preview.
class TemplateCard extends ConsumerWidget {
  final CustomTemplate template;
  final VoidCallback? onApply;

  const TemplateCard({super.key, required this.template, this.onApply});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final props = template.properties;

    Color bgColor = _parseColor(props.backgroundColorHex, Colors.white);
    Color lineColor = _parseColor(props.lineColorHex, Colors.grey);
    Color accentColor = _parseColor(props.accentColorHex, Colors.redAccent);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Visual Paper Preview Box
          Container(
            height: 90,
            color: bgColor,
            child: Stack(
              children: [
                // Ruled / Grid Lines Simulation
                CustomPaint(
                  size: const Size(double.infinity, 90),
                  painter: _MiniPaperPainter(
                    lineColor: lineColor,
                    accentColor: accentColor,
                    isGrid: props.gridSize > 0 && props.gridSize < 25,
                    hasHeader: props.hasHeaderArea,
                  ),
                ),
                // Category Chip Overlay
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      template.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Downloads Counter Overlay
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.file_download_outlined,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${template.downloadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details & Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Author and Rating Row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'by ${template.author}',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      template.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Install / Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonal(
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () async {
                          final storeService = ref.read(
                            templateStoreServiceProvider,
                          );
                          await storeService.installTemplate(template);
                          ref.invalidate(installedTemplatesProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Installed "${template.title}" to templates library!',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            onApply?.call();
                          }
                        },
                        child: Text(
                          template.isInstalled ? 'Installed' : 'Install',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.outlined(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.share_outlined, size: 16),
                      tooltip: 'Copy JSON Definition',
                      onPressed: () {
                        final storeService = ref.read(
                          templateStoreServiceProvider,
                        );
                        final json = storeService.exportTemplateToJson(
                          template,
                        );
                        Clipboard.setData(ClipboardData(text: json));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Template JSON copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('0xFF$clean'));
      } else if (clean.length == 8) {
        return Color(int.parse('0x$clean'));
      }
    } catch (_) {}
    return fallback;
  }
}

class _MiniPaperPainter extends CustomPainter {
  final Color lineColor;
  final Color accentColor;
  final bool isGrid;
  final bool hasHeader;

  _MiniPaperPainter({
    required this.lineColor,
    required this.accentColor,
    required this.isGrid,
    required this.hasHeader,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor.withValues(alpha: 0.6)
      ..strokeWidth = 1.0;

    final accentPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.7)
      ..strokeWidth = 1.2;

    // Margin cue line
    canvas.drawLine(const Offset(24, 0), Offset(24, size.height), accentPaint);

    // Header line
    if (hasHeader) {
      canvas.drawLine(const Offset(0, 24), Offset(size.width, 24), accentPaint);
    }

    // Body lines / grid
    final startY = hasHeader ? 32.0 : 12.0;
    for (double y = startY; y < size.height; y += 14.0) {
      canvas.drawLine(Offset(24, y), Offset(size.width, y), linePaint);
    }

    if (isGrid) {
      for (double x = 38.0; x < size.width; x += 14.0) {
        canvas.drawLine(Offset(x, startY), Offset(x, size.height), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
