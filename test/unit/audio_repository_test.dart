import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/audio_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/repositories/audio_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';

void main() {
  group('DriftAudioRepository SQLite Tests', () {
    late AppDatabase db;
    late DriftNotebookRepository notebookRepo;
    late DriftAudioRepository audioRepo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      notebookRepo = DriftNotebookRepository(db);
      audioRepo = DriftAudioRepository(db);

      // Seed parent notebook
      final now = DateTime.now();
      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb-audio-test',
          ownerId: 'user-1',
          title: 'Quantum Mechanics Lecture',
          coverId: 'dark_academia_leather',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('saves and retrieves audio recording with bookmarks', () async {
      final now = DateTime.now();
      final recording = AudioRecording(
        id: 'rec-101',
        notebookId: 'nb-audio-test',
        title: 'Lecture 1: Schrodinger Equation',
        filePath: 'audio/rec-101.m4a',
        durationMs: 125000,
        bookmarks: [
          AudioBookmark(
            id: 'bm-1',
            recordingId: 'rec-101',
            timestampMs: 30000,
            label: 'Wave function definition',
            createdAt: now,
          ),
          AudioBookmark(
            id: 'bm-2',
            recordingId: 'rec-101',
            timestampMs: 90000,
            label: 'Hamiltonian operator',
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      await audioRepo.saveRecording(recording);

      final retrieved = await audioRepo.getRecordingById('rec-101');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Lecture 1: Schrodinger Equation');
      expect(retrieved.durationMs, 125000);
      expect(retrieved.formattedDuration, '02:05');
      expect(retrieved.bookmarks.length, 2);
      expect(retrieved.bookmarks[0].label, 'Wave function definition');
      expect(retrieved.bookmarks[0].formattedTimestamp, '00:30');
      expect(retrieved.bookmarks[1].formattedTimestamp, '01:30');
    });

    test(
      'retrieves recordings for notebook ordered by creation date',
      () async {
        final now = DateTime.now();
        await audioRepo.saveRecording(
          AudioRecording(
            id: 'rec-first',
            notebookId: 'nb-audio-test',
            title: 'First Recording',
            filePath: 'audio/1.m4a',
            durationMs: 60000,
            createdAt: now.subtract(const Duration(hours: 2)),
            updatedAt: now,
          ),
        );

        await audioRepo.saveRecording(
          AudioRecording(
            id: 'rec-second',
            notebookId: 'nb-audio-test',
            title: 'Second Recording',
            filePath: 'audio/2.m4a',
            durationMs: 90000,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final list = await audioRepo.getRecordingsForNotebook('nb-audio-test');
        expect(list.length, 2);
        expect(list.first.id, 'rec-second'); // Most recent first
      },
    );

    test('deleteRecording deletes recording and cascades bookmarks', () async {
      final now = DateTime.now();
      final recording = AudioRecording(
        id: 'rec-del',
        notebookId: 'nb-audio-test',
        title: 'Delete Me',
        filePath: 'audio/del.m4a',
        durationMs: 40000,
        bookmarks: [
          AudioBookmark(
            id: 'bm-del',
            recordingId: 'rec-del',
            timestampMs: 15000,
            label: 'To delete',
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      await audioRepo.saveRecording(recording);
      expect(await audioRepo.getRecordingById('rec-del'), isNotNull);

      await audioRepo.deleteRecording('rec-del');
      expect(await audioRepo.getRecordingById('rec-del'), isNull);
      final bookmarks = await audioRepo.getBookmarksForRecording('rec-del');
      expect(bookmarks.isEmpty, true);
    });
  });
}
