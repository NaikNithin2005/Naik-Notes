import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:naik_notes/core/theme/app_theme.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';

/// Card widget displayed under Settings → Cloud Storage for configuring
/// personal Google Drive attachment storage (`appDataFolder`).
class GoogleDriveSettingsCard extends ConsumerWidget {
  const GoogleDriveSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driveState = ref.watch(googleDriveProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryColor = isDark ? const Color(0xFFE07A5F) : AppColors.leatherTerracotta;
    const successColor = Color(0xFF22C55E);
    const warningColor = Color(0xFFF59E0B);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : Colors.brown.shade200;

    final dateFormat = DateFormat('MMM d, yyyy · h:mm a');

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
                        'Google Drive Attachments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Private appDataFolder Storage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.grey.shade400 : Colors.brown.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Connection Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: driveState.isConnected
                        ? successColor.withValues(alpha: 0.15)
                        : warningColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: driveState.isConnected
                          ? successColor.withValues(alpha: 0.4)
                          : warningColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        driveState.isConnected
                            ? Icons.check_circle_rounded
                            : Icons.cloud_off_rounded,
                        color: driveState.isConnected ? successColor : warningColor,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        driveState.isConnected ? 'Connected' : 'Not Connected',
                        style: TextStyle(
                          color: driveState.isConnected ? successColor : warningColor,
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
                  label: 'Last Verified',
                  value: dateFormat.format(driveState.lastVerifiedAt!),
                ),
              const SizedBox(height: 10),
              _buildDetailRow(
                context,
                icon: Icons.folder_special_outlined,
                label: 'Storage Provider',
                value: 'Google Drive API v3 (Hidden appDataFolder)',
              ),
              const SizedBox(height: 16),

              // Queue diagnostics
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor.withValues(alpha: 0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricColumn(
                      context,
                      label: 'Pending Uploads',
                      value: '${driveState.pendingUploadsCount}',
                      color: driveState.pendingUploadsCount > 0 ? primaryColor : Colors.grey,
                    ),
                    Container(height: 30, width: 1, color: borderColor),
                    _buildMetricColumn(
                      context,
                      label: 'Failed Uploads',
                      value: '${driveState.failedUploadsCount}',
                      color: driveState.failedUploadsCount > 0 ? Colors.red : Colors.grey,
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
                          : () => ref.read(googleDriveProvider.notifier).syncNow(),
                      icon: driveState.isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sync Attachments'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: driveState.isLoading
                        ? null
                        : () => _confirmDisconnect(context, ref),
                    icon: const Icon(Icons.link_off_rounded, size: 18, color: Colors.redAccent),
                    label: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ] else ...[
              // Disconnected Explanation
              Text(
                'Connect your personal Google Drive to store images, PDFs, and attachments '
                'in your private hidden application folder. Attachments sync seamlessly across '
                'Windows Desktop, iPadOS, and Android without incurring cloud storage costs.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade300 : Colors.brown.shade800,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              if (driveState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade800),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            driveState.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
                      : () => ref.read(googleDriveProvider.notifier).connectDrive(),
                  icon: driveState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_to_drive_rounded),
                  label: Text(
                    driveState.isLoading ? 'Connecting...' : 'Connect Google Drive',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.brown.shade600),
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
          'Your existing local attachments will remain intact on this device, but new attachments '
          'will not synchronize across your other devices until you reconnect Google Drive.',
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
