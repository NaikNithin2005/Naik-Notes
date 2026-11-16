import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/features/authentication/data/auth_error_handler.dart';

void main() {
  group('AuthErrorHandler Tests', () {
    test('translates invalid-email code to friendly message', () {
      final msg = AuthErrorHandler.fromCode('invalid-email');
      expect(msg, 'Please enter a valid email address.');
    });

    test('translates user-not-found code to friendly message', () {
      final msg = AuthErrorHandler.fromCode('user-not-found');
      expect(msg, contains('No account found with this email'));
    });

    test('translates wrong-password and invalid-credential codes', () {
      expect(
        AuthErrorHandler.fromCode('wrong-password'),
        contains('Incorrect email or password'),
      );
      expect(
        AuthErrorHandler.fromCode('invalid-credential'),
        contains('Incorrect email or password'),
      );
      expect(
        AuthErrorHandler.fromCode('INVALID_LOGIN_CREDENTIALS'),
        contains('Incorrect email or password'),
      );
    });

    test('translates email-already-in-use code', () {
      final msg = AuthErrorHandler.fromCode('email-already-in-use');
      expect(msg, contains('An account already exists'));
    });

    test('translates weak-password code', () {
      final msg = AuthErrorHandler.fromCode('weak-password');
      expect(msg, contains('password is too weak'));
    });

    test('translates user-disabled code', () {
      final msg = AuthErrorHandler.fromCode('user-disabled');
      expect(msg, contains('account has been disabled'));
    });

    test('translates operation-not-allowed code', () {
      final msg = AuthErrorHandler.fromCode('operation-not-allowed');
      expect(msg, contains('This sign-in method is currently disabled'));
      expect(msg, contains('Email & Password'));
    });

    test('translates network-request-failed code', () {
      final msg = AuthErrorHandler.fromCode('network-request-failed');
      expect(msg, contains('Network connection failed'));
    });

    test('translates internal-error and channel-error codes', () {
      final msg = AuthErrorHandler.fromCode('internal-error');
      expect(msg, contains('temporary error'));
    });

    test('translates non-mobile unsupported operation exception', () {
      final msg = AuthErrorHandler.handle(
        Exception('Operation is not supported on non-mobile systems.'),
      );
      expect(msg, contains('natively on Android and iPadOS'));
      expect(msg, contains('Email and Password'));
    });

    test('translates SMS region restriction exception', () {
      final msg = AuthErrorHandler.handle(
        Exception(
          'SMS unable to be sent until this region enabled by the app developer.',
        ),
      );
      expect(msg, contains('SMS verification is restricted by region'));
      expect(msg, contains('SMS Region Policy'));
    });

    test('translates Google certificate hash missing exception', () {
      final msg = AuthErrorHandler.handle(
        Exception('ApiException: 10: certificate hash verification failed'),
      );
      expect(msg, contains('Google Sign-In configuration required'));
      expect(msg, contains('BB:42:0F:07:F9:08:43:69:3D:54:93:1A:02:A8:09:9B:46:F8:66:E7'));
    });
  });
}

