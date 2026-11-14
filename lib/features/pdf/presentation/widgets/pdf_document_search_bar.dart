import 'package:flutter/material.dart';

/// In-document text search bar for searching content across PDF pages.
class PdfDocumentSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onNextMatch;
  final VoidCallback onPreviousMatch;
  final VoidCallback onClose;
  final int currentMatchIndex;
  final int totalMatches;

  const PdfDocumentSearchBar({
    super.key,
    required this.onSearch,
    required this.onNextMatch,
    required this.onPreviousMatch,
    required this.onClose,
    this.currentMatchIndex = 0,
    this.totalMatches = 0,
  });

  @override
  State<PdfDocumentSearchBar> createState() => _PdfDocumentSearchBarState();
}

class _PdfDocumentSearchBarState extends State<PdfDocumentSearchBar> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      color: theme.colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Search in document...',
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: widget.onSearch,
                onSubmitted: widget.onSearch,
              ),
            ),
            if (widget.totalMatches > 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${widget.currentMatchIndex} of ${widget.totalMatches}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                tooltip: 'Previous match',
                onPressed: widget.onPreviousMatch,
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                tooltip: 'Next match',
                onPressed: widget.onNextMatch,
              ),
            ] else if (_searchController.text.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'No matches',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],
            const VerticalDivider(width: 8, thickness: 1),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Close search',
              onPressed: widget.onClose,
            ),
          ],
        ),
      ),
    );
  }
}
