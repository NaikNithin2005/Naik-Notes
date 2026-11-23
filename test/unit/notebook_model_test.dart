import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/notebook_model.dart';

void main() {
  group('Notebook Model Tests', () {
    final now = DateTime(2026, 11, 14, 12, 0, 0);

    test('instantiates with required fields and defaults', () {
      final nb = Notebook(
        id: 'test-1',
        ownerId: 'user-1',
        title: 'Physics Mechanics',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );

      expect(nb.id, 'test-1');
      expect(nb.title, 'Physics Mechanics');
      expect(nb.pageSize, 'A4');
      expect(nb.orientation, 'portrait');
      expect(nb.pageCount, 1);
      expect(nb.isFavorite, false);
      expect(nb.revision, 1);
    });

    test('serializes to JSON and deserializes correctly', () {
      final original = Notebook(
        id: 'nb-json-test',
        ownerId: 'user-42',
        title: 'Organic Chemistry',
        description: 'Semester 1 notes',
        coverId: 'dark_academia',
        coverColorHex: '#1E2A38',
        paperTemplateId: 'square_grid',
        orientation: 'landscape',
        pageSize: 'Letter',
        pageCount: 18,
        isFavorite: true,
        revision: 3,
        createdAt: now,
        updatedAt: now,
      );

      final json = original.toJson();
      final recreated = Notebook.fromJson(json);

      expect(recreated.id, original.id);
      expect(recreated.ownerId, original.ownerId);
      expect(recreated.title, original.title);
      expect(recreated.description, original.description);
      expect(recreated.coverId, original.coverId);
      expect(recreated.coverColorHex, original.coverColorHex);
      expect(recreated.paperTemplateId, original.paperTemplateId);
      expect(recreated.orientation, 'landscape');
      expect(recreated.pageSize, 'Letter');
      expect(recreated.pageCount, 18);
      expect(recreated.isFavorite, true);
      expect(recreated.revision, 3);
    });

    test('copyWith properly updates specified attributes', () {
      final original = Notebook(
        id: 'nb-copy-test',
        ownerId: 'user-1',
        title: 'Original Title',
        coverId: 'classic_leather',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        isFavorite: true,
        pageCount: 5,
      );

      expect(updated.id, original.id);
      expect(updated.title, 'Updated Title');
      expect(updated.isFavorite, true);
      expect(updated.pageCount, 5);
      expect(updated.coverId, original.coverId);
    });

    test('serializes and deserializes Google Drive cover attributes', () {
      final coverTime = DateTime(2026, 11, 20, 10, 30, 0);
      final nb = Notebook(
        id: 'nb-cover-test',
        ownerId: 'user-cover',
        title: 'Biology Notes',
        coverId: 'custom',
        coverDriveId: 'drive_file_id_xyz789',
        coverFileName: 'cover_biology.jpg',
        coverUpdatedAt: coverTime,
        coverImageUrl: 'C:\\Users\\test\\covers\\legacy.jpg',
        createdAt: now,
        updatedAt: now,
      );

      final json = nb.toJson();
      expect(json['coverDriveId'], 'drive_file_id_xyz789');
      expect(json['coverFileName'], 'cover_biology.jpg');
      expect(json['coverUpdatedAt'], coverTime.toIso8601String());
      expect(json['coverImageUrl'], 'C:\\Users\\test\\covers\\legacy.jpg');

      final deserialized = Notebook.fromJson(json);
      expect(deserialized.coverDriveId, 'drive_file_id_xyz789');
      expect(deserialized.coverFileName, 'cover_biology.jpg');
      expect(deserialized.coverUpdatedAt, coverTime);

      // Test clearCoverDriveId in copyWith
      final cleared = deserialized.copyWith(clearCoverDriveId: true);
      expect(cleared.coverDriveId, isNull);
      expect(cleared.coverFileName, isNull);
      expect(cleared.coverUpdatedAt, isNull);
    });

    test('serializes, deserializes and clears Firestore coverImageBase64', () {
      const sampleBase64 = '/9j/4AAQSkZJRgABAQEASABIAAD/2wBD...testBase64Payload==';
      final nb = Notebook(
        id: 'nb-base64-test',
        ownerId: 'user-base64',
        title: 'Physics Notes',
        coverId: 'custom',
        coverImageBase64: sampleBase64,
        createdAt: now,
        updatedAt: now,
      );

      final json = nb.toJson();
      expect(json['coverImageBase64'], sampleBase64);

      final deserialized = Notebook.fromJson(json);
      expect(deserialized.coverImageBase64, sampleBase64);

      // Test clearCoverImageBase64 in copyWith
      final cleared = deserialized.copyWith(clearCoverImageBase64: true);
      expect(cleared.coverImageBase64, isNull);
    });
  });
}
