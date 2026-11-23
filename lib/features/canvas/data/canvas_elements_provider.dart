import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/canvas_element_model.dart';

class CanvasElementsState {
  final Map<String, List<CanvasElement>> pageElements;
  final String? activeSelectedElementId;
  final CanvasElement? elementClipboard;

  const CanvasElementsState({
    this.pageElements = const {},
    this.activeSelectedElementId,
    this.elementClipboard,
  });

  CanvasElementsState copyWith({
    Map<String, List<CanvasElement>>? pageElements,
    String? activeSelectedElementId,
    bool clearActiveSelected = false,
    CanvasElement? elementClipboard,
  }) {
    return CanvasElementsState(
      pageElements: pageElements ?? this.pageElements,
      activeSelectedElementId: clearActiveSelected ? null : (activeSelectedElementId ?? this.activeSelectedElementId),
      elementClipboard: elementClipboard ?? this.elementClipboard,
    );
  }
}

class CanvasElementsNotifier extends Notifier<CanvasElementsState> {
  final _uuid = const Uuid();

  @override
  CanvasElementsState build() => const CanvasElementsState();

  void selectElement(String? elementId) {
    state = state.copyWith(
      activeSelectedElementId: elementId,
      clearActiveSelected: elementId == null,
    );
  }

  void addElement(CanvasElement element) {
    final currentList = List<CanvasElement>.from(state.pageElements[element.pageId] ?? []);
    currentList.add(element);

    final updatedMap = Map<String, List<CanvasElement>>.from(state.pageElements);
    updatedMap[element.pageId] = currentList;

    state = state.copyWith(
      pageElements: updatedMap,
      activeSelectedElementId: element.id,
    );
  }

  void updateElement(CanvasElement element) {
    final currentList = List<CanvasElement>.from(state.pageElements[element.pageId] ?? []);
    final idx = currentList.indexWhere((e) => e.id == element.id);
    if (idx != -1) {
      currentList[idx] = element.copyWith(updatedAt: DateTime.now());
      final updatedMap = Map<String, List<CanvasElement>>.from(state.pageElements);
      updatedMap[element.pageId] = currentList;
      state = state.copyWith(pageElements: updatedMap);
    }
  }

  void deleteElement(String pageId, String elementId) {
    final currentList = List<CanvasElement>.from(state.pageElements[pageId] ?? []);
    currentList.removeWhere((e) => e.id == elementId);

    final updatedMap = Map<String, List<CanvasElement>>.from(state.pageElements);
    updatedMap[pageId] = currentList;

    state = state.copyWith(
      pageElements: updatedMap,
      clearActiveSelected: state.activeSelectedElementId == elementId,
    );
  }

  void duplicateElement(String pageId, String elementId) {
    final currentList = state.pageElements[pageId] ?? [];
    final original = currentList.where((e) => e.id == elementId).firstOrNull;
    if (original == null) return;

    final newId = 'elem-${_uuid.v4()}';
    final duplicated = original.copyWith(
      id: newId,
      x: original.x + 24.0,
      y: original.y + 24.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    addElement(duplicated);
  }

  void reorderElement(String pageId, String elementId, {required bool bringToFront}) {
    final currentList = List<CanvasElement>.from(state.pageElements[pageId] ?? []);
    final target = currentList.where((e) => e.id == elementId).firstOrNull;
    if (target == null) return;

    currentList.remove(target);
    if (bringToFront) {
      currentList.add(target);
    } else {
      currentList.insert(0, target);
    }

    final updatedMap = Map<String, List<CanvasElement>>.from(state.pageElements);
    updatedMap[pageId] = currentList;
    state = state.copyWith(pageElements: updatedMap);
  }

  void copyElement(String pageId, String elementId) {
    final currentList = state.pageElements[pageId] ?? [];
    final target = currentList.where((e) => e.id == elementId).firstOrNull;
    if (target != null) {
      state = state.copyWith(elementClipboard: target);
    }
  }

  void pasteElement(String targetPageId, Offset targetCenter) {
    final clip = state.elementClipboard;
    if (clip == null) return;

    final newId = 'elem-${_uuid.v4()}';
    final pasted = clip.copyWith(
      id: newId,
      pageId: targetPageId,
      x: targetCenter.dx - (clip.width / 2.0),
      y: targetCenter.dy - (clip.height / 2.0),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    addElement(pasted);
  }
}

final canvasElementsProvider = NotifierProvider<CanvasElementsNotifier, CanvasElementsState>(
  CanvasElementsNotifier.new,
);

final pageCanvasElementsProvider = Provider.family<List<CanvasElement>, String>((ref, pageId) {
  final state = ref.watch(canvasElementsProvider);
  return state.pageElements[pageId] ?? const [];
});

