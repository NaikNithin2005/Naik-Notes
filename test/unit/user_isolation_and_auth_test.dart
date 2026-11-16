import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/user_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/data/repositories/folder_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_user);

  @override
  Future<AppUser> login(String email, String password) async {
    _user = AppUser(
      id: 'uid_${email.split('@').first}',
      email: email,
      displayName: email.split('@').first,
      token: 'jwt_token',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName, {
    String? confirmPassword,
  }) async {
    if (confirmPassword != null && confirmPassword != password) {
      throw Exception('Passwords do not match.');
    }
    _user = AppUser(
      id: 'uid_${email.split('@').first}',
      email: email,
      displayName: displayName,
      token: 'jwt_token',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<AppUser> signInWithGoogle({bool promptAccountSelection = true}) async {
    _user = AppUser(
      id: 'google_user_uid',
      email: 'user@gmail.com',
      displayName: 'Google User',
      token: 'google_token',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<AppUser> signInWithApple() async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(AppUser user)? onVerificationCompleted,
  }) async {}

  @override
  Future<AppUser> verifyPhoneOtp(String verificationId, String smsCode) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> deleteAccount() async {
    _user = null;
  }

  @override
  Future<void> logout() async {
    _user = null;
  }

  @override
  Future<AppUser?> restoreSession() async => _user;

  @override
  Future<List<Map<String, dynamic>>> getRegisteredDevices(String uid) async => [];

  @override
  Future<void> removeRegisteredDevice(String uid, String deviceId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DriftNotebookRepository notebookRepo;
  late DriftFolderRepository folderRepo;
  late _FakeAuthRepository authRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    notebookRepo = DriftNotebookRepository(db);
    folderRepo = DriftFolderRepository(db);
    authRepo = _FakeAuthRepository();
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 6 — Strict User Data Isolation Tests', () {
    test('Notebook repository strictly filters by ownerId', () async {
      final now = DateTime.now();

      // Create notebooks for User A
      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb_a1',
          ownerId: 'user_alice',
          title: "Alice's Secret Journal",
          coverId: 'classic_leather',
          coverColorHex: '#8B4513',
          paperTemplateId: 'college_ruled',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create notebooks for User B
      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb_b1',
          ownerId: 'user_bob',
          title: "Bob's Work Project",
          coverId: 'classic_navy',
          coverColorHex: '#1E2A38',
          paperTemplateId: 'square_grid',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Alice queries her notebooks: MUST NOT see Bob's notebooks
      final aliceNotebooks = await notebookRepo.getAllNotebooks(
        ownerId: 'user_alice',
      );
      expect(aliceNotebooks.length, 1);
      expect(aliceNotebooks.first.id, 'nb_a1');
      expect(aliceNotebooks.first.title, "Alice's Secret Journal");

      // Bob queries his notebooks: MUST NOT see Alice's notebooks
      final bobNotebooks = await notebookRepo.getAllNotebooks(
        ownerId: 'user_bob',
      );
      expect(bobNotebooks.length, 1);
      expect(bobNotebooks.first.id, 'nb_b1');
      expect(bobNotebooks.first.title, "Bob's Work Project");
    });

    test('Folder repository strictly filters by ownerId', () async {
      final now = DateTime.now();

      await db.into(db.foldersTable).insert(
        FoldersTableCompanion.insert(
          id: 'f_a',
          ownerId: const drift.Value('user_alice'),
          name: 'Alice Finance',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.into(db.foldersTable).insert(
        FoldersTableCompanion.insert(
          id: 'f_b',
          ownerId: const drift.Value('user_bob'),
          name: 'Bob Engineering',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final aliceFolders = await folderRepo.getAllFolders(ownerId: 'user_alice');
      expect(aliceFolders.length, 1);
      expect(aliceFolders.first.name, 'Alice Finance');

      final bobFolders = await folderRepo.getAllFolders(ownerId: 'user_bob');
      expect(bobFolders.length, 1);
      expect(bobFolders.first.name, 'Bob Engineering');
    });

    test(
      'Account Switching Lifecycle: User A -> Logout -> User B -> User A',
      () async {
        final testContainer = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            notebookRepositoryProvider.overrideWithValue(notebookRepo),
            folderRepositoryProvider.overrideWithValue(folderRepo),
            authRepositoryProvider.overrideWithValue(authRepo),
          ],
        );
        addTearDown(testContainer.dispose);

        // 1. User Alice logs in
        final aliceLoginSuccess = await testContainer
            .read(authProvider.notifier)
            .login('alice@example.com', 'password123');
        expect(aliceLoginSuccess, isTrue);
        expect(testContainer.read(authProvider).user?.id, 'uid_alice');

        // Alice adds a notebook
        final aliceNb = await testContainer
            .read(notebooksProvider.notifier)
            .addNotebook(
              title: "Alice Private Study",
              coverId: 'classic_leather',
              coverColorHex: '#8B4513',
              paperTemplateId: 'college_ruled',
            );
        expect(aliceNb.ownerId, 'uid_alice');

        // Verify Alice's list contains her notebook
        await testContainer.read(notebooksProvider.notifier).loadForUser('uid_alice');
        var notebooks = testContainer.read(notebooksProvider);
        expect(notebooks.any((n) => n.title == 'Alice Private Study'), isTrue);

        // 2. Alice Logs out
        await testContainer.read(authProvider.notifier).logout();
        expect(testContainer.read(authProvider).isAuthenticated, isFalse);

        // 3. Bob logs in
        final bobLoginSuccess = await testContainer
            .read(authProvider.notifier)
            .login('bob@example.com', 'password123');
        expect(bobLoginSuccess, isTrue);
        expect(testContainer.read(authProvider).user?.id, 'uid_bob');

        // Reload notebooks for Bob: MUST NOT contain Alice's notebook
        await testContainer.read(notebooksProvider.notifier).loadForUser('uid_bob');
        notebooks = testContainer.read(notebooksProvider);
        expect(
          notebooks.any((n) => n.title == 'Alice Private Study'),
          isFalse,
          reason: "User B must NEVER see User A's private notebooks",
        );

        // Bob creates his own notebook
        final bobNb = await testContainer
            .read(notebooksProvider.notifier)
            .addNotebook(
              title: "Bob Architecture Plans",
              coverId: 'classic_navy',
              coverColorHex: '#1E2A38',
              paperTemplateId: 'square_grid',
            );
        expect(bobNb.ownerId, 'uid_bob');

        // 4. Bob logs out
        await testContainer.read(authProvider.notifier).logout();
        expect(testContainer.read(authProvider).isAuthenticated, isFalse);

        // 5. Alice logs back in
        await testContainer
            .read(authProvider.notifier)
            .login('alice@example.com', 'password123');
        await testContainer.read(notebooksProvider.notifier).loadForUser('uid_alice');

        // Alice should see her notebook, and NOT Bob's notebook
        notebooks = testContainer.read(notebooksProvider);
        expect(notebooks.any((n) => n.title == 'Alice Private Study'), isTrue);
        expect(notebooks.any((n) => n.title == 'Bob Architecture Plans'), isFalse);
      },
    );

    test('Auth lifecycle state transitions: idle -> validating -> authenticating -> success', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authProvider).authStatus, AuthStatus.idle);

      final loginFuture = container
          .read(authProvider.notifier)
          .login('test@domain.com', 'password123');

      final success = await loginFuture;
      expect(success, isTrue);
      expect(container.read(authProvider).authStatus, AuthStatus.success);
      expect(container.read(authProvider).isAuthenticated, isTrue);
    });

    test('Registration validates password confirmation', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepo),
        ],
      );
      addTearDown(container.dispose);

      // Password mismatch
      final failed = await container
          .read(authProvider.notifier)
          .register(
            'new@domain.com',
            'password123',
            'New User',
            confirmPassword: 'different_password',
          );

      expect(failed, isFalse);
      expect(container.read(authProvider).authStatus, AuthStatus.error);
      expect(container.read(authProvider).errorMessage, 'Passwords do not match.');
    });
  });
}
