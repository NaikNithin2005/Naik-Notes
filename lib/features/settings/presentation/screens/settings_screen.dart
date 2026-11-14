import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/core/config/app_config.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';

/// Settings screen for configuring user profile, theme, cloud sync, stylus behavior, and account.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _enableCloudSync = true;
  bool _enablePalmRejection = true;
  bool _highPrecisionSmoothing = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
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
                      onPressed: () {
                        ref.read(authProvider.notifier).logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logged out of cloud account.'),
                          ),
                        );
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
                  leading: const Icon(Icons.devices_rounded),
                  title: const Text('Registered Devices'),
                  subtitle: const Text(
                    'Windows PC (Current) • iPad Pro 11 • Samsung Galaxy Tab S9',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup_rounded),
                  title: const Text('Backup & Export All'),
                  subtitle: const Text(
                    'Export complete notebook archive to zip file',
                  ),
                  trailing: const Icon(Icons.download_rounded),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Archive export prepared.')),
                    );
                  },
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
                    'End-to-end user ownership. No third-party data tracking.',
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
