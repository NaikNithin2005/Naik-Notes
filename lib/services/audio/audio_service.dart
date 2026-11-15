import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/audio_model.dart';
import '../../data/models/stroke_model.dart';
import '../../data/repositories/audio_repository.dart';

/// State of an active or recent audio recording session.
@immutable
class RecordingSessionState {
  final bool isRecording;
  final bool isPaused;
  final int durationMs;
  final String? activeRecordingId;
  final String? notebookId;
  final String? pageId;
  final String? title;
  final int? recordingStartTimeEpoch;
  final List<double> waveformAmplitudes;
  final List<AudioBookmark> bookmarks;

  const RecordingSessionState({
    this.isRecording = false,
    this.isPaused = false,
    this.durationMs = 0,
    this.activeRecordingId,
    this.notebookId,
    this.pageId,
    this.title,
    this.recordingStartTimeEpoch,
    this.waveformAmplitudes = const [],
    this.bookmarks = const [],
  });

  String get formattedDuration {
    final totalSeconds = (durationMs / 1000).floor();
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  RecordingSessionState copyWith({
    bool? isRecording,
    bool? isPaused,
    int? durationMs,
    String? activeRecordingId,
    String? notebookId,
    String? pageId,
    String? title,
    int? recordingStartTimeEpoch,
    List<double>? waveformAmplitudes,
    List<AudioBookmark>? bookmarks,
  }) {
    return RecordingSessionState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      durationMs: durationMs ?? this.durationMs,
      activeRecordingId: activeRecordingId ?? this.activeRecordingId,
      notebookId: notebookId ?? this.notebookId,
      pageId: pageId ?? this.pageId,
      title: title ?? this.title,
      recordingStartTimeEpoch:
          recordingStartTimeEpoch ?? this.recordingStartTimeEpoch,
      waveformAmplitudes: waveformAmplitudes ?? this.waveformAmplitudes,
      bookmarks: bookmarks ?? this.bookmarks,
    );
  }
}

/// State of audio playback with scrubbing, speed control, and stroke synchronization.
@immutable
class PlaybackSessionState {
  final bool isPlaying;
  final bool isPaused;
  final int currentPositionMs;
  final int totalDurationMs;
  final AudioSpeed speed;
  final AudioRecording? activeRecording;
  final bool syncStrokesEnabled;

  const PlaybackSessionState({
    this.isPlaying = false,
    this.isPaused = false,
    this.currentPositionMs = 0,
    this.totalDurationMs = 0,
    this.speed = AudioSpeed.speed1x,
    this.activeRecording,
    this.syncStrokesEnabled = true,
  });

  String get formattedPosition {
    final totalSeconds = (currentPositionMs / 1000).floor();
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get formattedTotal {
    final totalSeconds = (totalDurationMs / 1000).floor();
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double get progressFraction {
    if (totalDurationMs <= 0) return 0.0;
    return (currentPositionMs / totalDurationMs).clamp(0.0, 1.0);
  }

  PlaybackSessionState copyWith({
    bool? isPlaying,
    bool? isPaused,
    int? currentPositionMs,
    int? totalDurationMs,
    AudioSpeed? speed,
    AudioRecording? activeRecording,
    bool? syncStrokesEnabled,
  }) {
    return PlaybackSessionState(
      isPlaying: isPlaying ?? this.isPlaying,
      isPaused: isPaused ?? this.isPaused,
      currentPositionMs: currentPositionMs ?? this.currentPositionMs,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      speed: speed ?? this.speed,
      activeRecording: activeRecording ?? this.activeRecording,
      syncStrokesEnabled: syncStrokesEnabled ?? this.syncStrokesEnabled,
    );
  }
}

/// Service managing audio lecture recording, persistent storage,
/// playback controls, waveform scrubbing, and handwriting stroke synchronization.
class AudioService {
  final AudioRepository repository;
  final Uuid _uuid = const Uuid();

  RecordingSessionState _recordState = const RecordingSessionState();
  PlaybackSessionState _playbackState = const PlaybackSessionState();

  final _recordStateController =
      StreamController<RecordingSessionState>.broadcast();
  final _playbackStateController =
      StreamController<PlaybackSessionState>.broadcast();

  Timer? _recordTimer;
  Timer? _playbackTimer;
  final math.Random _random = math.Random();

  AudioService({required this.repository});

  RecordingSessionState get recordState => _recordState;
  PlaybackSessionState get playbackState => _playbackState;

  Stream<RecordingSessionState> get recordStateStream =>
      _recordStateController.stream;
  Stream<PlaybackSessionState> get playbackStateStream =>
      _playbackStateController.stream;

  void dispose() {
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    _recordStateController.close();
    _playbackStateController.close();
  }

  // ==========================================
  // Recording Engine
  // ==========================================

  /// Begins an audio recording session tied to a notebook and optional page.
  void startRecording(String notebookId, {String? pageId, String? title}) {
    _recordTimer?.cancel();

    final id = 'rec-${_uuid.v4()}';
    final now = DateTime.now();

    _recordState = RecordingSessionState(
      isRecording: true,
      isPaused: false,
      durationMs: 0,
      activeRecordingId: id,
      notebookId: notebookId,
      pageId: pageId,
      title: title,
      recordingStartTimeEpoch: now.millisecondsSinceEpoch,
      waveformAmplitudes: [0.2],
      bookmarks: [],
    );
    _recordStateController.add(_recordState);

    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_recordState.isRecording || _recordState.isPaused) return;

      final newDuration = _recordState.durationMs + 100;
      final currentAmps = List<double>.from(_recordState.waveformAmplitudes);

      // Sample a realistic speech amplitude wave
      final nextAmp = (0.2 + (_random.nextDouble() * 0.75)).clamp(0.1, 1.0);
      currentAmps.add(nextAmp);
      if (currentAmps.length > 80) currentAmps.removeAt(0);

      _recordState = _recordState.copyWith(
        durationMs: newDuration,
        waveformAmplitudes: currentAmps,
      );
      _recordStateController.add(_recordState);
    });
  }

  void pauseRecording() {
    if (!_recordState.isRecording || _recordState.isPaused) return;
    _recordState = _recordState.copyWith(isPaused: true);
    _recordStateController.add(_recordState);
  }

  void resumeRecording() {
    if (!_recordState.isRecording || !_recordState.isPaused) return;
    _recordState = _recordState.copyWith(isPaused: false);
    _recordStateController.add(_recordState);
  }

  /// Adds a timestamped bookmark to the active recording session.
  AudioBookmark addBookmark(String label, {String? pageId, String? strokeId}) {
    final timestamp = _recordState.isRecording
        ? _recordState.durationMs
        : _playbackState.currentPositionMs;
    final recordingId =
        _recordState.activeRecordingId ??
        _playbackState.activeRecording?.id ??
        'default-rec';

    final bookmark = AudioBookmark(
      id: 'bm-${_uuid.v4()}',
      recordingId: recordingId,
      pageId: pageId ?? _recordState.pageId,
      strokeId: strokeId,
      timestampMs: timestamp,
      label: label,
      createdAt: DateTime.now(),
    );

    final updatedBookmarks = List<AudioBookmark>.from(_recordState.bookmarks)
      ..add(bookmark);
    _recordState = _recordState.copyWith(bookmarks: updatedBookmarks);
    _recordStateController.add(_recordState);

    // Save bookmark directly if repository is active
    repository.addBookmark(bookmark);
    return bookmark;
  }

  /// Stops recording, persists metadata to SQLite, and returns the saved recording.
  Future<AudioRecording?> stopRecording({String? customTitle}) async {
    if (!_recordState.isRecording && _recordState.activeRecordingId == null) {
      return null;
    }

    _recordTimer?.cancel();
    final recId = _recordState.activeRecordingId!;
    final nbId = _recordState.notebookId ?? '';
    final pId = _recordState.pageId;
    final duration = _recordState.durationMs;
    final bookmarks = List<AudioBookmark>.from(_recordState.bookmarks);
    final now = DateTime.now();

    final recording = AudioRecording(
      id: recId,
      notebookId: nbId,
      pageId: pId,
      title:
          customTitle ??
          _recordState.title ??
          'Lecture Audio (${now.month}/${now.day})',
      filePath: 'audio/$recId.m4a',
      durationMs: duration,
      bookmarks: bookmarks,
      createdAt: now,
      updatedAt: now,
    );

    await repository.saveRecording(recording);

    _recordState = const RecordingSessionState();
    _recordStateController.add(_recordState);

    // Automatically load into playback state
    loadRecording(recording);
    return recording;
  }

  // ==========================================
  // Playback & Scrubber Engine
  // ==========================================

  void loadRecording(AudioRecording recording) {
    _playbackTimer?.cancel();
    _playbackState = PlaybackSessionState(
      isPlaying: false,
      isPaused: false,
      currentPositionMs: 0,
      totalDurationMs: recording.durationMs,
      speed: AudioSpeed.speed1x,
      activeRecording: recording,
    );
    _playbackStateController.add(_playbackState);
  }

  void play() {
    if (_playbackState.activeRecording == null) return;
    _playbackTimer?.cancel();

    _playbackState = _playbackState.copyWith(isPlaying: true, isPaused: false);
    _playbackStateController.add(_playbackState);

    const stepMs = 100;
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_playbackState.isPlaying || _playbackState.isPaused) return;

      final advance = (stepMs * _playbackState.speed.multiplier).round();
      final newPos = _playbackState.currentPositionMs + advance;

      if (newPos >= _playbackState.totalDurationMs) {
        seekTo(_playbackState.totalDurationMs);
        pause();
      } else {
        _playbackState = _playbackState.copyWith(currentPositionMs: newPos);
        _playbackStateController.add(_playbackState);
      }
    });
  }

  void pause() {
    _playbackTimer?.cancel();
    _playbackState = _playbackState.copyWith(isPlaying: false, isPaused: true);
    _playbackStateController.add(_playbackState);
  }

  void seekTo(int positionMs) {
    final clamped = positionMs.clamp(0, _playbackState.totalDurationMs);
    _playbackState = _playbackState.copyWith(currentPositionMs: clamped);
    _playbackStateController.add(_playbackState);
  }

  void cycleSpeed() {
    final nextSpeed = _playbackState.speed.next();
    _playbackState = _playbackState.copyWith(speed: nextSpeed);
    _playbackStateController.add(_playbackState);
  }

  void toggleSyncStrokes() {
    _playbackState = _playbackState.copyWith(
      syncStrokesEnabled: !_playbackState.syncStrokesEnabled,
    );
    _playbackStateController.add(_playbackState);
  }

  void seekToBookmark(AudioBookmark bookmark) {
    seekTo(bookmark.timestampMs);
  }

  // ==========================================
  // Stroke Synchronization Helpers
  // ==========================================

  /// Computes the relative millisecond timestamp of a stroke within a recording session.
  int? getStrokeAudioTimestamp(Stroke stroke, int sessionStartTimeEpoch) {
    final diff =
        stroke.createdAt.millisecondsSinceEpoch - sessionStartTimeEpoch;
    return diff >= 0 ? diff : null;
  }

  /// Evaluates whether a stroke was written within [windowMs] of the current playback head.
  bool isStrokeSynchronizedWithHead(
    Stroke stroke,
    int currentPlaybackMs, {
    int sessionStartTimeEpoch = 0,
    int windowMs = 4000,
  }) {
    if (!_playbackState.syncStrokesEnabled) return false;
    final strokeTime =
        stroke.createdAt.millisecondsSinceEpoch - sessionStartTimeEpoch;
    return (strokeTime - currentPlaybackMs).abs() <= windowMs;
  }
}
