import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/app.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/user_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';

class MockSmokeAuthRepository implements AuthRepository {
  final AppUser _user = AppUser(
    id: 'test_user_id',
    email: 'test@naiknotes.com',
    displayName: 'Test User',
    token: 'token',
    isGuest: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  AppUser? get currentUser => _user;
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_user);
  @override
  Future<AppUser> login(String email, String password) async => _user;
  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName,
  ) async => _user;
  @override
  Future<AppUser> signInWithGoogle() async => _user;
  @override
  Future<AppUser> signInWithApple() async => _user;
  @override
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(AppUser user)? onVerificationCompleted,
  }) async => onCodeSent('id', null);
  @override
  Future<AppUser> verifyPhoneOtp(String verificationId, String smsCode) async =>
      _user;
  @override
  Future<void> logout() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<List<Map<String, dynamic>>> getRegisteredDevices(String uid) async =>
      [];
  @override
  Future<void> removeRegisteredDevice(String uid, String deviceId) async {}
  @override
  Future<AppUser?> restoreSession() async => _user;
  @override
  Future<void> sendPasswordReset(String email) async {}
}

void main() {
  group('Naik Notes App Smoke Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository repo;
    late MockSmokeAuthRepository authRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftNotebookRepository(db);
      authRepo = MockSmokeAuthRepository();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders dashboard with brand, search bar and notebook cards', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notebookRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: const NaikNotesApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Brand Name and Tagline
      expect(find.text('Naik Notes'), findsWidgets);

      // Verify Quick Action Buttons
      expect(find.text('New Notebook'), findsOneWidget);
      expect(find.text('Import PDF'), findsOneWidget);

      // Verify Filter Buttons
      expect(find.text('All Notebooks'), findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);

      // Verify Library view displays the provisioned Welcome Notebook
      expect(find.text('Welcome to Naik Notes'), findsWidgets);
    });

    testWidgets('opens Create Notebook dialog and validates input', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notebookRepositoryProvider.overrideWithValue(repo),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
          child: const NaikNotesApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'New Notebook' button
      final newNotebookButton = find.text('New Notebook');
      expect(newNotebookButton, findsOneWidget);
      await tester.tap(newNotebookButton);
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.text('Create New Notebook'), findsOneWidget);
      expect(find.text('Notebook Title *'), findsOneWidget);

      // Tap create button inside dialog without title to trigger validation
      final createButton = find
          .widgetWithText(FilledButton, 'Create Notebook')
          .last;
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a notebook title'), findsOneWidget);

      // Enter valid title
      await tester.enterText(
        find.byType(TextFormField).first,
        'Quantum Mechanics',
      );
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Dialog should close and new notebook should be listed
      expect(find.text('Create New Notebook'), findsNothing);
      expect(find.text('Quantum Mechanics'), findsWidgets);
    });
  });
}
