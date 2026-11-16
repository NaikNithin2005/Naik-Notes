import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:naik_notes/data/models/cover_template_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';

import '../widgets/template_customizer_sheet.dart';

/// Template Gallery screen showcasing paper and cover templates.
class TemplateGalleryScreen extends ConsumerStatefulWidget {
  const TemplateGalleryScreen({super.key});

  @override
  ConsumerState<TemplateGalleryScreen> createState() =>
      _TemplateGalleryScreenState();
}

class _TemplateGalleryScreenState extends ConsumerState<TemplateGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCoverCategory = 'All';
  CoverTemplate _activePreviewCover = CoverRegistry.builtInCovers.first;
  final _previewTitleController = TextEditingController(
    text: 'My Handwritten Journal',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _previewTitleController.dispose();
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

  void _createWithCover(CoverTemplate cover) {
    final title = _previewTitleController.text.trim().isEmpty
        ? 'Notebook (${cover.name})'
        : _previewTitleController.text.trim();

    ref
        .read(notebooksProvider.notifier)
        .addNotebook(
          title: title,
          description: '${cover.category} collection cover',
          coverId: cover.id,
          coverColorHex: cover.primaryColorHex,
          paperTemplateId: 'college_ruled',
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created notebook "$title" with ${cover.name} cover!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _iconForTemplate(PaperTemplateType type) {
    switch (type) {
      case PaperTemplateType.mathematicsNotes:
        return Icons.calculate_outlined;
      case PaperTemplateType.physicsNotes:
        return Icons.science_outlined;
      case PaperTemplateType.chemistryNotes:
        return Icons.biotech_outlined;
      case PaperTemplateType.lectureNotes:
        return Icons.menu_book_outlined;
      case PaperTemplateType.habitTracker:
        return Icons.check_circle_outline_rounded;
      case PaperTemplateType.goalPlanner:
        return Icons.flag_outlined;
      case PaperTemplateType.sketchbook:
        return Icons.draw_outlined;
      case PaperTemplateType.bulletJournal:
        return Icons.scatter_plot_outlined;
      case PaperTemplateType.mindMapping:
        return Icons.hub_outlined;
      case PaperTemplateType.creativeJournal:
        return Icons.brush_outlined;
      case PaperTemplateType.ideaNotebook:
        return Icons.lightbulb_outline;
      case PaperTemplateType.projectPlanner:
        return Icons.assignment_outlined;
      case PaperTemplateType.researchJournal:
        return Icons.auto_stories_outlined;
      case PaperTemplateType.businessNotes:
        return Icons.business_center_outlined;
      case PaperTemplateType.projectDocumentation:
        return Icons.integration_instructions_outlined;
      case PaperTemplateType.blankPaper:
        return Icons.crop_portrait_outlined;
      case PaperTemplateType.narrowRuled:
        return Icons.reorder;
      case PaperTemplateType.collegeRuled:
        return Icons.format_align_justify;
      case PaperTemplateType.wideRuled:
        return Icons.view_headline;
      case PaperTemplateType.dottedPaper:
        return Icons.grain;
      case PaperTemplateType.squareGrid:
        return Icons.grid_4x4;
      case PaperTemplateType.graphPaper:
        return Icons.grid_on;
      case PaperTemplateType.cornellNotes:
        return Icons.space_dashboard;
      case PaperTemplateType.meetingNotes:
        return Icons.groups_outlined;
      case PaperTemplateType.dailyPlanner:
        return Icons.today;
      case PaperTemplateType.weeklyPlanner:
        return Icons.view_week;
      case PaperTemplateType.monthlyPlanner:
        return Icons.calendar_month;
      case PaperTemplateType.studyPlanner:
        return Icons.school_outlined;
      case PaperTemplateType.engineeringPaper:
        return Icons.architecture;
      case PaperTemplateType.isometricPaper:
        return Icons.hexagon_outlined;
      case PaperTemplateType.musicManuscript:
        return Icons.music_note;
      case PaperTemplateType.checklist:
        return Icons.checklist;
      case PaperTemplateType.journalPages:
        return Icons.auto_stories;
      case PaperTemplateType.customTemplate:
        return Icons.tune;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group the 19 paper templates by category
    final paperCategories = <String, List<PaperTemplateType>>{};
    for (final t in PaperTemplateType.values) {
      paperCategories.putIfAbsent(t.category, () => []).add(t);
    }

    final filteredCovers = _selectedCoverCategory == 'All'
        ? CoverRegistry.builtInCovers
        : CoverRegistry.builtInCovers
              .where((c) => c.category == _selectedCoverCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Template & Cover Gallery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.auto_stories_outlined), text: 'Cover Designs'),
            Tab(
              icon: Icon(Icons.description_outlined),
              text: 'Paper Templates (19)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Cover Gallery Tab
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Categories and Cover Grid
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Chips
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: CoverRegistry.categories.map((cat) {
                            final isSelected = _selectedCoverCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(
                                      () => _selectedCoverCategory = cat,
                                    );
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const Divider(height: 1),

                    // Covers Grid
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 180,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredCovers.length,
                        itemBuilder: (context, index) {
                          final cover = filteredCovers[index];
                          final isSelected = cover.id == _activePreviewCover.id;
                          final color = _parseColor(cover.primaryColorHex);

                          return InkWell(
                            onTap: () {
                              setState(() => _activePreviewCover = cover);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.black26,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                    offset: const Offset(2, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Spine shadow
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    bottom: 0,
                                    width: 14,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(8),
                                          bottomLeft: Radius.circular(8),
                                        ),
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Content
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 12,
                                      top: 14,
                                      bottom: 12,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            cover.category,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          cover.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            fontFamily: 'Georgia',
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const VerticalDivider(width: 1),

              // Right: Live Interactive Cover Customizer & Preview
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Live Cover Preview',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Large realistic notebook preview
                      Center(
                        child: Container(
                          width: 220,
                          height: 310,
                          decoration: BoxDecoration(
                            color: _parseColor(
                              _activePreviewCover.primaryColorHex,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(6, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Spine
                              Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 22,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      bottomLeft: Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              // Embossed label
                              Center(
                                child: Container(
                                  width: 170,
                                  padding: const EdgeInsets.all(14),
                                  margin: const EdgeInsets.only(left: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _parseColor(
                                        _activePreviewCover.accentColorHex,
                                      ).withValues(alpha: 0.8),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _previewTitleController.text.isEmpty
                                            ? 'Naik Notes'
                                            : _previewTitleController.text,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: _parseColor(
                                            _activePreviewCover.accentColorHex,
                                          ),
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        width: 40,
                                        height: 1,
                                        color: _parseColor(
                                          _activePreviewCover.accentColorHex,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      Text(
                        _activePreviewCover.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_activePreviewCover.category} Collection • ${_activePreviewCover.patternType} pattern',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activePreviewCover.description,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 18),

                      // Customize Embossed Title
                      TextField(
                        controller: _previewTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Embossed Title',
                          hintText: 'Enter title to emboss',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 20),

                      FilledButton.icon(
                        onPressed: () => _createWithCover(_activePreviewCover),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Create Notebook with this Cover'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 2. Paper Templates Tab (All 19 Templates)
          ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: paperCategories.length,
            itemBuilder: (context, catIdx) {
              final entry = paperCategories.entries.elementAt(catIdx);
              final categoryName = entry.key;
              final templateList = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: templateList.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          mainAxisExtent: 104,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                    itemBuilder: (context, itemIdx) {
                      final item = templateList[itemIdx];
                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            showDialog<void>(
                              context: context,
                              builder: (ctx) => TemplateCustomizerSheet(
                                initialType: item,
                                initialProperties: PaperProperties.defaultFor(
                                  item,
                                ),
                                onApply: (type, props, applyToAll) {
                                  ref
                                      .read(notebooksProvider.notifier)
                                      .addNotebook(
                                        title:
                                            'New ${type.displayName} Notebook',
                                        description: type.description,
                                        coverId: 'dark_academia_leather',
                                        coverColorHex: '#1E2A38',
                                        paperTemplateId: type.id,
                                        orientation: props.orientation,
                                        pageSize: props.pageSize,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Created new notebook with ${type.displayName}!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _iconForTemplate(item),
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.description,
                                        style: theme.textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
