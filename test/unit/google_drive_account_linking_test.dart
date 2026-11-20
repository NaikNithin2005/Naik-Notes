import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/google_drive_connection_model.dart';

void main() {
  group('GoogleDriveConnectionModel & Account Linking Tests', () {
    test('serializes and deserializes GoogleDriveConnectionModel with Firestore types', () {
      final now = DateTime(2026, 11, 20, 14, 0);
      final model = GoogleDriveConnectionModel(
        provider: 'google_drive',
        connected: true,
        googleAccountEmail: 'student@university.edu',
        googleAccountSubjectId: 'sub_987654321',
        connectedAt: now,
        lastVerifiedAt: now,
        storageProvider: 'google_drive_appdata',
        schemaVersion: 1,
      );

      final map = model.toFirestore();
      expect(map['provider'], equals('google_drive'));
      expect(map['connected'], isTrue);
      expect(map['googleAccountEmail'], equals('student@university.edu'));
      expect(map['googleAccountSubjectId'], equals('sub_987654321'));
      expect(map['storageProvider'], equals('google_drive_appdata'));
      expect(map['schemaVersion'], equals(1));
      expect(map['connectedAt'], isA<Timestamp>());
      expect(map['lastVerifiedAt'], isA<Timestamp>());

      final deserialized = GoogleDriveConnectionModel.fromFirestore(map);
      expect(deserialized.connected, isTrue);
      expect(deserialized.googleAccountEmail, equals('student@university.edu'));
      expect(deserialized.googleAccountSubjectId, equals('sub_987654321'));
      expect(deserialized.storageProvider, equals('google_drive_appdata'));
    });

    test('serializes to and from JSON for local storage and diagnostics', () {
      final now = DateTime(2026, 11, 20, 14, 0);
      final model = GoogleDriveConnectionModel(
        provider: 'google_drive',
        connected: false,
        googleAccountEmail: null,
        connectedAt: null,
        lastVerifiedAt: now,
      );

      final json = model.toJson();
      expect(json['connected'], isFalse);
      expect(json['googleAccountEmail'], isNull);

      final fromJson = GoogleDriveConnectionModel.fromJson(json);
      expect(fromJson.connected, isFalse);
      expect(fromJson.googleAccountEmail, isNull);
      expect(fromJson.lastVerifiedAt, equals(now));
    });

    test('copyWith preserves existing metadata on partial updates', () {
      const initial = GoogleDriveConnectionModel(
        connected: false,
        googleAccountEmail: 'old@gmail.com',
        schemaVersion: 1,
      );

      final updated = initial.copyWith(
        connected: true,
        googleAccountEmail: 'new@gmail.com',
      );

      expect(updated.connected, isTrue);
      expect(updated.googleAccountEmail, equals('new@gmail.com'));
      expect(updated.schemaVersion, equals(1));
    });
  });
}
