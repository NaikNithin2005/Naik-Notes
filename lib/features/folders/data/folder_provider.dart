import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database_provider.dart';
import '../../../data/models/folder_model.dart';
import '../../../data/models/sync_operation_model.dart';
import '../../../data/repositories/folder_repository.dart';
import '../../authentication/data/auth_provider.dart';
import '../../sync/data/sync_provider.dart';

/// State notifier managing user folders with strict identity isolation.
class FoldersNotifier extends Notifier<List<Folder>> {
  final _uuid = const Uuid();
  FolderRepository get _repository => ref.read(folderRepositoryProvider);

  @override
  List<Folder> build() {
    ref.watch(folderRepositoryProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user != null) {
      _loadInitial(user.id);
    } else {
      state = const [];
    }
    return [];
  }

  void _loadInitial(String userId) {
    _repository.getAllFolders(ownerId: userId).then((dbFolders) {
      if (ref.mounted) {
        state = dbFolders;
      }
    });
  }

  Future<void> loadFolders() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      state = const [];
      return;
    }
    final dbFolders = await _repository.getAllFolders(ownerId: user.id);
    state = dbFolders;
  }

  Future<void> loadFromDatabase() async => loadFolders();

  Future<Folder> createFolder({
    required String name,
    String colorHex = '#8B4513',
    String? parentId,
  }) async {
    final now = DateTime.now();
    final currentUserId = ref.read(authProvider).user?.id ?? 'local_user';
    final newFolder = Folder(
      id: _uuid.v4(),
      ownerId: currentUserId,
      parentId: parentId,
      name: name,
      colorHex: colorHex,
      createdAt: now,
      updatedAt: now,
    );

    state = [...state, newFolder];
    await _repository.saveFolder(newFolder);
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueFolderMutation(newFolder, SyncOperationType.insert);
    } catch (_) {}
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
    try {
      final f = state.firstWhere((folder) => folder.id == id);
      await ref
          .read(syncServiceProvider)
          .enqueueFolderMutation(f, SyncOperationType.update);
    } catch (_) {}
  }

  Future<void> deleteFolder(String id) async {
    final toDelete = state.firstWhere(
      (f) => f.id == id,
      orElse: () => Folder(
        id: id,
        ownerId: 'local_user',
        name: 'Deleted Folder',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    state = state.where((f) => f.id != id).toList();
    await _repository.deleteFolder(id);
    try {
      await ref
          .read(syncServiceProvider)
          .enqueueFolderMutation(toDelete, SyncOperationType.delete);
    } catch (_) {}
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
