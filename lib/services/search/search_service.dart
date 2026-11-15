import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../data/models/search_index_model.dart';
import '../../data/repositories/folder_repository.dart';
import '../../data/repositories/notebook_repository.dart';
import '../../data/repositories/page_repository.dart';
import '../../data/repositories/page_search_repository.dart';
import '../../data/repositories/sticky_note_repository.dart';

/// Unified search coordinator spanning notebooks, folders, pages,
/// handwritten OCR text, and sticky notes.
class SearchService {
  final NotebookRepository notebookRepository;
  final FolderRepository folderRepository;
  final PageRepository pageRepository;
  final PageSearchRepository pageSearchRepository;
  final StickyNoteRepository stickyNoteRepository;

  SearchService({
    required this.notebookRepository,
    required this.folderRepository,
    required this.pageRepository,
    required this.pageSearchRepository,
    required this.stickyNoteRepository,
  });

  /// Performs global full-text search across all notebooks, folders,
  /// handwritten strokes, sticky notes, and PDF pages.
  Future<List<SearchResultItem>> searchGlobal(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final results = <SearchResultItem>[];

    // 1. Search Notebook titles & descriptions
    try {
      final notebooks = await notebookRepository.getAllNotebooks();
      for (final nb in notebooks) {
        if (nb.title.toLowerCase().contains(cleanQuery)) {
          results.add(
            SearchResultItem(
              notebookId: nb.id,
              notebookTitle: nb.title,
              snippet: _extractSnippet(nb.title, cleanQuery),
              matchedTerm: cleanQuery,
              sourceType: 'notebookTitle',
            ),
          );
        } else if (nb.description.toLowerCase().contains(cleanQuery)) {
          results.add(
            SearchResultItem(
              notebookId: nb.id,
              notebookTitle: nb.title,
              snippet: _extractSnippet(nb.description, cleanQuery),
              matchedTerm: cleanQuery,
              sourceType: 'notebookDescription',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Search error in notebooks: $e');
    }

    // 2. Search Folders
    try {
      final folders = await folderRepository.getAllFolders();
      for (final f in folders) {
        if (f.name.toLowerCase().contains(cleanQuery)) {
          results.add(
            SearchResultItem(
              notebookId: '',
              notebookTitle: 'Folder: ${f.name}',
              snippet: _extractSnippet(f.name, cleanQuery),
              matchedTerm: cleanQuery,
              sourceType: 'folder',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Search error in folders: $e');
    }

    // 3. Search Indexed Pages (Handwriting, PDF, Notes)
    try {
      final pageEntries = await pageSearchRepository.searchPages(cleanQuery);
      final notebooksMap = {
        for (var nb in await notebookRepository.getAllNotebooks())
          nb.id: nb.title,
      };

      for (final entry in pageEntries) {
        final title = notebooksMap[entry.notebookId] ?? 'Notebook';
        final matchingBoxes = entry.boundingBoxes.where((b) {
          return b.word.toLowerCase().contains(cleanQuery);
        }).toList();

        // Resolve page number if possible
        int? pageNumber;
        try {
          final pages = await pageRepository.getPagesForNotebook(
            entry.notebookId,
          );
          final pIdx = pages.indexWhere((p) => p.id == entry.pageId);
          if (pIdx != -1) {
            pageNumber = pages[pIdx].pageNumber;
          }
        } catch (_) {}

        results.add(
          SearchResultItem(
            notebookId: entry.notebookId,
            notebookTitle: title,
            pageId: entry.pageId,
            pageNumber: pageNumber,
            snippet: _extractSnippet(entry.textContent, cleanQuery),
            matchedTerm: cleanQuery,
            sourceType: entry.sourceType,
            matchingBoxes: matchingBoxes,
          ),
        );
      }
    } catch (e) {
      debugPrint('Search error in indexed pages: $e');
    }

    return results;
  }

  /// Searches within a specific notebook and returns matches with exact page
  /// and bounding box coordinates for canvas highlighting.
  Future<List<SearchResultItem>> searchInNotebook(
    String notebookId,
    String query,
  ) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return [];

    final results = <SearchResultItem>[];

    final notebook = await notebookRepository.getNotebookById(notebookId);
    final nbTitle = notebook?.title ?? 'Notebook';
    final pages = await pageRepository.getPagesForNotebook(notebookId);
    final pageMap = {for (var p in pages) p.id: p.pageNumber};

    final entries = await pageSearchRepository.searchPages(
      cleanQuery,
      notebookId: notebookId,
    );

    for (final entry in entries) {
      final matchingBoxes = entry.boundingBoxes.where((b) {
        return b.word.toLowerCase().contains(cleanQuery);
      }).toList();

      results.add(
        SearchResultItem(
          notebookId: notebookId,
          notebookTitle: nbTitle,
          pageId: entry.pageId,
          pageNumber: pageMap[entry.pageId] ?? 1,
          snippet: _extractSnippet(entry.textContent, cleanQuery),
          matchedTerm: cleanQuery,
          sourceType: entry.sourceType,
          matchingBoxes: matchingBoxes,
        ),
      );
    }

    return results;
  }

  /// Generates a contextual snippet around the matched query.
  String _extractSnippet(
    String fullText,
    String query, {
    int maxContextChars = 40,
  }) {
    if (fullText.isEmpty) return '';
    final lowerText = fullText.toLowerCase();
    final index = lowerText.indexOf(query.toLowerCase());
    if (index == -1) {
      return fullText.length <= maxContextChars * 2
          ? fullText
          : '${fullText.substring(0, maxContextChars * 2)}...';
    }

    final start = math.max(0, index - maxContextChars);
    final end = math.min(
      fullText.length,
      index + query.length + maxContextChars,
    );

    final prefix = start > 0 ? '...' : '';
    final suffix = end < fullText.length ? '...' : '';

    return '$prefix${fullText.substring(start, end).trim()}$suffix';
  }
}
