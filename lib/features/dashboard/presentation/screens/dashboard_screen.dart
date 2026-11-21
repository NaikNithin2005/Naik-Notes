import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:naik_notes/core/constants/app_constants.dart';
import 'package:naik_notes/core/routing/route_names.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/search_index_model.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/folders/data/folder_provider.dart';
import 'package:naik_notes/features/folders/presentation/widgets/create_folder_dialog.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/notebooks/data/page_provider.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/create_notebook_dialog.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/move_to_folder_dialog.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/rename_notebook_dialog.dart';
import 'package:naik_notes/features/search/data/search_provider.dart';
import 'package:naik_notes/features/sync/data/sync_provider.dart';
import 'package:naik_notes/features/template_store/presentation/widgets/template_store_sheet.dart';
import 'package:naik_notes/core/theme/theme_controller.dart';
import 'package:naik_notes/core/widgets/naik_empty_state.dart';
import 'package:naik_notes/core/widgets/naik_notes_logo.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/page_model.dart';
import 'package:naik_notes/data/models/paper_template_model.dart';
import 'package:naik_notes/features/notebooks/presentation/widgets/export_notebook_dialog.dart';
import 'package:naik_notes/services/pdf/pdf_service.dart';

import 'package:naik_notes/features/history/presentation/widgets/notes_history_sheet.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';
import 'package:naik_notes/features/storage/presentation/widgets/google_drive_connect_dialog.dart';

import '../widgets/notebook_card.dart';
import '../widgets/sync_status_badge.dart';

/// Main Dashboard screen displaying notebooks, folders, quick actions, and search.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDriveOnStartup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final driveState = ref.read(googleDriveProvider);
      if (driveState.isConnected) {
        ref.read(googleDriveProvider.notifier).scheduleAutoSync(
          delay: const Duration(seconds: 1),
          reason: 'app_resumed',
        );
      }
    }
  }

  Future<void> _checkDriveOnStartup() async {
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) return;

    // Await initial Drive status resolution to prevent false popup triggers if already connected
    await ref.read(googleDriveProvider.notifier).initializationFuture;
    if (!mounted) return;

    final driveState = ref.read(googleDriveProvider);
    if (driveState.isConnected) {
      // Already authorized: automatically pull latest notes from other devices
      ref.read(googleDriveProvider.notifier).syncNow(silent: true);
      return;
    }

    await GoogleDriveConnectDialog.checkAndShow(context, ref);
  }

  void _showCreateNotebookDialog(BuildContext context, {String? folderId}) {
    showDialog<void>(
      context: context,
      builder: (context) => CreateNotebookDialog(initialFolderId: folderId),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const CreateFolderDialog(),
    );
  }

  void _showRenameDialog(BuildContext context, Notebook nb) {
    showDialog<void>(
      context: context,
      builder: (context) => RenameNotebookDialog(notebook: nb),
    );
  }

  void _showMoveToFolderDialog(BuildContext context, Notebook nb) {
    showDialog<void>(
      context: context,
      builder: (context) => MoveToFolderDialog(notebook: nb),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Notebook nb,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Notebook?'),
        content: Text(
          'Are you sure you want to delete "${nb.title}"? This item can be recovered from trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(notebooksProvider.notifier).deleteNotebook(nb.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notebook "${nb.title}" deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _changeCoverImage(
    BuildContext context,
    WidgetRef ref,
    Notebook nb,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result.isEmpty) return;
      final file = result.first;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Uploading custom cover to cloud storage...'),
              ],
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }

      final authState = ref.read(authProvider);
      final uid = authState.user?.id ?? 'guest';
      final storageService = ref.read(firebaseStorageServiceProvider);

      final extension = file.extension ?? 'jpg';
      final downloadUrl = await storageService.uploadNotebookCover(
        uid: uid,
        notebookId: nb.id,
        imageBytes: bytes,
        extension: extension,
      );

      await ref
          .read(notebooksProvider.notifier)
          .updateCover(nb.id, coverImageUrl: downloadUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cover image updated for "${nb.title}"!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update cover image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (files.isNotEmpty) {
        final file = files.first;
        final bytes = await file.readAsBytes();
        final name = file.name;

        if (bytes.isNotEmpty) {
          final pdfService = ref.read(pdfServiceProvider);
          final newNotebook = await pdfService.importPdfFromBytes(
            bytes: bytes,
            filename: name,
          );

          await ref.read(notebooksProvider.notifier).loadNotebooks();

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Imported "${newNotebook.title}" (${newNotebook.pageCount} pages)',
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('${RouteNames.notebookView}?id=${newNotebook.id}');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not import PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportNotebook(
    BuildContext context,
    WidgetRef ref,
    Notebook nb,
  ) async {
    final pageRepo = ref.read(pageRepositoryProvider);
    final pages = await pageRepo.getPagesForNotebook(nb.id);
    if (!context.mounted) return;
    ExportNotebookDialog.show(
      context,
      notebook: nb,
      pages: pages.isNotEmpty
          ? pages
          : [
              NotebookPage(
                id: 'page-${nb.id}-1',
                notebookId: nb.id,
                pageNumber: 1,
                templateId: nb.paperTemplateId,
                properties: PaperProperties.defaultFor(
                  PaperTemplateType.fromId(nb.paperTemplateId),
                ),
                createdAt: nb.createdAt,
                updatedAt: nb.updatedAt,
              ),
            ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    int filterTab,
    String searchQuery,
    String? selectedFolderId,
    List<Notebook> notebooks,
    dynamic folders,
  ) {
    if (searchQuery.isNotEmpty) {
      return NaikEmptyState.search(
        query: searchQuery,
        onClearSearch: () =>
            ref.read(searchQueryProvider.notifier).setQuery(''),
      );
    }

    if (selectedFolderId != null) {
      String folderName = 'Folder';
      if (selectedFolderId == '__unfiled__') {
        folderName = 'Unfiled';
      } else {
        final match = folders.where((f) => f.id == selectedFolderId);
        if (match.isNotEmpty) {
          folderName = match.first.name;
        }
      }
      return NaikEmptyState.folder(
        folderName: folderName,
        onCreateNotebook: () => _showCreateNotebookDialog(
          context,
          folderId: selectedFolderId == '__unfiled__' ? null : selectedFolderId,
        ),
      );
    }

    if (filterTab == 1) {
      return NaikEmptyState.recent(
        onBrowseNotebooks: () =>
            ref.read(dashboardFilterProvider.notifier).setFilter(0),
      );
    }

    if (filterTab == 2) {
      return NaikEmptyState.favorites(
        onBrowseNotebooks: () =>
            ref.read(dashboardFilterProvider.notifier).setFilter(0),
      );
    }

    if (filterTab == 3) {
      return NaikEmptyState.archive();
    }

    return NaikEmptyState.notebooks(
      onCreateNotebook: () => _showCreateNotebookDialog(context),
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notebooks = ref.watch(notebooksProvider);
    final folders = ref.watch(foldersProvider);
    final selectedFolderId = ref.watch(selectedFolderProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResultsAsync = ref.watch(globalSearchResultsProvider);
    final filterTab = ref.watch(dashboardFilterProvider);
    final isGridView = ref.watch(isGridViewProvider);
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;

    // Filter notebooks according to search, folder, and tab
    final filteredNotebooks = notebooks.where((nb) {
      if (nb.deletedAt != null) return false;

      // Filter tab logic:
      // 0: All active (non-archived)
      // 1: Recent (updated within 7 days, non-archived)
      // 2: Favorites (non-archived)
      // 3: Archived only
      if (filterTab == 3) {
        if (!nb.isArchived) return false;
      } else {
        if (nb.isArchived) return false;
        if (filterTab == 1) {
          if (DateTime.now().difference(nb.updatedAt).inDays > 7) return false;
        } else if (filterTab == 2) {
          if (!nb.isFavorite) return false;
        }
      }

      // Folder filtering
      if (selectedFolderId != null) {
        if (selectedFolderId == '__unfiled__') {
          if (nb.folderId != null) return false;
        } else {
          if (nb.folderId != selectedFolderId) return false;
        }
      }

      // Search query filtering
      final matchesSearch =
          nb.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          nb.description.toLowerCase().contains(searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      return true;
    }).toList();

    final isCompact = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Top Header & Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row with User Greeting & Sync Status
                  if (isCompact) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const NaikNotesLogo(size: 32, showText: true),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Theme toggle button (Dark vs Reading Mode)
                            IconButton(
                              icon: Icon(
                                ref.watch(themeControllerProvider).themeMode ==
                                        AppThemeMode.dark
                                    ? Icons.auto_stories_outlined
                                    : Icons.dark_mode_outlined,
                                size: 20,
                              ),
                              tooltip:
                                  ref
                                          .watch(themeControllerProvider)
                                          .themeMode ==
                                      AppThemeMode.dark
                                  ? 'Switch to Reading Mode'
                                  : 'Switch to Dark Mode',
                              onPressed: () => ref
                                  .read(themeControllerProvider.notifier)
                                  .toggleTheme(),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.storefront_outlined,
                                size: 20,
                              ),
                              tooltip: 'Template Store',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => const TemplateStoreSheet(),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.history_edu_rounded,
                                size: 20,
                              ),
                              tooltip: 'Notes & Sync History',
                              onPressed: () => NotesHistorySheet.show(context),
                            ),
                            const SyncStatusBadge(),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => context.go(RouteNames.profile),
                              borderRadius: BorderRadius.circular(20),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: theme.colorScheme.primary,
                                child: Text(
                                  (currentUser?.displayName ?? 'U')
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your thoughts. Your pages. Your creativity.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const NaikNotesLogo(size: 40, showText: true),
                              const SizedBox(height: 4),
                              Text(
                                'Your thoughts. Your pages. Your creativity.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Actions: Theme Toggle, Template Store, Sync, Profile
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                ref.watch(themeControllerProvider).themeMode ==
                                        AppThemeMode.dark
                                    ? Icons.auto_stories_outlined
                                    : Icons.dark_mode_outlined,
                              ),
                              tooltip:
                                  ref
                                          .watch(themeControllerProvider)
                                          .themeMode ==
                                      AppThemeMode.dark
                                  ? 'Switch to Reading Mode'
                                  : 'Switch to Dark Mode',
                              onPressed: () => ref
                                  .read(themeControllerProvider.notifier)
                                  .toggleTheme(),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.storefront_outlined),
                              tooltip: 'Community Template Store',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => const TemplateStoreSheet(),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.history_edu_rounded),
                              tooltip: 'Notes & Sync History',
                              onPressed: () => NotesHistorySheet.show(context),
                            ),
                            const SizedBox(width: 4),
                            const SyncStatusBadge(),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => context.go(RouteNames.profile),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 10,
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      child: Text(
                                        (currentUser?.displayName ?? 'U')
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentUser?.displayName ?? 'User',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              tooltip: 'Settings',
                              onPressed: () => context.go(RouteNames.settings),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Search Bar and Quick Actions (Responsive)
                  if (isCompact) ...[
                    SearchBar(
                      hintText: 'Search notebooks, handwriting, tags...',
                      leading: const Icon(Icons.search_rounded),
                      trailing: searchQuery.isNotEmpty
                          ? [
                              IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .clear();
                                },
                              ),
                            ]
                          : null,
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val);
                      },
                      elevation: const WidgetStatePropertyAll(0.5),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _showCreateNotebookDialog(
                              context,
                              folderId: selectedFolderId == '__unfiled__'
                                  ? null
                                  : selectedFolderId,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('New Notebook'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _importPdf(context, ref),
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                          ),
                          label: const Text('Import PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(RouteNames.notes),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Open Rich Text Notes'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            hintText:
                                'Search notebooks, handwritten notes, tags...',
                            leading: const Icon(Icons.search_rounded),
                            trailing: searchQuery.isNotEmpty
                                ? [
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        ref
                                            .read(searchQueryProvider.notifier)
                                            .clear();
                                      },
                                    ),
                                  ]
                                : null,
                            onChanged: (val) {
                              ref
                                  .read(searchQueryProvider.notifier)
                                  .setQuery(val);
                            },
                            elevation: const WidgetStatePropertyAll(0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _importPdf(context, ref),
                          icon: const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                          ),
                          label: const Text('Import PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => context.go(RouteNames.notes),
                          icon: const Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                          ),
                          label: const Text('Rich Notes'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _showCreateNotebookDialog(
                            context,
                            folderId: selectedFolderId == '__unfiled__'
                                ? null
                                : selectedFolderId,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('New Notebook'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Folder Navigation Chips Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // "All Folders" Chip
                        FilterChip(
                          avatar: const Icon(
                            Icons.folder_copy_outlined,
                            size: 16,
                          ),
                          label: const Text('All Folders'),
                          selected: selectedFolderId == null,
                          onSelected: (_) {
                            ref
                                .read(selectedFolderProvider.notifier)
                                .clearSelection();
                          },
                        ),
                        const SizedBox(width: 8),

                        // "Unfiled" Chip
                        FilterChip(
                          avatar: const Icon(
                            Icons.folder_off_outlined,
                            size: 16,
                          ),
                          label: const Text('Unfiled'),
                          selected: selectedFolderId == '__unfiled__',
                          onSelected: (_) {
                            ref
                                .read(selectedFolderProvider.notifier)
                                .selectFolder('__unfiled__');
                          },
                        ),
                        const SizedBox(width: 8),

                        // Custom User Folders
                        ...folders.map((f) {
                          final isSelected = selectedFolderId == f.id;
                          final color = _parseColor(f.colorHex);
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              avatar: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              label: Text(f.name),
                              selected: isSelected,
                              onSelected: (_) {
                                ref
                                    .read(selectedFolderProvider.notifier)
                                    .selectFolder(f.id);
                              },
                            ),
                          );
                        }),

                        // "+ New Folder" action chip
                        ActionChip(
                          avatar: const Icon(
                            Icons.create_new_folder_outlined,
                            size: 16,
                          ),
                          label: const Text('New Folder'),
                          onPressed: () => _showCreateFolderDialog(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Segment & View Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(
                                value: 0,
                                label: Text('All Notebooks'),
                                icon: Icon(Icons.book_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: 1,
                                label: Text('Recent'),
                                icon: Icon(Icons.history_rounded, size: 16),
                              ),
                              ButtonSegment(
                                value: 2,
                                label: Text('Favorites'),
                                icon: Icon(Icons.star_rounded, size: 16),
                              ),
                              ButtonSegment(
                                value: 3,
                                label: Text('Archived'),
                                icon: Icon(Icons.archive_outlined, size: 16),
                              ),
                            ],
                            selected: {filterTab},
                            onSelectionChanged: (set) {
                              ref
                                  .read(dashboardFilterProvider.notifier)
                                  .setFilter(set.first);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // View Mode (Grid / List)
                      IconButton(
                        icon: Icon(
                          isGridView
                              ? Icons.view_list_rounded
                              : Icons.grid_view_rounded,
                        ),
                        tooltip: isGridView
                            ? 'Switch to List View'
                            : 'Switch to Grid View',
                        onPressed: () {
                          ref.read(isGridViewProvider.notifier).toggle();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Global Deep Search Results (Handwriting, Sticky Notes, PDF matches)
          if (searchQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: searchResultsAsync.maybeWhen(
                  data: (List<SearchResultItem> results) {
                    final deepMatches = results
                        .where(
                          (r) =>
                              r.sourceType != 'notebookTitle' &&
                              r.sourceType != 'notebookDescription',
                        )
                        .toList();
                    if (deepMatches.isEmpty) return const SizedBox.shrink();

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Found in handwritten notes & pages (${deepMatches.length})',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...deepMatches.take(5).map((match) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  match.sourceType == 'handwriting'
                                      ? Icons.gesture
                                      : match.sourceType == 'sticky_note'
                                      ? Icons.note_alt_outlined
                                      : Icons.picture_as_pdf,
                                  size: 20,
                                  color: theme.colorScheme.secondary,
                                ),
                                title: Text(
                                  '${match.notebookTitle} • Page ${match.pageNumber ?? 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  match.snippet,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                ),
                                onTap: () {
                                  if (match.pageNumber != null) {
                                    ref
                                        .read(currentPageIndexProvider.notifier)
                                        .setPage(match.pageNumber!);
                                  }
                                  context.push('/notebook/${match.notebookId}');
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),

          // Global Deep Search Results (Handwriting, Sticky Notes, PDF matches)
          if (searchQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: searchResultsAsync.maybeWhen(
                  data: (List<SearchResultItem> results) {
                    final deepMatches = results
                        .where(
                          (r) =>
                              r.sourceType != 'notebookTitle' &&
                              r.sourceType != 'notebookDescription',
                        )
                        .toList();
                    if (deepMatches.isEmpty) return const SizedBox.shrink();

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Found in handwritten notes & pages (${deepMatches.length})',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...deepMatches.take(5).map((match) {
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(
                                  match.sourceType == 'handwriting'
                                      ? Icons.gesture
                                      : match.sourceType == 'sticky_note'
                                      ? Icons.note_alt_outlined
                                      : Icons.picture_as_pdf,
                                  size: 20,
                                  color: theme.colorScheme.secondary,
                                ),
                                title: Text(
                                  '${match.notebookTitle} • Page ${match.pageNumber ?? 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                subtitle: Text(
                                  match.snippet,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                ),
                                onTap: () {
                                  if (match.pageNumber != null) {
                                    ref
                                        .read(currentPageIndexProvider.notifier)
                                        .setPage(match.pageNumber!);
                                  }
                                  context.push('/notebook/${match.notebookId}');
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
              ),
            ),

          // Notebooks Content (Grid or Empty State)
          if (filteredNotebooks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                context,
                ref,
                filterTab,
                searchQuery,
                selectedFolderId,
                notebooks,
                folders,
              ),
            )
          else if (isGridView)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final crossAxisCount = width > AppConstants.tabletBreakpoint
                      ? 4
                      : width > AppConstants.mobileBreakpoint
                      ? 3
                      : 2;

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.68,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final nb = filteredNotebooks[index];
                      return NotebookCard(
                        notebook: nb,
                        onTap: () => context.go(RouteNames.notebookPath(nb.id)),
                        onToggleFavorite: () {
                          ref
                              .read(notebooksProvider.notifier)
                              .toggleFavorite(nb.id);
                        },
                        onRename: () => _showRenameDialog(context, nb),
                        onDuplicate: () async {
                          final copy = await ref
                              .read(notebooksProvider.notifier)
                              .duplicateNotebook(nb.id);
                          if (copy != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Duplicated "${nb.title}"'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        onChangeCover: () =>
                            _changeCoverImage(context, ref, nb),
                        onMoveToFolder: () =>
                            _showMoveToFolderDialog(context, nb),
                        onArchive: () async {
                          if (nb.isArchived) {
                            await ref
                                .read(notebooksProvider.notifier)
                                .unarchiveNotebook(nb.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Unarchived "${nb.title}"'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            await ref
                                .read(notebooksProvider.notifier)
                                .archiveNotebook(nb.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Archived "${nb.title}"'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        onExport: () => _exportNotebook(context, ref, nb),
                        onDelete: () => _confirmDelete(context, ref, nb),
                      );
                    }, childCount: filteredNotebooks.length),
                  );
                },
              ),
            )
          else
            // List View
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final nb = filteredNotebooks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _parseColor(nb.coverColorHex),
                          borderRadius: BorderRadius.circular(6),
                          image:
                              nb.coverImageUrl != null &&
                                  nb.coverImageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: (nb.coverImageUrl!.startsWith('http')
                                      ? NetworkImage(nb.coverImageUrl!)
                                      : FileImage(File(nb.coverImageUrl!))) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            nb.coverImageUrl != null &&
                                nb.coverImageUrl!.isNotEmpty
                            ? null
                            : const Icon(
                                Icons.book,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                      title: Text(
                        nb.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${nb.pageCount} pages • ${nb.pageSize} • ${nb.paperTemplateId.replaceAll('_', ' ')}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              nb.isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: nb.isFavorite
                                  ? const Color(0xFFF59E0B)
                                  : null,
                            ),
                            onPressed: () {
                              ref
                                  .read(notebooksProvider.notifier)
                                  .toggleFavorite(nb.id);
                            },
                          ),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded),
                            onSelected: (action) {
                              switch (action) {
                                case 'rename':
                                  _showRenameDialog(context, nb);
                                  break;
                                case 'duplicate':
                                  ref
                                      .read(notebooksProvider.notifier)
                                      .duplicateNotebook(nb.id);
                                  break;
                                case 'changeCover':
                                  _changeCoverImage(context, ref, nb);
                                  break;
                                case 'move':
                                  _showMoveToFolderDialog(context, nb);
                                  break;
                                case 'archive':
                                  if (nb.isArchived) {
                                    ref
                                        .read(notebooksProvider.notifier)
                                        .unarchiveNotebook(nb.id);
                                  } else {
                                    ref
                                        .read(notebooksProvider.notifier)
                                        .archiveNotebook(nb.id);
                                  }
                                  break;
                                case 'export':
                                  _exportNotebook(context, ref, nb);
                                  break;
                                case 'delete':
                                  _confirmDelete(context, ref, nb);
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'rename',
                                child: Text('Rename'),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicate'),
                              ),
                              const PopupMenuItem(
                                value: 'changeCover',
                                child: Text('Change Cover Image'),
                              ),
                              const PopupMenuItem(
                                value: 'move',
                                child: Text('Move to Folder'),
                              ),
                              PopupMenuItem(
                                value: 'archive',
                                child: Text(
                                  nb.isArchived ? 'Unarchive' : 'Archive',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'export',
                                child: Text('Export as PDF...'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => context.go(RouteNames.notebookPath(nb.id)),
                    ),
                  );
                }, childCount: filteredNotebooks.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
