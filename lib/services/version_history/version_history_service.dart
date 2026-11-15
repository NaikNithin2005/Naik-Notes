import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/version_history_model.dart';
import '../../data/repositories/page_repository.dart';
import '../../data/repositories/sticky_note_repository.dart';
import '../../data/repositories/stroke_repository.dart';
import '../../data/repositories/version_history_repository.dart';

/// Service managing page revision snapshots, version timeline, diff summaries,
/// and complete snapshot restoration.
class VersionHistoryService {
  final VersionHistoryRepository repository;
  final PageRepository pageRepository;
  final StrokeRepository strokeRepository;
  final StickyNoteRepository stickyNoteRepository;
  final Uuid _uuid = const Uuid();

  VersionHistoryService({
    required this.repository,
    required this.pageRepository,
    required this.strokeRepository,
    required this.stickyNoteRepository,
  });

  /// Captures an immutable snapshot of the page's current strokes, notes, and template.
  Future<PageSnapshot> captureSnapshot(
    String pageId,
    String notebookId, {
    String? label,
    String? deviceInfo,
  }) async {
    final existingSnapshots = await repository.getSnapshotsForPage(pageId);
    final versionNumber = existingSnapshots.isEmpty
        ? 1
        : (existingSnapshots.first.versionNumber + 1);

    final page = await pageRepository.getPageById(pageId);
    final strokes = await strokeRepository.getStrokesForPage(pageId);
    final notes = await stickyNoteRepository.getStickyNotesForPage(pageId);

    final snapshot = PageSnapshot(
      id: 'snap-${_uuid.v4()}',
      pageId: pageId,
      notebookId: notebookId,
      versionNumber: versionNumber,
      label: label ?? 'Version $versionNumber',
      strokes: strokes,
      stickyNotes: notes,
      templateId: page?.templateId ?? 'college_ruled',
      templateProperties: page?.properties,
      deviceInfo: deviceInfo ?? 'Local Device',
      createdAt: DateTime.now(),
    );

    await repository.saveSnapshot(snapshot);
    debugPrint(
      'Captured Snapshot: $pageId v$versionNumber (${strokes.length} strokes, ${notes.length} notes)',
    );
    return snapshot;
  }

  /// Retrieves chronological version timeline for a page.
  Future<List<PageSnapshot>> getPageTimeline(String pageId) async {
    return repository.getSnapshotsForPage(pageId);
  }

  /// Calculates visual diff metrics between two historical snapshots.
  PageDiffSummary calculateDiff(PageSnapshot before, PageSnapshot after) {
    return PageDiffSummary(
      strokesBefore: before.strokeCount,
      strokesAfter: after.strokeCount,
      notesBefore: before.noteCount,
      notesAfter: after.noteCount,
    );
  }

  /// Atomically restores the page to the specified snapshot version.
  Future<void> restoreSnapshot(String snapshotId) async {
    await repository.restoreSnapshot(snapshotId);
  }

  /// Deletes a single snapshot from history.
  Future<void> deleteSnapshot(String snapshotId) async {
    await repository.deleteSnapshot(snapshotId);
  }
}
