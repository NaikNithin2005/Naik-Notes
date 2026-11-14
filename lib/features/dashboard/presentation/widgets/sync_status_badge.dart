import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
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
    final effectiveStatus = status ?? ref.watch(syncProvider).status;

    Color badgeColor;
    IconData badgeIcon;
    String label;

    switch (effectiveStatus) {
      case SyncUiStatus.synced:
        badgeColor = AppColors.syncSuccess;
        badgeIcon = Icons.cloud_done_rounded;
        label = 'Synced';
        break;
      case SyncUiStatus.syncing:
        badgeColor = AppColors.syncPending;
        badgeIcon = Icons.sync_rounded;
        label = 'Syncing...';
        break;
      case SyncUiStatus.offline:
        badgeColor = AppColors.syncOffline;
        badgeIcon = Icons.cloud_off_rounded;
        label = 'Offline';
        break;
      case SyncUiStatus.error:
        badgeColor = AppColors.syncError;
        badgeIcon = Icons.sync_problem_rounded;
        label = 'Sync Error';
        break;
    }

    return Tooltip(
      message: 'Cloud Sync: $label (Tap for details)',
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
