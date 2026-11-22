import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/page_model.dart';
import '../../../data/models/paper_template_model.dart';
import '../../../data/repositories/page_repository.dart';
import '../../authentication/data/auth_provider.dart';
import '../../storage/data/google_drive_provider.dart';
import '../../sync/data/sync_provider.dart';
import 'notebook_provider.dart';

/// State notifier managing the pages of all loaded notebooks, keyed by notebook ID.
class NotebookPagesNotifier extends Notifier<Map<String, List<NotebookPage>>> {
  final _uuid = const Uuid();
  PageRepository get _repository => ref.read(pageRepositoryProvider);

  @override
  Map<String, List<NotebookPage>> build() {
    ref.watch(pageRepositoryProvider);
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

    final currentUserId = ref.read(authProvider).user?.id;
    if (currentUserId != null && currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .pushPage(currentUserId, notebookId, newPage);
      } catch (_) {}
    }

    // Update notebook page count in notebooksProvider
    final notebooksNotifier = ref.read(notebooksProvider.notifier);
    final notebooks = ref.read(notebooksProvider);
    final notebook = notebooks.where((n) => n.id == notebookId).firstOrNull;
    if (notebook != null) {
      await notebooksNotifier.renameNotebook(
        notebookId,
        notebook.title,
        newDescription: notebook.description,
      );
    }

    try {
      ref.read(googleDriveProvider.notifier).scheduleAutoSync(
        delay: const Duration(seconds: 3),
        reason: 'page_added',
      );
    } catch (_) {}

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
    try {
      ref.read(googleDriveProvider.notifier).scheduleAutoSync(
        delay: const Duration(seconds: 3),
        reason: 'template_changed',
      );
    } catch (_) {}
  }

  /// Updates paper properties for a specific page across notebooks.
  Future<void> updatePageProperties({
    required String pageId,
    required PaperProperties properties,
  }) async {
    for (final entry in state.entries) {
      final notebookId = entry.key;
      final pages = entry.value;
      final index = pages.indexWhere((p) => p.id == pageId);
      if (index != -1) {
        final current = pages[index];
        final updated = current.copyWith(
          properties: properties,
          updatedAt: DateTime.now(),
        );
        final updatedList = List<NotebookPage>.from(pages);
        updatedList[index] = updated;
        state = {...state, notebookId: updatedList};
        await _repository.updatePageTemplate(
          pageId,
          updated.templateId,
          properties,
        );
        break;
      }
    }
  }

  Future<void> toggleBookmark(String notebookId, String pageId) async {
    final currentPages = state[notebookId] ?? [];
    final updatedList = [
      for (final p in currentPages)
        if (p.id == pageId)
          p.copyWith(isBookmarked: !p.isBookmarked, updatedAt: DateTime.now())
        else
          p,
    ];
    state = {...state, notebookId: updatedList};
    await _repository.toggleBookmark(pageId);
  }

  Future<NotebookPage?> duplicatePage(String notebookId, String pageId) async {
    final currentPages = state[notebookId] ?? [];
    final targetIndex = currentPages.indexWhere((p) => p.id == pageId);
    if (targetIndex == -1) return null;
    final sourcePage = currentPages[targetIndex];
    final now = DateTime.now();
    final newPage = sourcePage.copyWith(
      id: _uuid.v4(),
      pageNumber: currentPages.length + 1,
      createdAt: now,
      updatedAt: now,
    );
    final updatedList = [...currentPages, newPage];
    state = {...state, notebookId: updatedList};
    await _repository.savePage(newPage);
    return newPage;
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
    final currentUserId = ref.read(authProvider).user?.id;
    if (currentUserId != null && currentUserId != 'local_user') {
      try {
        await ref
            .read(firebaseSyncServiceProvider)
            .deletePage(currentUserId, notebookId, pageId);
      } catch (_) {}
    }
    for (final p in renumbered) {
      await _repository.savePage(p);
    }
  }

  Future<NotebookPage> insertPageBefore(
    String notebookId,
    String referencePageId, {
    required String templateId,
    PaperProperties? properties,
  }) async {
    final currentPages = List<NotebookPage>.from(state[notebookId] ?? []);
    final refIndex = currentPages.indexWhere((p) => p.id == referencePageId);
    final targetIndex = refIndex == -1 ? 0 : refIndex;

    final type = PaperTemplateType.fromId(templateId);
    final now = DateTime.now();
    final props = properties ?? PaperProperties.defaultFor(type);
    final dims = PaperProperties.getDimensions(
      props.pageSize,
      props.orientation,
    );

    final newPage = NotebookPage(
      id: _uuid.v4(),
      notebookId: notebookId,
      pageNumber: targetIndex + 1,
      templateId: templateId,
      properties: props,
      width: dims.width,
      height: dims.height,
      createdAt: now,
      updatedAt: now,
    );

    currentPages.insert(targetIndex, newPage);
    final renumbered = <NotebookPage>[];
    for (int i = 0; i < currentPages.length; i++) {
      renumbered.add(currentPages[i].copyWith(pageNumber: i + 1));
    }

    state = {...state, notebookId: renumbered};
    for (final p in renumbered) {
      await _repository.savePage(p);
    }
    return newPage;
  }

  Future<NotebookPage> insertPageAfter(
    String notebookId,
    String referencePageId, {
    required String templateId,
    PaperProperties? properties,
  }) async {
    final currentPages = List<NotebookPage>.from(state[notebookId] ?? []);
    final refIndex = currentPages.indexWhere((p) => p.id == referencePageId);
    final targetIndex = refIndex == -1 ? currentPages.length : refIndex + 1;

    final type = PaperTemplateType.fromId(templateId);
    final now = DateTime.now();
    final props = properties ?? PaperProperties.defaultFor(type);
    final dims = PaperProperties.getDimensions(
      props.pageSize,
      props.orientation,
    );

    final newPage = NotebookPage(
      id: _uuid.v4(),
      notebookId: notebookId,
      pageNumber: targetIndex + 1,
      templateId: templateId,
      properties: props,
      width: dims.width,
      height: dims.height,
      createdAt: now,
      updatedAt: now,
    );

    currentPages.insert(targetIndex, newPage);
    final renumbered = <NotebookPage>[];
    for (int i = 0; i < currentPages.length; i++) {
      renumbered.add(currentPages[i].copyWith(pageNumber: i + 1));
    }

    state = {...state, notebookId: renumbered};
    for (final p in renumbered) {
      await _repository.savePage(p);
    }
    return newPage;
  }

  Future<void> reorderPages(
    String notebookId,
    int oldIndex,
    int newIndex,
  ) async {
    final currentPages = List<NotebookPage>.from(state[notebookId] ?? []);
    if (oldIndex < 0 || oldIndex >= currentPages.length) return;
    if (newIndex < 0 || newIndex > currentPages.length) return;

    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = currentPages.removeAt(oldIndex);
    currentPages.insert(newIndex, item);

    final renumbered = <NotebookPage>[];
    for (int i = 0; i < currentPages.length; i++) {
      renumbered.add(currentPages[i].copyWith(pageNumber: i + 1));
    }

    state = {...state, notebookId: renumbered};
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
