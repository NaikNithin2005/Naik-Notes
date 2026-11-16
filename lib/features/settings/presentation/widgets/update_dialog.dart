import 'package:flutter/material.dart';

import '../../../../services/update/app_update_service.dart';

/// Modal dialog presenting app update status, changelog, and actions.
class UpdateDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final VoidCallback? onUpdate;

  const UpdateDialog({super.key, required this.updateInfo, this.onUpdate});

  static Future<void> show(
    BuildContext context,
    AppUpdateInfo info, {
    VoidCallback? onUpdate,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !info.isMandatory,
      builder: (ctx) => UpdateDialog(updateInfo: info, onUpdate: onUpdate),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUpdate = updateInfo.hasUpdate;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          Icon(
            hasUpdate
                ? Icons.system_update_rounded
                : Icons.check_circle_outline_rounded,
            color: hasUpdate ? theme.colorScheme.primary : Colors.green,
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(hasUpdate ? 'Update Available' : 'Up to Date'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Installed Version',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'v${updateInfo.currentVersion}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.grey,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Latest Version',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'v${updateInfo.latestVersion}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasUpdate
                              ? theme.colorScheme.primary
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasUpdate
                  ? "What's New in v${updateInfo.latestVersion}:"
                  : 'Version Status:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Text(
                updateInfo.releaseNotes,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!updateInfo.isMandatory)
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(hasUpdate ? 'Later' : 'Close'),
          ),
        if (hasUpdate)
          FilledButton.icon(
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Update Now'),
            onPressed: () {
              Navigator.of(context).pop();
              if (onUpdate != null) {
                onUpdate!();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Downloading Naik Notes v${updateInfo.latestVersion}...',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
      ],
    );
  }
}
