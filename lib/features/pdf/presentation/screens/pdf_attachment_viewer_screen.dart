import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../../../data/models/attachment_model.dart';

/// Full-featured PDF viewer screen supporting zoom, page navigation,
/// text search, text selection, and annotation capabilities.
class PdfAttachmentViewerScreen extends StatefulWidget {
  final File pdfFile;
  final String title;
  final NoteAttachment? attachment;

  const PdfAttachmentViewerScreen({
    super.key,
    required this.pdfFile,
    required this.title,
    this.attachment,
  });

  /// Opens the PDF viewer in a modal or full-screen route.
  static Future<void> open(
    BuildContext context, {
    required File pdfFile,
    required String title,
    NoteAttachment? attachment,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PdfAttachmentViewerScreen(
          pdfFile: pdfFile,
          title: title,
          attachment: attachment,
        ),
      ),
    );
  }

  @override
  State<PdfAttachmentViewerScreen> createState() => _PdfAttachmentViewerScreenState();
}

class _PdfAttachmentViewerScreenState extends State<PdfAttachmentViewerScreen> {
  late PdfViewerController _pdfViewerController;
  late TextEditingController _searchController;
  PdfTextSearchResult? _searchResult;
  bool _isSearchVisible = false;
  int _currentPage = 1;
  int _pageCount = 0;
  bool _isDocumentLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchResult?.removeListener(_onSearchResultUpdate);
    _searchController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _onSearchResultUpdate() {
    if (mounted) setState(() {});
  }

  void _startSearch(String text) {
    if (text.trim().isEmpty) {
      _searchResult?.clear();
      setState(() => _searchResult = null);
      return;
    }

    _searchResult?.removeListener(_onSearchResultUpdate);
    _searchResult = _pdfViewerController.searchText(text.trim());
    _searchResult?.addListener(_onSearchResultUpdate);
    setState(() {});
  }

  void _showJumpToPageDialog() {
    final pageTextCtrl = TextEditingController(text: '$_currentPage');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: pageTextCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page Number',
            hintText: '1 - $_pageCount',
          ),
          onSubmitted: (val) {
            final page = int.tryParse(val);
            if (page != null && page >= 1 && page <= _pageCount) {
              _pdfViewerController.jumpToPage(page);
              Navigator.of(ctx).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final page = int.tryParse(pageTextCtrl.text);
              if (page != null && page >= 1 && page <= _pageCount) {
                _pdfViewerController.jumpToPage(page);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_isDocumentLoaded)
              Text(
                'Page $_currentPage of $_pageCount',
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
              ),
          ],
        ),
        actions: [
          // Zoom In
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded),
            tooltip: 'Zoom In',
            onPressed: () {
              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
            },
          ),
          // Zoom Out
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded),
            tooltip: 'Zoom Out',
            onPressed: () {
              _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
            },
          ),
          // Toggle Search
          IconButton(
            icon: Icon(_isSearchVisible ? Icons.search_off_rounded : Icons.search_rounded),
            tooltip: _isSearchVisible ? 'Close Search' : 'Search Text',
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchResult?.clear();
                  _searchResult = null;
                  _searchController.clear();
                }
              });
            },
          ),
          // Jump to page
          IconButton(
            icon: const Icon(Icons.numbers_rounded),
            tooltip: 'Jump to Page',
            onPressed: _pageCount > 1 ? _showJumpToPageDialog : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          if (_isSearchVisible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? theme.colorScheme.surfaceContainer : theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search in document...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? Colors.black26 : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: _startSearch,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_searchResult != null) ...[
                    Text(
                      _searchResult!.totalInstanceCount > 0
                          ? '${_searchResult!.currentInstanceIndex} of ${_searchResult!.totalInstanceCount}'
                          : '0 found',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_up),
                      tooltip: 'Previous match',
                      onPressed: () => _searchResult?.previousInstance(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down),
                      tooltip: 'Next match',
                      onPressed: () => _searchResult?.nextInstance(),
                    ),
                  ],
                ],
              ),
            ),

          // Main PDF Canvas
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SfPdfViewer.file(
                    widget.pdfFile,
                    controller: _pdfViewerController,
                    enableTextSelection: true,
                    canShowScrollHead: true,
                    canShowScrollStatus: true,
                    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                      if (mounted) {
                        setState(() {
                          _pageCount = details.document.pages.count;
                          _isDocumentLoaded = true;
                        });
                      }
                    },
                    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                      if (mounted) {
                        setState(() {
                          _errorMessage = 'Failed to load PDF: ${details.description}';
                        });
                      }
                    },
                    onPageChanged: (PdfPageChangedDetails details) {
                      if (mounted) {
                        setState(() {
                          _currentPage = details.newPageNumber;
                        });
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

