import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/history/note_history_service.dart';

/// Modal bottom sheet displaying the audit history of created, updated, and deleted notes,
/// including exact date/time, originating device, and user email.
class NotesHistorySheet extends ConsumerStatefulWidget {
  const NotesHistorySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotesHistorySheet(),
    );
  }

  @override
  ConsumerState<NotesHistorySheet> createState() => _NotesHistorySheetState();
}

class _NotesHistorySheetState extends ConsumerState<NotesHistorySheet> {
  NoteActionType? _selectedFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = ref.watch(noteHistoryProvider);

    final filtered = history.where((entry) {
      if (_selectedFilter != null && entry.action != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchTitle = entry.noteTitle.toLowerCase().contains(query);
        final matchDevice = entry.deviceName.toLowerCase().contains(query);
        final matchUser = entry.userEmail.toLowerCase().contains(query);
        return matchTitle || matchDevice || matchUser;
      }
      return true;
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.leatherTerracotta.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_edu_rounded,
                    color: AppColors.leatherTerracotta,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes & Sync History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Timeline of notes created, updated, and deleted across devices',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by note title, device, or user...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Activity'),
                        selected: _selectedFilter == null,
                        onSelected: (_) => setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
                        label: const Text('Created'),
                        selected: _selectedFilter == NoteActionType.created,
                        onSelected: (_) => setState(() => _selectedFilter = NoteActionType.created),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.edit_note_rounded, size: 16, color: Colors.blue),
                        label: const Text('Updated'),
                        selected: _selectedFilter == NoteActionType.updated,
                        onSelected: (_) => setState(() => _selectedFilter = NoteActionType.updated),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        avatar: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                        label: const Text('Deleted'),
                        selected: _selectedFilter == NoteActionType.deleted,
                        onSelected: (_) => setState(() => _selectedFilter = NoteActionType.deleted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // History List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 56,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedFilter == null
                                ? 'No note activity recorded yet'
                                : 'No ${_selectedFilter!.name} notes found',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Actions performed on your notebooks across devices will be automatically logged and synced here.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _HistoryCard(entry: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final NoteActivityEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color actionColor;
    IconData actionIcon;
    String actionLabel;

    switch (entry.action) {
      case NoteActionType.created:
        actionColor = Colors.green;
        actionIcon = Icons.add_circle_outline_rounded;
        actionLabel = 'CREATED';
        break;
      case NoteActionType.updated:
        actionColor = Colors.blue;
        actionIcon = Icons.edit_note_rounded;
        actionLabel = 'UPDATED';
        break;
      case NoteActionType.deleted:
        actionColor = Colors.red;
        actionIcon = Icons.delete_outline_rounded;
        actionLabel = 'DELETED';
        break;
    }

    IconData deviceIcon = Icons.devices_rounded;
    final devLower = entry.deviceName.toLowerCase();
    if (devLower.contains('windows')) {
      deviceIcon = Icons.laptop_windows_rounded;
    } else if (devLower.contains('android')) {
      deviceIcon = Icons.android_rounded;
    } else if (devLower.contains('ipad') || devLower.contains('apple') || devLower.contains('ios')) {
      deviceIcon = Icons.tablet_mac_rounded;
    } else if (devLower.contains('mac')) {
      deviceIcon = Icons.laptop_mac_rounded;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: entry.action == NoteActionType.deleted
            ? null
            : () {
                Navigator.of(context).pop();
                context.go(RouteNames.notebookPath(entry.noteId));
              },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Action Badge + Date/Time
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(actionIcon, size: 14, color: actionColor),
                    const SizedBox(width: 4),
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: actionColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(
                Icons.access_time_rounded,
                size: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
              Text(
                entry.formattedDateTime,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Note Title
          Text(
            entry.noteTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              decoration: entry.action == NoteActionType.deleted
                  ? TextDecoration.lineThrough
                  : null,
            ),
          ),

          if (entry.details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.details,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Metadata Chips (Device & User)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Device Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(deviceIcon, size: 13, color: theme.colorScheme.primary),
                    const SizedBox(width: 5),
                    Text(
                      entry.deviceName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // User Email Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 13,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      entry.userEmail,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
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
);
  }
}

