import 'package:flutter/material.dart';

import '../../../../data/models/paper_template_model.dart';
import 'canvas_floating_pill.dart';

/// Top floating navigation chrome containing:
/// - Top-Left Pill: [ ← | Editable Note Title • Sync Dot | ↶ ↷ ]
/// - Top-Right Pill: [ 100% Zoom Badge | ▤ Page & Scroll Mode | ↗ Export | ⋯ Overflow ]
class CanvasTopNavBar extends StatelessWidget {
  final String title;
  final String syncStatus;
  final bool isReadingMode;
  final bool canUndo;
  final bool canRedo;
  final int currentZoomPercent;
  final bool isContinuousScroll;
  final PaperTemplateType currentTemplate;
  final VoidCallback onBack;
  final VoidCallback onEditTitle;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onResetZoom;
  final VoidCallback onToggleScrollMode;
  final void Function(PaperTemplateType type) onSelectTemplate;
  final VoidCallback onOpenTemplateCustomizer;
  final VoidCallback onExport;
  final void Function(String action) onOverflowAction;

  const CanvasTopNavBar({
    super.key,
    required this.title,
    required this.syncStatus,
    required this.isReadingMode,
    required this.canUndo,
    required this.canRedo,
    required this.currentZoomPercent,
    required this.isContinuousScroll,
    required this.currentTemplate,
    required this.onBack,
    required this.onEditTitle,
    required this.onUndo,
    required this.onRedo,
    required this.onResetZoom,
    required this.onToggleScrollMode,
    required this.onSelectTemplate,
    required this.onOpenTemplateCustomizer,
    required this.onExport,
    required this.onOverflowAction,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isPhone = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 8.0 : 16.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ==========================================
          // 1. TOP-LEFT PILL
          // ==========================================
          CanvasFloatingPill(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back Button
                Tooltip(
                  message: 'Return to Library',
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.arrow_back_rounded, size: 18),
                    ),
                  ),
                ),

                // Note Title & Sync Dot (Desktop & Tablet)
                if (!isPhone) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onEditTitle,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 220 : 130,
                            ),
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _buildSyncDot(syncStatus),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    height: 18,
                    child: VerticalDivider(
                      width: 10,
                      thickness: 1,
                      color: Colors.grey.withValues(alpha: 0.25),
                    ),
                  ),
                ],

                // Undo Button
                Tooltip(
                  message: 'Undo (Ctrl+Z)',
                  child: InkWell(
                    onTap: canUndo ? onUndo : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.undo_rounded,
                        size: 18,
                        color: canUndo ? null : Colors.grey.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),

                // Redo Button
                Tooltip(
                  message: 'Redo (Ctrl+Y)',
                  child: InkWell(
                    onTap: canRedo ? onRedo : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.redo_rounded,
                        size: 18,
                        color: canRedo ? null : Colors.grey.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // 2. TOP-RIGHT PILL
          // ==========================================
          CanvasFloatingPill(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 100% Zoom Reset Badge (Desktop & Tablet)
                if (!isPhone) ...[
                  Tooltip(
                    message: 'Reset Zoom (Ctrl+0)',
                    child: InkWell(
                      onTap: onResetZoom,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$currentZoomPercent%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // ▤ Page & Scroll Mode Menu
                PopupMenuButton<String>(
                  tooltip: 'Page, Scroll Mode & Paper Template (▤)',
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (val) {
                    if (val == 'toggle_scroll') {
                      onToggleScrollMode();
                    } else if (val == 'custom_template') {
                      onOpenTemplateCustomizer();
                    } else if (val.startsWith('template:')) {
                      final tId = val.replaceFirst('template:', '');
                      final targetType = PaperTemplateType.fromId(tId);
                      onSelectTemplate(targetType);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'toggle_scroll',
                      child: Row(
                        children: [
                          Icon(
                            isContinuousScroll ? Icons.view_stream_rounded : Icons.view_carousel_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isContinuousScroll
                                ? 'Switch to Horizontal Flip'
                                : 'Switch to Vertical Scroll',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      enabled: false,
                      child: Text(
                        'PAPER TEMPLATE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    _buildTemplateMenuItem('Blank', PaperTemplateType.blankPaper),
                    _buildTemplateMenuItem('College Ruled', PaperTemplateType.collegeRuled),
                    _buildTemplateMenuItem('Wide Ruled', PaperTemplateType.wideRuled),
                    _buildTemplateMenuItem('Square Grid', PaperTemplateType.squareGrid),
                    _buildTemplateMenuItem('Dot Grid', PaperTemplateType.dottedPaper),
                    _buildTemplateMenuItem('Isometric', PaperTemplateType.isometricPaper),
                    _buildTemplateMenuItem('Cornell Notes', PaperTemplateType.cornellNotes),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'custom_template',
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded, size: 18),
                          SizedBox(width: 10),
                          Text(
                            'Paper Template & Style...',
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ↗ Export Button (Desktop & Tablet)
                if (!isPhone) ...[
                  const SizedBox(width: 2),
                  Tooltip(
                    message: 'Export Notebook (PDF, PNG, SVG)',
                    child: InkWell(
                      onTap: onExport,
                      borderRadius: BorderRadius.circular(999),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.ios_share_rounded, size: 18),
                      ),
                    ),
                  ),
                ],

                // ⋯ Overflow Menu
                PopupMenuButton<String>(
                  tooltip: 'More actions (⋯)',
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: onOverflowAction,
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'readingMode',
                      child: Row(
                        children: [
                          Icon(
                            isReadingMode ? Icons.edit_note : Icons.auto_stories_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isReadingMode ? 'Exit Focus Mode' : 'Focus / Reading Mode',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'search',
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Search Document', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'attachments',
                      child: Row(
                        children: [
                          Icon(Icons.attachment_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Attachments (Drive)', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'audio',
                      child: Row(
                        children: [
                          Icon(Icons.mic_none_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Lecture Audio', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'aiAssistant',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18, color: Colors.amber),
                          SizedBox(width: 10),
                          Text('AI Study Assistant', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'history',
                      child: Row(
                        children: [
                          Icon(Icons.history_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Version History', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'templateStore',
                      child: Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Template Store', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'bookmark',
                      child: Row(
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Bookmark Page', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    if (isPhone)
                      const PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.ios_share_rounded, size: 18),
                            SizedBox(width: 10),
                            Text('Export (PDF / PNG)', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildTemplateMenuItem(String label, PaperTemplateType type) {
    final isCurrent = currentTemplate == type;
    return PopupMenuItem(
      value: 'template:${type.id}',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          if (isCurrent)
            const Icon(Icons.check, size: 16, color: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildSyncDot(String status) {
    Color dotColor = Colors.green;
    String tip = 'Synced to Cloud';
    if (status == 'syncing') {
      dotColor = Colors.blueAccent;
      tip = 'Syncing...';
    } else if (status == 'offline') {
      dotColor = Colors.amber;
      tip = 'Offline (Saved Locally)';
    } else if (status == 'error') {
      dotColor = Colors.redAccent;
      tip = 'Sync Error';
    }

    return Tooltip(
      message: tip,
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

