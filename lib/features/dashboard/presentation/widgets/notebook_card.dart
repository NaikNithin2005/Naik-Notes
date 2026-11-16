import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/notebook_model.dart';

/// Realistic stationery notebook card widget with context actions.
class NotebookCard extends StatelessWidget {
  final Notebook notebook;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onRename;
  final VoidCallback? onDuplicate;
  final VoidCallback? onMoveToFolder;
  final VoidCallback? onArchive;
  final VoidCallback? onChangeCover;
  final VoidCallback? onExport;
  final VoidCallback? onDelete;

  const NotebookCard({
    super.key,
    required this.notebook,
    required this.onTap,
    required this.onToggleFavorite,
    this.onRename,
    this.onDuplicate,
    this.onMoveToFolder,
    this.onArchive,
    this.onChangeCover,
    this.onExport,
    this.onDelete,
  });

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF8B4513);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverColor = _parseColor(notebook.coverColorHex);
    final isDarkCover =
        ThemeData.estimateBrightnessForColor(coverColor) == Brightness.dark;
    final titleColor = isDarkCover ? Colors.white : const Color(0xFF1A1A1A);
    final subtitleColor = isDarkCover ? Colors.white70 : Colors.black54;

    return Semantics(
      label: 'Notebook: ${notebook.title}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notebook Cover with Book Spine and Ribbon Effect
              Expanded(
                child: Container(
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
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(4, 5),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Custom Uploaded Cover Image Background
                      if (notebook.coverImageUrl != null &&
                          notebook.coverImageUrl!.isNotEmpty)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(8),
                              bottomLeft: Radius.circular(8),
                              topRight: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: notebook.coverImageUrl!.startsWith('http')
                                ? Image.network(
                                    notebook.coverImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  )
                                : Image.file(
                                    File(notebook.coverImageUrl!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  ),
                          ),
                        ),

                      // Book Spine Shadow on Left
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 24,
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
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Spine Stitches / Crease
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        width: 1,
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                      ),

                      // Cover Content Area
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 32,
                          right: 16,
                          top: 18,
                          bottom: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Page Count and Favorite Star
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (isDarkCover
                                                ? Colors.white
                                                : Colors.black)
                                            .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${notebook.pageCount} pgs',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: titleColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (notebook.isArchived)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        margin: const EdgeInsets.only(right: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: const Text(
                                          'ARCHIVED',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    IconButton(
                                      icon: Icon(
                                        notebook.isFavorite
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        size: 22,
                                        color: notebook.isFavorite
                                            ? const Color(0xFFF59E0B)
                                            : titleColor.withValues(alpha: 0.5),
                                      ),
                                      onPressed: onToggleFavorite,
                                      tooltip: notebook.isFavorite
                                          ? 'Remove from favorites'
                                          : 'Add to favorites',
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const Spacer(),

                            // Notebook Label / Plate (Stationery look)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDarkCover ? Colors.black : Colors.white)
                                        .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      (isDarkCover
                                              ? Colors.white
                                              : Colors.black)
                                          .withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notebook.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                      fontFamily: 'Georgia',
                                      height: 1.25,
                                    ),
                                  ),
                                  if (notebook.description.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      notebook.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: subtitleColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Title, Date, and Context Actions Menu beneath book cover
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notebook.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat(
                              'MMM d, yyyy',
                            ).format(notebook.updatedAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Notebook options',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (action) {
                        switch (action) {
                          case 'rename':
                            onRename?.call();
                            break;
                          case 'duplicate':
                            onDuplicate?.call();
                            break;
                          case 'move':
                            onMoveToFolder?.call();
                            break;
                          case 'archive':
                            onArchive?.call();
                            break;
                          case 'change_cover':
                            onChangeCover?.call();
                            break;
                          case 'export':
                            onExport?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'move',
                          child: Row(
                            children: [
                              Icon(Icons.drive_file_move_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Move to Folder'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(
                                notebook.isArchived
                                    ? Icons.unarchive_outlined
                                    : Icons.archive_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                notebook.isArchived ? 'Unarchive' : 'Archive',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'change_cover',
                          child: Row(
                            children: [
                              Icon(Icons.image_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Change Cover Image'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.ios_share_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Export as PDF...'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
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
        ),
      ),
    );
  }
}
