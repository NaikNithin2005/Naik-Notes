import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naik_notes/data/models/cover_template_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/folders/data/folder_provider.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/templates/presentation/widgets/paper_template_view.dart';
import 'package:naik_notes/services/storage/cover_image_service.dart';

/// Modal dialog for creating a new notebook with custom cover image upload
/// and visual page template selection with live previews.
class CreateNotebookDialog extends ConsumerStatefulWidget {
  final String? initialFolderId;

  const CreateNotebookDialog({super.key, this.initialFolderId});

  @override
  ConsumerState<CreateNotebookDialog> createState() =>
      _CreateNotebookDialogState();
}

class _CreateNotebookDialogState extends ConsumerState<CreateNotebookDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late String _selectedCoverId;
  late String _selectedCoverColor;
  String? _selectedFolderId;
  String? _customCoverPath;
  Uint8List? _customCoverBytes;
  bool _isUploadingCover = false;

  PaperTemplateType _selectedTemplate = PaperTemplateType.collegeRuled;
  String _selectedOrientation = 'portrait';
  String _selectedPageSize = 'A4';

  final List<CoverTemplate> _covers = CoverRegistry.builtInCovers;

  // The 11 core templates specified in project requirements
  static final List<PaperTemplateType> _requiredTemplates = [
    PaperTemplateType.blankPaper,
    PaperTemplateType.collegeRuled,
    PaperTemplateType.narrowRuled,
    PaperTemplateType.dottedPaper,
    PaperTemplateType.squareGrid,
    PaperTemplateType.graphPaper,
    PaperTemplateType.cornellNotes,
    PaperTemplateType.isometricPaper,
    PaperTemplateType.musicManuscript,
    PaperTemplateType.weeklyPlanner,
    PaperTemplateType.customTemplate,
  ];

  @override
  void initState() {
    super.initState();
    _selectedFolderId = widget.initialFolderId;
    _selectedCoverId = _covers.first.id;
    _selectedCoverColor = _covers.first.primaryColorHex;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF1E2A38);
    }
  }

  Future<void> _pickCustomCoverImage() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);

      if (result.isNotEmpty) {
        final file = result.first;
        final bytes = await file.readAsBytes();
        setState(() {
          _customCoverBytes = bytes;
          _customCoverPath = file.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select cover image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isUploadingCover = true);

    String? coverImageUrl;
    String? coverDriveId;
    String? coverFileName;
    DateTime? coverUpdatedAt;
    String? coverImageBase64;

    // Compress to Base64 for instant Firestore sync & upload to Google Drive if custom image is selected
    if (_customCoverBytes != null) {
      try {
        coverImageBase64 = await CoverImageService.encodeCoverImageToBase64(_customCoverBytes!);
      } catch (e) {
        debugPrint('[CreateNotebookDialog] Cover base64 compression notice: $e');
      }

      final auth = ref.read(authProvider);
      final uid = auth.user?.id ?? 'local_user';
      try {
        final coverService = ref.read(coverImageServiceProvider);
        final result = await coverService.uploadCoverImage(
          uid: uid,
          notebookId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          rawBytes: _customCoverBytes!,
        );
        coverDriveId = result.driveFileId;
        coverFileName = result.fileName;
        coverUpdatedAt = result.updatedAt;
        coverImageUrl = result.localPath;
      } catch (e) {
        // Fallback to local path if Drive storage is offline
        coverImageUrl = _customCoverPath;
      }
    } else if (_customCoverPath != null) {
      coverImageUrl = _customCoverPath;
    }

    try {
      await ref
          .read(notebooksProvider.notifier)
          .addNotebook(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            folderId: _selectedFolderId,
            coverId: _selectedCoverId,
            coverColorHex: _selectedCoverColor,
            coverImageUrl: coverImageUrl,
            coverDriveId: coverDriveId,
            coverFileName: coverFileName,
            coverUpdatedAt: coverUpdatedAt,
            coverImageBase64: coverImageBase64,
            paperTemplateId: _selectedTemplate.id,
            orientation: _selectedOrientation,
            pageSize: _selectedPageSize,
          );
    } catch (_) {}

    if (mounted) {
      setState(() => _isUploadingCover = false);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);
    final coverColor = _parseColor(_selectedCoverColor);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create New Notebook',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(height: 20),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Input
                        TextFormField(
                          controller: _titleController,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Notebook Title *',
                            hintText: 'e.g., Organic Chemistry, Lecture Notes',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a notebook title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Description Input
                        TextFormField(
                          controller: _descriptionController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Subject, professor, semester or tags',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Folder Selection
                        Row(
                          children: [
                            const Icon(Icons.folder_outlined, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Folder Location',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          initialValue: _selectedFolderId,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Unfiled (Root Library)'),
                            ),
                            ...folders.map(
                              (f) => DropdownMenuItem<String?>(
                                value: f.id,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: _parseColor(f.colorHex),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(f.name),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedFolderId = val);
                          },
                        ),
                        const SizedBox(height: 24),

                        // ---------------------------------------------
                        // NOTEBOOK COVER CUSTOMIZATION & PREVIEW
                        // ---------------------------------------------
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Notebook Cover Design',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _pickCustomCoverImage,
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 16,
                              ),
                              label: Text(
                                _customCoverBytes != null ||
                                        _customCoverPath != null
                                    ? 'Change Custom Image'
                                    : 'Upload Custom Cover',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Live Cover Card Miniature Preview
                        Center(
                          child: Container(
                            width: 150,
                            height: 200,
                            decoration: BoxDecoration(
                              color: coverColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 10,
                                  offset: const Offset(3, 5),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                if (_customCoverBytes != null)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      child: Image.memory(
                                        _customCoverBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )
                                else if (_customCoverPath != null && !kIsWeb)
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                      child: Image.file(
                                        File(_customCoverPath!),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                // Left Book Spine with Shadow Gradient
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  width: 20,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        bottomLeft: Radius.circular(8),
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.35),
                                          Colors.black.withValues(alpha: 0.15),
                                          Colors.black.withValues(alpha: 0.0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Spine Stitch line
                                Positioned(
                                  left: 18,
                                  top: 0,
                                  bottom: 0,
                                  width: 1,
                                  child: Container(
                                    color: Colors.black.withValues(alpha: 0.15),
                                  ),
                                ),

                                // Centered, Non-overlapping Horizontal Title Plate
                                Positioned(
                                  left: 28,
                                  right: 14,
                                  top: 65,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          ThemeData.estimateBrightnessForColor(
                                                coverColor,
                                              ) ==
                                              Brightness.dark
                                          ? Colors.black.withValues(alpha: 0.45)
                                          : Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color:
                                            ThemeData.estimateBrightnessForColor(
                                                  coverColor,
                                                ) ==
                                                Brightness.dark
                                            ? const Color(
                                                0xFFD4AF37,
                                              ).withValues(alpha: 0.6)
                                            : const Color(
                                                0xFF8B5A2B,
                                              ).withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _titleController.text.trim().isEmpty
                                          ? 'Notebook Title'
                                          : _titleController.text.trim(),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color:
                                            ThemeData.estimateBrightnessForColor(
                                                  coverColor,
                                                ) ==
                                                Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFF1E1E1E),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Georgia',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Built-in Cover Palette Selector with Dynamic Contrast
                        Text(
                          'Preset Stationery Patterns',
                          style: theme.textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 60,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _covers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final item = _covers[index];
                              final isSelected =
                                  _selectedCoverId == item.id &&
                                  _customCoverBytes == null &&
                                  _customCoverPath == null;
                              final c = _parseColor(item.primaryColorHex);
                              final isDark =
                                  ThemeData.estimateBrightnessForColor(c) ==
                                  Brightness.dark;
                              final checkColor = isDark
                                  ? Colors.white
                                  : Colors.black87;

                              return Semantics(
                                label: '${item.name} cover',
                                selected: isSelected,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCoverId = item.id;
                                      _selectedCoverColor =
                                          item.primaryColorHex;
                                      _customCoverBytes = null;
                                      _customCoverPath = null;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 44,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: c,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.black26,
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                    child: isSelected
                                        ? Center(
                                            child: Icon(
                                              Icons.check_rounded,
                                              color: checkColor,
                                              size: 20,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ---------------------------------------------
                        // VISUAL PAGE TEMPLATE SELECTION
                        // ---------------------------------------------
                        Text(
                          'Page Template (Visual Selection)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select the default paper style. Each page can be customized later.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),

                        // Horizontal Visual Thumbnail List for All 11 Templates
                        SizedBox(
                          height: 140,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _requiredTemplates.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final template = _requiredTemplates[index];
                              final isSelected = _selectedTemplate == template;

                              return InkWell(
                                onTap: () => setState(
                                  () => _selectedTemplate = template,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 105,
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primaryContainer
                                              .withValues(alpha: 0.4)
                                        : theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.outline
                                                .withValues(alpha: 0.3),
                                      width: isSelected ? 2.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // Miniature Rendered Vector Paper View
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.contain,
                                            child: PaperTemplateView(
                                              width: 140,
                                              height: 198,
                                              type: template,
                                              properties:
                                                  PaperProperties.defaultFor(
                                                    template,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        template.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Selected Template Details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedTemplate.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      _selectedTemplate.description,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Page Size & Orientation Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Page Size',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'A4',
                                        label: Text('A4'),
                                      ),
                                      ButtonSegment(
                                        value: 'Letter',
                                        label: Text('Letter'),
                                      ),
                                    ],
                                    selected: {_selectedPageSize},
                                    onSelectionChanged: (set) {
                                      setState(
                                        () => _selectedPageSize = set.first,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Orientation',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment(
                                        value: 'portrait',
                                        icon: Icon(
                                          Icons.stay_current_portrait_rounded,
                                          size: 18,
                                        ),
                                      ),
                                      ButtonSegment(
                                        value: 'landscape',
                                        icon: Icon(
                                          Icons.stay_current_landscape_rounded,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                    selected: {_selectedOrientation},
                                    onSelectionChanged: (set) {
                                      setState(
                                        () => _selectedOrientation = set.first,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isUploadingCover ? null : _submit,
                      icon: _isUploadingCover
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_stories_rounded, size: 18),
                      label: Text(
                        _isUploadingCover
                            ? 'Creating & Uploading...'
                            : 'Create Notebook',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
