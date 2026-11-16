import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/models/template_store_model.dart';
import 'package:naik_notes/data/repositories/template_store_repository.dart';

void main() {
  group('DriftTemplateStoreRepository Tests', () {
    late AppDatabase db;
    late DriftTemplateStoreRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftTemplateStoreRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'saves, retrieves, and filters templates by category and installation status',
      () async {
        final tpl1 = CustomTemplate(
          id: 'tpl-1',
          title: 'Circuit Schematic Quad Grid',
          description: '5mm grid for circuit diagrams',
          category: 'Engineering',
          author: 'EE Club',
          properties: const PaperProperties(gridSize: 14.17),
          isInstalled: true,
          downloadCount: 150,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final tpl2 = CustomTemplate(
          id: 'tpl-2',
          title: 'Weekly Task Board',
          description: 'Planner with 7 days',
          category: 'Planning',
          author: 'Naik Notes Team',
          properties: const PaperProperties(lineSpacing: 22.0),
          isInstalled: true,
          downloadCount: 400,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await repo.saveCustomTemplate(tpl1);
        await repo.saveCustomTemplate(tpl2);

        // All installed
        final allInstalled = await repo.getInstalledTemplates();
        expect(allInstalled.length, 2);

        // Filter by category
        final engineeringOnly = await repo.getInstalledTemplates(
          category: 'Engineering',
        );
        expect(engineeringOnly.length, 1);
        expect(engineeringOnly.first.title, 'Circuit Schematic Quad Grid');

        // Change installation status
        await repo.setTemplateInstalled('tpl-1', false);
        final activeInstalled = await repo.getInstalledTemplates();
        expect(activeInstalled.length, 1);
        expect(activeInstalled.first.id, 'tpl-2');

        // Delete template
        await repo.deleteCustomTemplate('tpl-2');
        final remaining = await repo.getInstalledTemplates();
        expect(remaining, isEmpty);
      },
    );
  });
}
