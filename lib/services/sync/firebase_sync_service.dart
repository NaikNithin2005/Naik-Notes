import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/folder_model.dart';
import '../../data/models/notebook_model.dart';
import '../../data/models/page_model.dart';
import '../../data/models/paper_template_model.dart';
import '../../data/models/sticky_note_model.dart';
import '../../data/models/stroke_model.dart';

/// Direct Firebase Cloud Firestore synchronization service.
/// Enforces user-isolated paths: `/users/{uid}/...`
class FirebaseSyncService {
  final FirebaseFirestore? _customFirestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notebooksSubscription;

  FirebaseSyncService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  CollectionReference<Map<String, dynamic>>? _userNotebooksRef(String uid) {
    return _firestore?.collection('users').doc(uid).collection('notebooks');
  }

  CollectionReference<Map<String, dynamic>>? _userFoldersRef(String uid) {
    return _firestore?.collection('users').doc(uid).collection('folders');
  }

  CollectionReference<Map<String, dynamic>>? _userPagesRef(
    String uid,
    String notebookId,
  ) {
    return _userNotebooksRef(uid)?.doc(notebookId).collection('pages');
  }

  CollectionReference<Map<String, dynamic>>? _userStrokesRef(
    String uid,
    String notebookId,
    String pageId,
  ) {
    return _userPagesRef(uid, notebookId)?.doc(pageId).collection('strokes');
  }

  CollectionReference<Map<String, dynamic>>? _userStickyNotesRef(
    String uid,
    String notebookId,
    String pageId,
  ) {
    return _userPagesRef(uid, notebookId)?.doc(pageId).collection('sticky_notes');
  }

  // --- NOTEBOOKS ---

  /// Pushes a notebook document to `/users/{uid}/notebooks/{notebookId}`
  Future<bool> pushNotebook(String uid, Notebook notebook) async {
    final ref = _userNotebooksRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(notebook.id).set({
        'id': notebook.id,
        'ownerId': uid,
        'folderId': notebook.folderId,
        'title': notebook.title,
        'description': notebook.description,
        'coverId': notebook.coverId,
        'coverColorHex': notebook.coverColorHex,
        'coverImageUrl': notebook.coverImageUrl,
        'paperTemplateId': notebook.paperTemplateId,
        'orientation': notebook.orientation,
        'pageSize': notebook.pageSize,
        'pageCount': notebook.pageCount,
        'isFavorite': notebook.isFavorite,
        'isArchived': notebook.isArchived,
        'isPdf': notebook.isPdf,
        'pdfPath': notebook.pdfPath,
        'revision': notebook.revision,
        'createdAt': notebook.createdAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': notebook.deletedAt?.toIso8601String(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushNotebook failed for ${notebook.id}: $e');
      return false;
    }
  }

  /// Soft or hard deletes a notebook document from Firestore.
  Future<bool> deleteNotebook(String uid, String notebookId) async {
    final ref = _userNotebooksRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(notebookId).set({
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] deleteNotebook failed for $notebookId: $e');
      return false;
    }
  }

  /// Fetches all remote notebooks for [uid].
  Future<List<Notebook>> fetchNotebooks(String uid) async {
    final ref = _userNotebooksRef(uid);
    if (ref == null) return [];
    try {
      final snapshot = await ref.get();

      final list = <Notebook>[];
      for (final doc in snapshot.docs) {
        list.add(_notebookFromFirestore(doc.id, doc.data()));
      }
      return list;
    } catch (e) {
      debugPrint('Firestore fetchNotebooks note: $e');
      return [];
    }
  }

  /// Listens to real-time changes on `/users/{uid}/notebooks` and invokes callback.
  void listenToNotebooks(
    String uid,
    void Function(List<Notebook> notebooks) onData,
  ) {
    _notebooksSubscription?.cancel();
    final ref = _userNotebooksRef(uid);
    if (ref == null) return;
    try {
      _notebooksSubscription = ref
          .snapshots()
          .listen(
            (snapshot) {
              final list = <Notebook>[];
              for (final doc in snapshot.docs) {
                try {
                  final data = doc.data();
                  list.add(_notebookFromFirestore(doc.id, data));
                } catch (e) {
                  debugPrint('Parsing remote notebook error: $e');
                }
              }
              onData(list);
            },
            onError: (err) {
              debugPrint('Firestore notebooks listener note: $err');
            },
          );
    } catch (e) {
      debugPrint('Listen to notebooks init note: $e');
    }
  }

  // --- FOLDERS ---

  /// Pushes a folder document to `/users/{uid}/folders/{folderId}`
  Future<bool> pushFolder(String uid, Folder folder) async {
    final ref = _userFoldersRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(folder.id).set({
        'id': folder.id,
        'ownerId': uid,
        'parentId': folder.parentId,
        'name': folder.name,
        'colorHex': folder.colorHex,
        'createdAt': folder.createdAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': folder.deletedAt?.toIso8601String(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushFolder failed for ${folder.id}: $e');
      return false;
    }
  }

  /// Soft deletes a folder document.
  Future<bool> deleteFolder(String uid, String folderId) async {
    final ref = _userFoldersRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(folderId).set({
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] deleteFolder failed for $folderId: $e');
      return false;
    }
  }

  /// Fetches all folders for [uid].
  Future<List<Folder>> fetchFolders(String uid) async {
    final ref = _userFoldersRef(uid);
    if (ref == null) return [];
    try {
      final snapshot = await ref.get();
      final list = <Folder>[];
      for (final doc in snapshot.docs) {
        final d = doc.data();
        final now = DateTime.now();
        list.add(
          Folder(
            id: doc.id,
            ownerId: d['ownerId'] as String? ?? uid,
            parentId: d['parentId'] as String?,
            name: d['name'] as String? ?? 'Folder',
            colorHex: d['colorHex'] as String? ?? '#8B4513',
            createdAt: d['createdAt'] != null
                ? DateTime.tryParse(d['createdAt'] as String) ?? now
                : now,
            updatedAt: now,
            deletedAt: d['deletedAt'] != null
                ? DateTime.tryParse(d['deletedAt'] as String)
                : null,
          ),
        );
      }
      return list;
    } catch (e) {
      debugPrint('Firestore fetchFolders note: $e');
      return [];
    }
  }

  // --- PAGES ---

  /// Pushes a page document to `/users/{uid}/notebooks/{notebookId}/pages/{pageId}`
  Future<bool> pushPage(
    String uid,
    String notebookId,
    NotebookPage page,
  ) async {
    final ref = _userPagesRef(uid, notebookId);
    if (ref == null) return false;
    try {
      await ref.doc(page.id).set({
        'id': page.id,
        'notebookId': notebookId,
        'sectionId': page.sectionId,
        'pageNumber': page.pageNumber,
        'templateId': page.templateId,
        'properties': page.properties.toJson(),
        'width': page.width,
        'height': page.height,
        'isBookmarked': page.isBookmarked,
        'pdfPageIndex': page.pdfPageIndex,
        'revision': page.revision,
        'createdAt': page.createdAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushPage failed for ${page.id}: $e');
      return false;
    }
  }

  /// Deletes a page document from `/users/{uid}/notebooks/{notebookId}/pages/{pageId}`
  Future<bool> deletePage(String uid, String notebookId, String pageId) async {
    final ref = _userPagesRef(uid, notebookId);
    if (ref == null) return false;
    try {
      await ref.doc(pageId).delete();
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] deletePage failed for $pageId: $e');
      return false;
    }
  }

  /// Fetches all pages for a given notebook under `/users/{uid}/notebooks/{notebookId}/pages`
  Future<List<NotebookPage>> fetchPages(String uid, String notebookId) async {
    final ref = _userPagesRef(uid, notebookId);
    if (ref == null) return [];
    try {
      final snapshot = await ref.orderBy('pageNumber').get();

      final list = <NotebookPage>[];
      for (final doc in snapshot.docs) {
        final d = doc.data();
        final templateId = d['templateId'] as String? ?? 'college_ruled';
        final propsMap = d['properties'] as Map<String, dynamic>?;

        list.add(
          NotebookPage(
            id: doc.id,
            notebookId: notebookId,
            sectionId: d['sectionId'] as String?,
            pageNumber: d['pageNumber'] as int? ?? 1,
            templateId: templateId,
            properties: propsMap != null
                ? PaperProperties.fromJson(propsMap)
                : PaperProperties.defaultFor(
                    PaperTemplateType.fromId(templateId),
                  ),
            width: (d['width'] as num?)?.toDouble() ?? 595.28,
            height: (d['height'] as num?)?.toDouble() ?? 841.89,
            isBookmarked: d['isBookmarked'] as bool? ?? false,
            pdfPageIndex: d['pdfPageIndex'] as int?,
            revision: d['revision'] as int? ?? 1,
            createdAt: d['createdAt'] != null
                ? DateTime.tryParse(d['createdAt'] as String) ?? DateTime.now()
                : DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }
      return list;
    } catch (e) {
      debugPrint('Firestore fetchPages note: $e');
      return [];
    }
  }

  // --- STROKES ---

  /// Pushes a batch of handwriting strokes to Firestore
  Future<void> pushStrokes(
    String uid,
    String notebookId,
    String pageId,
    List<Stroke> strokes,
  ) async {
    if (strokes.isEmpty) return;
    final db = _firestore;
    final strokesRef = _userStrokesRef(uid, notebookId, pageId);
    if (db == null || strokesRef == null) return;
    try {
      final batch = db.batch();

      for (final s in strokes) {
        final doc = strokesRef.doc(s.id);
        batch.set(doc, {
          'id': s.id,
          'pageId': pageId,
          'tool': s.tool.name,
          'colorValue': s.colorValue,
          'width': s.width,
          'opacity': s.opacity,
          'points': s.points
              .map(
                (p) => {
                  'x': p.x,
                  'y': p.y,
                  'pressure': p.pressure,
                  'tilt': p.tilt,
                  'timestamp': p.timestamp,
                },
              )
              .toList(),
          'revision': s.revision,
          'createdAt': s.createdAt.toIso8601String(),
          'deletedAt': s.deletedAt?.toIso8601String(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Firestore pushStrokes note: $e');
    }
  }

  /// Fetches strokes for a page.
  Future<List<Stroke>> fetchStrokes(
    String uid,
    String notebookId,
    String pageId,
  ) async {
    final strokesRef = _userStrokesRef(uid, notebookId, pageId);
    if (strokesRef == null) return [];
    try {
      final snapshot = await strokesRef.get();
      final list = <Stroke>[];
      for (final doc in snapshot.docs) {
        final d = doc.data();
        final ptsRaw = d['points'] as List<dynamic>? ?? [];
        final points = ptsRaw.map((p) {
          final m = p as Map<String, dynamic>;
          return StrokePoint(
            x: (m['x'] as num).toDouble(),
            y: (m['y'] as num).toDouble(),
            pressure: (m['pressure'] as num?)?.toDouble() ?? 0.5,
            tilt: (m['tilt'] as num?)?.toDouble() ?? 0.0,
            timestamp: m['timestamp'] as int? ?? 0,
          );
        }).toList();

        final toolName = d['tool'] as String? ?? 'ballpointPen';
        final tool = ToolType.values.firstWhere(
          (t) => t.name == toolName,
          orElse: () => ToolType.ballpointPen,
        );

        list.add(
          Stroke(
            id: doc.id,
            pageId: pageId,
            tool: tool,
            colorValue: d['colorValue'] as int? ?? 0xFF000000,
            width: (d['width'] as num?)?.toDouble() ?? 2.0,
            opacity: (d['opacity'] as num?)?.toDouble() ?? 1.0,
            points: points,
            revision: d['revision'] as int? ?? 1,
            createdAt: d['createdAt'] != null
                ? DateTime.tryParse(d['createdAt'] as String) ?? DateTime.now()
                : DateTime.now(),
            deletedAt: d['deletedAt'] != null
                ? DateTime.tryParse(d['deletedAt'] as String)
                : null,
          ),
        );
      }
      return list;
    } catch (e) {
      debugPrint('Firestore fetchStrokes note: $e');
      return [];
    }
  }

  // --- STICKY NOTES ---

  /// Pushes a sticky note annotation to Firestore
  Future<bool> pushStickyNote(
    String uid,
    String notebookId,
    String pageId,
    StickyNote note,
  ) async {
    final ref = _userStickyNotesRef(uid, notebookId, pageId);
    if (ref == null) return false;
    try {
      await ref.doc(note.id).set({
        'id': note.id,
        'pageId': pageId,
        'x': note.x,
        'y': note.y,
        'width': note.width,
        'height': note.height,
        'content': note.content,
        'colorHex': note.colorHex,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Firestore pushStickyNote note: $e');
      return false;
    }
  }

  /// Deletes a sticky note annotation from Firestore
  Future<bool> deleteStickyNote(
    String uid,
    String notebookId,
    String pageId,
    String noteId,
  ) async {
    final ref = _userStickyNotesRef(uid, notebookId, pageId);
    if (ref == null) return false;
    try {
      await ref.doc(noteId).delete();
      return true;
    } catch (e) {
      debugPrint('Firestore deleteStickyNote note: $e');
      return false;
    }
  }

  void dispose() {
    _notebooksSubscription?.cancel();
  }

  Notebook _notebookFromFirestore(String id, Map<String, dynamic> d) {
    final now = DateTime.now();
    return Notebook(
      id: id,
      ownerId: d['ownerId'] as String? ?? 'unknown',
      folderId: d['folderId'] as String?,
      title: d['title'] as String? ?? 'Untitled Notebook',
      description: d['description'] as String? ?? '',
      coverId: d['coverId'] as String? ?? 'classic_leather',
      coverColorHex: d['coverColorHex'] as String? ?? '#8B4513',
      coverImageUrl: d['coverImageUrl'] as String?,
      paperTemplateId: d['paperTemplateId'] as String? ?? 'college_ruled',
      orientation: d['orientation'] as String? ?? 'portrait',
      pageSize: d['pageSize'] as String? ?? 'A4',
      pageCount: d['pageCount'] as int? ?? 1,
      isFavorite: d['isFavorite'] as bool? ?? false,
      isArchived: d['isArchived'] as bool? ?? false,
      isPdf: d['isPdf'] as bool? ?? false,
      pdfPath: d['pdfPath'] as String?,
      revision: d['revision'] as int? ?? 1,
      createdAt: d['createdAt'] != null
          ? DateTime.tryParse(d['createdAt'] as String) ?? now
          : now,
      updatedAt: now,
      deletedAt: d['deletedAt'] != null
          ? DateTime.tryParse(d['deletedAt'] as String)
          : null,
    );
  }
}
