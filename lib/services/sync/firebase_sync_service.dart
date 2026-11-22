import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/folder_model.dart';
import '../../data/models/note_model.dart';
import '../../data/models/notebook_model.dart';
import '../../data/models/page_model.dart';
import '../../data/models/paper_template_model.dart';
import '../../data/models/sticky_note_model.dart';
import '../../data/models/stroke_model.dart';
import '../../data/models/tombstone_model.dart';
import 'package:uuid/uuid.dart';

/// Result container for cursor-based paginated note queries.
class PaginatedNotesResult {
  final List<Note> notes;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PaginatedNotesResult({
    required this.notes,
    this.lastDocument,
    required this.hasMore,
  });

  factory PaginatedNotesResult.empty() => const PaginatedNotesResult(
        notes: [],
        lastDocument: null,
        hasMore: false,
      );
}

/// Direct Firebase Cloud Firestore synchronization service.
/// Enforces user-isolated paths: `/users/{uid}/...`
class FirebaseSyncService {
  final FirebaseFirestore? _customFirestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notebooksSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notesSubscription;

  FirebaseSyncService({FirebaseFirestore? firestore})
    : _customFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      if (Firebase.apps.isEmpty) return null;
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

  CollectionReference<Map<String, dynamic>>? _userNotesRef(String uid) {
    return _firestore?.collection('users').doc(uid).collection('notes');
  }

  CollectionReference<Map<String, dynamic>>? _userTombstonesRef(String uid) {
    return _firestore?.collection('users').doc(uid).collection('tombstones');
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

  // --- TOMBSTONES ---

  /// Pushes a permanent deletion tombstone to `/users/{uid}/tombstones/{id}`.
  Future<bool> pushTombstone(String uid, Tombstone tombstone) async {
    final ref = _userTombstonesRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(tombstone.id).set({
        'id': tombstone.id,
        'ownerId': uid,
        'entityType': tombstone.entityType,
        'deletionId': tombstone.deletionId,
        'deletedAt': tombstone.deletedAt.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushTombstone failed for ${tombstone.id}: $e');
      return false;
    }
  }

  /// Batches pushing multiple deletion tombstones to Firestore.
  Future<bool> pushTombstonesBatch(String uid, List<Tombstone> tombstones) async {
    final ref = _userTombstonesRef(uid);
    if (ref == null || _firestore == null || tombstones.isEmpty) return false;
    try {
      const chunkSize = 100;
      for (var i = 0; i < tombstones.length; i += chunkSize) {
        final end = (i + chunkSize < tombstones.length) ? i + chunkSize : tombstones.length;
        final chunk = tombstones.sublist(i, end);
        final batch = _firestore!.batch();
        for (final t in chunk) {
          batch.set(ref.doc(t.id), {
            'id': t.id,
            'ownerId': uid,
            'entityType': t.entityType,
            'deletionId': t.deletionId,
            'deletedAt': t.deletedAt.toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushTombstonesBatch failed: $e');
      return false;
    }
  }

  /// Fetches all active deletion tombstones for [uid].
  Future<List<Tombstone>> fetchTombstones(String uid) async {
    final ref = _userTombstonesRef(uid);
    if (ref == null) return [];
    try {
      final snapshot = await ref.get();
      final list = <Tombstone>[];
      for (final doc in snapshot.docs) {
        final d = doc.data();
        list.add(Tombstone(
          id: doc.id,
          ownerId: uid,
          entityType: d['entityType'] as String? ?? 'notebook',
          deletionId: d['deletionId'] as String? ?? doc.id,
          deletedAt: d['deletedAt'] != null
              ? DateTime.tryParse(d['deletedAt'] as String) ?? DateTime.now()
              : DateTime.now(),
          syncedAt: DateTime.now(),
        ));
      }
      return list;
    } catch (e) {
      debugPrint('[FirebaseSyncService] fetchTombstones note: $e');
      return [];
    }
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
        'deletionId': notebook.deletionId,
        'isDeleted': notebook.isDeleted,
        'syncStatus': 'synced',
        'lastSyncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushNotebook failed for ${notebook.id}: $e');
      return false;
    }
  }

  /// Soft deletes a notebook document from Firestore (moves to Trash).
  Future<bool> deleteNotebook(String uid, String notebookId, {String? deletionId}) async {
    final ref = _userNotebooksRef(uid);
    if (ref == null) return false;
    try {
      final delId = deletionId ?? const Uuid().v4();
      await ref.doc(notebookId).set({
        'ownerId': uid,
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'deletionId': delId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] deleteNotebook failed for $notebookId: $e');
      return false;
    }
  }

  /// Permanently removes a notebook document from Firestore and records a tombstone.
  Future<bool> permanentlyDeleteNotebook(
    String uid,
    String notebookId, {
    String? deletionId,
  }) async {
    final ref = _userNotebooksRef(uid);
    final tombRef = _userTombstonesRef(uid);
    if (ref == null) return false;
    try {
      final delId = deletionId ?? const Uuid().v4();
      if (tombRef != null) {
        try {
          await tombRef.doc(notebookId).set({
            'id': notebookId,
            'ownerId': uid,
            'entityType': 'notebook',
            'deletionId': delId,
            'deletedAt': DateTime.now().toIso8601String(),
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (te) {
          debugPrint('[FirebaseSyncService] push tombstone inside permanentlyDeleteNotebook: $te');
        }
      }
      await ref.doc(notebookId).delete();
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] permanentlyDeleteNotebook failed: $e');
      return false;
    }
  }

  /// Batches pushing multiple notebooks to `/users/{uid}/notebooks/{notebookId}`
  /// using Firestore WriteBatch with chunking (max 100 per batch).
  Future<bool> pushNotebooksBatch(String uid, List<Notebook> notebooks) async {
    final ref = _userNotebooksRef(uid);
    if (ref == null || _firestore == null || notebooks.isEmpty) return false;
    try {
      const chunkSize = 100;
      for (var i = 0; i < notebooks.length; i += chunkSize) {
        final end = (i + chunkSize < notebooks.length) ? i + chunkSize : notebooks.length;
        final chunk = notebooks.sublist(i, end);
        final batch = _firestore!.batch();
        for (final nb in chunk) {
          batch.set(ref.doc(nb.id), {
            'id': nb.id,
            'ownerId': uid,
            'folderId': nb.folderId,
            'title': nb.title,
            'description': nb.description,
            'coverId': nb.coverId,
            'coverColorHex': nb.coverColorHex,
            'coverImageUrl': nb.coverImageUrl,
            'paperTemplateId': nb.paperTemplateId,
            'orientation': nb.orientation,
            'pageSize': nb.pageSize,
            'pageCount': nb.pageCount,
            'isFavorite': nb.isFavorite,
            'isArchived': nb.isArchived,
            'isPdf': nb.isPdf,
            'pdfPath': nb.pdfPath,
            'revision': nb.revision,
            'createdAt': nb.createdAt.toIso8601String(),
            'updatedAt': FieldValue.serverTimestamp(),
            'deletedAt': nb.deletedAt?.toIso8601String(),
            'deletionId': nb.deletionId,
            'isDeleted': nb.isDeleted,
            'syncStatus': 'synced',
            'lastSyncedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushNotebooksBatch failed: $e');
      return false;
    }
  }

  /// Batches soft deleting multiple notebooks from Firestore.
  Future<bool> deleteNotebooksBatch(
    String uid,
    List<String> notebookIds, {
    String? deletionId,
  }) async {
    final ref = _userNotebooksRef(uid);
    if (ref == null || _firestore == null || notebookIds.isEmpty) return false;
    try {
      const chunkSize = 100;
      final nowIso = DateTime.now().toIso8601String();
      final delId = deletionId ?? const Uuid().v4();
      for (var i = 0; i < notebookIds.length; i += chunkSize) {
        final end = (i + chunkSize < notebookIds.length) ? i + chunkSize : notebookIds.length;
        final chunk = notebookIds.sublist(i, end);
        final batch = _firestore!.batch();
        for (final id in chunk) {
          batch.set(ref.doc(id), {
            'ownerId': uid,
            'isDeleted': true,
            'deletedAt': nowIso,
            'deletionId': delId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] deleteNotebooksBatch failed: $e');
      return false;
    }
  }

  /// Batches permanently deleting multiple notebooks from Firestore and records tombstones.
  Future<bool> permanentlyDeleteNotebooksBatch(
    String uid,
    List<String> notebookIds, {
    String? deletionId,
  }) async {
    final ref = _userNotebooksRef(uid);
    final tombRef = _userTombstonesRef(uid);
    if (ref == null || _firestore == null || notebookIds.isEmpty) return false;
    try {
      const chunkSize = 100;
      final nowIso = DateTime.now().toIso8601String();
      final delId = deletionId ?? const Uuid().v4();
      for (var i = 0; i < notebookIds.length; i += chunkSize) {
        final end = (i + chunkSize < notebookIds.length) ? i + chunkSize : notebookIds.length;
        final chunk = notebookIds.sublist(i, end);
        final deleteBatch = _firestore!.batch();
        for (final id in chunk) {
          deleteBatch.delete(ref.doc(id));
        }
        await deleteBatch.commit();

        if (tombRef != null) {
          try {
            final tombBatch = _firestore!.batch();
            for (final id in chunk) {
              tombBatch.set(tombRef.doc(id), {
                'id': id,
                'ownerId': uid,
                'entityType': 'notebook',
                'deletionId': delId,
                'deletedAt': nowIso,
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
            await tombBatch.commit();
          } catch (te) {
            debugPrint('[FirebaseSyncService] tombstone batch set notice: $te');
          }
        }
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] permanentlyDeleteNotebooksBatch failed: $e');
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
        'ownerId': uid,
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

  // --- RICH-TEXT NOTES ---

  /// Pushes a rich-text note document to `/users/{uid}/notes/{noteId}`.
  Future<bool> pushNote(String uid, Note note) async {
    final ref = _userNotesRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(note.id).set({
        'id': note.id,
        'ownerId': uid,
        'notebookId': note.notebookId,
        'title': note.title,
        'contentDelta': note.contentDelta,
        'plainText': note.plainText,
        'preview': note.preview,
        'tags': note.tags,
        'isPinned': note.isPinned,
        'isFavorite': note.isFavorite,
        'isArchived': note.isArchived,
        'isDeleted': note.isDeleted,
        'createdAt': note.createdAt.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': note.deletedAt?.toIso8601String(),
        'deletionId': note.deletionId,
        'syncStatus': 'synced',
        'lastSyncedAt': FieldValue.serverTimestamp(),
        'localVersion': note.localVersion,
        'serverVersion': note.serverVersion,
        'deviceId': note.deviceId,
        'lastModifiedBy': note.lastModifiedBy,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushNote failed for ${note.id}: $e');
      return false;
    }
  }

  /// Soft deletes a rich-text note document in Firestore.
  Future<bool> deleteNote(String uid, String noteId) async {
    final ref = _userNotesRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(noteId).set({
        'ownerId': uid,
        'isDeleted': true,
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] deleteNote failed for $noteId: $e');
      return false;
    }
  }

  /// Permanently removes a note document from Firestore.
  Future<bool> permanentlyDeleteNote(String uid, String noteId) async {
    final ref = _userNotesRef(uid);
    if (ref == null) return false;
    try {
      await ref.doc(noteId).delete();
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] permanentlyDeleteNote failed for $noteId: $e');
      return false;
    }
  }

  /// Batches pushing multiple notes to `/users/{uid}/notes/{noteId}`.
  Future<bool> pushNotesBatch(String uid, List<Note> notes) async {
    final ref = _userNotesRef(uid);
    if (ref == null || _firestore == null || notes.isEmpty) return false;
    try {
      const chunkSize = 100;
      for (var i = 0; i < notes.length; i += chunkSize) {
        final end = (i + chunkSize < notes.length) ? i + chunkSize : notes.length;
        final chunk = notes.sublist(i, end);
        final batch = _firestore!.batch();
        for (final note in chunk) {
          batch.set(ref.doc(note.id), {
            'id': note.id,
            'ownerId': uid,
            'notebookId': note.notebookId,
            'title': note.title,
            'contentDelta': note.contentDelta,
            'plainText': note.plainText,
            'preview': note.preview,
            'tags': note.tags,
            'isPinned': note.isPinned,
            'isFavorite': note.isFavorite,
            'isArchived': note.isArchived,
            'isDeleted': note.isDeleted,
            'createdAt': note.createdAt.toIso8601String(),
            'updatedAt': FieldValue.serverTimestamp(),
            'deletedAt': note.deletedAt?.toIso8601String(),
            'deletionId': note.deletionId,
            'syncStatus': 'synced',
            'lastSyncedAt': FieldValue.serverTimestamp(),
            'localVersion': note.localVersion,
            'serverVersion': note.serverVersion,
            'deviceId': note.deviceId,
            'lastModifiedBy': note.lastModifiedBy,
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] pushNotesBatch failed: $e');
      return false;
    }
  }

  /// Batches soft deleting multiple notes from Firestore.
  Future<bool> deleteNotesBatch(String uid, List<String> noteIds) async {
    final ref = _userNotesRef(uid);
    if (ref == null || _firestore == null || noteIds.isEmpty) return false;
    try {
      const chunkSize = 100;
      final nowIso = DateTime.now().toIso8601String();
      for (var i = 0; i < noteIds.length; i += chunkSize) {
        final end = (i + chunkSize < noteIds.length) ? i + chunkSize : noteIds.length;
        final chunk = noteIds.sublist(i, end);
        final batch = _firestore!.batch();
        for (final id in chunk) {
          batch.set(ref.doc(id), {
            'ownerId': uid,
            'isDeleted': true,
            'deletedAt': nowIso,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] deleteNotesBatch failed: $e');
      return false;
    }
  }

  /// Batches permanently deleting multiple notes from Firestore.
  Future<bool> permanentlyDeleteNotesBatch(String uid, List<String> noteIds) async {
    final ref = _userNotesRef(uid);
    if (ref == null || _firestore == null || noteIds.isEmpty) return false;
    try {
      const chunkSize = 100;
      for (var i = 0; i < noteIds.length; i += chunkSize) {
        final end = (i + chunkSize < noteIds.length) ? i + chunkSize : noteIds.length;
        final chunk = noteIds.sublist(i, end);
        final batch = _firestore!.batch();
        for (final id in chunk) {
          batch.delete(ref.doc(id));
        }
        await batch.commit();
      }
      return true;
    } catch (e) {
      debugPrint('[FirebaseSyncService] permanentlyDeleteNotesBatch failed: $e');
      return false;
    }
  }

  /// Fetches remote notes for [uid], with optional [notebookId] or [tag] filter.
  Future<List<Note>> fetchNotes(
    String uid, {
    String? notebookId,
    String? tag,
  }) async {
    final ref = _userNotesRef(uid);
    if (ref == null) return [];
    try {
      Query<Map<String, dynamic>> query = ref;
      if (notebookId != null) {
        query = query.where('notebookId', isEqualTo: notebookId);
      }
      if (tag != null) {
        query = query.where('tags', arrayContains: tag);
      }
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => _noteFromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FirebaseSyncService] fetchNotes error: $e');
      return [];
    }
  }

  /// Listens to real-time changes on `/users/{uid}/notes` and invokes callback.
  void listenToNotes(
    String uid,
    void Function(List<Note> notes, bool hasPendingWrites) onData,
  ) {
    _notesSubscription?.cancel();
    final ref = _userNotesRef(uid);
    if (ref == null) return;
    try {
      _notesSubscription = ref.snapshots(includeMetadataChanges: true).listen(
        (snapshot) {
          final list = <Note>[];
          for (final doc in snapshot.docs) {
            try {
              list.add(_noteFromFirestore(doc.id, doc.data()));
            } catch (e) {
              debugPrint('Parsing remote note error: $e');
            }
          }
          onData(list, snapshot.metadata.hasPendingWrites);
        },
        onError: (err) {
          debugPrint('Firestore notes listener error: $err');
        },
      );
    } catch (e) {
      debugPrint('Listen to notes error: $e');
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _scopedNotebookSub;

  /// Attaches a scoped real-time listener to notes within an active notebook.
  void listenToNotebookNotes(
    String uid,
    String notebookId,
    void Function(List<Note> notes, bool hasPendingWrites) onData,
  ) {
    _scopedNotebookSub?.cancel();
    final ref = _userNotesRef(uid);
    if (ref == null) return;
    try {
      _scopedNotebookSub = ref
          .where('notebookId', isEqualTo: notebookId)
          .snapshots(includeMetadataChanges: true)
          .listen((snapshot) {
        final list = <Note>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(_noteFromFirestore(doc.id, doc.data()));
          } catch (_) {}
        }
        onData(list, snapshot.metadata.hasPendingWrites);
      });
    } catch (e) {
      debugPrint('Listen to scoped notebook notes error: $e');
    }
  }

  /// Cursor-based pagination query for notes under `/users/{uid}/notes`.
  Future<PaginatedNotesResult> fetchNotesPaginated(
    String uid, {
    String? notebookId,
    int pageSize = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final ref = _userNotesRef(uid);
    if (ref == null) return PaginatedNotesResult.empty();
    try {
      Query<Map<String, dynamic>> query = ref
          .where('isDeleted', isEqualTo: false)
          .where('isArchived', isEqualTo: false)
          .orderBy('updatedAt', descending: true)
          .limit(pageSize);

      if (notebookId != null) {
        query = query.where('notebookId', isEqualTo: notebookId);
      }
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final notes = snapshot.docs
          .map((doc) => _noteFromFirestore(doc.id, doc.data()))
          .toList();
      return PaginatedNotesResult(
        notes: notes,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
        hasMore: snapshot.docs.length == pageSize,
      );
    } catch (e) {
      debugPrint('[FirebaseSyncService] fetchNotesPaginated error: $e');
      return PaginatedNotesResult.empty();
    }
  }

  void dispose() {
    _notebooksSubscription?.cancel();
    _notesSubscription?.cancel();
    _scopedNotebookSub?.cancel();
  }

  Note _noteFromFirestore(String id, Map<String, dynamic> d) {
    final now = DateTime.now();
    final rawDelta = d['contentDelta'] as String? ?? '[{"insert":"\\n"}]';
    final rawText = d['plainText'] as String? ?? Note.extractPlainText(rawDelta);
    final rawPreview = d['preview'] as String? ?? Note.generatePreview(rawText);

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return Note(
      id: id,
      ownerId: d['ownerId'] as String? ?? 'unknown',
      notebookId: d['notebookId'] as String? ?? '',
      title: d['title'] as String? ?? 'Untitled Note',
      contentDelta: rawDelta,
      plainText: rawText,
      preview: rawPreview,
      tags: (d['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isPinned: d['isPinned'] as bool? ?? false,
      isFavorite: d['isFavorite'] as bool? ?? false,
      isArchived: d['isArchived'] as bool? ?? false,
      isDeleted: d['isDeleted'] as bool? ?? false,
      createdAt: parseDate(d['createdAt']) ?? now,
      updatedAt: parseDate(d['updatedAt']) ?? now,
      deletedAt: parseDate(d['deletedAt']),
      deletionId: d['deletionId'] as String?,
      syncStatus: d['syncStatus'] as String? ?? 'synced',
      lastSyncedAt: parseDate(d['lastSyncedAt']) ?? now,
      localVersion: d['localVersion'] as int? ?? 1,
      serverVersion: d['serverVersion'] as int? ?? 1,
      deviceId: d['deviceId'] as String?,
      lastModifiedBy: d['lastModifiedBy'] as String?,
    );
  }

  Notebook _notebookFromFirestore(String id, Map<String, dynamic> d) {
    final now = DateTime.now();

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

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
      createdAt: parseDate(d['createdAt']) ?? now,
      updatedAt: parseDate(d['updatedAt']) ?? now,
      deletedAt: parseDate(d['deletedAt']),
      deletionId: d['deletionId'] as String?,
      syncStatus: d['syncStatus'] as String? ?? 'synced',
      lastSyncedAt: parseDate(d['lastSyncedAt']) ?? now,
    );
  }
}
