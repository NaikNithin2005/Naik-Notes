import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'package:naik_notes/core/config/app_config.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/core/theme/theme_controller.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/canvas/data/toolbar_preferences.dart';
import 'package:naik_notes/features/canvas/presentation/widgets/toolbar_customizer_dialog.dart';
import 'package:naik_notes/features/folders/data/folder_provider.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/sync/data/sync_provider.dart';
import 'package:naik_notes/features/settings/presentation/widgets/update_dialog.dart';
import 'package:naik_notes/services/backup/backup_service.dart';
import 'package:naik_notes/services/update/app_update_service.dart';

/// Settings screen for configuring appearance/themes, cloud synchronization,
/// registered devices, backup & export, stylus behavior, and account details.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _enableCloudSync = true;
  bool _enablePalmRejection = true;
  bool _highPrecisionSmoothing = true;

  Future<void> _exportBackup() async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Packaging notebooks into ZIP archive...'),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );

      final backupService = ref.read(backupServiceProvider);
      final zipBytes = await backupService.createBackupArchive();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final defaultFileName = 'NaikNotes_Backup_$timestamp.zip';

      String? targetPath;
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final savedUri = await FilePicker.saveFile(
          dialogTitle: 'Save Notebooks Backup Archive',
          fileName: defaultFileName,
          bytes: zipBytes,
        );
        targetPath = savedUri?.toFilePath();
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$defaultFileName');
        await file.writeAsBytes(zipBytes);
        targetPath = file.path;
      }

      if (targetPath != null && mounted) {
        final sizeKb = (zipBytes.lengthInBytes / 1024).toStringAsFixed(1);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Backup archive saved ($sizeKb KB): $targetPath'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip', 'naiknotes'],
      );

      if (result.isEmpty) return;
      final file = result.first;
      final bytes = await file.readAsBytes();

      if (bytes.isEmpty) return;

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore from Backup?'),
          content: const Text(
            'This will merge the backup archive into your local library. Any existing notebooks with matching IDs will be updated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Restoring notebooks from archive...'),
            ],
          ),
          duration: Duration(seconds: 4),
        ),
      );

      final backupService = ref.read(backupServiceProvider);
      final stats = await backupService.restoreFromZip(bytes);

      // Reload notebooks and folders in UI
      await ref.read(notebooksProvider.notifier).loadNotebooks();
      await ref.read(foldersProvider.notifier).loadFolders();

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Restored ${stats.notebooksRestored} notebooks, ${stats.pagesRestored} pages, and ${stats.strokesRestored} strokes!',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _showRegisteredDevicesDialog(String? userId) async {
    if (userId == null || userId == 'guest') {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Registered Devices'),
          content: const Text(
            'Device registration and cross-device sync require signing in with a Firebase account. Sign in to synchronize your notes across Android, iPad, and Windows.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go(RouteNames.login);
              },
              child: const Text('Sign In'),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Registered Devices',
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Devices synchronized with your Firebase account (users/$userId/devices):',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('devices')
                          .get(),
                      builder: (fCtx, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        final hasAndroid = docs.any(
                          (d) => (d.data()['platform'] as String? ?? '')
                              .toLowerCase()
                              .contains('android'),
                        );
                        final hasIos = docs.any(
                          (d) =>
                              (d.data()['platform'] as String? ?? '')
                                  .toLowerCase()
                                  .contains('ios') ||
                              (d.data()['platform'] as String? ?? '')
                                  .toLowerCase()
                                  .contains('ipad') ||
                              (d.data()['platform'] as String? ?? '')
                                  .toLowerCase()
                                  .contains('mac'),
                        );
                        final hasWindows = docs.any(
                          (d) => (d.data()['platform'] as String? ?? '')
                              .toLowerCase()
                              .contains('window'),
                        );

                        return Column(
                          children: [
                            // Platform Registration Status Breakdown
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(ctx)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildPlatformStatusBadge(
                                      ctx,
                                      'Android',
                                      hasAndroid,
                                      Icons.phone_android,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildPlatformStatusBadge(
                                      ctx,
                                      'iPad / iOS',
                                      hasIos,
                                      Icons.tablet_mac,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildPlatformStatusBadge(
                                      ctx,
                                      'Windows',
                                      hasWindows,
                                      Icons.laptop_windows,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            Expanded(
                              child: docs.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.devices,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Current client session active',
                                            style: Theme.of(
                                              ctx,
                                            ).textTheme.titleSmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sign in on Android, iPad or Windows to sync across devices.',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              ctx,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      controller: scrollController,
                                      itemCount: docs.length,
                                      separatorBuilder: (c, i) =>
                                          const Divider(height: 1),
                                      itemBuilder: (itemCtx, index) {
                                        final data = docs[index].data();
                                        final deviceName =
                                            data['deviceName'] as String? ??
                                            'Device';
                                        final platform =
                                            (data['platform'] as String? ?? '')
                                                .toLowerCase();
                                        final lastActiveRaw =
                                            data['lastActiveAt'];
                                        String lastActiveText =
                                            'Active recently';
                                        if (lastActiveRaw is Timestamp) {
                                          lastActiveText =
                                              'Last active: ${DateFormat.yMMMd().add_jm().format(lastActiveRaw.toDate())}';
                                        }

                                        IconData deviceIcon =
                                            Icons.devices_other;
                                        if (platform.contains('window')) {
                                          deviceIcon = Icons.laptop_windows;
                                        } else if (platform.contains('ios') ||
                                            platform.contains('ipad') ||
                                            platform.contains('mac')) {
                                          deviceIcon = Icons.tablet_mac;
                                        } else if (platform.contains(
                                          'android',
                                        )) {
                                          deviceIcon = Icons.phone_android;
                                        }

                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Theme.of(
                                              ctx,
                                            ).colorScheme.primaryContainer,
                                            child: Icon(
                                              deviceIcon,
                                              color: Theme.of(
                                                ctx,
                                              ).colorScheme.onPrimaryContainer,
                                            ),
                                          ),
                                          title: Text(
                                            deviceName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            lastActiveText,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Linked',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlatformStatusBadge(
    BuildContext context,
    String platformName,
    bool isRegistered,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final color = isRegistered
        ? Colors.green
        : theme.colorScheme.onSurface.withValues(alpha: 0.4);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: isRegistered
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isRegistered
              ? Colors.green.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            platformName,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            isRegistered ? 'Registered' : 'Not Linked',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isRegistered ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required BuildContext context,
    required AppThemeMode mode,
    required String title,
    required String description,
    required IconData icon,
    required Color previewBg,
    required Color previewText,
    required Color previewBorder,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Miniature theme preview box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: previewBorder),
              ),
              child: Center(child: Icon(icon, color: previewText, size: 24)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final themeSettings = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Section: Appearance & Themes
          Text(
            'Appearance & Theme',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),

          // Theme selection cards
          _buildThemeCard(
            context: context,
            mode: AppThemeMode.dark,
            title: 'Dark Mode',
            description:
                'OLED dark canvas (#121212) easy on the eyes and battery.',
            icon: Icons.dark_mode_rounded,
            previewBg: const Color(0xFF121212),
            previewText: const Color(0xFFF5F5F5),
            previewBorder: const Color(0xFF383838),
            isSelected: themeSettings.themeMode == AppThemeMode.dark,
            onTap: () => themeNotifier.setThemeMode(AppThemeMode.dark),
          ),
          const SizedBox(height: 10),

          _buildThemeCard(
            context: context,
            mode: AppThemeMode.reading,
            title: 'Reading Mode',
            description:
                'Distraction-free warm paper (#F3EEDC) with serif typography.',
            icon: Icons.auto_stories_rounded,
            previewBg: const Color(0xFFF3EEDC),
            previewText: const Color(0xFF332F29),
            previewBorder: const Color(0xFFDED5C3),
            isSelected: themeSettings.themeMode == AppThemeMode.reading,
            onTap: () => themeNotifier.setThemeMode(AppThemeMode.reading),
          ),

          // Reading Mode Customization Controls
          if (themeSettings.themeMode == AppThemeMode.reading) ...[
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFFAF6EB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFDED5C3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: Color(0xFF5C4033),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reading Mode Preferences',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C4033),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Font Size Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Text Size',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF332F29),
                          ),
                        ),
                        Text(
                          '${themeSettings.readingFontSize.toInt()} pt',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C4033),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: themeSettings.readingFontSize,
                      min: 12.0,
                      max: 24.0,
                      divisions: 12,
                      activeColor: const Color(0xFF8C531B),
                      onChanged: (val) => themeNotifier.setReadingFontSize(val),
                    ),

                    // Line Spacing Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Line Spacing',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF332F29),
                          ),
                        ),
                        Text(
                          '${themeSettings.readingLineSpacing.toStringAsFixed(1)}x',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5C4033),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: themeSettings.readingLineSpacing,
                      min: 1.2,
                      max: 2.2,
                      divisions: 10,
                      activeColor: const Color(0xFF8C531B),
                      onChanged: (val) =>
                          themeNotifier.setReadingLineSpacing(val),
                    ),

                    // Margins Option
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Page Margins',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF332F29),
                          ),
                        ),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'compact',
                              label: Text(
                                'Compact',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            ButtonSegment(
                              value: 'comfortable',
                              label: Text(
                                'Normal',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            ButtonSegment(
                              value: 'wide',
                              label: Text(
                                'Wide',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                          selected: {themeSettings.readingMargins},
                          onSelectionChanged: (set) =>
                              themeNotifier.setReadingMargins(set.first),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Section: User Account & Profile
          Text(
            'Account & Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      (user?.displayName ?? 'G').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Guest User',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.isGuest ?? true
                              ? 'Offline Guest Mode (Local storage only)'
                              : (user?.email ?? ''),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (user?.isGuest ?? true)
                    FilledButton.tonal(
                      onPressed: () => context.go(RouteNames.login),
                      child: const Text('Sign In / Sync'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Logged out of cloud account.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Log Out'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Section: Cloud Sync & Backup
          Text(
            'Cloud & Synchronization',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Automatic Cloud Sync'),
                  subtitle: const Text(
                    'Sync notebooks seamlessly across iPad, Android and Windows',
                  ),
                  value: _enableCloudSync,
                  onChanged: (val) => setState(() => _enableCloudSync = val),
                  secondary: const Icon(Icons.cloud_sync_rounded),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: const Text('Sync Now'),
                  subtitle: const Text(
                    'Push local changes and pull cloud updates',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Syncing notebooks with Firebase...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    final result = await ref
                        .read(syncProvider.notifier)
                        .syncNow();
                    if (context.mounted) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            result.isSuccess
                                ? 'Cloud synchronization complete!'
                                : 'Sync warning: ${result.errorMessage}',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.devices_rounded),
                  title: const Text('Registered Devices'),
                  subtitle: const Text(
                    'View and manage all connected iPads, Android tablets & Windows PCs',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                  ),
                  onTap: () => _showRegisteredDevicesDialog(user?.id),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.archive_outlined),
                  title: const Text('Backup & Export All (.zip)'),
                  subtitle: const Text(
                    'Export complete notebook archive with pages, strokes & folders',
                  ),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: _exportBackup,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.unarchive_outlined),
                  title: const Text('Restore from Backup (.zip)'),
                  subtitle: const Text(
                    'Import a previously exported Naik Notes archive into library',
                  ),
                  trailing: const Icon(Icons.upload_file_rounded),
                  onTap: _restoreBackup,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Stylus & Handwriting
          Text(
            'Stylus & Handwriting',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Hardware Palm Rejection'),
                  subtitle: const Text(
                    'Ignore finger contact while Apple Pencil or stylus is hovering',
                  ),
                  value: _enablePalmRejection,
                  onChanged: (val) =>
                      setState(() => _enablePalmRejection = val),
                  secondary: const Icon(Icons.touch_app_rounded),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Vector Curve Smoothing'),
                  subtitle: const Text(
                    'Catmull-Rom spline smoothing for natural ink strokes',
                  ),
                  value: _highPrecisionSmoothing,
                  onChanged: (val) =>
                      setState(() => _highPrecisionSmoothing = val),
                  secondary: const Icon(Icons.gesture_rounded),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section: Toolbar Customization
          Text(
            'Toolbar Customization',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Consumer(
            builder: (context, ref, _) {
              final toolbarPrefs = ref.watch(toolbarPreferencesProvider);
              final notifier = ref.read(toolbarPreferencesProvider.notifier);
              final visibleCount = toolbarPrefs.visibleToolIds.length;
              final totalCount = ToolbarCatalog.allTools.length;

              return Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.tune_rounded),
                      title: const Text('Manage Visible Tools & Favorites'),
                      subtitle: Text(
                        '$visibleCount of $totalCount tools active • ${toolbarPrefs.favoriteToolIds.length} favorites',
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                      ),
                      onTap: () => ToolbarCustomizerDialog.show(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.dock_rounded),
                      title: const Text('Toolbar Dock Placement'),
                      subtitle: Text(toolbarPrefs.dockPosition.label),
                      trailing: DropdownButton<ToolbarDockPosition>(
                        value: toolbarPrefs.dockPosition,
                        underline: const SizedBox(),
                        items: ToolbarDockPosition.values.map((pos) {
                          return DropdownMenuItem(
                            value: pos,
                            child: Row(
                              children: [
                                Icon(pos.icon, size: 16),
                                const SizedBox(width: 8),
                                Text(pos.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) notifier.setDockPosition(val);
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.aspect_ratio_rounded),
                      title: const Text('Compact Toolbar Mode'),
                      subtitle: const Text(
                        'Reduced padding and icon size for high density',
                      ),
                      value: toolbarPrefs.isCompact,
                      onChanged: (val) => notifier.toggleCompactMode(val),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section: About
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text(AppConfig.appName),
                  subtitle: Text(
                    'Version ${AppConfig.appVersion} • 100% Free & Open Stationery',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Privacy & Security'),
                  subtitle: const Text(
                    'End-to-end user data isolation with Firebase Security Rules.',
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                Consumer(
                  builder: (context, ref, _) {
                    final autoUpdate = ref.watch(autoUpdateEnabledProvider);
                    final updateState = ref.watch(appUpdateNotifierProvider);
                    final isChecking = updateState.isLoading;

                    return Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.sync_rounded),
                          title: const Text('Automatic Update Checks'),
                          subtitle: const Text(
                            'Automatically check for new releases on startup',
                          ),
                          value: autoUpdate,
                          onChanged: (val) {
                            ref
                                .read(autoUpdateEnabledProvider.notifier)
                                .toggle(val);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.system_update_rounded),
                          title: const Text('Check for Updates'),
                          subtitle: Text(
                            updateState.value?.hasUpdate == true
                                ? 'Update available: v${updateState.value!.latestVersion}'
                                : 'App is up to date (v${AppConfig.appVersion})',
                          ),
                          trailing: isChecking
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.chevron_right),
                          onTap: isChecking
                              ? null
                              : () async {
                                  final info = await ref
                                      .read(appUpdateNotifierProvider.notifier)
                                      .check(force: true);
                                  if (context.mounted) {
                                    UpdateDialog.show(context, info);
                                  }
                                },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
