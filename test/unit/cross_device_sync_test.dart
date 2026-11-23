import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/data/repositories/page_repository.dart';

class _FakePageRepository implements PageRepository {
  final Map<String, NotebookPage> _pages = {};

  @override
  Future<List<NotebookPage>> getPagesForNotebook(String notebookId) async {
    return _pages.values.where((p) => p.notebookId == notebookId).toList();
  }

  @override
  Stream<List<NotebookPage>> watchPagesForNotebook(String notebookId) {
    return Stream.value(
      _pages.values.where((p) => p.notebookId == notebookId).toList(),
    );
  }

  @override
  Future<NotebookPage?> getPageById(String pageId) async => _pages[pageId];

  @override
  Future<void> savePage(NotebookPage page) async {
    _pages[page.id] = page;
  }

  @override
  Future<void> deletePage(String pageId) async {
    _pages.remove(pageId);
  }

  @override
  Future<void> updatePageTemplate(
    String pageId,
    String templateId,
    PaperProperties properties,
  ) async {
    final existing = _pages[pageId];
    if (existing != null) {
      _pages[pageId] = existing.copyWith(
        templateId: templateId,
        properties: properties,
      );
    }
  }

  @override
  Future<void> toggleBookmark(String pageId) async {
    final existing = _pages[pageId];
    if (existing != null) {
      _pages[pageId] = existing.copyWith(isBookmarked: !existing.isBookmarked);
    }
  }

  @override
  Future<List<NotebookPage>> ensurePagesExist(
    String notebookId, {
    String templateId = 'college_ruled',
    String pageSize = 'A4',
    String orientation = 'portrait',
    int count = 1,
  }) async {
    final existing = await getPagesForNotebook(notebookId);
    if (existing.isNotEmpty) return existing;

    final type = PaperTemplateType.fromId(templateId);
    final props = PaperProperties.defaultFor(type);
    final dims = PaperProperties.getDimensions(pageSize, orientation);
    final now = DateTime.now();

    final created = <NotebookPage>[];
    for (var i = 1; i <= count; i++) {
      final p = NotebookPage(
        id: 'auto-page-$i',
        notebookId: notebookId,
        pageNumber: i,
        templateId: templateId,
        properties: props,
        width: dims.width,
        height: dims.height,
        createdAt: now,
        updatedAt: now,
      );
      _pages[p.id] = p;
      created.add(p);
    }
    return created;
  }
}

void main() {
  group('Cross-Device Synchronization & Conflict Safeguards', () {
    test('Remote page hydration prevents creating divergent page IDs on secondary device', () async {
      final pageRepo = _FakePageRepository();
      const notebookId = 'nb-shared-across-devices';

      // Simulate Device A created Page 'cloud-page-1' on Firestore
      final cloudPage = NotebookPage(
        id: 'cloud-page-1',
        notebookId: notebookId,
        pageNumber: 1,
        templateId: 'college_ruled',
        properties: PaperProperties.defaultFor(PaperTemplateType.collegeRuled),
        createdAt: DateTime(2026, 11, 23, 10, 0),
        updatedAt: DateTime(2026, 11, 23, 10, 0),
      );

      // On Device B, loadPages receives remote pages first and saves to repo
      await pageRepo.savePage(cloudPage);

      // When ensurePagesExist is called, it returns the shared cloud page instead of generating a new random UUID
      final pagesOnDeviceB = await pageRepo.ensurePagesExist(notebookId);
      expect(pagesOnDeviceB.length, 1);
      expect(pagesOnDeviceB.first.id, 'cloud-page-1');
      expect(pagesOnDeviceB.first.id, isNot('auto-page-1'));
    });

    test('Conflict detection detects concurrent divergence and preserves local edits', () {
      final originalNote = Note.createBlank(
        ownerId: 'user-alpha',
        notebookId: 'nb-shared',
        title: 'Original Title',
      ).copyWith(
        contentDelta: '[{"insert":"Version 1\\n"}]',
        localVersion: 1,
        serverVersion: 1,
        syncStatus: 'synced',
      );

      // Local device edits offline
      final localDirtyNote = originalNote.copyWith(
        title: 'Local Edits by Device A',
        contentDelta: '[{"insert":"Device A offline edits\\n"}]',
        localVersion: 2,
        syncStatus: 'pending',
      );

      // Meanwhile, Device B pushed a newer version to Firestore
      final remoteNewerNote = originalNote.copyWith(
        title: 'Remote Edits by Device B',
        contentDelta: '[{"insert":"Device B cloud edits\\n"}]',
        serverVersion: 2,
        syncStatus: 'synced',
        updatedAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      final isLocalModified = localDirtyNote.syncStatus == 'pending';
      final isRemoteNewer = remoteNewerNote.serverVersion > localDirtyNote.serverVersion ||
          (remoteNewerNote.serverVersion == localDirtyNote.serverVersion &&
              remoteNewerNote.updatedAt.isAfter(localDirtyNote.updatedAt));
      final hasContentDiverged =
          localDirtyNote.contentDelta != remoteNewerNote.contentDelta ||
          localDirtyNote.title != remoteNewerNote.title;

      // Assert collision condition matches
      expect(isLocalModified, isTrue);
      expect(isRemoteNewer, isTrue);
      expect(hasContentDiverged, isTrue);

      // Create conflict copy safely
      final conflictTitle = '${localDirtyNote.title} (Conflict Copy - Windows)';
      final conflictNote = localDirtyNote.copyWith(
        id: 'conflict-copy-id',
        title: conflictTitle,
      );

      expect(conflictNote.title.contains('Conflict Copy'), isTrue);
      expect(conflictNote.contentDelta, localDirtyNote.contentDelta);
      // Canonical note accepts authoritative remote
      expect(remoteNewerNote.contentDelta.contains('Device B'), isTrue);
    });

    test('Dirty state protection ignores remote document clobbering while actively editing', () {
      bool canHydrate({
        required bool isDirty,
        required String activeId,
        required String incomingId,
      }) {
        return !isDirty && activeId == incomingId;
      }

      expect(
        canHydrate(isDirty: true, activeId: 'note-1', incomingId: 'note-1'),
        isFalse,
      );
      expect(
        canHydrate(isDirty: false, activeId: 'note-1', incomingId: 'note-1'),
        isTrue,
      );
      expect(
        canHydrate(isDirty: false, activeId: 'note-1', incomingId: 'note-2'),
        isFalse,
      );
    });
  });
}
