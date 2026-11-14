import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/repositories/folder_repository.dart';

/// State notifier managing user folders.
class FoldersNotifier extends Notifier<List<Folder>> {
  final _uuid = const Uuid();
  late final FolderRepository _repository;

  @override
  List<Folder> build() {
    _repository = ref.watch(folderRepositoryProvider);
    return _initialSampleFolders();
  }

  List<Folder> _initialSampleFolders() {
    final now = DateTime.now();
    return [
      Folder(
        id: 'folder-math-sci',
        ownerId: 'user-default',
        name: 'Mathematics & Science',
        colorHex: '#1E2A38',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      Folder(
        id: 'folder-personal',
        ownerId: 'user-default',
        name: 'Personal & Journal',
        colorHex: '#8B4513',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      Folder(
        id: 'folder-research',
        ownerId: 'user-default',
        name: 'Research & Planning',
        colorHex: '#4A6B53',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
    ];
  }

  Future<void> loadFromDatabase() async {
    await _repository.populateDefaultSampleFoldersIfEmpty();
    final dbFolders = await _repository.getAllFolders();
    if (dbFolders.isNotEmpty) {
      state = dbFolders;
    }
  }

  Future<Folder> createFolder({
    required String name,
    String colorHex = '#8B4513',
    String? parentId,
  }) async {
    final now = DateTime.now();
    final newFolder = Folder(
      id: _uuid.v4(),
      ownerId: 'user-default',
      parentId: parentId,
      name: name,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );

    state = [...state, newFolder];
    await _repository.saveFolder(newFolder);
    return newFolder;
  }

  Future<void> renameFolder(
    String id,
    String newName, {
    String? newColorHex,
  }) async {
    state = [
      for (final f in state)
        if (f.id == id)
          f.copyWith(
            name: newName,
            colorHex: newColorHex ?? f.colorHex,
            updatedAt: DateTime.now(),
          )
        else
          f,
    ];
    await _repository.renameFolder(id, newName, newColorHex: newColorHex);
  }

  Future<void> deleteFolder(String id) async {
    state = state.where((f) => f.id != id).toList();
    await _repository.deleteFolder(id);
  }
}

/// Global provider for folder list.
final foldersProvider = NotifierProvider<FoldersNotifier, List<Folder>>(
  FoldersNotifier.new,
);

/// Active folder filter on the dashboard (null = all notebooks, '__unfiled__' = no folder).
class SelectedFolderNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectFolder(String? folderId) => state = folderId;
  void clearSelection() => state = null;
}

final selectedFolderProvider =
    NotifierProvider<SelectedFolderNotifier, String?>(
      SelectedFolderNotifier.new,
    );
