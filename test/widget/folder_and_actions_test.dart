import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/app.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/folder_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/user_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/data/repositories/folder_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/dashboard/presentation/widgets/notebook_card.dart';
import 'package:naik_notes/features/folders/presentation/widgets/create_folder_dialog.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/move_to_folder_dialog.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/rename_notebook_dialog.dart';

class _MockFolderAuthRepo implements AuthRepository {
  final AppUser _user = AppUser(
    id: 'user-default',
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
  group('Dashboard Folders & Notebook Actions Widget Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftFolderRepository folderRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      folderRepo = DriftFolderRepository(db);

      final now = DateTime.now();
      await folderRepo.saveFolder(
        Folder(
          id: 'folder-math-sci',
          ownerId: 'user-default',
          name: 'Mathematics & Science',
          colorHex: '#1E2A38',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await folderRepo.saveFolder(
        Folder(
          id: 'folder-personal',
          ownerId: 'user-default',
          name: 'Personal & Journal',
          colorHex: '#8B4513',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb-test-1',
          ownerId: 'user-default',
          title: 'Mathematics I',
          description: 'Calculus and Linear Algebra',
          coverId: 'classic_leather',
          coverColorHex: '#8B4513',
          paperTemplateId: 'college_ruled',
          pageCount: 3,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          notebookRepositoryProvider.overrideWithValue(notebookRepo),
          folderRepositoryProvider.overrideWithValue(folderRepo),
          authRepositoryProvider.overrideWithValue(_MockFolderAuthRepo()),
        ],
        child: const NaikNotesApp(),
      );
    }

    testWidgets('renders folder chips and "+ New Folder" action on dashboard', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Folder chips should be visible
      expect(find.text('All Folders'), findsOneWidget);
      expect(find.text('Unfiled'), findsOneWidget);
      expect(find.text('New Folder'), findsOneWidget);
      expect(find.text('Mathematics & Science'), findsOneWidget);
      expect(find.text('Personal & Journal'), findsOneWidget);
    });

    testWidgets('opens CreateFolderDialog and validates empty input', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Scroll to and tap "New Folder" chip
      await tester.ensureVisible(find.text('New Folder'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('New Folder'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(CreateFolderDialog), findsOneWidget);
      expect(find.text('Create New Folder'), findsOneWidget);

      // Tap Create Folder without entering name
      await tester.tap(find.widgetWithText(FilledButton, 'Create Folder'));
      await tester.pumpAndSettle();

      // Validation error appears
      expect(find.text('Please enter a folder name'), findsOneWidget);
    });

    testWidgets('displays notebook context menu with full action list', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Find first notebook card
      expect(find.byType(NotebookCard), findsWidgets);

      // Find the popup menu button on the first card
      final moreButton = find.byIcon(Icons.more_vert_rounded).first;
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Check all actions are present
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Move to Folder'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('opens RenameNotebookDialog and updates title', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert_rounded).first;
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.byType(RenameNotebookDialog), findsOneWidget);
      expect(find.text('Rename Notebook'), findsOneWidget);
    });

    testWidgets('opens MoveToFolderDialog with folder choices', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final moreButton = find.byIcon(Icons.more_vert_rounded).first;
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Move to Folder'));
      await tester.pumpAndSettle();

      expect(find.byType(MoveToFolderDialog), findsOneWidget);
      expect(find.text('None (Unfiled)'), findsOneWidget);
    });
  });
}
