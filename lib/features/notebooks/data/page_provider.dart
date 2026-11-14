import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/page_model.dart';
import '../../../data/models/paper_template_model.dart';
import '../../../data/repositories/page_repository.dart';
import 'notebook_provider.dart';

/// State notifier managing the pages of all loaded notebooks, keyed by notebook ID.
class NotebookPagesNotifier extends Notifier<Map<String, List<NotebookPage>>> {
  final _uuid = const Uuid();
  late final PageRepository _repository;

  @override
  Map<String, List<NotebookPage>> build() {
    _repository = ref.watch(pageRepositoryProvider);
    return {};
  }

  List<NotebookPage> getPages(String notebookId) {
    return state[notebookId] ?? [];
  }

  Future<void> loadPages(
    String notebookId, {
    String templateId = 'college_ruled',
    String pageSize = 'A4',
    String orientation = 'portrait',
    int count = 1,
  }) async {
    final pages = await _repository.ensurePagesExist(
      notebookId,
      templateId: templateId,
      pageSize: pageSize,
      orientation: orientation,
      count: count,
    );
    if (pages.isNotEmpty) {
      state = {...state, notebookId: pages};
    }
  }

  Future<NotebookPage> addPage(
    String notebookId, {
    required String templateId,
    PaperProperties? properties,
  }) async {
    final type = PaperTemplateType.fromId(templateId);
    final now = DateTime.now();
    final currentPages = state[notebookId] ?? [];
    final newPageNumber = currentPages.length + 1;
    final props = properties ?? PaperProperties.defaultFor(type);
    final dims = PaperProperties.getDimensions(
      props.pageSize,
      props.orientation,
    );

    final newPage = NotebookPage(
      id: _uuid.v4(),
      notebookId: notebookId,
      pageNumber: newPageNumber,
      templateId: templateId,
      properties: props,
      width: dims.width,
      height: dims.height,
      createdAt: now,
      updatedAt: now,
    );

    final updatedList = [...currentPages, newPage];
    state = {...state, notebookId: updatedList};
    await _repository.savePage(newPage);

    // Update notebook page count in notebooksProvider
    final notebooksNotifier = ref.read(notebooksProvider.notifier);
    final notebooks = ref.read(notebooksProvider);
    final notebook = notebooks.firstWhere(
      (n) => n.id == notebookId,
      orElse: () => notebooks.first,
    );
    await notebooksNotifier.renameNotebook(
      notebookId,
      notebook.title,
      newDescription: notebook.description,
    );

    return newPage;
  }

  Future<void> changePageTemplate(
    String notebookId,
    String pageId,
    String templateId,
    PaperProperties properties,
  ) async {
    final currentPages = state[notebookId] ?? [];
    final updatedList = [
      for (final p in currentPages)
        if (p.id == pageId)
          p.copyWith(
            templateId: templateId,
            properties: properties,
            updatedAt: DateTime.now(),
          )
        else
          p,
    ];

    state = {...state, notebookId: updatedList};
    await _repository.updatePageTemplate(pageId, templateId, properties);
  }

  Future<void> deletePage(String notebookId, String pageId) async {
    final currentPages = state[notebookId] ?? [];
    if (currentPages.length <= 1) return; // Keep at least one page

    final remaining = currentPages.where((p) => p.id != pageId).toList();
    // Renumber remaining pages sequentially
    final renumbered = <NotebookPage>[];
    for (int i = 0; i < remaining.length; i++) {
      renumbered.add(remaining[i].copyWith(pageNumber: i + 1));
    }

    state = {...state, notebookId: renumbered};
    await _repository.deletePage(pageId);
    for (final p in renumbered) {
      await _repository.savePage(p);
    }
  }
}

/// Global provider for notebook pages dictionary.
final notebookPagesProvider =
    NotifierProvider<NotebookPagesNotifier, Map<String, List<NotebookPage>>>(
      NotebookPagesNotifier.new,
    );

/// State notifier for the currently selected page number (1-based).
class CurrentPageNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void setPage(int page) => state = page;
  void nextPage(int maxPages) {
    if (state < maxPages) state += 1;
  }

  void prevPage() {
    if (state > 1) state -= 1;
  }
}

final currentPageIndexProvider = NotifierProvider<CurrentPageNotifier, int>(
  CurrentPageNotifier.new,
);
