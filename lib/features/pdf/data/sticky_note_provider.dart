import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/sticky_note_model.dart';
import 'package:naik_notes/data/repositories/sticky_note_repository.dart';
import 'package:uuid/uuid.dart';

/// State notifier managing sticky notes per page ID.
class StickyNotesNotifier extends Notifier<Map<String, List<StickyNote>>> {
  final _uuid = const Uuid();

  @override
  Map<String, List<StickyNote>> build() {
    return {};
  }

  StickyNoteRepository get _repo => ref.read(stickyNoteRepositoryProvider);

  /// Loads sticky notes from SQLite for a page.
  Future<void> loadStickyNotes(String pageId) async {
    final notes = await _repo.getStickyNotesForPage(pageId);
    state = {...state, pageId: notes};
  }

  /// Creates and adds a new sticky note on the specified page.
  Future<StickyNote> addStickyNote(
    String pageId, {
    required double x,
    required double y,
    String content = 'Tap to edit note...',
    String colorHex = StickyNoteColors.canaryYellow,
  }) async {
    final now = DateTime.now();
    final note = StickyNote(
      id: 'sticky-${_uuid.v4()}',
      pageId: pageId,
      x: x,
      y: y,
      content: content,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );

    final currentNotes = List<StickyNote>.from(state[pageId] ?? [])..add(note);
    state = {...state, pageId: currentNotes};

    await _repo.saveStickyNote(note);
    return note;
  }

  /// Updates the position of a sticky note.
  Future<void> updatePosition(
    String pageId,
    String noteId,
    double x,
    double y,
  ) async {
    final currentNotes = state[pageId] ?? [];
    final updatedList = [
      for (final n in currentNotes)
        if (n.id == noteId)
          n.copyWith(x: x, y: y, updatedAt: DateTime.now())
        else
          n,
    ];
    state = {...state, pageId: updatedList};
    await _repo.updatePosition(noteId, x, y);
  }

  /// Updates the text content of a sticky note.
  Future<void> updateContent(
    String pageId,
    String noteId,
    String content,
  ) async {
    final currentNotes = state[pageId] ?? [];
    final updatedList = [
      for (final n in currentNotes)
        if (n.id == noteId)
          n.copyWith(content: content, updatedAt: DateTime.now())
        else
          n,
    ];
    state = {...state, pageId: updatedList};
    await _repo.updateContent(noteId, content);
  }

  /// Updates the background color of a sticky note.
  Future<void> updateColor(
    String pageId,
    String noteId,
    String colorHex,
  ) async {
    final currentNotes = state[pageId] ?? [];
    final updatedList = [
      for (final n in currentNotes)
        if (n.id == noteId)
          n.copyWith(colorHex: colorHex, updatedAt: DateTime.now())
        else
          n,
    ];
    state = {...state, pageId: updatedList};
    await _repo.updateColor(noteId, colorHex);
  }

  /// Deletes a sticky note.
  Future<void> deleteStickyNote(String pageId, String noteId) async {
    final currentNotes = state[pageId] ?? [];
    final updatedList = currentNotes.where((n) => n.id != noteId).toList();
    state = {...state, pageId: updatedList};
    await _repo.deleteStickyNote(noteId);
  }
}

/// Global provider for sticky notes.
final stickyNotesProvider =
    NotifierProvider<StickyNotesNotifier, Map<String, List<StickyNote>>>(
      StickyNotesNotifier.new,
    );

/// Computed provider for sticky notes on a specific page.
final pageStickyNotesProvider = Provider.family<List<StickyNote>, String>((
  ref,
  pageId,
) {
  final notesMap = ref.watch(stickyNotesProvider);
  return notesMap[pageId] ?? [];
});
