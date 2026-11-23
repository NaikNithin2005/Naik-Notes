import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/notebook_model.dart';
import '../../features/authentication/data/auth_provider.dart';
import '../../services/storage/cover_image_service.dart';

/// Cross-platform widget for displaying notebook cover images.
///
/// Features:
/// 1. Prioritizes inline Firestore-synced `coverImageBase64` (fastest, offline, zero-token).
/// 2. Google Drive `coverDriveId` fallback with deterministic local caching.
/// 3. In-flight download deduplication and background fetching.
/// 4. Graceful fallback to legacy URLs or local paths.
/// 5. Clean loading placeholders and zero-crash error handling.
class NotebookCoverImage extends ConsumerStatefulWidget {
  final Notebook notebook;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? fallback;

  const NotebookCoverImage({
    super.key,
    required this.notebook,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.fallback,
  });

  @override
  ConsumerState<NotebookCoverImage> createState() => _NotebookCoverImageState();
}

class _NotebookCoverImageState extends ConsumerState<NotebookCoverImage> {
  Uint8List? _cachedBase64Bytes;
  String? _lastBase64String;
  File? _cachedFile;
  bool _isLoading = false;
  String? _loadedDriveId;

  @override
  void initState() {
    super.initState();
    _updateBase64Bytes();
    if (_cachedBase64Bytes == null) {
      _resolveCoverImage();
    }
  }

  @override
  void didUpdateWidget(covariant NotebookCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notebook.coverImageBase64 != widget.notebook.coverImageBase64) {
      _updateBase64Bytes();
    }
    if (_cachedBase64Bytes == null) {
      if (oldWidget.notebook.coverDriveId != widget.notebook.coverDriveId ||
          oldWidget.notebook.coverImageUrl != widget.notebook.coverImageUrl) {
        _resolveCoverImage();
      }
    }
  }

  void _updateBase64Bytes() {
    final b64 = widget.notebook.coverImageBase64;
    if (b64 != _lastBase64String) {
      _lastBase64String = b64;
      if (b64 != null && b64.isNotEmpty) {
        try {
          _cachedBase64Bytes = base64Decode(b64);
        } catch (e) {
          debugPrint('[NotebookCoverImage] Base64 decode error: $e');
          _cachedBase64Bytes = null;
        }
      } else {
        _cachedBase64Bytes = null;
      }
    }
  }

  Future<void> _resolveCoverImage() async {
    final driveId = widget.notebook.coverDriveId;
    if (driveId == null || driveId.isEmpty) {
      if (mounted) {
        setState(() {
          _cachedFile = null;
          _isLoading = false;
          _loadedDriveId = null;
        });
      }
      return;
    }

    if (_loadedDriveId == driveId && _cachedFile != null) {
      return;
    }

    final coverService = ref.read(coverImageServiceProvider);
    final existingLocal = await coverService.getLocallyCachedCover(driveId);
    if (existingLocal != null && mounted) {
      setState(() {
        _cachedFile = existingLocal;
        _isLoading = false;
        _loadedDriveId = driveId;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final uid = ref.read(authProvider).user?.id ?? widget.notebook.ownerId;
    final file = await coverService.getCoverImageFile(
      uid: uid,
      driveFileId: driveId,
    );

    if (mounted) {
      setState(() {
        _cachedFile = file;
        _isLoading = false;
        _loadedDriveId = driveId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_cachedBase64Bytes != null) {
      content = Image.memory(
        _cachedBase64Bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => widget.fallback ?? const SizedBox.shrink(),
      );
    } else if (_cachedFile != null && _cachedFile!.existsSync()) {
      content = Image.file(
        _cachedFile!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => widget.fallback ?? const SizedBox.shrink(),
      );
    } else if (_isLoading) {
      content = widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.black.withValues(alpha: 0.1),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                ),
              ),
            ),
          );
    } else if (widget.notebook.coverImageUrl != null &&
        widget.notebook.coverImageUrl!.isNotEmpty) {
      final legacyUrl = widget.notebook.coverImageUrl!;
      if (legacyUrl.startsWith('http://') || legacyUrl.startsWith('https://')) {
        content = Image.network(
          legacyUrl,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          errorBuilder: (_, _, _) => widget.fallback ?? const SizedBox.shrink(),
        );
      } else {
        // Local path check
        final localFile = File(legacyUrl);
        if (localFile.existsSync()) {
          content = Image.file(
            localFile,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            errorBuilder: (_, _, _) => widget.fallback ?? const SizedBox.shrink(),
          );
        } else {
          content = widget.fallback ?? const SizedBox.shrink();
        }
      }
    } else {
      content = widget.fallback ?? const SizedBox.shrink();
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }

    return content;
  }
}
