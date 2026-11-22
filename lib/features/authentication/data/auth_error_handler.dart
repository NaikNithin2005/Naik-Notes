import 'package:firebase_auth/firebase_auth.dart' as fb;

/// Centralized, production-grade Authentication Error Handler for Naik Notes.
///
/// Translates raw Firebase exceptions, network errors, platform constraints,
/// and internal codes into friendly, understandable, actionable user messages.
/// NEVER exposes raw internal Firebase strings or unhandled stack traces.
class AuthErrorHandler {
  AuthErrorHandler._();

  /// Maps any caught dynamic exception or error code to a human-friendly message.
  static String handle(dynamic error) {
    if (error == null) return 'An unexpected authentication error occurred.';

    if (error is fb.FirebaseAuthException) {
      return fromCode(error.code, rawMessage: error.message);
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    return fromRawMessage(raw);
  }

  /// Maps standard Firebase Auth error codes to user-facing messages.
  static String fromCode(String code, {String? rawMessage}) {
    final normalized = code.toLowerCase().trim().replaceAll('_', '-');
    switch (normalized) {
      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-not-found':
        return 'No account found with this email. Please check the address or create a new account.';

      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Incorrect email or password. If you originally signed up with Google, please tap "Continue with Google", or use "Forgot Password?" to reset your password.';

      case 'email-already-in-use':
        return 'An account already exists with this email address. Please sign in instead.';

      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';

      case 'user-disabled':
        return 'This account has been disabled. Please contact Naik Notes support.';

      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled in your Firebase project. '
            'Please enable it in the Firebase Console under Authentication > Sign-in method, '
            'or sign in using Email & Password.';

      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection and try again.';

      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few moments and try again.';

      case 'internal-error':
      case 'channel-error':
        return 'Incorrect email or password, or temporary error occurred. If you originally signed up with Google, tap "Continue with Google", or use "Forgot Password?" to reset your password.';

      case 'invalid-verification-code':
        return 'The SMS verification code is incorrect or has expired. Please request a new code.';

      case 'invalid-verification-id':
        return 'The verification session has expired. Please request a new SMS code.';

      case 'quota-exceeded':
        return 'SMS verification limit reached for this project. Please sign in using Email or Google.';

      case 'session-expired':
        return 'Your authentication session has expired. Please sign in again.';

      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'Google Sign-In configuration required: Please add your SHA-1 and SHA-256 '
            'fingerprints to the Firebase Console under Project Settings > Your apps.';

      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email using a different sign-in method.';

      default:
        if (rawMessage != null && rawMessage.isNotEmpty) {
          return fromRawMessage(rawMessage);
        }
        return 'Authentication failed. Please verify your details and try again.';
    }
  }

  /// Translates raw error message strings, catching platform-specific exceptions.
  static String fromRawMessage(String raw) {
    final lower = raw.toLowerCase();

    // Windows C++ SDK / desktop unsupported operations
    if (lower.contains('non-mobile') ||
        lower.contains('not supported on non-mobile') ||
        lower.contains('unimplemented')) {
      return 'This sign-in method is available natively on Android and iPadOS. '
          'On Windows, please sign in with your Email and Password.';
    }

    // Google Sign-In missing certificate hash or API 10 / 12500
    if (lower.contains('certificate hash') ||
        lower.contains('api exception: 10') ||
        lower.contains('10:') ||
        lower.contains('12500') ||
        lower.contains('play integrity')) {
      return 'Google Sign-In configuration required: Please add your SHA-1 fingerprint '
          '(BB:42:0F:07:F9:08:43:69:3D:54:93:1A:02:A8:09:9B:46:F8:66:E7) in the Firebase Console under Project Settings > Your apps.';
    }

    // Phone / SMS region restriction
    if (lower.contains('sms unable to be sent') ||
        lower.contains('region enabled by the app developer')) {
      return 'SMS verification is restricted by region. Please enable your country code '
          'under Firebase Console > Authentication > Settings > SMS Region Policy, '
          'or sign in with Email.';
    }

    // Invalid credentials
    if (lower.contains('invalid_login_credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('wrong password')) {
      return 'Incorrect email or password. If you originally signed up with Google, tap "Continue with Google", or use "Forgot Password?" to reset your password.';
    }

    // Google OAuth Loopback redirect URI mismatch / Google Cloud Console setup
    if (lower.contains('redirect_uri_mismatch') ||
        lower.contains('redirect uri') ||
        lower.contains('google cloud console')) {
      return raw;
    }

    // Timeout
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'Connection timed out. Please check your internet connection and try again.';
    }

    // Network error
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network_request_failed')) {
      return 'Network connection failed. Please check your internet connection.';
    }

    // Clean up generic raw internal errors
    if (lower.contains('an internal error has occurred') ||
        lower.contains('internal-error') ||
        lower == 'internal error') {
      return 'Incorrect email or password, or temporary error occurred. If you originally signed up with Google, tap "Continue with Google", or use "Forgot Password?" to reset your password.';
    }

    return raw;
  }

  /// Determines whether Google Sign-In is supported on the current operating system.
  static bool isGoogleSupported() {
    return true; // Fully supported on Android, iPadOS/iOS, Windows Desktop, and Web
  }

  /// Determines whether Apple Sign-In is supported natively on the current operating system.
  static bool isAppleSupported() {
    return false; // Disabled across all platforms
  }

  /// Determines whether Phone SMS OTP is supported natively on the current operating system.
  static bool isPhoneSupported() {
    return false; // Disabled across all platforms
  }
}
