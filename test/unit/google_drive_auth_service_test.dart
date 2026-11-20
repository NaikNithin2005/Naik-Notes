import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/services/storage/google_drive_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleDriveAuthService Scope & Security Tests', () {
    test('enforces exact least-privilege appDataScope (no broad drive scope)', () {
      expect(
        GoogleDriveAuthService.appDataScope,
        equals('https://www.googleapis.com/auth/drive.appdata'),
      );
      // Strictly verify broad drive scope is NOT used
      expect(
        GoogleDriveAuthService.appDataScope,
        isNot(equals('https://www.googleapis.com/auth/drive')),
      );
      expect(
        GoogleDriveAuthService.appDataScope,
        isNot(equals('https://www.googleapis.com/auth/drive.file')),
      );
    });

    test('GoogleDriveCredentials expiration check behaves accurately', () {
      final validCreds = GoogleDriveCredentials(
        accessToken: 'valid_token_123',
        refreshToken: 'refresh_token_abc',
        expiry: DateTime.now().add(const Duration(minutes: 30)),
        accountEmail: 'user@example.com',
        subjectId: 'sub_12345',
      );

      expect(validCreds.isExpired, isFalse);

      final expiredCreds = GoogleDriveCredentials(
        accessToken: 'expired_token_123',
        refreshToken: 'refresh_token_abc',
        expiry: DateTime.now().subtract(const Duration(seconds: 10)),
        accountEmail: 'user@example.com',
        subjectId: 'sub_12345',
      );

      expect(expiredCreds.isExpired, isTrue);

      // Token expiring in less than 60 seconds should be treated as expired
      final nearingExpiryCreds = GoogleDriveCredentials(
        accessToken: 'near_expiry_token',
        refreshToken: 'refresh_token_abc',
        expiry: DateTime.now().add(const Duration(seconds: 30)),
        accountEmail: 'user@example.com',
      );

      expect(nearingExpiryCreds.isExpired, isTrue);
    });

    test('GoogleDriveAccountMismatchException formats descriptive security error message', () {
      final exception = GoogleDriveAccountMismatchException(
        expectedEmail: 'primary@gmail.com',
        attemptedEmail: 'intruder@gmail.com',
      );

      expect(exception.expectedEmail, equals('primary@gmail.com'));
      expect(exception.attemptedEmail, equals('intruder@gmail.com'));
      expect(
        exception.toString(),
        contains('Google Drive Account Mismatch'),
      );
      expect(exception.toString(), contains('primary@gmail.com'));
      expect(exception.toString(), contains('intruder@gmail.com'));
    });
  });
}
