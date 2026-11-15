import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/version_history_model.dart';
import 'package:naik_notes/services/version_history/version_history_service.dart';

/// Global provider for the VersionHistoryService.
final versionHistoryServiceProvider = Provider<VersionHistoryService>((ref) {
  final historyRepo = ref.watch(versionHistoryRepositoryProvider);
  final pageRepo = ref.watch(pageRepositoryProvider);
  final strokeRepo = ref.watch(strokeRepositoryProvider);
  final stickyRepo = ref.watch(stickyNoteRepositoryProvider);

  return VersionHistoryService(
    repository: historyRepo,
    pageRepository: pageRepo,
    strokeRepository: strokeRepo,
    stickyNoteRepository: stickyRepo,
  );
});

/// Asynchronous stream/future provider for a page's historical snapshots.
final pageSnapshotsProvider = FutureProvider.family<List<PageSnapshot>, String>(
  (ref, pageId) async {
    final service = ref.watch(versionHistoryServiceProvider);
    return service.getPageTimeline(pageId);
  },
);

/// Notifier tracking the currently previewed snapshot in Version History sheet.
class ActivePreviewSnapshotNotifier extends Notifier<PageSnapshot?> {
  @override
  PageSnapshot? build() => null;

  void select(PageSnapshot? snapshot) {
    state = snapshot;
  }
}

final activePreviewSnapshotProvider =
    NotifierProvider<ActivePreviewSnapshotNotifier, PageSnapshot?>(
      ActivePreviewSnapshotNotifier.new,
    );
