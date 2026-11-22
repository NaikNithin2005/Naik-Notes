import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/note_model.dart';
import '../../../data/repositories/note_repository.dart';
import '../../../services/sync/firebase_sync_service.dart';
import '../../authentication/data/auth_provider.dart';
import '../../sync/data/sync_provider.dart';

/// Status of the note auto-save process.
enum SaveStatus {
  idle,
  saving,
  saved,
  failed,
}

/// State representation for auto-save notifications and UI feedback.
class NoteSaveState {
  final SaveStatus status;
  final DateTime? lastSavedAt;
  final String? errorMessage;
  final String? activeNoteId;
  final bool isDirty;

  const NoteSaveState({
    this.status = SaveStatus.idle,
    this.lastSavedAt,
    this.errorMessage,
    this.activeNoteId,
    this.isDirty = false,
  });

  NoteSaveState copyWith({
    SaveStatus? status,
    DateTime? lastSavedAt,
    String? errorMessage,
    String? activeNoteId,
    bool? isDirty,
    bool clearError = false,
  }) {
    return NoteSaveState(
      status: status ?? this.status,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      activeNoteId: activeNoteId ?? this.activeNoteId,
      isDirty: isDirty ?? this.isDirty,
    );
  }
}

/// Pending edit payload waiting for debounce flush.
class _PendingNoteEdit {
  final Note originalNote;
  final String deltaJson;
  final String? title;
  final List<String>? tags;
  final DateTime changeTimestamp;

  _PendingNoteEdit({
    required this.originalNote,
    required this.deltaJson,
    this.title,
    this.tags,
    required this.changeTimestamp,
  });
}

/// Coordinator handling debounced auto-saves (1500ms) with SQLite offline guarantee
/// and cloud Firestore sync.
class NoteAutoSaveCoordinator extends Notifier<NoteSaveState>
    with WidgetsBindingObserver {
  static const Duration debounceDuration = Duration(milliseconds: 1500);

  Timer? _debounceTimer;
  _PendingNoteEdit? _pendingEdit;

  NoteRepository get _noteRepo => ref.read(noteRepositoryProvider);
  FirebaseSyncService get _firebaseSync => ref.read(firebaseSyncServiceProvider);

  @override
  NoteSaveState build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _debounceTimer?.cancel();
    });
    return const NoteSaveState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      flushPendingSave();
    }
  }

  /// Registers a content change and resets the 1500ms debounce timer.
  void onNoteChanged({
    required Note note,
    required String deltaJson,
    String? title,
    List<String>? tags,
  }) {
    _debounceTimer?.cancel();

    _pendingEdit = _PendingNoteEdit(
      originalNote: note,
      deltaJson: deltaJson,
      title: title,
      tags: tags,
      changeTimestamp: DateTime.now(),
    );

    state = state.copyWith(
      status: SaveStatus.saving,
      activeNoteId: note.id,
      isDirty: true,
      clearError: true,
    );

    _debounceTimer = Timer(debounceDuration, () {
      _executePendingSave();
    });
  }

  /// Explicitly flushes pending note modifications immediately.
  /// Useful before note switching, screen pop, or app backgrounding.
  Future<void> flushPendingSave({String? noteId}) async {
    _debounceTimer?.cancel();
    if (_pendingEdit == null) return;
    if (noteId != null && _pendingEdit!.originalNote.id != noteId) return;

    await _executePendingSave();
  }

  Future<void> _executePendingSave() async {
    final pending = _pendingEdit;
    if (pending == null) return;
    _pendingEdit = null;

    final now = DateTime.now();
    final plainText = Note.extractPlainText(pending.deltaJson);
    final preview = Note.generatePreview(plainText);

    final updatedNote = pending.originalNote.copyWith(
      title: pending.title ?? pending.originalNote.title,
      contentDelta: pending.deltaJson,
      plainText: plainText,
      preview: preview,
      tags: pending.tags ?? pending.originalNote.tags,
      updatedAt: now,
      localVersion: pending.originalNote.localVersion + 1,
      syncStatus: 'pending',
    );

    // 1. Immediate offline-first local persistence to SQLite
    try {
      await _noteRepo.saveNote(updatedNote);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: SaveStatus.failed,
        errorMessage: 'Local storage error: $e',
        isDirty: true,
      );
      return;
    }

    if (!ref.mounted) return;

    // 2. Cloud Firestore synchronization
    final authState = ref.read(authProvider);
    final uid = authState.user?.id;

    if (uid != null && uid != 'local_user') {
      try {
        final pushed = await _firebaseSync.pushNote(uid, updatedNote);
        if (!ref.mounted) return;
        if (pushed) {
          final syncedNote = updatedNote.copyWith(
            serverVersion: updatedNote.localVersion,
            syncStatus: 'synced',
            lastSyncedAt: now,
          );
          await _noteRepo.saveNote(syncedNote);
          state = state.copyWith(
            status: SaveStatus.saved,
            lastSavedAt: now,
            isDirty: false,
            clearError: true,
          );
        } else {
          state = state.copyWith(
            status: SaveStatus.saved,
            errorMessage: 'Saved locally (Offline)',
            lastSavedAt: now,
            isDirty: false,
          );
        }
      } catch (e) {
        if (!ref.mounted) return;
        state = state.copyWith(
          status: SaveStatus.saved,
          errorMessage: 'Saved locally (Offline)',
          lastSavedAt: now,
          isDirty: false,
        );
      }
    } else {
      // Local user / offline mode
      if (!ref.mounted) return;
      state = state.copyWith(
        status: SaveStatus.saved,
        lastSavedAt: now,
        isDirty: false,
        clearError: true,
      );
    }
  }

  /// Retries saving an active note.
  Future<void> retrySave(Note note) async {
    onNoteChanged(note: note, deltaJson: note.contentDelta);
    await flushPendingSave(noteId: note.id);
  }
}

/// Provider for the note auto-save coordinator.
final noteAutoSaveCoordinatorProvider =
    NotifierProvider<NoteAutoSaveCoordinator, NoteSaveState>(
  NoteAutoSaveCoordinator.new,
);
