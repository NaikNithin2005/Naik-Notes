import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../storage/data/google_drive_provider.dart';
import '../../../storage/presentation/widgets/google_drive_connect_dialog.dart';
import '../../../sync/data/sync_provider.dart';
import '../../../sync/presentation/widgets/sync_details_dialog.dart';

/// Backward compatibility alias
typedef SyncStatusState = SyncUiStatus;

/// Pill indicator displaying cloud synchronization status with interactive diagnostics dialog.
class SyncStatusBadge extends ConsumerWidget {
  final SyncUiStatus? status;
  final VoidCallback? onTap;

  const SyncStatusBadge({super.key, this.status, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final driveState = ref.watch(googleDriveProvider);

    var effectiveStatus = status ?? syncState.status;
    if (status == null && driveState.isSyncing) {
      effectiveStatus = SyncUiStatus.syncing;
    } else if (effectiveStatus == SyncUiStatus.synced && syncState.pendingCount > 0) {
      effectiveStatus = SyncUiStatus.pending;
    }

    Color badgeColor;
    Widget leadingWidget;
    String label;

    // When status is not explicitly passed and Drive is not connected, display Backup Required
    if (status == null && !driveState.isConnected) {
      badgeColor = Colors.amber.shade700;
      leadingWidget = Icon(
        Icons.cloud_off_rounded,
        size: 14,
        color: badgeColor,
      );
      label = 'Backup Required';
      return Tooltip(
        message: 'Cloud Sync: Backup Required (Tap to connect Google Drive)',
        child: InkWell(
          onTap: onTap ??
              () => showDialog<void>(
                    context: context,
                    builder: (ctx) =>
                        const GoogleDriveConnectDialog(isPoliteReminder: true),
                  ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leadingWidget,
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: badgeColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    switch (effectiveStatus) {
      case SyncUiStatus.synced:
        badgeColor = AppColors.syncSuccess;
        leadingWidget = Icon(
          Icons.cloud_done_rounded,
          size: 14,
          color: badgeColor,
        );
        label = driveState.isConnected ? 'Cloud Synced' : 'Synced';
        break;
      case SyncUiStatus.saving:
        badgeColor = Colors.blue.shade700;
        leadingWidget = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: badgeColor),
        );
        label = 'Saving';
        break;
      case SyncUiStatus.syncing:
        badgeColor = AppColors.syncPending;
        leadingWidget = SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: badgeColor),
        );
        label = status != null ? 'Synchronizing...' : 'Syncing';
        break;
      case SyncUiStatus.offline:
        badgeColor = AppColors.syncOffline;
        leadingWidget = Icon(
          Icons.cloud_off_rounded,
          size: 14,
          color: badgeColor,
        );
        label = status != null ? 'Offline' : 'Waiting for Internet';
        break;
      case SyncUiStatus.error:
        badgeColor = AppColors.syncError;
        leadingWidget = Icon(
          Icons.sync_problem_rounded,
          size: 14,
          color: badgeColor,
        );
        label = 'Sync Failed';
        break;
      case SyncUiStatus.pending:
        badgeColor = Colors.amber.shade700;
        leadingWidget = Icon(
          Icons.cloud_upload_outlined,
          size: 14,
          color: badgeColor,
        );
        label = 'Pending Changes';
        break;
      case SyncUiStatus.conflict:
        badgeColor = Colors.deepOrange.shade600;
        leadingWidget = Icon(
          Icons.call_split_rounded,
          size: 14,
          color: badgeColor,
        );
        label = 'Conflict Copy';
        break;
    }

    final tooltipMessage = switch (effectiveStatus) {
      SyncUiStatus.synced => 'All notes are up to date.',
      SyncUiStatus.saving => 'Saving changes locally to this device...',
      SyncUiStatus.syncing => 'Synchronizing changes with cloud...',
      SyncUiStatus.offline => 'Your changes are saved on this device and will sync when you\'re online.',
      SyncUiStatus.pending => 'Your changes are saved on this device and will sync when you\'re online.',
      SyncUiStatus.error => 'Some changes could not be synchronized. Your local content is safe.',
      SyncUiStatus.conflict => 'Conflicting edits were detected. A separate copy has been preserved.',
    };

    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        onTap: onTap ?? () => SyncDetailsDialog.show(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leadingWidget,
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
