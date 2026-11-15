import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/audio_model.dart';
import 'package:naik_notes/services/audio/audio_service.dart';

/// Global provider for the AudioService singleton.
final audioServiceProvider = Provider<AudioService>((ref) {
  final repo = ref.watch(audioRepositoryProvider);
  final service = AudioService(repository: repo);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Reactive stream provider for recording session state.
final recordingSessionProvider = StreamProvider<RecordingSessionState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.recordStateStream;
});

/// Reactive stream provider for playback session state.
final playbackSessionProvider = StreamProvider<PlaybackSessionState>((ref) {
  final service = ref.watch(audioServiceProvider);
  return service.playbackStateStream;
});

/// Asynchronous list of saved audio recordings for a specific notebook.
final notebookRecordingsProvider =
    FutureProvider.family<List<AudioRecording>, String>((
      ref,
      notebookId,
    ) async {
      final repo = ref.watch(audioRepositoryProvider);
      return repo.getRecordingsForNotebook(notebookId);
    });
