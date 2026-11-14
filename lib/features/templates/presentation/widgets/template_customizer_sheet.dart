import 'package:flutter/material.dart';

import '../../../../data/models/paper_template_model.dart';
import 'paper_template_view.dart';

/// Modal bottom sheet / dialog allowing deep customization of paper template properties.
class TemplateCustomizerSheet extends StatefulWidget {
  final PaperTemplateType initialType;
  final PaperProperties initialProperties;
  final void Function(
    PaperTemplateType type,
    PaperProperties properties,
    bool applyToAll,
  )
  onApply;

  const TemplateCustomizerSheet({
    super.key,
    required this.initialType,
    required this.initialProperties,
    required this.onApply,
  });

  @override
  State<TemplateCustomizerSheet> createState() =>
      _TemplateCustomizerSheetState();
}

class _TemplateCustomizerSheetState extends State<TemplateCustomizerSheet> {
  late PaperTemplateType _selectedType;
  late PaperProperties _properties;
  bool _applyToAll = false;

  static const _paperBackgrounds = [
    {'name': 'Ivory Cream', 'colorHex': '#FDFBF7', 'border': '#E2DCD2'},
    {'name': 'Pure White', 'colorHex': '#FFFFFF', 'border': '#E2E8F0'},
    {'name': 'Vintage Sepia', 'colorHex': '#F5EFEB', 'border': '#D8CBBF'},
    {'name': 'Dark Slate', 'colorHex': '#1E2022', 'border': '#33373B'},
    {'name': 'Sage Mint', 'colorHex': '#F0F5F2', 'border': '#CBE2D4'},
    {'name': 'Blush Rose', 'colorHex': '#FAF0F2', 'border': '#E8CFD4'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _properties = widget.initialProperties;
  }

  Color _parseColor(String hex) {
    if (hex == 'transparent') return Colors.transparent;
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFFFDFBF7);
    }
  }

  void _onTypeSelected(PaperTemplateType type) {
    setState(() {
      _selectedType = type;
      _properties = PaperProperties.defaultFor(
        type,
        pageSize: _properties.pageSize,
        orientation: _properties.orientation,
        backgroundColorHex: _properties.backgroundColorHex,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group 19 templates by category
    final categories = <String, List<PaperTemplateType>>{};
    for (final t in PaperTemplateType.values) {
      categories.putIfAbsent(t.category, () => []).add(t);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paper Template & Style',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Select ruling, grid dimensions, margins and paper background',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              // Content Area: Split View (Options on left, Live Preview on right)
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Template selection & Sliders
                    Expanded(
                      flex: 6,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(4, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Template Type Chips by Category
                            Text(
                              'Template Layout (${PaperTemplateType.values.length} styles)',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...categories.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.primary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: entry.value.map((type) {
                                        final isSelected =
                                            _selectedType == type;
                                        return ChoiceChip(
                                          label: Text(type.displayName),
                                          selected: isSelected,
                                          onSelected: (selected) {
                                            if (selected) _onTypeSelected(type);
                                          },
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),

                            // 2. Paper Background Color Palette
                            Text(
                              'Paper Background Tone',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: _paperBackgrounds.map((bg) {
                                final isSelected =
                                    _properties.backgroundColorHex ==
                                    bg['colorHex'];
                                final color = _parseColor(bg['colorHex']!);
                                final borderColor = _parseColor(bg['border']!);

                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _properties = _properties.copyWith(
                                        backgroundColorHex: bg['colorHex']!,
                                      );
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 100,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : borderColor,
                                        width: isSelected ? 2.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isSelected)
                                          Icon(
                                            Icons.check,
                                            size: 14,
                                            color: theme.colorScheme.primary,
                                          ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            bg['name']!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: bg['colorHex'] == '#1E2022'
                                                  ? Colors.white
                                                  : Colors.black87,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 18),
                            const Divider(),
                            const SizedBox(height: 12),

                            // 3. Spacing & Grid Size Controls
                            Text(
                              'Line Spacing & Grid Precision',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Line Spacing Slider (if applicable)
                            Row(
                              children: [
                                const Text(
                                  'Line Spacing: ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${(_properties.lineSpacing / 2.83465).toStringAsFixed(1)} mm',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _properties.lineSpacing.clamp(10.0, 36.0),
                              min: 10.0,
                              max: 36.0,
                              divisions: 26,
                              onChanged: (val) {
                                setState(() {
                                  _properties = _properties.copyWith(
                                    lineSpacing: val,
                                  );
                                });
                              },
                            ),

                            // Grid Size Slider
                            Row(
                              children: [
                                const Text(
                                  'Grid Size: ',
                                  style: TextStyle(fontSize: 12),
                                ),
                                Text(
                                  '${(_properties.gridSize / 2.83465).toStringAsFixed(1)} mm',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _properties.gridSize.clamp(8.0, 30.0),
                              min: 8.0,
                              max: 30.0,
                              divisions: 22,
                              onChanged: (val) {
                                setState(() {
                                  _properties = _properties.copyWith(
                                    gridSize: val,
                                  );
                                });
                              },
                            ),

                            const SizedBox(height: 12),

                            // Margins adjustment
                            const Text(
                              'Page Margins',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SegmentedButton<double>(
                              segments: const [
                                ButtonSegment(
                                  value: 36.0,
                                  label: Text('Narrow'),
                                ),
                                ButtonSegment(
                                  value: 56.0,
                                  label: Text('Standard'),
                                ),
                                ButtonSegment(value: 80.0, label: Text('Wide')),
                              ],
                              selected: {
                                _properties.marginLeft.clamp(36.0, 80.0),
                              },
                              onSelectionChanged: (set) {
                                final val = set.first;
                                setState(() {
                                  _properties = _properties.copyWith(
                                    marginLeft: val,
                                    marginRight: val > 60 ? 48.0 : 36.0,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const VerticalDivider(width: 1),

                    // Right Column: Live Miniature Paper Preview
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        child: Column(
                          children: [
                            Text(
                              'Live Preview',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_selectedType.displayName} • ${_properties.pageSize}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(height: 14),

                            // Miniature preview box
                            Expanded(
                              child: Center(
                                child: AspectRatio(
                                  aspectRatio:
                                      _properties.orientation == 'landscape'
                                      ? 841.89 / 595.28
                                      : 595.28 / 841.89,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: PaperTemplateView(
                                      type: _selectedType,
                                      properties: _properties,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Scope Toggle: Apply to this page vs entire notebook
                            Material(
                              color: Colors.transparent,
                              child: CheckboxListTile(
                                value: _applyToAll,
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Apply to all pages in notebook',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onChanged: (val) {
                                  setState(() => _applyToAll = val ?? false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () {
                      widget.onApply(_selectedType, _properties, _applyToAll);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Apply Template'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
