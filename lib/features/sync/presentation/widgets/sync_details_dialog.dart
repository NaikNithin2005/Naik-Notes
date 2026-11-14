import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/sync_provider.dart';

/// Modal dialog displaying detailed synchronization diagnostics, status,
/// pending queue counts, and manual sync controls.
class SyncDetailsDialog extends ConsumerWidget {
  const SyncDetailsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const SyncDetailsDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final theme = Theme.of(context);

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    switch (syncState.status) {
      case SyncUiStatus.synced:
        statusColor = AppColors.syncSuccess;
        statusTitle = 'All Changes Synced';
        statusIcon = Icons.cloud_done_rounded;
        break;
      case SyncUiStatus.syncing:
        statusColor = AppColors.syncPending;
        statusTitle = 'Synchronizing...';
        statusIcon = Icons.sync_rounded;
        break;
      case SyncUiStatus.offline:
        statusColor = AppColors.syncOffline;
        statusTitle = 'Offline Mode';
        statusIcon = Icons.cloud_off_rounded;
        break;
      case SyncUiStatus.error:
        statusColor = AppColors.syncError;
        statusTitle = 'Sync Error';
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    final formattedLastSync = syncState.lastSyncedAt != null
        ? DateFormat('MMM d, y • HH:mm:ss').format(syncState.lastSyncedAt!)
        : 'Never';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(statusIcon, color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cloud Synchronization',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                statusTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
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
              const SizedBox(height: 20),

              // Diagnostics cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      context,
                      'Pending Queue',
                      '${syncState.pendingCount} operations',
                      syncState.pendingCount > 0 ? Colors.orange : Colors.green,
                    ),
                    const Divider(height: 20),
                    _buildRow(
                      context,
                      'Last Synchronized',
                      formattedLastSync,
                      theme.colorScheme.onSurface,
                    ),
                    const Divider(height: 20),
                    _buildRow(
                      context,
                      'Backend Endpoint',
                      AppConfig.devApiBaseUrl,
                      theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    if (syncState.lastError != null) ...[
                      const Divider(height: 20),
                      _buildRow(
                        context,
                        'Last Error',
                        syncState.lastError!,
                        Colors.red,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Activity stats row
              Row(
                children: [
                  Expanded(
                    child: _buildStatChip(
                      'Pushed',
                      '${syncState.lastPushed}',
                      Icons.arrow_upward_rounded,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatChip(
                      'Pulled',
                      '${syncState.lastPulled}',
                      Icons.arrow_downward_rounded,
                      theme,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatChip(
                      'Conflicts',
                      '${syncState.lastConflicts}',
                      Icons.compare_arrows_rounded,
                      theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Auto-sync toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Automatic Synchronization',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Sync mutations automatically in background when connected',
                  style: TextStyle(fontSize: 12),
                ),
                value: syncState.autoSyncEnabled,
                onChanged: (val) {
                  ref.read(syncProvider.notifier).toggleAutoSync(val);
                },
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: syncState.status == SyncUiStatus.syncing
                        ? null
                        : () async {
                            await ref.read(syncProvider.notifier).syncNow();
                          },
                    icon: syncState.status == SyncUiStatus.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync, size: 18),
                    label: Text(
                      syncState.status == SyncUiStatus.syncing
                          ? 'Syncing...'
                          : 'Sync Now',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(
    String label,
    String count,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$label: $count',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
