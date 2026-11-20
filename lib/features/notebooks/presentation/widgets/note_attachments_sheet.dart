import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:naik_notes/core/theme/app_theme.dart';
import 'package:naik_notes/data/models/attachment_model.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/storage/data/google_drive_provider.dart';

/// Bottom sheet widget allowing users to view, download, preview, and upload
/// note attachments stored in personal Google Drive `appDataFolder` and cached locally.
class NoteAttachmentsSheet extends ConsumerStatefulWidget {
  final String noteId;

  const NoteAttachmentsSheet({
    super.key,
    required this.noteId,
  });

  static Future<void> show(BuildContext context, String noteId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NoteAttachmentsSheet(noteId: noteId),
    );
  }

  @override
  ConsumerState<NoteAttachmentsSheet> createState() =>
      _NoteAttachmentsSheetState();
}

class _NoteAttachmentsSheetState extends ConsumerState<NoteAttachmentsSheet> {
  bool _isPickingOrUploading = false;
  String? _statusMessage;
  double? _uploadProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor =
        isDark ? const Color(0xFFE07A5F) : AppColors.leatherTerracotta;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    final driveState = ref.watch(googleDriveProvider);
    final repo = ref.watch(attachmentRepositoryProvider);
    final auth = ref.watch(authProvider);
    final currentUser = auth.user;
    final uid = currentUser?.id ?? 'local_user';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.brown.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Icon(Icons.attachment_rounded, color: primaryColor, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Note Attachments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Google Drive disconnected warning banner
          if (!driveState.isConnected)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade900.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Google Drive is not connected. Attachments are saved locally and will not sync across other devices until connected in Settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.amber.shade200
                            : Colors.brown.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_isPickingOrUploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _statusMessage ?? 'Uploading attachment...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),

          // Attachments Stream List
          Flexible(
            child: StreamBuilder<List<NoteAttachment>>(
              stream: repo.watchAttachmentsForNote(widget.noteId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final attachments = snapshot.data ?? [];
                if (attachments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 40,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_present_rounded,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No attachments in this notebook yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Attach images, diagrams, research papers, or PDF files.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: attachments.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = attachments[index];
                    return _buildAttachmentCard(context, item, uid);
                  },
                );
              },
            ),
          ),

          // Bottom Action Bar: "+ Add Attachment"
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isPickingOrUploading ? null : () => _pickAndAddAttachment(uid),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Add Attachment (Image / PDF)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentCard(
    BuildContext context,
    NoteAttachment attachment,
    String uid,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final (badgeColor, badgeLabel) = _getStatusBadge(attachment.uploadStatus);

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF0F172A) : Colors.brown.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.brown.shade200,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: attachment.isPdf
                ? Colors.red.shade900.withValues(alpha: 0.15)
                : Colors.blue.shade900.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            attachment.isPdf
                ? Icons.picture_as_pdf_rounded
                : Icons.image_rounded,
            color: attachment.isPdf ? Colors.redAccent : Colors.lightBlueAccent,
            size: 24,
          ),
        ),
        title: Text(
          attachment.fileName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              attachment.humanReadableSize,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: badgeColor.withValues(alpha: 0.4),
                  width: 0.8,
                ),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              tooltip: 'Open / View',
              onPressed: () => _openAttachment(context, attachment, uid),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: Colors.redAccent,
              tooltip: 'Delete',
              onPressed: () => _confirmDeleteAttachment(context, attachment, uid),
            ),
          ],
        ),
      ),
    );
  }

  (Color, String) _getStatusBadge(String status) {
    switch (status) {
      case AttachmentUploadStatus.uploaded:
        return (const Color(0xFF22C55E), 'Uploaded');
      case AttachmentUploadStatus.uploading:
        return (const Color(0xFF38BDF8), 'Uploading...');
      case AttachmentUploadStatus.downloading:
        return (const Color(0xFFA855F7), 'Downloading...');
      case AttachmentUploadStatus.availableOffline:
        return (const Color(0xFF60A5FA), 'Offline Cache');
      case AttachmentUploadStatus.driveDisconnected:
        return (const Color(0xFFF59E0B), 'Local Only');
      case AttachmentUploadStatus.failed:
        return (const Color(0xFFEF4444), 'Upload Failed');
      case AttachmentUploadStatus.downloadFailed:
        return (const Color(0xFFEF4444), 'Download Failed');
      case AttachmentUploadStatus.fileUnavailable:
        return (const Color(0xFF64748B), 'Missing on Drive');
      default:
        return (const Color(0xFF94A3B8), 'Waiting');
    }
  }

  Future<void> _pickAndAddAttachment(String uid) async {
    setState(() {
      _isPickingOrUploading = true;
      _statusMessage = 'Selecting attachment...';
      _uploadProgress = null;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'pdf'],
      );

      if (result.isEmpty || result.first.path == null) {
        setState(() => _isPickingOrUploading = false);
        return;
      }

      final file = File(result.first.path!);
      final fileName = result.first.name;

      setState(() {
        _statusMessage = 'Saving and syncing attachment to Drive...';
      });

      final coordinator = ref.read(attachmentSyncCoordinatorProvider);
      await coordinator.addAttachment(
        uid: uid,
        noteId: widget.noteId,
        sourceFile: file,
        fileName: fileName,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attachment added: $fileName'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add attachment: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingOrUploading = false;
          _statusMessage = null;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<void> _openAttachment(
    BuildContext context,
    NoteAttachment attachment,
    String uid,
  ) async {
    final coordinator = ref.read(attachmentSyncCoordinatorProvider);

    try {
      final file = await coordinator.getAttachmentFile(
        uid: uid,
        attachment: attachment,
        onProgress: (p) {
          // Could update progress
        },
      );

      if (attachment.isImage) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(file),
                ),
                IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      } else {
        // PDF or document: launch with system handler
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open attachment: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _confirmDeleteAttachment(
    BuildContext context,
    NoteAttachment attachment,
    String uid,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Attachment?'),
        content: Text(
          'Are you sure you want to delete "${attachment.fileName}"? '
          'It will be removed from your note, local storage, and Google Drive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(attachmentSyncCoordinatorProvider).deleteAttachment(
                    uid: uid,
                    noteId: widget.noteId,
                    attachmentId: attachment.attachmentId,
                  );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
