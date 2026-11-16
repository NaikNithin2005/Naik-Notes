import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/notebook_model.dart';
import '../../data/models/page_model.dart';
import '../../data/models/paper_template_model.dart';
import '../../data/models/stroke_model.dart';

/// Direct Firebase Cloud Firestore synchronization service.
/// Enforces user-isolated paths: `/users/{uid}/notebooks/{notebookId}/...`
class FirebaseSyncService {
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notebooksSubscription;

  FirebaseSyncService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userNotebooksRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('notebooks');
  }

  CollectionReference<Map<String, dynamic>> _userPagesRef(
    String uid,
    String notebookId,
  ) {
    return _userNotebooksRef(uid).doc(notebookId).collection('pages');
  }

  CollectionReference<Map<String, dynamic>> _userStrokesRef(
    String uid,
    String notebookId,
    String pageId,
  ) {
    return _userPagesRef(uid, notebookId).doc(pageId).collection('strokes');
  }

  /// Pushes a notebook document to `/users/{uid}/notebooks/{notebookId}`
  Future<void> pushNotebook(String uid, Notebook notebook) async {
    try {
      await _userNotebooksRef(uid).doc(notebook.id).set({
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
    } catch (e) {
      debugPrint('Firestore pushNotebook note: $e');
    }
  }

  /// Soft or hard deletes a notebook document from Firestore.
  Future<void> deleteNotebook(String uid, String notebookId) async {
    try {
      await _userNotebooksRef(uid).doc(notebookId).update({
        'deletedAt': DateTime.now().toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore deleteNotebook note: $e');
    }
  }

  /// Pushes a page document to `/users/{uid}/notebooks/{notebookId}/pages/{pageId}`
  Future<void> pushPage(
    String uid,
    String notebookId,
    NotebookPage page,
  ) async {
    try {
      await _userPagesRef(uid, notebookId).doc(page.id).set({
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
    } catch (e) {
      debugPrint('Firestore pushPage note: $e');
    }
  }

  /// Deletes a page document from `/users/{uid}/notebooks/{notebookId}/pages/{pageId}`
  Future<void> deletePage(String uid, String notebookId, String pageId) async {
    try {
      await _userPagesRef(uid, notebookId).doc(pageId).delete();
    } catch (e) {
      debugPrint('Firestore deletePage note: $e');
    }
  }

  /// Pushes a batch of handwriting strokes to Firestore
  Future<void> pushStrokes(
    String uid,
    String notebookId,
    String pageId,
    List<Stroke> strokes,
  ) async {
    if (strokes.isEmpty) return;
    try {
      final batch = _firestore.batch();
      final strokesRef = _userStrokesRef(uid, notebookId, pageId);

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

  /// Listens to real-time changes on `/users/{uid}/notebooks` and invokes callback.
  void listenToNotebooks(
    String uid,
    void Function(List<Notebook> notebooks) onData,
  ) {
    _notebooksSubscription?.cancel();
    try {
      _notebooksSubscription = _userNotebooksRef(uid)
          .where('deletedAt', isNull: true)
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

  /// Fetches all remote notebooks for [uid].
  Future<List<Notebook>> fetchNotebooks(String uid) async {
    try {
      final snapshot = await _userNotebooksRef(
        uid,
      ).where('deletedAt', isNull: true).get();

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

  /// Fetches all pages for a given notebook under `/users/{uid}/notebooks/{notebookId}/pages`
  Future<List<NotebookPage>> fetchPages(String uid, String notebookId) async {
    try {
      final snapshot = await _userPagesRef(
        uid,
        notebookId,
      ).orderBy('pageNumber').get();

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
    );
  }
}
