import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:naik_notes/features/dashboard/presentation/widgets/sync_status_badge.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';
import 'package:naik_notes/features/storage/presentation/widgets/google_drive_connect_dialog.dart';
import 'package:naik_notes/features/settings/presentation/widgets/google_drive_settings_card.dart';
import 'package:naik_notes/features/sync/data/sync_provider.dart';
import 'package:naik_notes/services/storage/google_drive_sync_coordinator.dart';

void main() {
  group('Google Drive Cloud Sync & Authentication Master Tests', () {
    testWidgets('GoogleDriveConnectDialog renders required title, description, buttons, and footnote', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleDriveConnectDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Title
      expect(find.text('Keep Your Notes Safe with Cloud Backup'), findsOneWidget);

      // Description
      expect(
        find.text(
          'Connect your Google Drive to securely back up your notebooks, '
          'handwritten notes, PDFs, and other documents. Access your notes '
          'across your devices whenever you need them.',
        ),
        findsOneWidget,
      );

      // Action Buttons
      expect(find.text('Connect Google Drive'), findsOneWidget);
      expect(find.text('Maybe Later'), findsOneWidget);

      // Reassurance Footnote
      expect(
        find.text('Your notes remain available on this device even without cloud synchronization.'),
        findsOneWidget,
      );
    });

    testWidgets('GoogleDriveConnectDialog renders polite reminder button when flagged', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: GoogleDriveConnectDialog(isPoliteReminder: true),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Continue Without Cloud Backup'), findsOneWidget);
    });

    testWidgets('GoogleDriveSettingsCard renders connection status, metrics, and actions', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: GoogleDriveSettingsCard(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Google Drive Cloud Storage'), findsOneWidget);
      expect(find.text('Automatic Private Backup & Sync'), findsOneWidget);
      expect(find.text('Not Connected'), findsOneWidget);
      expect(find.text('Connect Google Drive'), findsOneWidget);
    });

    testWidgets('SyncStatusBadge renders correct labels for various sync states', (tester) async {
      // 1. Explicit Sync Failed
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SyncStatusBadge(status: SyncUiStatus.error),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sync Failed'), findsOneWidget);

      // 2. Explicit Synchronizing (uses pump instead of pumpAndSettle due to CircularProgressIndicator animation)
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SyncStatusBadge(status: SyncUiStatus.syncing),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Synchronizing...'), findsOneWidget);

      // 3. Explicit Offline
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SyncStatusBadge(status: SyncUiStatus.offline),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Offline'), findsOneWidget);

      // 4. Default unconnected state renders Backup Required
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SyncStatusBadge(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Backup Required'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen renders branded header, inputs, and submit button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ResetPasswordScreen(code: 'test_code_12345'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('Verification / Action Code'), findsOneWidget);
      expect(find.text('test_code_12345'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Reset My Password'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);
    });

    test('GoogleDriveState cleanly isolates isConnecting and isSyncing to prevent infinite loading', () {
      const state = GoogleDriveState(
        status: DriveConnectionStatus.connecting,
        isSyncing: false,
      );

      expect(state.isConnecting, isTrue);
      expect(state.isSyncing, isFalse);

      final connectedState = state.copyWith(
        status: DriveConnectionStatus.connected,
        isConnected: true,
        isSyncing: true,
      );

      expect(connectedState.isConnected, isTrue);
      expect(connectedState.isConnecting, isFalse);
      expect(connectedState.isSyncing, isTrue);
    });

    test('GoogleDriveSyncResult model serializes and tracks metrics correctly', () {
      final now = DateTime.now();
      final result = GoogleDriveSyncResult(
        success: true,
        uploadedNotebooks: 4,
        downloadedNotebooks: 2,
        uploadedPages: 16,
        downloadedPages: 8,
        uploadedAttachments: 3,
        conflictCount: 1,
        timestamp: now,
      );

      expect(result.success, isTrue);
      expect(result.uploadedNotebooks, equals(4));
      expect(result.downloadedNotebooks, equals(2));
      expect(result.uploadedPages, equals(16));
      expect(result.downloadedPages, equals(8));
      expect(result.uploadedAttachments, equals(3));
      expect(result.conflictCount, equals(1));
      expect(result.toString(), contains('upNb: 4'));
    });
  });
}
