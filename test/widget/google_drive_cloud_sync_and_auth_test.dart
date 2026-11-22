import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/features/authentication/presentation/screens/reset_password_screen.dart';
import 'package:naik_notes/features/dashboard/presentation/widgets/sync_status_badge.dart';
import 'package:naik_notes/features/history/presentation/widgets/notes_history_sheet.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';
import 'package:naik_notes/features/storage/presentation/widgets/google_drive_connect_dialog.dart';
import 'package:naik_notes/features/settings/presentation/widgets/google_drive_settings_card.dart';
import 'package:naik_notes/features/sync/data/sync_provider.dart';
import 'package:naik_notes/services/history/note_history_service.dart';
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
        deletedCount: 1,
        uploadedPages: 16,
        downloadedPages: 8,
        uploadedAttachments: 3,
        conflictCount: 1,
        timestamp: now,
      );

      expect(result.success, isTrue);
      expect(result.uploadedNotebooks, equals(4));
      expect(result.downloadedNotebooks, equals(2));
      expect(result.deletedCount, equals(1));
      expect(result.uploadedPages, equals(16));
      expect(result.downloadedPages, equals(8));
      expect(result.uploadedAttachments, equals(3));
      expect(result.conflictCount, equals(1));
      expect(result.hasChanges, isTrue);
      expect(result.toString(), contains('upNb: 4'));
      expect(result.toString(), contains('deleted: 1'));
    });

    test('NoteActivityEntry serializes and deserializes accurately with date, device, and user', () {
      final entry = NoteActivityEntry(
        id: 'act-1',
        noteId: 'nb-123',
        noteTitle: 'Calculus Notes',
        action: NoteActionType.created,
        timestamp: DateTime(2026, 11, 21, 14, 30),
        deviceName: 'Windows Desktop',
        userEmail: 'student@example.com',
        details: 'Initial creation',
      );

      final json = entry.toJson();
      expect(json['id'], equals('act-1'));
      expect(json['noteId'], equals('nb-123'));
      expect(json['noteTitle'], equals('Calculus Notes'));
      expect(json['action'], equals('created'));
      expect(json['deviceName'], equals('Windows Desktop'));
      expect(json['userEmail'], equals('student@example.com'));

      final fromJson = NoteActivityEntry.fromJson(json);
      expect(fromJson.id, equals('act-1'));
      expect(fromJson.noteTitle, equals('Calculus Notes'));
      expect(fromJson.action, equals(NoteActionType.created));
      expect(fromJson.userEmail, equals('student@example.com'));
      expect(fromJson.deviceName, equals('Windows Desktop'));
    });

    testWidgets('NotesHistorySheet renders title, filters, and activity entries', (tester) async {
      final testEntries = [
        NoteActivityEntry(
          id: 'test-act-1',
          noteId: 'nb-1',
          noteTitle: 'Physics Semester 1',
          action: NoteActionType.created,
          timestamp: DateTime(2026, 11, 21, 10, 0),
          deviceName: 'iPad Pro',
          userEmail: 'naik@example.com',
          details: 'Notebook created',
        ),
        NoteActivityEntry(
          id: 'test-act-2',
          noteId: 'nb-2',
          noteTitle: 'Old Drafts',
          action: NoteActionType.deleted,
          timestamp: DateTime(2026, 11, 21, 11, 0),
          deviceName: 'Windows PC',
          userEmail: 'naik@example.com',
          details: 'Notebook deleted',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            noteHistoryProvider.overrideWith(() => _FakeHistoryNotifier(testEntries)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: NotesHistorySheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Notes & Sync History'), findsOneWidget);
      expect(
        find.text('Timeline of notes created, updated, and deleted across devices'),
        findsOneWidget,
      );

      // Verify Action Filters
      expect(find.text('All Activity'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Updated'), findsOneWidget);
      expect(find.text('Deleted'), findsOneWidget);

      // Verify Entries
      expect(find.text('Physics Semester 1'), findsOneWidget);
      expect(find.text('Old Drafts'), findsOneWidget);
      expect(find.text('iPad Pro'), findsOneWidget);
      expect(find.text('Windows PC'), findsOneWidget);
      expect(find.text('naik@example.com'), findsNWidgets(2));
    });
  });
}

class _FakeHistoryNotifier extends NoteHistoryNotifier {
  final List<NoteActivityEntry> _initial;
  _FakeHistoryNotifier(this._initial);

  @override
  List<NoteActivityEntry> build() => _initial;
}
