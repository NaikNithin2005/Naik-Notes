import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/services/search/search_service.dart';

/// Global provider for the unified SearchService.
final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(
    notebookRepository: ref.watch(notebookRepositoryProvider),
    folderRepository: ref.watch(folderRepositoryProvider),
    pageRepository: ref.watch(pageRepositoryProvider),
    pageSearchRepository: ref.watch(pageSearchRepositoryProvider),
    stickyNoteRepository: ref.watch(stickyNoteRepositoryProvider),
  );
});

/// Query string entered into the dashboard global search bar.
class GlobalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final globalSearchQueryProvider =
    NotifierProvider<GlobalSearchQueryNotifier, String>(
      GlobalSearchQueryNotifier.new,
    );

/// Asynchronous results of the global search across all notebooks and indexed content.
final globalSearchResultsProvider = FutureProvider<List<SearchResultItem>>((
  ref,
) async {
  final explicitQuery = ref.watch(globalSearchQueryProvider);
  final dashQuery = ref.watch(searchQueryProvider);
  final query = explicitQuery.isNotEmpty ? explicitQuery : dashQuery;
  if (query.trim().isEmpty) return const [];

  final service = ref.watch(searchServiceProvider);
  return service.searchGlobal(query);
});

/// In-document search query for the currently opened notebook.
class InDocumentSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final inDocumentSearchQueryProvider =
    NotifierProvider<InDocumentSearchQueryNotifier, String>(
      InDocumentSearchQueryNotifier.new,
    );

/// In-document search results scoped to a specific notebook.
final inDocumentSearchResultsProvider =
    FutureProvider.family<List<SearchResultItem>, String>((
      ref,
      notebookId,
    ) async {
      final query = ref.watch(inDocumentSearchQueryProvider);
      if (query.trim().isEmpty) return const [];

      final service = ref.watch(searchServiceProvider);
      return service.searchInNotebook(notebookId, query);
    });

/// Currently active / focused search match index within the document.
class ActiveSearchMatchIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int idx) => state = idx;
  void next(int total) {
    if (total > 0) state = (state + 1) % total;
  }

  void previous(int total) {
    if (total > 0) state = (state - 1 + total) % total;
  }
}

final activeSearchMatchIndexProvider =
    NotifierProvider<ActiveSearchMatchIndexNotifier, int>(
      ActiveSearchMatchIndexNotifier.new,
    );

/// List of word bounding boxes on the current page that match the active search query.
final currentPageSearchMatchesProvider =
    Provider.family<List<WordBoundingBox>, String>((ref, pageId) {
      final query = ref.watch(inDocumentSearchQueryProvider);
      if (query.trim().isEmpty) return const [];

      final inDocAsync = ref.watch(inDocumentSearchResultsProvider(''));

      return inDocAsync.maybeWhen(
        data: (items) {
          final pageItem = items.firstWhere(
            (it) => it.pageId == pageId,
            orElse: () => const SearchResultItem(
              notebookId: '',
              notebookTitle: '',
              snippet: '',
              matchedTerm: '',
              sourceType: '',
            ),
          );
          return pageItem.matchingBoxes;
        },
        orElse: () => const [],
      );
    });
