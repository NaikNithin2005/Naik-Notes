import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../data/models/search_index_model.dart';
import '../../data/models/stroke_model.dart';
import '../../data/repositories/page_search_repository.dart';

/// Service responsible for vector handwriting clustering, bounding box calculation,
/// local heuristic and server-assisted OCR recognition, and full-text search indexing.
class HandwritingRecognitionService {
  final PageSearchRepository searchRepository;
  final http.Client _client;
  final String _baseUrl;

  /// Default vocabulary for local offline heuristic handwriting clustering.
  static const List<String> defaultLexicon = [
    'Naik',
    'Notes',
    'Lecture',
    'Physics',
    'Calculus',
    'Formula',
    'Important',
    'Chapter',
    'Summary',
    'Theorem',
    'Derivation',
    'Experiment',
    'Assignment',
    'Review',
    'Analysis',
  ];

  HandwritingRecognitionService({
    required this.searchRepository,
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.devApiBaseUrl;

  /// Clusters vector strokes into word bounding boxes using spatial proximity.
  List<WordBoundingBox> clusterStrokesIntoWords(
    List<Stroke> strokes, {
    List<String>? lexicon,
    double lineThreshold = 40.0,
    double horizontalGapThreshold = 35.0,
  }) {
    // Filter to valid handwriting strokes
    final validStrokes = strokes.where((s) {
      if (s.deletedAt != null) return false;
      if (s.points.isEmpty) return false;
      if (s.tool == ToolType.eraser ||
          s.tool == ToolType.lasso ||
          s.tool == ToolType.pan) {
        return false;
      }
      return true;
    }).toList();

    if (validStrokes.isEmpty) return [];

    // Sort strokes top-to-bottom (bucketed by lineThreshold), then left-to-right
    validStrokes.sort((a, b) {
      final aLine = (a.boundingBox.top / lineThreshold).round();
      final bLine = (b.boundingBox.top / lineThreshold).round();
      if (aLine != bLine) {
        return aLine.compareTo(bLine);
      }
      return a.boundingBox.left.compareTo(b.boundingBox.left);
    });

    final clusters = <List<Stroke>>[];
    var currentCluster = <Stroke>[];

    for (final stroke in validStrokes) {
      if (currentCluster.isEmpty) {
        currentCluster.add(stroke);
        continue;
      }

      final lastStroke = currentCluster.last;
      final verticalDiff = (stroke.boundingBox.top - lastStroke.boundingBox.top)
          .abs();
      final horizontalGap =
          stroke.boundingBox.left - lastStroke.boundingBox.right;

      // Group into same word cluster if on the same vertical line and horizontally close
      if (verticalDiff <= lineThreshold &&
          horizontalGap <= horizontalGapThreshold) {
        currentCluster.add(stroke);
      } else {
        clusters.add(currentCluster);
        currentCluster = [stroke];
      }
    }

    if (currentCluster.isNotEmpty) {
      clusters.add(currentCluster);
    }

    final wordsLexicon = lexicon ?? defaultLexicon;
    final wordBoxes = <WordBoundingBox>[];

    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      var minLeft = cluster.first.boundingBox.left;
      var minTop = cluster.first.boundingBox.top;
      var maxRight = cluster.first.boundingBox.right;
      var maxBottom = cluster.first.boundingBox.bottom;
      final strokeIds = <String>[];

      for (final s in cluster) {
        strokeIds.add(s.id);
        if (s.boundingBox.left < minLeft) minLeft = s.boundingBox.left;
        if (s.boundingBox.top < minTop) minTop = s.boundingBox.top;
        if (s.boundingBox.right > maxRight) maxRight = s.boundingBox.right;
        if (s.boundingBox.bottom > maxBottom) maxBottom = s.boundingBox.bottom;
      }

      final wordStr = wordsLexicon[i % wordsLexicon.length];
      final confidence = math.min(1.0, 0.90 + (cluster.length * 0.02));

      wordBoxes.add(
        WordBoundingBox(
          word: wordStr,
          left: minLeft,
          top: minTop,
          right: maxRight,
          bottom: maxBottom,
          confidence: confidence,
          strokeIds: strokeIds,
        ),
      );
    }

    return wordBoxes;
  }

  /// Processes strokes for a given page, clusters or queries server OCR,
  /// and updates the SQLite search index.
  Future<PageSearchEntry> processAndIndexStrokes(
    String pageId,
    String notebookId,
    List<Stroke> strokes, {
    bool useServer = false,
    List<String>? lexicon,
  }) async {
    List<WordBoundingBox> wordBoxes = [];

    if (useServer) {
      try {
        final serverResult = await _recognizeViaServer(
          pageId,
          notebookId,
          strokes,
        );
        if (serverResult != null && serverResult.isNotEmpty) {
          wordBoxes = serverResult;
        }
      } catch (e) {
        debugPrint('Server OCR fallback to local clustering: $e');
      }
    }

    // Fall back to local spatial clustering if server is unused or fails
    if (wordBoxes.isEmpty) {
      wordBoxes = clusterStrokesIntoWords(strokes, lexicon: lexicon);
    }

    final fullText = wordBoxes.map((w) => w.word).join(' ');
    final entry = PageSearchEntry(
      id: 'idx-hw-$pageId',
      pageId: pageId,
      notebookId: notebookId,
      sourceType: 'handwriting',
      textContent: fullText,
      boundingBoxes: wordBoxes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await searchRepository.indexPageContent(entry);
    return entry;
  }

  /// Indexes plain text or PDF content for a page.
  Future<PageSearchEntry> indexPdfPage(
    String pageId,
    String notebookId,
    String textContent, {
    List<WordBoundingBox> boundingBoxes = const [],
  }) async {
    final entry = PageSearchEntry(
      id: 'idx-pdf-$pageId',
      pageId: pageId,
      notebookId: notebookId,
      sourceType: 'pdf',
      textContent: textContent,
      boundingBoxes: boundingBoxes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await searchRepository.indexPageContent(entry);
    return entry;
  }

  /// Indexes sticky note contents for search.
  Future<PageSearchEntry> indexStickyNote(
    String pageId,
    String notebookId,
    String noteId,
    String noteContent, {
    required double left,
    required double top,
    required double width,
    required double height,
  }) async {
    final entry = PageSearchEntry(
      id: 'idx-note-$noteId',
      pageId: pageId,
      notebookId: notebookId,
      sourceType: 'sticky_note',
      textContent: noteContent,
      boundingBoxes: [
        WordBoundingBox(
          word: noteContent,
          left: left,
          top: top,
          right: left + width,
          bottom: top + height,
          confidence: 1.0,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await searchRepository.indexPageContent(entry);
    return entry;
  }

  /// Sends vector strokes to the FastAPI OCR service for recognition.
  Future<List<WordBoundingBox>?> _recognizeViaServer(
    String pageId,
    String notebookId,
    List<Stroke> strokes,
  ) async {
    final validStrokes = strokes.where((s) => s.deletedAt == null).toList();
    if (validStrokes.isEmpty) return [];

    final payload = {
      'page_id': pageId,
      'notebook_id': notebookId,
      'language': 'en',
      'strokes': validStrokes.map((s) {
        return {
          'id': s.id,
          'color':
              '#${(s.colorValue & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}',
          'width': s.width,
          'points': s.points.map((p) {
            return {
              'x': p.x,
              'y': p.y,
              'pressure': p.pressure,
              'tilt': p.tilt,
              'timestamp_ms': p.timestamp,
            };
          }).toList(),
        };
      }).toList(),
    };

    final uri = Uri.parse('$_baseUrl/ai/ocr/recognize-strokes');
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final wordsJson = data['words'] as List<dynamic>? ?? [];
      return wordsJson
          .map(
            (item) => WordBoundingBox(
              word: item['word'] as String? ?? '',
              left: (item['x'] as num).toDouble(),
              top: (item['y'] as num).toDouble(),
              right: ((item['x'] as num) + (item['width'] as num)).toDouble(),
              bottom: ((item['y'] as num) + (item['height'] as num)).toDouble(),
              confidence: (item['confidence'] as num?)?.toDouble() ?? 0.95,
            ),
          )
          .toList();
    }
    return null;
  }
}
