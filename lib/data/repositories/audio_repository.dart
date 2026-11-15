import 'package:drift/drift.dart';

import '../local/app_database.dart';
import '../models/audio_model.dart';

abstract class AudioRepository {
  Future<void> saveRecording(AudioRecording recording);
  Future<AudioRecording?> getRecordingById(String id);
  Future<List<AudioRecording>> getRecordingsForNotebook(String notebookId);
  Future<void> deleteRecording(String id);
  Future<void> addBookmark(AudioBookmark bookmark);
  Future<List<AudioBookmark>> getBookmarksForRecording(String recordingId);
  Future<void> deleteBookmark(String id);
}

class DriftAudioRepository implements AudioRepository {
  final AppDatabase db;

  DriftAudioRepository(this.db);

  @override
  Future<void> saveRecording(AudioRecording recording) async {
    await db
        .into(db.audioRecordingsTable)
        .insertOnConflictUpdate(
          AudioRecordingsTableCompanion(
            id: Value(recording.id),
            notebookId: Value(recording.notebookId),
            pageId: Value(recording.pageId),
            title: Value(recording.title),
            filePath: Value(recording.filePath),
            durationMs: Value(recording.durationMs),
            createdAt: Value(recording.createdAt),
            updatedAt: Value(recording.updatedAt),
          ),
        );

    // Save bookmarks
    for (final b in recording.bookmarks) {
      await addBookmark(b);
    }
  }

  @override
  Future<AudioRecording?> getRecordingById(String id) async {
    final row = await (db.select(
      db.audioRecordingsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (row == null) return null;

    final bookmarks = await getBookmarksForRecording(id);

    return AudioRecording(
      id: row.id,
      notebookId: row.notebookId,
      pageId: row.pageId,
      title: row.title,
      filePath: row.filePath,
      durationMs: row.durationMs,
      bookmarks: bookmarks,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<List<AudioRecording>> getRecordingsForNotebook(
    String notebookId,
  ) async {
    final rows =
        await (db.select(db.audioRecordingsTable)
              ..where((t) => t.notebookId.equals(notebookId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
            .get();

    final result = <AudioRecording>[];
    for (final r in rows) {
      final bookmarks = await getBookmarksForRecording(r.id);
      result.add(
        AudioRecording(
          id: r.id,
          notebookId: r.notebookId,
          pageId: r.pageId,
          title: r.title,
          filePath: r.filePath,
          durationMs: r.durationMs,
          bookmarks: bookmarks,
          createdAt: r.createdAt,
          updatedAt: r.updatedAt,
        ),
      );
    }
    return result;
  }

  @override
  Future<void> deleteRecording(String id) async {
    await (db.delete(
      db.audioBookmarksTable,
    )..where((t) => t.recordingId.equals(id))).go();
    await (db.delete(
      db.audioRecordingsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> addBookmark(AudioBookmark bookmark) async {
    await db
        .into(db.audioBookmarksTable)
        .insertOnConflictUpdate(
          AudioBookmarksTableCompanion(
            id: Value(bookmark.id),
            recordingId: Value(bookmark.recordingId),
            pageId: Value(bookmark.pageId),
            strokeId: Value(bookmark.strokeId),
            timestampMs: Value(bookmark.timestampMs),
            label: Value(bookmark.label),
            createdAt: Value(bookmark.createdAt),
          ),
        );
  }

  @override
  Future<List<AudioBookmark>> getBookmarksForRecording(
    String recordingId,
  ) async {
    final rows =
        await (db.select(db.audioBookmarksTable)
              ..where((t) => t.recordingId.equals(recordingId))
              ..orderBy([(t) => OrderingTerm.asc(t.timestampMs)]))
            .get();

    return rows
        .map(
          (r) => AudioBookmark(
            id: r.id,
            recordingId: r.recordingId,
            pageId: r.pageId,
            strokeId: r.strokeId,
            timestampMs: r.timestampMs,
            label: r.label,
            createdAt: r.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> deleteBookmark(String id) async {
    await (db.delete(
      db.audioBookmarksTable,
    )..where((t) => t.id.equals(id))).go();
  }
}
