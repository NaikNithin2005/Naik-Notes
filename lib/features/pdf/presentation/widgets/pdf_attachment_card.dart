import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/attachment_model.dart';
import '../../../../features/authentication/data/auth_provider.dart';
import '../../../../features/storage/data/google_drive_provider.dart';
import '../screens/pdf_attachment_viewer_screen.dart';

/// Compact PDF card rendered inside notes and attachments panes.
class PdfAttachmentCard extends ConsumerStatefulWidget {
  final NoteAttachment attachment;
  final VoidCallback? onDelete;

  const PdfAttachmentCard({
    super.key,
    required this.attachment,
    this.onDelete,
  });

  @override
  ConsumerState<PdfAttachmentCard> createState() => _PdfAttachmentCardState();
}

class _PdfAttachmentCardState extends ConsumerState<PdfAttachmentCard> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  Future<void> _handleTap(BuildContext context) async {
    final attachment = widget.attachment;
    final auth = ref.read(authProvider);
    final uid = auth.user?.id ?? 'local_user';

    // 1. Check if local file exists
    if (attachment.localPath != null && attachment.localPath!.isNotEmpty) {
      final localFile = File(attachment.localPath!);
      if (await localFile.exists()) {
        if (!context.mounted) return;
        await PdfAttachmentViewerScreen.open(
          context,
          pdfFile: localFile,
          title: attachment.fileName,
          attachment: attachment,
        );
        return;
      }
    }

    // 2. Download from Google Drive if needed
    if (attachment.driveFileId != null && attachment.driveFileId!.isNotEmpty) {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
      });

      try {
        final coordinator = ref.read(attachmentSyncCoordinatorProvider);
        final file = await coordinator.getAttachmentFile(
          uid: uid,
          attachment: attachment,
          onProgress: (p) {
            if (mounted) setState(() => _downloadProgress = p);
          },
        );

        if (!context.mounted) return;
        await PdfAttachmentViewerScreen.open(
          context,
          pdfFile: file,
          title: attachment.fileName,
          attachment: attachment,
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load PDF from Google Drive: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF file is not available locally or in Google Drive.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  (Color, String) _getStatusBadge(String status) {
    switch (status) {
      case AttachmentUploadStatus.uploaded:
        return (const Color(0xFF22C55E), 'Synced');
      case AttachmentUploadStatus.uploading:
        return (const Color(0xFF38BDF8), 'Uploading...');
      case AttachmentUploadStatus.downloading:
        return (const Color(0xFFA855F7), 'Downloading...');
      case AttachmentUploadStatus.availableOffline:
        return (const Color(0xFF60A5FA), 'Offline');
      case AttachmentUploadStatus.driveDisconnected:
        return (const Color(0xFFF59E0B), 'Local Only');
      case AttachmentUploadStatus.failed:
        return (const Color(0xFFEF4444), 'Failed');
      default:
        return (const Color(0xFF94A3B8), 'Pending');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (badgeColor, badgeLabel) = _getStatusBadge(widget.attachment.uploadStatus);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isDark ? const Color(0xFF1E293B) : Colors.red.shade50.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.red.shade200.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _isDownloading ? null : () => _handleTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // PDF Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),

              // Title and Size
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.attachment.fileName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          widget.attachment.humanReadableSize,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: badgeColor.withValues(alpha: 0.5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isDownloading) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _downloadProgress > 0 ? _downloadProgress : null,
                        color: Colors.redAccent,
                        backgroundColor: Colors.red.shade100,
                      ),
                    ],
                  ],
                ),
              ),

              // Action buttons
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                tooltip: 'Open PDF',
                onPressed: _isDownloading ? null : () => _handleTap(context),
              ),
              if (widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  tooltip: 'Remove',
                  onPressed: widget.onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
