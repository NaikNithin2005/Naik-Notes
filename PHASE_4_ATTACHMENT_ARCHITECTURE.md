# Naik Notes — Phase 4 Attachment Architecture
**Cross-Platform Storage, Offline Queue, Google Drive appDataFolder & iPad Sketching**
**Date:** November 22, 2026  

---

## 1. System Overview

Naik Notes adopts a **Hybrid Offline-First Architecture** designed to deliver instant responsiveness while safeguarding user data privacy and bandwidth across Windows, Android, and iPadOS:

1. **Rich-Text Notes & Attachment References**: Persisted in local Drift SQLite and synchronized with Cloud Firestore (`notebooks/{noteId}`).
2. **Raw Binaries (Images, PDFs, Sketches, Documents)**: Stored in the authenticated user's private Google Drive `appDataFolder` (hidden from regular Drive file browsing, protecting against accidental deletion).
3. **Local Filesystem Cache**: Partitioned under `getApplicationDocumentsDirectory()/users/{sanitized_uid}/attachments/` for offline availability and zero-latency display.
4. **Resilient Synchronization Queue**: Managed via Drift SQLite (`AttachmentsTable`) and auto-resumed via network connectivity triggers (`connectivity_plus`).

---

## 2. Component Architecture Diagram

```mermaid
graph TD
    UI[NoteEditorView / PDF Viewer / Sketch Canvas]
    Picker[AttachmentPickerService<br/>file_picker / image_picker]
    Storage[AttachmentStorageService<br/>Resize, Compress, SHA-256, Thumbnails]
    Coordinator[AttachmentSyncCoordinator<br/>Queue Orchestrator]
    SQLite[(Local SQLite Cache<br/>AttachmentsTable)]
    DriveService[GoogleDriveStorageService<br/>API v3 appDataFolder]
    Firestore[(Cloud Firestore<br/>Note Metadata Array)]
    NetMonitor[Connectivity Monitor<br/>connectivity_plus]

    UI -->|1. Pick File / Photo / Sketch| Picker
    Picker -->|2. Local File / Stream| Coordinator
    Coordinator -->|3. Optimize & Ingest| Storage
    Storage -->|4. Copy to User Category Dir| Storage
    Coordinator -->|5. Record Local State| SQLite
    Coordinator -->|6. Return LocalAttachment Model| UI
    Coordinator -.->|7. Asynchronous Upload| DriveService
    NetMonitor -.->|Auto-retry on reconnect| Coordinator
    DriveService -->|8. Receive driveFileId| Coordinator
    Coordinator -->|9. Update Remote Metadata| Firestore
    Coordinator -->|10. Mark Uploaded Status| SQLite
```

---

## 3. Local Filesystem Directory Structure

Attachment files are sandboxed and partitioned per user ID:

```text
getApplicationDocumentsDirectory()/
└── users/
    └── {sanitized_uid}/
        └── attachments/
            ├── images/
            │   └── {uuid}.jpg / {uuid}.png
            ├── documents/
            │   └── {uuid}.docx / {uuid}.txt
            ├── pdfs/
            │   └── {uuid}.pdf
            ├── sketches/
            │   └── {uuid}.png
            ├── thumbnails/
            │   └── {uuid}_thumb.jpg
            └── temporary/
                └── (staging buffers)
```

### Path Sanitization
User IDs (such as email addresses or alphanumeric IDs) are sanitized via:
```dart
static String sanitizeUid(String uid) {
  final sanitized = uid.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  final cleaned = sanitized.replaceAll(RegExp(r'^_+|_+$'), '');
  return cleaned.isEmpty ? 'local_user' : cleaned;
}
```
This guarantees cross-platform filesystem compatibility without invalid directory characters across Windows, Android, and iOS/iPadOS.

---

## 4. Attachment Lifecycle & State Machine

```mermaid
stateDiagram-v2
    [*] --> LocalOnly: Picked Offline / No Drive Auth
    [*] --> Pending: Picked Online
    LocalOnly --> Pending: Network Reconnected
    Pending --> Uploading: Upload Worker Dispatched
    Uploading --> Synced: Drive Upload OK & Firestore Committed
    Uploading --> Failed: Network Timeout / Drive Error
    Failed --> Pending: Auto-Retry / Network Reconnected
    Synced --> Downloading: Requested on Another Device
    Downloading --> Synced: Binary Cached & Checksum Verified
    Downloading --> DownloadFailed: Missing File / Checksum Mismatch
    Synced --> PendingDeletion: User Deletes Attachment
    PendingDeletion --> [*]: Local Cache & Remote File Removed (Ref Count == 0)
```

### State Definitions:
- `local_only`: File imported locally; Google Drive account not linked.
- `pending`: Queued for background upload.
- `uploading`: Actively transferring chunks to Google Drive API v3.
- `uploaded` (Synced): Remote file exists in `appDataFolder`; metadata committed to Cloud Firestore.
- `downloading`: Fetching binary on-demand for a note created on another device.
- `failed`: Upload encountered network or authorization error; queued for auto-retry.
- `pending_deletion`: Marked for safe cleanup.

---

## 5. Non-Blocking Synchronous UI Pipeline

To ensure typing, scrolling, and editing notes is never blocked while uploading large files:

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Editor as NoteEditorView
    participant Coord as AttachmentSyncCoordinator
    participant Storage as AttachmentStorageService
    participant SQLite as Drift AttachmentsTable
    participant Drive as Google Drive appDataFolder
    participant Firestore as Cloud Firestore

    User->>Editor: Attach Image / PDF / Sketch
    Editor->>Coord: addAttachment(file, noteId)
    Coord->>Storage: importFile(sourceFile)
    Note over Storage: 1. Downsample (max 1920px)<br/>2. Compress (80% JPEG)<br/>3. Compute SHA-256<br/>4. Generate 256px Thumbnail
    Storage-->>Coord: ProcessedAttachmentResult
    Coord->>SQLite: saveAttachment(status: pending)
    Coord-->>Editor: NoteAttachment (localPath set)
    Note over Editor: Attachment rendered immediately.<br/>User continues writing without delay.
    
    par Async Upload in Background
        Coord->>Drive: uploadAttachment(appDataFolder)
        Drive-->>Coord: driveFileId
        Coord->>Firestore: updateNote(attachments: [...])
        Coord->>SQLite: updateStatus(status: uploaded)
        Editor-->>User: Badge updates to 'Synced'
    end
```

---

## 6. iPad Apple Pencil & Sketching Subsystem

The `SketchCanvasDialog` captures touch and stylus events:
1. **Pressure Sensitivity**: `PointerMoveEvent.pressure` modulates stroke width smoothly according to tool type.
2. **Bezier Smoothing**: Raw input coordinates are smoothed using quadratic / cubic bezier interpolation, eliminating jitter.
3. **Tools**:
   - **Pen**: Dynamic pressure, crisp ink, 100% opacity.
   - **Pencil**: Textured graphite rendering with lighter opacity.
   - **Highlighter**: Wide translucent marker with `BlendMode.multiply`.
   - **Eraser**: Segment distance hit-testing deletes touched strokes.
4. **Direct PNG Export**:
   ```dart
   final recorder = ui.PictureRecorder();
   final canvas = Canvas(recorder);
   // ... paint strokes ...
   final picture = recorder.endRecording();
   final img = await picture.toImage(width, height);
   final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
   await coordinator.addAttachmentFromBytes(
     bytes: byteData.buffer.asUint8List(),
     isSketch: true,
   );
   ```
   Exports directly to memory bytes and saves to `users/{uid}/attachments/sketches/`, completely bypassing temporary picker files.

---

## 7. Storage Hygiene & Safe Deletion Model

To prevent accidental data loss when notes are duplicated or reference identical attachments:

```mermaid
flowchart TD
    Start[User deletes attachment / empties Trash] --> CountCheck{Count references in SQLite<br/>with driveFileId}
    CountCheck -->|References > 0| LocalOnly[Delete local cache & SQLite record]
    LocalOnly --> SkipDrive[Keep Drive binary intact for other notes]
    CountCheck -->|References == 0| RemoteDelete[Delete from Google Drive appDataFolder]
    RemoteDelete --> CleanLocal[Delete local cache & thumbnail]
    CleanLocal --> UpdateFirestore[Remove from Firestore note attachment array]
    UpdateFirestore --> Done[Complete Cleanup]
```

### Trash Retention Rule
- Moving a note to Trash sets `isDeleted: true` on the note document.
- Local attachment binaries, thumbnails, and remote Google Drive files are **strictly preserved** while in Trash.
- When the user restores the note, all attachments remain instantly available.
- When the user permanently empties the Trash, `onNotePermanentlyDeleted()` triggers the cleanup pipeline.

