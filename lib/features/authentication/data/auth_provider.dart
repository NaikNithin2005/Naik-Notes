import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/firebase_auth_repository.dart';

/// Authentication state model for Naik Notes.
class AuthState {
  final AppUser? user;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final String? verificationId;
  final int? resendToken;

  const AuthState({
    this.user,
    this.isLoading = false,
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
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      verificationId:
          clearPhoneAuth ? null : (verificationId ?? this.verificationId),
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
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    final initial = _repository.currentUser;
    return AuthState(user: initial);
  }

  /// Clears any transient status banners.
  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  /// Email & Password Sign In.
  Future<bool> login(String email, String password) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _repository.login(email, password);
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    } finally {
      if (state.isLoading) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Email & Password Registration.
  Future<bool> register(
    String email,
    String password,
    String displayName,
  ) async {
    if (state.isLoading) return false;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final user = await _repository.register(email, password, displayName);
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
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
          state = state.copyWith(isLoading: false, errorMessage: errorMessage);
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
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
        errorMessage: 'Please enter your phone number to receive a verification code first.',
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
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
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
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

  /// Account Logout.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.logout();
    } finally {
      state = const AuthState();
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
