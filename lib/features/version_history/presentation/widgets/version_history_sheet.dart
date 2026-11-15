import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/features/canvas/data/stroke_provider.dart';
import 'package:naik_notes/features/version_history/data/version_history_provider.dart';

/// Modal sheet displaying chronological page revisions, stroke counts,
/// diff summaries, and one-tap restore functionality.
class VersionHistorySheet extends ConsumerStatefulWidget {
  final String pageId;
  final String notebookId;

  const VersionHistorySheet({
    super.key,
    required this.pageId,
    required this.notebookId,
  });

  @override
  ConsumerState<VersionHistorySheet> createState() =>
      _VersionHistorySheetState();
}

class _VersionHistorySheetState extends ConsumerState<VersionHistorySheet> {
  bool _isSavingSnapshot = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshotsAsync = ref.watch(pageSnapshotsProvider(widget.pageId));

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header Title & Save Snapshot Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Page Version History',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Review revisions or revert page to any previous snapshot',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    icon: _isSavingSnapshot
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 16,
                          ),
                    label: const Text(
                      'Save Snapshot',
                      style: TextStyle(fontSize: 12),
                    ),
                    onPressed: _isSavingSnapshot ? null : _saveManualSnapshot,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Snapshot Timeline List
            Expanded(
              child: snapshotsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error loading history: $err')),
                data: (snapshots) {
                  if (snapshots.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 56,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No previous versions recorded yet.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap "Save Snapshot" above to preserve the current state.',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final snap = snapshots[index];
                      final isLatest = index == 0;

                      return Container(
                        decoration: BoxDecoration(
                          color: isLatest
                              ? theme.colorScheme.primaryContainer.withValues(
                                  alpha: 0.25,
                                )
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLatest
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.4,
                                  )
                                : theme.colorScheme.outlineVariant.withValues(
                                    alpha: 0.3,
                                  ),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isLatest
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.2),
                                  child: Text(
                                    'v${snap.versionNumber}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isLatest
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    snap.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                if (isLatest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  snap.formattedDate,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.devices_rounded,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  snap.deviceInfo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: const Icon(Icons.gesture, size: 14),
                                  label: Text(
                                    '${snap.strokeCount} strokes',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Chip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: const Icon(
                                    Icons.note_alt_outlined,
                                    size: 14,
                                  ),
                                  label: Text(
                                    '${snap.noteCount} notes',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.restore_rounded,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Restore',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () => _confirmRestore(
                                    snap.id,
                                    'Version ${snap.versionNumber}',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveManualSnapshot() async {
    setState(() => _isSavingSnapshot = true);
    final historyService = ref.read(versionHistoryServiceProvider);

    try {
      await historyService.captureSnapshot(
        widget.pageId,
        widget.notebookId,
        label: 'Manual Snapshot',
      );
      ref.invalidate(pageSnapshotsProvider(widget.pageId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Version snapshot created successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingSnapshot = false);
      }
    }
  }

  Future<void> _confirmRestore(String snapshotId, String versionLabel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Version?'),
        content: Text(
          'Reverting to $versionLabel will replace the current strokes and notes on this page. Do you wish to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final historyService = ref.read(versionHistoryServiceProvider);
      await historyService.restoreSnapshot(snapshotId);

      // Invalidate strokes state for page
      ref.invalidate(strokesNotifierProvider);
      ref.invalidate(pageSnapshotsProvider(widget.pageId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restored $versionLabel successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
