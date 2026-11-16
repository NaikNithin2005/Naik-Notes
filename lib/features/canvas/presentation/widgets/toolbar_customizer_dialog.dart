import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/toolbar_preferences.dart';

/// Interactive dialog and modal sheet allowing users to customize their drawing toolbar:
/// dock position, compact/expanded mode, tool visibility, and favorites.
class ToolbarCustomizerDialog extends ConsumerWidget {
  const ToolbarCustomizerDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const ToolbarCustomizerDialog(),
    );
  }

  static Future<void> showAsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const ToolbarCustomizerDialog(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(toolbarPreferencesProvider);
    final notifier = ref.read(toolbarPreferencesProvider.notifier);
    final theme = Theme.of(context);

    // Group tools by category
    final Map<String, List<ToolbarItemDef>> grouped = {};
    for (final item in ToolbarCatalog.allTools) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
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
                          'Customize Toolbar',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Configure layout, visible tools and quick-access favorites',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              Expanded(
                child: ListView(
                  children: [
                    // Layout Controls
                    Text(
                      'Toolbar Layout & Position',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dock Position
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Dock Placement'),
                        SegmentedButton<ToolbarDockPosition>(
                          segments: ToolbarDockPosition.values.map((pos) {
                            return ButtonSegment(
                              value: pos,
                              label: Text(
                                pos.name.toUpperCase(),
                                style: const TextStyle(fontSize: 10),
                              ),
                              icon: Icon(pos.icon, size: 14),
                            );
                          }).toList(),
                          selected: {prefs.dockPosition},
                          onSelectionChanged: (selected) {
                            notifier.setDockPosition(selected.first);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Compact Mode Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Compact Mode'),
                      subtitle: const Text(
                        'Tight spacing optimized for smaller screens or split-view',
                      ),
                      value: prefs.isCompact,
                      onChanged: (val) => notifier.toggleCompactMode(val),
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Tool Visibility & Favorites
                    Text(
                      'Available Tools & Favorites',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toggle switch to show/hide tool. Tap star to mark as quick favorite.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),

                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 4),
                        child: Text(
                          entry.key.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < entry.value.length; i++) ...[
                              if (i > 0) const Divider(height: 1, indent: 48),
                              _buildToolRow(
                                context: context,
                                item: entry.value[i],
                                isVisible: prefs.isToolVisible(
                                  entry.value[i].id,
                                ),
                                isFavorite: prefs.isFavorite(entry.value[i].id),
                                onToggleVisible: (val) => notifier
                                    .setToolVisibility(entry.value[i].id, val),
                                onToggleFavorite: () =>
                                    notifier.toggleFavorite(entry.value[i].id),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => notifier.resetDefaults(),
                    icon: const Icon(Icons.restore, size: 16),
                    label: const Text('Reset to Defaults'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolRow({
    required BuildContext context,
    required ToolbarItemDef item,
    required bool isVisible,
    required bool isFavorite,
    required ValueChanged<bool> onToggleVisible,
    required VoidCallback onToggleFavorite,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: Icon(
        item.icon,
        size: 20,
        color: isVisible
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.35),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isVisible ? FontWeight.w600 : FontWeight.normal,
          color: isVisible
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
      subtitle: Text(
        item.description,
        style: TextStyle(
          fontSize: 11,
          color: theme.colorScheme.onSurface.withValues(
            alpha: isVisible ? 0.65 : 0.3,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFavorite ? Colors.amber : Colors.grey,
              size: 20,
            ),
            tooltip: isFavorite ? 'Remove Favorite' : 'Mark as Favorite',
            onPressed: isVisible ? onToggleFavorite : null,
          ),
          Switch(value: isVisible, onChanged: onToggleVisible),
        ],
      ),
    );
  }
}
