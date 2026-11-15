import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/template_store_model.dart';
import 'package:naik_notes/services/template_store/template_store_service.dart';

/// Global provider for the TemplateStoreService.
final templateStoreServiceProvider = Provider<TemplateStoreService>((ref) {
  final repo = ref.watch(templateStoreRepositoryProvider);
  return TemplateStoreService(repository: repo);
});

/// List of locally installed custom paper templates.
final installedTemplatesProvider = FutureProvider<List<CustomTemplate>>((
  ref,
) async {
  final repo = ref.watch(templateStoreRepositoryProvider);
  return repo.getInstalledTemplates();
});

/// Active category filter for the Community Template Store.
class TemplateCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void select(String category) {
    state = category;
  }
}

final selectedTemplateCategoryProvider =
    NotifierProvider<TemplateCategoryNotifier, String>(
      TemplateCategoryNotifier.new,
    );

/// Active search query for filtering Community templates.
class TemplateSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String query) {
    state = query;
  }
}

final templateSearchQueryProvider =
    NotifierProvider<TemplateSearchQueryNotifier, String>(
      TemplateSearchQueryNotifier.new,
    );

/// Asynchronous list of community templates from backend API matching selected category and search.
final communityCatalogProvider = FutureProvider<List<CustomTemplate>>((
  ref,
) async {
  final service = ref.watch(templateStoreServiceProvider);
  final category = ref.watch(selectedTemplateCategoryProvider);
  final query = ref.watch(templateSearchQueryProvider);

  return service.fetchCommunityCatalog(
    category: category,
    search: query.isEmpty ? null : query,
  );
});
