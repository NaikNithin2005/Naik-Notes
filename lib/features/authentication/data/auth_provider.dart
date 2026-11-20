import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/firebase_auth_repository.dart';
import '../../folders/data/folder_provider.dart';
import '../../notebooks/data/notebook_provider.dart';
import '../../sync/data/sync_provider.dart';
import 'auth_error_handler.dart';

/// Lifecycle state for authentication operations.
enum AuthStatus {
  idle,
  validating,
  authenticating,
  success,
  error,
}

/// Authentication state model for Naik Notes.
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final AuthStatus authStatus;
  final String? errorMessage;
  final String? successMessage;
  final String? verificationId;
  final int? resendToken;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.authStatus = AuthStatus.idle,
    this.errorMessage,
    this.successMessage,
    this.verificationId,
    this.resendToken,
  });

  /// User is strictly authenticated if an identity profile exists.
  bool get isAuthenticated => user != null;

  /// Guest mode is permanently disabled.
  bool get isGuest => false;

  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    AuthStatus? authStatus,
    String? errorMessage,
    String? successMessage,
    String? verificationId,
    int? resendToken,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearUser = false,
    bool clearPhoneAuth = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      authStatus: authStatus ?? this.authStatus,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      verificationId: clearPhoneAuth
          ? null
          : (verificationId ?? this.verificationId),
      resendToken: clearPhoneAuth ? null : (resendToken ?? this.resendToken),
    );
  }
}

/// Global provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// State notifier managing user authentication and active sessions.
class AuthNotifier extends Notifier<AuthState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    ref.watch(authRepositoryProvider);
    final initial = _repository.currentUser;

    // Listen to reactive auth state changes to auto-restore active sessions with zero latency
    final sub = _repository.authStateChanges.listen((user) {
      if (user != state.user) {
        state = state.copyWith(
          user: user,
          clearUser: user == null,
          isLoading: false,
          authStatus: user != null ? AuthStatus.success : AuthStatus.idle,
        );
      }
    });
    ref.onDispose(() => sub.cancel());

    return AuthState(user: initial);
  }

  /// Clears any transient status banners.
  void clearMessages() {
    state = state.copyWith(
      clearError: true,
      clearSuccess: true,
      authStatus: AuthStatus.idle,
    );
  }

  /// Email & Password Sign In with strict lifecycle.
  Future<bool> login(String email, String password) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      authStatus: AuthStatus.validating,
      clearError: true,
      clearSuccess: true,
    );

    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || password.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        authStatus: AuthStatus.error,
        errorMessage: 'Email and password are required.',
      );
      return false;
    }

    state = state.copyWith(authStatus: AuthStatus.authenticating);
    try {
      final user = await _repository.login(cleanEmail, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        authStatus: AuthStatus.success,
        clearError: true,
        clearSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        authStatus: AuthStatus.error,
        errorMessage: AuthErrorHandler.handle(e),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Email & Password Registration with validation and Firestore profile initialization.
  Future<bool> register(
    String email,
    String password,
    String displayName, {
    String? confirmPassword,
  }) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      authStatus: AuthStatus.validating,
      clearError: true,
      clearSuccess: true,
    );

    final cleanName = displayName.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        authStatus: AuthStatus.error,
        errorMessage: 'Please enter your full name.',
      );
      return false;
    }
    if (cleanEmail.isEmpty ||
        !cleanEmail.contains('@') ||
        !cleanEmail.contains('.')) {
      state = state.copyWith(
        isLoading: false,
        authStatus: AuthStatus.error,
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }
    if (password.length < 6) {
      state = state.copyWith(
        isLoading: false,
        authStatus: AuthStatus.error,
        errorMessage: 'Password must be at least 6 characters long.',
      );
      return false;
    }
    if (confirmPassword != null && confirmPassword != password) {
      state = state.copyWith(
        isLoading: false,
        authStatus: AuthStatus.error,
        errorMessage: 'Passwords do not match.',
      );
      return false;
    }

    state = state.copyWith(authStatus: AuthStatus.authenticating);
    try {
      final user = await _repository.register(
        cleanEmail,
        password,
        cleanName,
        confirmPassword: confirmPassword,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        authStatus: AuthStatus.success,
        clearError: true,
        clearSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        authStatus: AuthStatus.error,
        errorMessage: AuthErrorHandler.handle(e),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Google Authentication OAuth Sign-In.
  Future<bool> signInWithGoogle() async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _repository.signInWithGoogle();
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearError: true,
        clearSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Apple Sign-In.
  Future<bool> signInWithApple() async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _repository.signInWithApple();
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearError: true,
        clearSuccess: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Phone Number & OTP - Send SMS code.
  Future<bool> sendPhoneOtp(String phoneNumber) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );

    bool codeSentSuccess = false;
    try {
      await _repository.sendPhoneOtp(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId, resendToken) {
          codeSentSuccess = true;
          state = state.copyWith(
            isLoading: false,
            verificationId: verificationId,
            resendToken: resendToken,
            successMessage: 'Verification code sent to $phoneNumber',
          );
        },
        onError: (errorMessage) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: AuthErrorHandler.handle(errorMessage),
          );
        },
        onVerificationCompleted: (user) {
          state = state.copyWith(
            user: user,
            isLoading: false,
            clearError: true,
            clearSuccess: true,
          );
        },
      );
      return codeSentSuccess;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Phone Number & OTP - Verify SMS code.
  Future<bool> verifyPhoneOtp(String smsCode) async {
    final verifId = state.verificationId;
    if (verifId == null) {
      state = state.copyWith(
        errorMessage:
            'Please enter your phone number to receive a verification code first.',
      );
      return false;
    }
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _repository.verifyPhoneOtp(verifId, smsCode);
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearError: true,
        clearSuccess: true,
        clearPhoneAuth: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Password reset email.
  Future<bool> sendPasswordReset(String email) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repository.sendPasswordReset(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent to $email',
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: AuthErrorHandler.handle(e),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Account deletion with confirmation.
  Future<bool> deleteAccount() async {
    if (state.isLoading) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteAccount();
      state = const AuthState();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Complete Account Logout with full session and provider cleanup.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.logout();
    } finally {
      state = const AuthState();
      try {
        ref.invalidate(notebooksProvider);
        ref.invalidate(foldersProvider);
        ref.read(selectedFolderProvider.notifier).clearSelection();
        ref.invalidate(syncProvider);
        ref.read(firebaseSyncServiceProvider).dispose();
      } catch (_) {}
    }
  }
}

/// Global provider for AuthNotifier state.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provider fetching registered devices for the active user.
final registeredDevicesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final auth = ref.watch(authProvider);
      final repo = ref.watch(authRepositoryProvider);
      if (auth.user == null) return [];
      return repo.getRegisteredDevices(auth.user!.id);
    });
