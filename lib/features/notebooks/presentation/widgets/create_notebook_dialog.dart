import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naik_notes/data/models/cover_template_model.dart';
import 'package:naik_notes/features/folders/data/folder_provider.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';

/// Modal dialog for creating a new notebook.
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
  String _selectedTemplate = 'college_ruled';
  String _selectedOrientation = 'portrait';
  String _selectedPageSize = 'A4';

  final List<CoverTemplate> _covers = CoverRegistry.builtInCovers;

  final List<Map<String, String>> _templateOptions = [
    {'id': 'blank_paper', 'name': 'Blank Paper', 'desc': 'Clean canvas'},
    {
      'id': 'college_ruled',
      'name': 'College Ruled',
      'desc': 'Standard 7.1mm lines',
    },
    {
      'id': 'narrow_ruled',
      'name': 'Narrow Ruled',
      'desc': '6.35mm dense lines',
    },
    {'id': 'square_grid', 'name': 'Square Grid', 'desc': '5mm quad grid'},
    {'id': 'dotted_paper', 'name': 'Dotted Paper', 'desc': '5mm dot matrix'},
    {
      'id': 'cornell_notes',
      'name': 'Cornell Notes',
      'desc': 'Cue & summary margin',
    },
    {
      'id': 'weekly_planner',
      'name': 'Weekly Planner',
      'desc': 'Schedule & goals',
    },
    {
      'id': 'engineering',
      'name': 'Engineering Paper',
      'desc': 'Precision grid',
    },
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

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(notebooksProvider.notifier)
          .addNotebook(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            folderId: _selectedFolderId,
            coverId: _selectedCoverId,
            coverColorHex: _selectedCoverColor,
            paperTemplateId: _selectedTemplate,
            orientation: _selectedOrientation,
            pageSize: _selectedPageSize,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final folders = ref.watch(foldersProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
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
                      style: theme.textTheme.headlineMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Input
                        TextFormField(
                          controller: _titleController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Notebook Title *',
                            hintText:
                                'e.g., Organic Chemistry II, Project Notes',
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
                          decoration: const InputDecoration(
                            labelText: 'Description (Optional)',
                            hintText: 'Subject, professor, tags or semester',
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
                        const SizedBox(height: 20),

                        // Cover Selection
                        Text(
                          'Select Cover Design',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _covers.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final item = _covers[index];
                              final isSelected = _selectedCoverId == item.id;
                              final color = _parseColor(item.primaryColorHex);

                              return Tooltip(
                                message: '${item.name} (${item.category})',
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedCoverId = item.id;
                                      _selectedCoverColor =
                                          item.primaryColorHex;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 60,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.black26,
                                        width: isSelected ? 3 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.15,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(1, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: 8,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.only(
                                                    topLeft: Radius.circular(7),
                                                    bottomLeft: Radius.circular(
                                                      7,
                                                    ),
                                                  ),
                                              color: Colors.black.withValues(
                                                alpha: 0.25,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Center(
                                            child: Icon(
                                              Icons.check_circle_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Paper Template Selection
                        Text(
                          'Paper Template',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _templateOptions.map((t) {
                            final isSelected = _selectedTemplate == t['id'];
                            return ChoiceChip(
                              label: Text(t['name']!),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedTemplate = t['id']!);
                                }
                              },
                            );
                          }).toList(),
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
                      onPressed: _submit,
                      icon: const Icon(Icons.auto_stories_rounded, size: 18),
                      label: const Text('Create Notebook'),
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
