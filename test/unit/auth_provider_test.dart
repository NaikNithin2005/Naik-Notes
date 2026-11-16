import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/user_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Future<AppUser> login(String email, String password) async {
    if (password == 'wrong') {
      throw Exception('Invalid credentials.');
    }
    _user = AppUser(
      id: 'mock_uid_1',
      email: email,
      displayName: 'Authenticated User',
      token: 'mock_jwt_token',
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
    String displayName,
  ) async {
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    _user = AppUser(
      id: 'mock_uid_2',
      email: email,
      displayName: displayName,
      token: 'mock_jwt_token',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    _user = AppUser(
      id: 'mock_google_uid',
      email: 'google@naiknotes.com',
      displayName: 'Google User',
      token: 'mock_google_token',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<AppUser> signInWithApple() async {
    _user = AppUser(
      id: 'mock_apple_uid',
      email: 'apple@naiknotes.com',
      displayName: 'Apple User',
      token: 'mock_apple_token',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(AppUser user)? onVerificationCompleted,
  }) async {
    onCodeSent('mock_verification_id_123', null);
  }

  @override
  Future<AppUser> verifyPhoneOtp(String verificationId, String smsCode) async {
    if (smsCode != '123456') {
      throw Exception('Invalid verification code');
    }
    _user = AppUser(
      id: 'mock_phone_uid',
      email: 'phone@naiknotes.com',
      displayName: 'Phone User',
      token: 'mock_phone_token',
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<void> logout() async {
    _user = null;
  }

  @override
  Future<void> deleteAccount() async {
    _user = null;
  }

  @override
  Future<List<Map<String, dynamic>>> getRegisteredDevices(String uid) async {
    return [
      {
        'deviceId': 'mock_device_1',
        'deviceName': 'Windows PC',
        'platform': 'windows',
        'isCurrent': true,
      },
    ];
  }

  @override
  Future<void> removeRegisteredDevice(String uid, String deviceId) async {}

  @override
  Future<AppUser?> restoreSession() async {
    return _user;
  }

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_user);

  @override
  Future<void> sendPasswordReset(String email) async {}
}

void main() {
  group('AuthNotifier & AuthState Tests', () {
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'initializes with unauthenticated user enforcing authentic credentials',
      () {
        final container = createContainer();
        final authState = container.read(authProvider);

        expect(authState.isAuthenticated, false);
        expect(authState.isGuest, false);
        expect(authState.user, isNull);
      },
    );

    test(
      'successful login updates user to authenticated non-guest state',
      () async {
        final container = createContainer();
        final notifier = container.read(authProvider.notifier);

        final success = await notifier.login(
          'test@naiknotes.com',
          'securePass123',
        );

        expect(success, true);
        final state = container.read(authProvider);
        expect(state.isAuthenticated, true);
        expect(state.isGuest, false);
        expect(state.user?.email, 'test@naiknotes.com');
        expect(state.errorMessage, isNull);
      },
    );

    test('failed login sets error message and retains state', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.login('test@naiknotes.com', 'wrong');

      expect(success, false);
      final state = container.read(authProvider);
      expect(state.errorMessage, contains('Invalid credentials'));
    });

    test('registration updates user state with provided name', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      final success = await notifier.register(
        'newuser@naiknotes.com',
        'securePass123',
        'Ada Lovelace',
      );

      expect(success, true);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.isGuest, false);
      expect(state.user?.displayName, 'Ada Lovelace');
      expect(state.user?.email, 'newuser@naiknotes.com');
    });

    test('logout resets session to unauthenticated state', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.login('test@naiknotes.com', 'securePass123');
      expect(container.read(authProvider).isAuthenticated, true);

      await notifier.logout();
      final state = container.read(authProvider);
      expect(state.isAuthenticated, false);
      expect(state.user, isNull);
    });
  });
}
