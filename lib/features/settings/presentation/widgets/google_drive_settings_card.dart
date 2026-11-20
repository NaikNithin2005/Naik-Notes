import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:naik_notes/core/theme/app_colors.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';

/// Card widget displayed under Settings → Cloud Storage for configuring
/// personal Google Drive note, drawing, and attachment storage (`appDataFolder`).
class GoogleDriveSettingsCard extends ConsumerWidget {
  const GoogleDriveSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driveState = ref.watch(googleDriveProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor =
        isDark ? const Color(0xFFE07A5F) : AppColors.leatherTerracotta;
    const successColor = Color(0xFF22C55E);
    const warningColor = Color(0xFFF59E0B);
    const errorColor = Color(0xFFEF4444);
    const infoColor = Color(0xFF3B82F6);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.brown.shade200;

    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');

    // Status pill config
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (driveState.status) {
      case DriveConnectionStatus.connected:
        statusColor = successColor;
        statusLabel = 'Connected';
        statusIcon = Icons.check_circle_rounded;
        break;
      case DriveConnectionStatus.connecting:
        statusColor = infoColor;
        statusLabel = 'Connecting...';
        statusIcon = Icons.sync_rounded;
        break;
      case DriveConnectionStatus.reconnecting:
        statusColor = warningColor;
        statusLabel = 'Reconnecting';
        statusIcon = Icons.autorenew_rounded;
        break;
      case DriveConnectionStatus.failed:
        statusColor = errorColor;
        statusLabel = 'Connection Failed';
        statusIcon = Icons.error_outline_rounded;
        break;
      case DriveConnectionStatus.idle:
        statusColor = warningColor;
        statusLabel = 'Not Connected';
        statusIcon = Icons.cloud_off_rounded;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 2 : 1,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_to_drive_rounded,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Drive Cloud Storage',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automatic Private Backup & Sync',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.brown.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Connection Status Pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Connected Account details or Explanation
            if (driveState.isConnected) ...[
              _buildDetailRow(
                context,
                icon: Icons.account_circle_outlined,
                label: 'Connected Account',
                value: driveState.accountEmail ?? 'Unknown Google Account',
              ),
              const SizedBox(height: 10),
              if (driveState.lastVerifiedAt != null)
                _buildDetailRow(
                  context,
                  icon: Icons.verified_user_outlined,
                  label: 'Last Synchronized',
                  value: dateFormat.format(driveState.lastVerifiedAt!),
                ),
              const SizedBox(height: 10),
              _buildDetailRow(
                context,
                icon: Icons.folder_special_outlined,
                label: 'Storage Provider',
                value: 'Google Drive API v3 (Private appDataFolder)',
              ),
              const SizedBox(height: 16),

              // Progress banner if active synchronization
              if (driveState.syncProgressMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              driveState.syncProgressMessage!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade200
                                    : Colors.brown.shade800,
                              ),
                            ),
                          ),
                          Text(
                            '${(driveState.syncProgress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: driveState.syncProgress > 0
                            ? driveState.syncProgress
                            : null,
                        color: primaryColor,
                        backgroundColor: primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Queue diagnostics metrics
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isDark ? const Color(0xFF0F172A) : Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                      context,
                      label: 'Synced Notebooks',
                      value: '${driveState.totalSyncedNotebooks}',
                      color: primaryColor,
                    ),
                    Container(height: 30, width: 1, color: borderColor),
                    _buildMetricColumn(
                      context,
                      label: 'Pending Uploads',
                      value: '${driveState.pendingUploadsCount}',
                      color: driveState.pendingUploadsCount > 0
                          ? primaryColor
                          : Colors.grey,
                    ),
                    Container(height: 30, width: 1, color: borderColor),
                    _buildMetricColumn(
                      context,
                      label: 'Failed Uploads',
                      value: '${driveState.failedUploadsCount}',
                      color: driveState.failedUploadsCount > 0
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: driveState.isLoading
                          ? null
                          : () => ref
                              .read(googleDriveProvider.notifier)
                              .syncNow(),
                      icon: driveState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync Now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: driveState.isLoading
                        ? null
                        : () => _confirmDisconnect(context, ref),
                    icon: const Icon(
                      Icons.link_off_rounded,
                      size: 18,
                      color: Colors.redAccent,
                    ),
                    label: const Text(
                      'Disconnect',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Disconnected / Failed Explanation
              Text(
                'Connect your personal Google Drive to securely back up your notebooks, '
                'handwritten notes, PDFs, and other documents in your private hidden folder. '
                'Notes sync seamlessly across Windows Desktop, iPadOS, and Android.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color:
                      isDark ? Colors.grey.shade300 : Colors.brown.shade800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              if (driveState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.red.shade400, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            driveState.errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: driveState.isLoading
                      ? null
                      : () => ref
                          .read(googleDriveProvider.notifier)
                          .connectDrive(),
                  icon: driveState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_to_drive_rounded),
                  label: Text(
                    driveState.isConnecting
                        ? 'Connecting...'
                        : (driveState.isReconnecting || driveState.hasFailed
                            ? 'Reconnect Google Drive'
                            : 'Connect Google Drive'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey.shade400 : Colors.brown.shade600,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade400 : Colors.brown.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade200 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google Drive?'),
        content: const Text(
          'Your existing local notes and attachments will remain intact on this device, '
          'but new notes and edits will not synchronize across your other devices '
          'until you reconnect Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(googleDriveProvider.notifier).disconnectDrive();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
