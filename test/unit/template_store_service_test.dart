import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/repositories/template_store_repository.dart';
import 'package:naik_notes/services/template_store/template_store_service.dart';

void main() {
  group('TemplateStoreService Tests', () {
    late AppDatabase db;
    late TemplateStoreService service;
    late DriftTemplateStoreRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = DriftTemplateStoreRepository(db);
      service = TemplateStoreService(repository: repo);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'fetchCommunityCatalog returns fallback seed templates when backend is offline',
      () async {
        final templates = await service.fetchCommunityCatalog();
        expect(templates.isNotEmpty, true);
        expect(templates.length, greaterThanOrEqualTo(3));

        // Category filter
        final engineering = await service.fetchCommunityCatalog(
          category: 'Engineering',
        );
        expect(engineering.every((t) => t.category == 'Engineering'), true);

        // Search filter
        final searchResult = await service.fetchCommunityCatalog(
          search: 'Cornell',
        );
        expect(searchResult.any((t) => t.title.contains('Cornell')), true);
      },
    );

    test(
      'createCustomTemplate saves template and export/import round-trips correctly',
      () async {
        // 1. Create custom template
        final created = await service.createCustomTemplate(
          title: 'Astrophysics Log Sheet',
          description: 'Constellation grid with observation header',
          category: 'Math & Science',
          author: 'Kepler',
          properties: const PaperProperties(
            backgroundColorHex: '#1E2022',
            gridSize: 18.0,
            lineSpacing: 18.0,
          ),
        );

        expect(created.title, 'Astrophysics Log Sheet');
        final installed = await repo.getInstalledTemplates();
        expect(installed.length, 1);
        expect(installed.first.title, 'Astrophysics Log Sheet');

        // 2. Export to JSON
        final json = service.exportTemplateToJson(created);
        expect(json.contains('Astrophysics Log Sheet'), true);
        expect(json.contains('#1E2022'), true);

        // 3. Import from JSON
        final imported = await service.importTemplateFromJson(json);
        expect(imported, isNotNull);
        expect(imported!.title, 'Astrophysics Log Sheet');
        expect(imported.properties.backgroundColorHex, '#1E2022');

        final installedAfterImport = await repo.getInstalledTemplates();
        expect(installedAfterImport.length, 2);
      },
    );
  });
}
