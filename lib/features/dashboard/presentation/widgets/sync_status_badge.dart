import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

enum SyncStatusState { synced, syncing, offline, error }

/// Pill indicator displaying cloud synchronization status.
class SyncStatusBadge extends StatelessWidget {
  final SyncStatusState status;
  final VoidCallback? onTap;

  const SyncStatusBadge({
    super.key,
    this.status = SyncStatusState.synced,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    IconData badgeIcon;
    String label;

    switch (status) {
      case SyncStatusState.synced:
        badgeColor = AppColors.syncSuccess;
        badgeIcon = Icons.cloud_done_rounded;
        label = 'Synced';
        break;
      case SyncStatusState.syncing:
        badgeColor = AppColors.syncPending;
        badgeIcon = Icons.sync_rounded;
        label = 'Syncing...';
        break;
      case SyncStatusState.offline:
        badgeColor = AppColors.syncOffline;
        badgeIcon = Icons.cloud_off_rounded;
        label = 'Offline';
        break;
      case SyncStatusState.error:
        badgeColor = AppColors.syncError;
        badgeIcon = Icons.sync_problem_rounded;
        label = 'Sync Error';
        break;
    }

    return Tooltip(
      message: 'Cloud Sync Status: $label',
      child: InkWell(
        onTap: onTap,
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
              Icon(badgeIcon, size: 14, color: badgeColor),
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
