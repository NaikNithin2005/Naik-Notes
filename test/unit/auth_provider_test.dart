import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/user_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';

class MockAuthRepository implements AuthRepository {
  AppUser? _user = AppUser.guest();

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
  Future<AppUser> continueAsGuest() async {
    _user = AppUser.guest();
    return _user!;
  }

  @override
  Future<void> logout() async {
    _user = null;
  }

  @override
  Future<AppUser?> restoreSession() async {
    return _user;
  }
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

    test('initializes with guest user enabling instant offline use', () {
      final container = createContainer();
      final authState = container.read(authProvider);

      expect(authState.isAuthenticated, true);
      expect(authState.isGuest, true);
      expect(authState.user?.displayName, 'Guest Writer');
    });

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
      expect(state.isGuest, false);
      expect(state.user?.displayName, 'Ada Lovelace');
      expect(state.user?.email, 'newuser@naiknotes.com');
    });

    test('logout resets session back to guest profile', () async {
      final container = createContainer();
      final notifier = container.read(authProvider.notifier);

      await notifier.login('test@naiknotes.com', 'securePass123');
      expect(container.read(authProvider).isGuest, false);

      await notifier.logout();
      final state = container.read(authProvider);
      expect(state.isGuest, true);
      expect(state.user?.displayName, 'Guest Writer');
    });
  });
}
