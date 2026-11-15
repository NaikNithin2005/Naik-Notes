import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/models/audio_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/stroke_model.dart';
import 'package:naik_notes/data/repositories/audio_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/services/audio/audio_service.dart';

void main() {
  group('AudioService Recording & Playback Tests', () {
    late AppDatabase db;
    late DriftAudioRepository audioRepo;
    late AudioService audioService;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final notebookRepo = DriftNotebookRepository(db);
      audioRepo = DriftAudioRepository(db);
      audioService = AudioService(repository: audioRepo);

      final now = DateTime.now();
      await notebookRepo.saveNotebook(
        Notebook(
          id: 'nb-service-test',
          ownerId: 'user-1',
          title: 'Audio Lecture Test',
          coverId: 'dark_academia_leather',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    tearDown(() async {
      audioService.dispose();
      await db.close();
    });

    test('recording session start, pause, resume, and stop flow', () async {
      expect(audioService.recordState.isRecording, false);

      audioService.startRecording(
        'nb-service-test',
        title: 'Calculus Session 1',
      );
      expect(audioService.recordState.isRecording, true);
      expect(audioService.recordState.isPaused, false);
      expect(audioService.recordState.notebookId, 'nb-service-test');

      audioService.pauseRecording();
      expect(audioService.recordState.isPaused, true);

      audioService.resumeRecording();
      expect(audioService.recordState.isPaused, false);

      // Add a bookmark during recording
      final bm = audioService.addBookmark('Important theorem proof');
      expect(bm.label, 'Important theorem proof');
      expect(audioService.recordState.bookmarks.length, 1);

      // Stop recording
      final saved = await audioService.stopRecording();
      expect(saved, isNotNull);
      expect(audioService.recordState.isRecording, false);
      expect(saved!.notebookId, 'nb-service-test');
      expect(saved.title, 'Calculus Session 1');

      // Verify persisted in repository
      final inDb = await audioRepo.getRecordingById(saved.id);
      expect(inDb, isNotNull);
      expect(inDb!.bookmarks.length, 1);
    });

    test('playback controls, seeking, and speed cycling', () {
      final now = DateTime.now();
      final recording = AudioRecording(
        id: 'rec-pb-test',
        notebookId: 'nb-service-test',
        title: 'Playback Test',
        filePath: 'audio/pb.m4a',
        durationMs: 180000, // 3 minutes
        bookmarks: [
          AudioBookmark(
            id: 'bm-seek',
            recordingId: 'rec-pb-test',
            timestampMs: 45000,
            label: 'Jump Point',
            createdAt: now,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      audioService.loadRecording(recording);
      expect(audioService.playbackState.totalDurationMs, 180000);
      expect(audioService.playbackState.formattedTotal, '03:00');
      expect(audioService.playbackState.currentPositionMs, 0);

      // Play and pause
      audioService.play();
      expect(audioService.playbackState.isPlaying, true);

      audioService.pause();
      expect(audioService.playbackState.isPlaying, false);
      expect(audioService.playbackState.isPaused, true);

      // Seek
      audioService.seekTo(60000);
      expect(audioService.playbackState.currentPositionMs, 60000);
      expect(audioService.playbackState.formattedPosition, '01:00');
      expect(audioService.playbackState.progressFraction, closeTo(0.333, 0.01));

      // Seek via bookmark
      audioService.seekToBookmark(recording.bookmarks.first);
      expect(audioService.playbackState.currentPositionMs, 45000);
      expect(audioService.playbackState.formattedPosition, '00:45');

      // Speed cycle: 1.0x -> 1.25x -> 1.5x -> 2.0x -> 1.0x
      expect(audioService.playbackState.speed, AudioSpeed.speed1x);
      audioService.cycleSpeed();
      expect(audioService.playbackState.speed, AudioSpeed.speed125x);
      audioService.cycleSpeed();
      expect(audioService.playbackState.speed, AudioSpeed.speed15x);
      audioService.cycleSpeed();
      expect(audioService.playbackState.speed, AudioSpeed.speed2x);
      audioService.cycleSpeed();
      expect(audioService.playbackState.speed, AudioSpeed.speed1x);
    });

    test('stroke audio synchronization calculations', () {
      const sessionStart = 1000000;
      const strokeTime = sessionStart + 35000; // 35 seconds into session

      final stroke = Stroke(
        id: 'st-synced',
        pageId: 'page-1',
        tool: ToolType.ballpointPen,
        colorValue: 0xFF000000,
        width: 2.0,
        opacity: 1.0,
        points: const [StrokePoint(x: 10, y: 10, timestamp: 1000035000)],
        createdAt: DateTime.fromMillisecondsSinceEpoch(strokeTime),
      );

      final offset = audioService.getStrokeAudioTimestamp(stroke, sessionStart);
      expect(offset, 35000);

      // In audio playback at 36 seconds (within 4000ms window): should be synchronized
      final isSync = audioService.isStrokeSynchronizedWithHead(
        stroke,
        36000,
        sessionStartTimeEpoch: sessionStart,
        windowMs: 4000,
      );
      expect(isSync, true);

      // In audio playback at 90 seconds (far away): should not be synchronized
      final notSync = audioService.isStrokeSynchronizedWithHead(
        stroke,
        90000,
        sessionStartTimeEpoch: sessionStart,
        windowMs: 4000,
      );
      expect(notSync, false);
    });
  });
}
