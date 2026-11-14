import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/features/dashboard/presentation/widgets/sync_status_badge.dart';
import 'package:naik_notes/features/sync/data/sync_provider.dart';
import 'package:naik_notes/features/sync/presentation/widgets/sync_details_dialog.dart';

void main() {
  group('Sync UI & Diagnostics Widget Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'SyncStatusBadge renders synced, syncing, offline and error labels',
      (tester) async {
        // 1. Synced
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SyncStatusBadge(status: SyncUiStatus.synced),
              ),
            ),
          ),
        );
        expect(find.text('Synced'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);

        // 2. Syncing
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SyncStatusBadge(status: SyncUiStatus.syncing),
              ),
            ),
          ),
        );
        expect(find.text('Syncing...'), findsOneWidget);
        expect(find.byIcon(Icons.sync_rounded), findsOneWidget);

        // 3. Offline
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: SyncStatusBadge(status: SyncUiStatus.offline),
              ),
            ),
          ),
        );
        expect(find.text('Offline'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

        // 4. Error
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(body: SyncStatusBadge(status: SyncUiStatus.error)),
            ),
          ),
        );
        expect(find.text('Sync Error'), findsOneWidget);
        expect(find.byIcon(Icons.sync_problem_rounded), findsOneWidget);
      },
    );

    testWidgets('Tapping SyncStatusBadge opens SyncDetailsDialog modal', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(child: SyncStatusBadge(status: SyncUiStatus.synced)),
            ),
          ),
        ),
      );

      expect(find.text('Synced'), findsOneWidget);
      await tester.tap(find.byType(SyncStatusBadge));
      await tester.pumpAndSettle();

      // Modal dialog should now be visible
      expect(find.byType(SyncDetailsDialog), findsOneWidget);
      expect(find.text('Cloud Synchronization'), findsOneWidget);
      expect(find.text('Pending Queue'), findsOneWidget);
      expect(find.text('Backend Endpoint'), findsOneWidget);
      expect(find.text('Automatic Synchronization'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(SyncDetailsDialog), findsNothing);
    });

    testWidgets('SyncDetailsDialog allows toggling automatic synchronization', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: const MaterialApp(home: Scaffold(body: SyncDetailsDialog())),
        ),
      );

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final initialSwitch = tester.widget<Switch>(switchFinder);
      expect(initialSwitch.value, isTrue);

      // Toggle switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      final updatedSwitch = tester.widget<Switch>(switchFinder);
      expect(updatedSwitch.value, isFalse);
    });
  });
}
