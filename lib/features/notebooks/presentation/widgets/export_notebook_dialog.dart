import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../data/models/notebook_model.dart';
import '../../../../data/models/page_model.dart';
import '../../../../services/pdf/pdf_service.dart';
import '../../../canvas/data/stroke_provider.dart';
import '../../../pdf/data/sticky_note_provider.dart';

enum ExportFormat {
  pdf(
    'PDF Document',
    'High-fidelity vector flattened document',
    Icons.picture_as_pdf_rounded,
    'pdf',
  ),
  png(
    'PNG Image',
    'High-resolution raster snapshot',
    Icons.image_rounded,
    'png',
  );

  final String title;
  final String subtitle;
  final IconData icon;
  final String extension;
  const ExportFormat(this.title, this.subtitle, this.icon, this.extension);
}

enum ExportScope {
  all('Entire Notebook'),
  currentPage('Current Page Only'),
  customRange('Custom Page Range');

  final String label;
  const ExportScope(this.label);
}

/// Production-ready dialog for exporting notebooks and individual pages
/// to vector PDF or high-resolution PNG with range selection and file system saving.
class ExportNotebookDialog extends ConsumerStatefulWidget {
  final Notebook notebook;
  final List<NotebookPage> pages;
  final NotebookPage? activePage;

  const ExportNotebookDialog({
    super.key,
    required this.notebook,
    required this.pages,
    this.activePage,
  });

  static Future<void> show(
    BuildContext context, {
    required Notebook notebook,
    required List<NotebookPage> pages,
    NotebookPage? activePage,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ExportNotebookDialog(
        notebook: notebook,
        pages: pages,
        activePage: activePage,
      ),
    );
  }

  @override
  ConsumerState<ExportNotebookDialog> createState() =>
      _ExportNotebookDialogState();
}

class _ExportNotebookDialogState extends ConsumerState<ExportNotebookDialog> {
  ExportFormat _format = ExportFormat.pdf;
  late ExportScope _scope;
  bool _includeBackground = true;
  bool _includeStickyNotes = true;
  bool _isExporting = false;
  String _statusMessage = '';

  final TextEditingController _rangeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scope = widget.activePage != null
        ? ExportScope.currentPage
        : ExportScope.all;
    _rangeController.text = '1-${widget.pages.length}';
  }

  @override
  void dispose() {
    _rangeController.dispose();
    super.dispose();
  }

  List<NotebookPage> _resolveSelectedPages() {
    switch (_scope) {
      case ExportScope.all:
        return widget.pages;
      case ExportScope.currentPage:
        if (widget.activePage != null) {
          return [widget.activePage!];
        }
        return widget.pages.isNotEmpty ? [widget.pages.first] : [];
      case ExportScope.customRange:
        return _parseCustomRange(_rangeController.text.trim());
    }
  }

  List<NotebookPage> _parseCustomRange(String text) {
    if (text.isEmpty || widget.pages.isEmpty) return widget.pages;
    final pages = <NotebookPage>[];
    final parts = text.split(RegExp(r'[,;]'));

    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.contains('-')) {
        final bounds = trimmed.split('-');
        if (bounds.length == 2) {
          final start = int.tryParse(bounds[0].trim()) ?? 1;
          final end = int.tryParse(bounds[1].trim()) ?? widget.pages.length;
          final lower = start.clamp(1, widget.pages.length);
          final upper = end.clamp(1, widget.pages.length);
          for (int i = lower; i <= upper; i++) {
            final page = widget.pages.firstWhere(
              (p) => p.pageNumber == i,
              orElse: () => widget.pages.first,
            );
            if (!pages.contains(page)) pages.add(page);
          }
        }
      } else {
        final num = int.tryParse(trimmed);
        if (num != null && num >= 1 && num <= widget.pages.length) {
          final page = widget.pages.firstWhere(
            (p) => p.pageNumber == num,
            orElse: () => widget.pages.first,
          );
          if (!pages.contains(page)) pages.add(page);
        }
      }
    }

    return pages.isNotEmpty ? pages : widget.pages;
  }

  Future<void> _performExport() async {
    setState(() {
      _isExporting = true;
      _statusMessage = 'Rendering vector content...';
    });

    try {
      final selectedPages = _resolveSelectedPages();
      if (selectedPages.isEmpty) {
        throw Exception('No pages selected for export.');
      }

      final pdfService = ref.read(pdfServiceProvider);
      final strokesState = ref.read(strokesNotifierProvider);
      final stickyNotesState = ref.read(stickyNotesProvider);

      Uint8List fileBytes;
      String extension = _format.extension;

      if (_format == ExportFormat.png) {
        setState(() => _statusMessage = 'Rasterizing high-DPI page canvas...');
        final targetPage = selectedPages.first;
        final strokes = strokesState.pageStrokes[targetPage.id] ?? [];
        final stickyNotes = stickyNotesState[targetPage.id] ?? [];

        fileBytes = await pdfService.renderPageToPng(
          page: targetPage,
          strokes: strokes,
          stickyNotes: stickyNotes,
          pixelRatio: 2.5,
          includeBackground: _includeBackground,
        );
      } else {
        setState(() => _statusMessage = 'Compiling vector PDF document...');
        fileBytes = await pdfService.exportFlattenedPdf(
          notebook: widget.notebook,
          pages: selectedPages,
          strokesPerPage: strokesState.pageStrokes,
          stickyNotesPerPage: stickyNotesState,
          includeBackground: _includeBackground,
          includeStickyNotes: _includeStickyNotes,
        );
      }

      setState(() => _statusMessage = 'Saving file to storage...');

      final sanitizedTitle = widget.notebook.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final defaultFileName = '${sanitizedTitle}_Export.$extension';

      String? outputPath;
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final savedUri = await FilePicker.saveFile(
          dialogTitle: 'Save Exported Document',
          fileName: defaultFileName,
          bytes: fileBytes,
        );
        outputPath = savedUri?.toFilePath();
      }

      if (outputPath == null) {
        // Fallback or mobile platform saving
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        outputPath = '${appDir.path}/${sanitizedTitle}_$timestamp.$extension';
        final file = File(outputPath);
        await file.writeAsBytes(fileBytes);
      }

      if (mounted) {
        Navigator.of(context).pop();
        final sizeKb = (fileBytes.lengthInBytes / 1024).toStringAsFixed(1);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.greenAccent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Export complete ($sizeKb KB)!\nSaved to: $outputPath',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
          _statusMessage = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.ios_share_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Export Document',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.notebook.title} • ${widget.pages.length} pages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isExporting) ...[
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_statusMessage, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                // --- Format Selection ---
                Text(
                  'Export Format',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: ExportFormat.values.map((fmt) {
                    final isSelected = _format == fmt;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _format = fmt;
                              if (fmt == ExportFormat.png &&
                                  _scope == ExportScope.all) {
                                _scope = ExportScope.currentPage;
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 56),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primaryContainer
                                        .withValues(alpha: 0.5)
                                  : (isDark
                                        ? Colors.grey[850]
                                        : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outlineVariant
                                          .withValues(alpha: 0.4),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  fmt.icon,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        fmt.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        fmt.subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(fontSize: 10),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // --- Scope Selection ---
                Text(
                  'Page Range',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                RadioListTile<ExportScope>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: ExportScope.all,
                  groupValue: _scope,
                  title: Text('Entire Notebook (${widget.pages.length} pages)'),
                  onChanged: _format == ExportFormat.png
                      ? null
                      : (val) => setState(() => _scope = val!),
                ),
                if (widget.activePage != null)
                  RadioListTile<ExportScope>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: ExportScope.currentPage,
                    groupValue: _scope,
                    title: Text(
                      'Current Page (Page ${widget.activePage!.pageNumber})',
                    ),
                    onChanged: (val) => setState(() => _scope = val!),
                  ),
                if (_format != ExportFormat.png) ...[
                  RadioListTile<ExportScope>(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    value: ExportScope.customRange,
                    groupValue: _scope,
                    title: const Text('Custom Page Range'),
                    onChanged: (val) => setState(() => _scope = val!),
                  ),
                  if (_scope == ExportScope.customRange)
                    Padding(
                      padding: const EdgeInsets.only(left: 36, bottom: 8),
                      child: TextField(
                        controller: _rangeController,
                        decoration: InputDecoration(
                          hintText: 'e.g. 1-3, 5, 7-9',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // --- Document Customization Options ---
                Text(
                  'Options',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include Paper Background & Grid'),
                  value: _includeBackground,
                  onChanged: (val) =>
                      setState(() => _includeBackground = val ?? true),
                ),
                if (_format == ExportFormat.pdf)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Include Sticky Note Annotations'),
                    value: _includeStickyNotes,
                    onChanged: (val) =>
                        setState(() => _includeStickyNotes = val ?? true),
                  ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isExporting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _isExporting ? null : _performExport,
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Export Now'),
        ),
      ],
    );
  }
}
