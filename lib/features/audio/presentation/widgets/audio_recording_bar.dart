import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/models/audio_model.dart';
import 'package:naik_notes/features/audio/data/audio_provider.dart';
import 'package:naik_notes/services/audio/audio_service.dart';

/// Floating audio control bar managing live lecture recording, waveform scrubbing,
/// bookmarking, speed selection, and stroke playback synchronization.
class AudioRecordingBar extends ConsumerWidget {
  final String notebookId;
  final String? activePageId;
  final VoidCallback onClose;

  const AudioRecordingBar({
    super.key,
    required this.notebookId,
    this.activePageId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final audioService = ref.watch(audioServiceProvider);

    final recordAsync = ref.watch(recordingSessionProvider);
    final playbackAsync = ref.watch(playbackSessionProvider);

    final recordState = recordAsync.value ?? audioService.recordState;
    final playbackState = playbackAsync.value ?? audioService.playbackState;

    final isRecording = recordState.isRecording;
    final isPlaying = playbackState.isPlaying;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      color: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode Indicator: Recording vs Playback
            if (isRecording) ...[
              // Blinking Red Dot
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'REC ${recordState.formattedDuration}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),

              // Waveform preview (5 small dynamic bars)
              Row(
                children: List.generate(5, (index) {
                  final amps = recordState.waveformAmplitudes;
                  final amp = (amps.length > index)
                      ? amps[amps.length - 1 - index]
                      : 0.3;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 3,
                    height: (amp * 18).clamp(4.0, 18.0),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 12),

              // Pause / Resume Record
              IconButton(
                icon: Icon(
                  recordState.isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  size: 20,
                ),
                tooltip: recordState.isPaused ? 'Resume' : 'Pause',
                onPressed: () {
                  if (recordState.isPaused) {
                    audioService.resumeRecording();
                  } else {
                    audioService.pauseRecording();
                  }
                },
              ),

              // Add Bookmark Button
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                tooltip: 'Add Audio Bookmark',
                onPressed: () => _promptAddBookmark(context, audioService),
              ),

              // Stop Recording
              FilledButton.tonalIcon(
                icon: const Icon(Icons.stop_rounded, size: 18),
                label: const Text('Stop', style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () async {
                  await audioService.stopRecording();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lecture audio saved'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ] else ...[
              // Playback Mode
              IconButton(
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: () {
                  if (isPlaying) {
                    audioService.pause();
                  } else {
                    audioService.play();
                  }
                },
              ),

              // Time indicator
              Text(
                '${playbackState.formattedPosition} / ${playbackState.formattedTotal}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),

              // Scrubber Slider
              SizedBox(
                width: 130,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: playbackState.progressFraction,
                    onChanged: (val) {
                      final targetMs = (val * playbackState.totalDurationMs)
                          .round();
                      audioService.seekTo(targetMs);
                    },
                  ),
                ),
              ),

              // Speed selector pill
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => audioService.cycleSpeed(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    playbackState.speed.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Stroke Sync Toggle
              IconButton(
                icon: Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: playbackState.syncStrokesEnabled
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
                tooltip: playbackState.syncStrokesEnabled
                    ? 'Stroke sync: Active (Highlights inking during speech)'
                    : 'Stroke sync: Off',
                onPressed: () => audioService.toggleSyncStrokes(),
              ),

              // Bookmarks menu
              if (playbackState.activeRecording?.bookmarks.isNotEmpty ?? false)
                PopupMenuButton<AudioBookmark>(
                  tooltip: 'Bookmarks',
                  icon: const Icon(Icons.bookmarks_outlined, size: 18),
                  onSelected: (bm) => audioService.seekToBookmark(bm),
                  itemBuilder: (ctx) {
                    final bms = playbackState.activeRecording!.bookmarks;
                    return bms.map((bm) {
                      return PopupMenuItem(
                        value: bm,
                        child: Text(
                          '${bm.formattedTimestamp} • ${bm.label}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList();
                  },
                ),
            ],

            const VerticalDivider(width: 8, thickness: 1),

            // Close audio bar
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Close audio controller',
              onPressed: () {
                if (isRecording) {
                  audioService.stopRecording();
                } else {
                  audioService.pause();
                }
                onClose();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _promptAddBookmark(BuildContext context, AudioService service) {
    final controller = TextEditingController(text: 'Important point');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Timestamp Bookmark'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Bookmark Label',
            hintText: 'e.g. Formula derivation, Theorem proof',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final label = controller.text.trim();
              if (label.isNotEmpty) {
                service.addBookmark(label, pageId: activePageId);
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save Bookmark'),
          ),
        ],
      ),
    );
  }
}
