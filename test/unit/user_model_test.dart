import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/user_model.dart';

void main() {
  group('AppUser Model Tests', () {
    final now = DateTime(2026, 11, 14, 18, 0, 0);

    test('instantiates with required fields and defaults', () {
      final user = AppUser(
        id: 'usr-123',
        email: 'physicist@naiknotes.com',
        displayName: 'Richard Feynman',
        createdAt: now,
        updatedAt: now,
      );

      expect(user.id, 'usr-123');
      expect(user.email, 'physicist@naiknotes.com');
      expect(user.displayName, 'Richard Feynman');
      expect(user.isGuest, false);
      expect(user.token, isNull);
    });

    test('serializes to JSON and deserializes correctly', () {
      final user = AppUser(
        id: 'usr-456',
        email: 'galileo@naiknotes.com',
        displayName: 'Galileo Galilei',
        photoUrl: 'https://example.com/avatar.png',
        token: 'auth_token_sample',
        isGuest: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = user.toJson();
      final recreated = AppUser.fromJson(json);

      expect(recreated.id, user.id);
      expect(recreated.email, user.email);
      expect(recreated.displayName, user.displayName);
      expect(recreated.photoUrl, user.photoUrl);
      expect(recreated.token, user.token);
      expect(recreated.isGuest, false);
    });

    test('guest factory creates standard offline guest profile', () {
      final guest = AppUser.guest();
      expect(guest.isGuest, true);
      expect(guest.displayName, 'Guest Writer');
      expect(guest.id, 'local_guest_user');
    });

    test('copyWith updates specified attributes', () {
      final user = AppUser.guest();
      final updated = user.copyWith(
        displayName: 'Nithin Naik',
        email: 'nithin@example.com',
        isGuest: false,
      );

      expect(updated.displayName, 'Nithin Naik');
      expect(updated.email, 'nithin@example.com');
      expect(updated.isGuest, false);
    });
  });
}
