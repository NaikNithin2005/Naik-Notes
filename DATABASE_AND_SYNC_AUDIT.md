# Database Architecture & Cloud Synchronization Audit — Naik Notes

This document provides a technical audit of the local relational database schema, mutation queuing mechanisms, and cloud synchronization protocol in **Naik Notes**.

---

## 1. Local Database Architecture (Drift SQLite)

Naik Notes persists all user data locally in SQLite using the type-safe **Drift ORM** (`app_database.dart`), ensuring zero-latency startup and offline-first capabilities.

### 1.1 Relational Schema Overview

| Table Name | Primary Key | Key Columns | Description |
| :--- | :--- | :--- | :--- |
| `NotebooksTable` | `id` (TEXT) | `title`, `coverId`, `paperTemplateId`, `isFavorite`, `isArchived`, `folderId`, `revision` | Stores notebook metadata, orientation, page counts |
| `PagesTable` | `id` (TEXT) | `notebookId`, `pageNumber`, `templateId`, `templatePropertiesJson`, `width`, `height`, `isBookmarked` | Stores individual notebook page dimensions and stationery settings |
| `StrokesTable` | `id` (TEXT) | `pageId`, `toolType`, `colorValue`, `width`, `opacity`, `pointsJson`, `boundingBoxJson`, `deletedAt` | Stores vector points, bezier curves, stroke bounding boxes |
| `StickyNotesTable` | `id` (TEXT) | `pageId`, `x`, `y`, `width`, `height`, `content`, `colorHex` | Stores sticky note annotations positioned on pages |
| `FoldersTable` | `id` (TEXT) | `name`, `colorHex`, `parentId`, `sortOrder` | Hierarchical folder tree structure |
| `AudioRecordingsTable` | `id` (TEXT) | `notebookId`, `pageId`, `filePath`, `durationSeconds`, `title` | Synchronized audio recordings with page timestamps |
| `SyncQueueTable` | `id` (TEXT) | `entityType`, `entityId`, `operationType`, `payloadJson`, `status`, `retryCount` | FIFO mutation queue for pending cloud synchronization |
| `SearchIndexTable` | `id` (TEXT) | `notebookId`, `pageId`, `recognizedText`, `confidence` | Full-text handwriting recognition search index |

---

## 2. Cloud Synchronization Engine

### 2.1 FIFO Mutation Queue
* Whenever a notebook, page, stroke, or sticky note is created or mutated, a `SyncOperation` is appended to `SyncQueueTable` locally.
* Operations are tagged with `operationType` (`insert`, `update`, `delete`) and the serialized entity payload.
* The local database remains the single source of truth; all UI updates occur synchronously before the sync operation is queued.

### 2.2 Reconciler & Conflict Resolution
* The `FirebaseSyncService` listens to connectivity state.
* When network connectivity is established:
  1. **Push Phase**: Dequeues pending operations in FIFO order and pushes them to Cloud Firestore `/users/{uid}/...`.
  2. **Pull Phase**: Queries Cloud Firestore for remote updates newer than the local sync watermark (`lastSyncedAt`).
  3. **Conflict Resolution**: Last-Write-Wins (LWW) utilizing monotonically increasing `revision` counters and `updatedAt` timestamps.

### 2.3 UI Indicators & Diagnostics
* The UI sync indicator badge (`SyncStatusBadge`) reflects 5 clear operational states:
  * **Synced**: All local changes match the remote cloud state.
  * **Synchronizing**: Active upload or download in progress.
  * **Offline**: Network unreachable; all modifications safely queued in Drift SQLite.
  * **Sync Failed**: Remote error (e.g. rate limit, permission); will retry automatically with exponential backoff.
  * **Pending Changes**: Uncommitted local mutations awaiting upload.

