# Naik Notes — Phase 4 Implementation Report
**Cross-Platform Attachments, PDF Viewer, Inline Images & Apple Pencil Sketching**
**Version:** Phase 4.0.0  
**Target Platforms:** Windows (Win32 Desktop), Android, iPadOS (Apple Pencil)  
**Date:** November 22, 2026  

---

## 1. Executive Summary

Phase 4 of Naik Notes has been fully implemented, introducing a complete cross-platform attachment ecosystem, rich-text inline image embedding, a dedicated PDF viewer and annotation subsystem, an iPad Apple Pencil sketching canvas, and a robust offline-first synchronization engine wired to Google Drive's hidden `appDataFolder` and Cloud Firestore metadata arrays.

All operations follow a strict **Local-First, Non-Blocking Architecture**:
- Selecting or importing an attachment immediately copies, compresses, and registers the file locally in user-partitioned directories.
- Attachments render in the note immediately with status indicators without blocking user typing or note navigation.
- Remote upload to Google Drive occurs asynchronously in the background. If the user is offline or Drive authorization is absent, operations remain safely queued in SQLite and automatically resume when network connectivity is restored.
- Deletion implements **Reference Counting Safety**: remote files on Google Drive are never deleted if referenced by another note or page.
- Notes moved to Trash preserve their attachments; only permanent deletion triggers local cache and remote storage cleanup.

The entire codebase is verified with **0 analyzer warnings or errors** (`flutter analyze` clean) and **100% test pass rate** across all Phase 4 unit and widget tests.

---

## 2. Dependency Audit & Additions

The `pubspec.yaml` was updated with compatible, modern production packages without deprecation warnings:

| Package | Version | Purpose |
|---|---|---|
| `file_picker` | `^13.4.1` | Native cross-platform file picking for Windows, Android, iPadOS |
| `image_picker` | `^1.2.4` | Direct device camera capture on Android and iPadOS |
| `flutter_quill_extensions` | `^11.0.0` | Embeds inline images directly into Flutter Quill documents |
| `syncfusion_flutter_pdfviewer` | `^35.2.12` | High-fidelity PDF viewing, zooming, page jumping & text search |
| `connectivity_plus` | `^7.3.2` | Reactive network connectivity monitoring for auto-resuming uploads |
| `image` | `^4.13.1` | Image downsampling (<=1920px), JPEG 80% compression, thumbnails (256px) |
| `crypto` | `^3.0.7` | SHA-256 integrity checksum calculation |
| `uuid` | `^4.5.3` | Collision-resistant local and attachment identifier generation |

All packages were resolved and verified via `flutter pub get`.

---

## 3. Subsystems Implemented

### 3.1. Attachment Storage Service (`lib/services/storage/attachment_storage_service.dart`)
- **User-Partitioned Directory Hierarchy**:
  ```text
  application_documents/
  └── users/
      └── {sanitized_uid}/
          └── attachments/
              ├── images/       # Resized & compressed JPEGs/PNGs/WEBP
              ├── documents/    # DOC, DOCX, TXT
              ├── pdfs/         # Cached and imported PDF documents
              ├── sketches/     # Apple Pencil drawings exported as PNG
              ├── thumbnails/   # 256px aspect-ratio preserved thumbnails
              └── temporary/    # Ingestion buffers
  ```
- **Automated Image Optimization**:
  - Resizes images exceeding 1920px on the longest dimension while preserving aspect ratio.
  - Compresses JPEG images at 80% quality.
  - Preserves 4-channel alpha transparency for PNG files.
  - Automatically generates 256px square/letterbox thumbnails for gallery preview.
  - Computes SHA-256 checksums on all ingested files for remote integrity validation.

### 3.2. Cross-Platform Attachment Picker (`lib/services/storage/attachment_picker_service.dart`)
- Integrates `file_picker: ^13.4.1` via direct static API (`FilePicker.pickFile` and `FilePicker.pickFiles`).
- Supports extensions: `jpg`, `jpeg`, `png`, `webp`, `pdf`, `doc`, `docx`, `txt`.
- Enforces a 50 MB per-file safety limit with human-readable error feedback.
- Gracefully handles user cancellations without throwing errors.
- Integrates `ImagePicker` for direct camera capture on mobile/iPad devices.

### 3.3. Offline-Resilient Sync Coordinator (`lib/services/storage/attachment_sync_coordinator.dart`)
- **Independent State Machine**:
  `local_only` ➔ `pending` ➔ `uploading` ➔ `uploaded` / `failed` / `drive_disconnected` / `downloading` / `pending_deletion`.
- **Non-Blocking Background Pipeline**:
  `addAttachment()` and `addAttachmentFromBytes()` copy/compress files locally, record them in SQLite (`AttachmentsTable`), and immediately return domain models to update UI before launching asynchronous uploads.
- **Auto-Sync on Reconnection**:
  Monitors `Connectivity().onConnectivityChanged`. When connectivity returns, pending uploads are automatically dispatched to Google Drive.
- **Interrupted Upload Recovery**:
  `recoverInterruptedUploads()` resets any attachments stuck in `uploading` back to `pending` upon application restart or crash recovery.
- **On-Demand Downloader**:
  `getAttachmentFile()` checks local cache and SHA-256 checksum. If absent on the current device, it fetches the binary from Google Drive's `appDataFolder` and verifies hash integrity.
- **Firestore Metadata Sync**:
  Commits `{ attachmentId, driveFileId, fileName, mimeType, fileSize, checksum, uploadStatus, createdAt }` directly to the note's `attachments` array in Cloud Firestore.

### 3.4. Dedicated PDF Viewer Subsystem (`lib/features/pdf/presentation/`)
- `PdfAttachmentViewerScreen`: Full-screen PDF viewer powered by `syncfusion_flutter_pdfviewer` (`SfPdfViewer.file`).
  - Supports smooth touch pinch-to-zoom and desktop zoom controls (`Zoom In`, `Zoom Out`, `Reset Zoom`).
  - Page indicator (`Page X of Y`) and "Jump to Page" dialog.
  - Integrated text search bar with real-time match count and Next/Previous match navigation.
- `PdfAttachmentCard`: Compact document card rendered directly under the note title:
  - Displays PDF icon, file name, human-readable file size, and upload status badge (`Synced`, `Uploading...`, `Offline`, `Local Only`, `Failed`).
  - Tap card opens full-screen PDF viewer.
  - Includes download progress indicator for on-demand Drive downloads and confirmation-guarded delete button.

### 3.5. iPad Apple Pencil Sketching Canvas (`lib/features/sketch/presentation/`)
- `SketchCanvasDialog`: Interactive full-screen / modal sketching dialog for iPadOS and stylus tablets:
  - Supports Apple Pencil pressure sensitivity (`PointerMoveEvent.pressure`) with smooth cubic bezier curve interpolation.
  - Distinct tools: **Pen** (pressure-sensitive, solid opacity), **Pencil** (textured rendering, lighter opacity), **Highlighter** (translucent blend mode), **Eraser** (point-radius deletion).
  - Preset palette (8 curated stationery ink colors) and 4 stroke thickness presets (2px, 4px, 6px, 10px).
  - Multi-level Undo/Redo stack and Clear Canvas confirmation.
  - Direct PNG export: rasterizes canvas via `ui.PictureRecorder` and feeds bytes directly into `addAttachmentFromBytes(isSketch: true)` without temporary file overhead.

### 3.6. Rich-Text Editor Inline Image Embedding (`lib/features/notes/presentation/widgets/note_editor_view.dart`)
- Configured `flutter_quill_extensions` with custom `imageProviderBuilder`:
  - Directly resolves local filesystem paths from the user's attachment cache.
  - Fallback logic displays loading indicators during background Drive downloads.
- Added custom toolbar buttons:
  - **Insert Image** (`Icons.image_outlined`)
  - **Attach File / PDF** (`Icons.attach_file_rounded`)
  - **Apple Pencil Sketch** (`Icons.draw_outlined`)
- Added horizontal attachment preview strip above editor displaying interactive PDF cards and thumbnail chips with full-screen zoom dialogs.

### 3.7. Safe Deletion & Storage Hygiene
- Reference counting on Google Drive files: `countAttachmentsWithDriveFileId()` ensures remote binaries are only deleted from Google Drive when zero notes or pages reference the file.
- Moving notes to Trash preserves all local and remote attachments.
- Emptying Trash or calling permanent deletion triggers full cleanup:
  1. Local disk cached file deleted.
  2. Thumbnail deleted.
  3. Google Drive remote file deleted (if reference count <= 0).
  4. SQLite record removed.
  5. Cloud Firestore attachment array updated.

---

## 4. Verification & Testing Summary

1. **Static Analysis (`flutter analyze`)**:
   - Result: **0 issues found** across the entire repository.
2. **Phase 4 Automated Tests**:
   - `test/unit/phase_4_attachment_storage_and_picker_test.dart`: **All 7 tests passed**.
   - `test/unit/phase_4_attachment_sync_queue_and_cleanup_test.dart`: **All 9 tests passed** (covering TEST 3, TEST 4, TEST 9, TEST 10, TEST 11, TEST 12, TEST 13, TEST 14).
   - `test/widget/phase_4_pdf_viewer_and_sketch_test.dart`: **All 4 widget tests passed**.
   - Total Phase 4 test suite: **20 tests passed, 0 failures**.
3. **Full Regression Test Suite**:
   - 342+ unit and widget tests passing across all Naik Notes features.

---

## 5. Architectural Compliance Checklist

- [x] Cross-platform compatibility on Windows, Android, and iPadOS.
- [x] Hidden Google Drive `appDataFolder` integration preserved without secondary login flows.
- [x] Local-first: attachments immediately visible and accessible offline.
- [x] Non-blocking upload queue with auto-retry on reconnection.
- [x] Syncfusion PDF viewer with zoom, search, and page navigation.
- [x] iPad Apple Pencil drawing canvas with pressure sensitivity and PNG export.
- [x] Safe deletion with cross-note reference counting.
- [x] 100% test coverage for required test cases.

