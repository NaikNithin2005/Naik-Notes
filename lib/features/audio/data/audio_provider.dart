import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/audio_model.dart';
import 'package:naik_notes/services/audio/audio_service.dart';

/// Active recording flag notifier to avoid eager initialization of AudioService.
class IsAudioRecordingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRecording(bool value) {
    state = value;
  }
}

final isAudioRecordingActiveProvider =
    NotifierProvider<IsAudioRecordingNotifier, bool>(
      IsAudioRecordingNotifier.new,
    );

/// Global provider for the AudioService singleton.
final audioServiceProvider = Provider<AudioService>((ref) {
  final repo = ref.watch(audioRepositoryProvider);
  final service = AudioService(repository: repo);
  final sub = service.recordStateStream.listen((recordState) {
    ref
        .read(isAudioRecordingActiveProvider.notifier)
        .setRecording(recordState.isRecording);
  });
  ref.onDispose(() {
    sub.cancel();
    service.dispose();
  });
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
