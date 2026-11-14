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
  });
}
