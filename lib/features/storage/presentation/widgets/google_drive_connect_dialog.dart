import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/google_drive_provider.dart';

/// Professional dialog prompting the user to connect their personal Google Drive
/// for automatic cloud backup of notes, pages, drawings, and attachments.
class GoogleDriveConnectDialog extends ConsumerStatefulWidget {
  final bool isPoliteReminder;

  const GoogleDriveConnectDialog({
    super.key,
    this.isPoliteReminder = false,
  });

  static DateTime? _lastDismissedAt;

  /// Global flag to suppress automatic startup popups during automated tests.
  static bool suppressAutoShow = false;

  /// Shows the dialog if user is eligible (authenticated, drive not connected, not snoozed).
  static Future<void> checkAndShow(
    BuildContext context,
    WidgetRef ref, {
    bool force = false,
  }) async {
    if (!force) {
      if (suppressAutoShow ||
          WidgetsBinding.instance.runtimeType
              .toString()
              .contains('TestWidgetsFlutterBinding')) {
        return;
      }
    }

    final driveState = ref.read(googleDriveProvider);
    if (driveState.isConnected && !force) return;

    final driveNotifier = ref.read(googleDriveProvider.notifier);
    if (!force) {
      final isDeclined = await driveNotifier.isDeclined();
      if (isDeclined) return;
      final isSnoozed = await driveNotifier.isSnoozed();
      if (isSnoozed) return;
      if (_lastDismissedAt != null) {
        if (DateTime.now().difference(_lastDismissedAt!).inDays < 3) {
          return;
        }
      }
    }

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const GoogleDriveConnectDialog(),
    );
  }

  @override
  ConsumerState<GoogleDriveConnectDialog> createState() =>
      _GoogleDriveConnectDialogState();
}

class _GoogleDriveConnectDialogState
    extends ConsumerState<GoogleDriveConnectDialog> {
  bool _connecting = false;
  String? _localError;

  Future<void> _handleConnect() async {
    setState(() {
      _connecting = true;
      _localError = null;
    });

    final success =
        await ref.read(googleDriveProvider.notifier).connectDrive();

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Google Drive Connected! Notes will now synchronize automatically.',
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final driveState = ref.read(googleDriveProvider);
      setState(() {
        _connecting = false;
        _localError = driveState.errorMessage ??
            'Could not connect Google Drive. Please try again.';
      });
    }
  }

  Future<void> _handleMaybeLater() async {
    GoogleDriveConnectDialog._lastDismissedAt = DateTime.now();
    if (widget.isPoliteReminder) {
      await ref.read(googleDriveProvider.notifier).setDeclined(true);
    } else {
      await ref.read(googleDriveProvider.notifier).setSnoozed();
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFFE07A5F) : AppColors.leatherTerracotta;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Terracotta / Cloud Header Badge
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.cloud_sync_rounded,
                    color: primaryColor,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Keep Your Notes Safe with Cloud Backup',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                widget.isPoliteReminder
                    ? 'Your notes are currently saved only on this device. Cloud backup is not enabled, so your notes may not be available on your other devices. Connect Google Drive to keep your notebooks backed up and access them across your devices.'
                    : 'Connect your Google Drive to securely back up your notebooks, '
                        'handwritten notes, PDFs, and other documents. Access your notes '
                        'across your devices whenever you need them.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Error display if connection failed
              if (_localError != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade400, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localError!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Primary: Connect Google Drive
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _connecting ? null : _handleConnect,
                  icon: _connecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add_to_drive_rounded, size: 20),
                  label: Text(
                    _connecting ? 'Connecting...' : 'Connect Google Drive',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary: Maybe Later
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _connecting ? null : _handleMaybeLater,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.isPoliteReminder
                        ? 'Continue Without Cloud Backup'
                        : 'Maybe Later',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Polite reassurance footnote
              Text(
                'Your notes remain available on this device even without cloud synchronization.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
