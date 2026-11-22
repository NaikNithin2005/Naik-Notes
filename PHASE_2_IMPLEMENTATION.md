# Phase 2: Core Note-Taking Engine & Responsive Multi-Platform UI

## Project: Naik Notes
**Status:** Completed & Fully Verified  
**Date:** November 21, 2026  
**Quality Standards:** 0 `flutter analyze` issues, 100% test pass rate (51/51 unit & widget tests).

---

## 1. Executive Summary

Phase 2 builds the core note-taking engine and adaptive multi-platform user interface for Naik Notes across **Windows Desktop**, **iPad (Portrait and Landscape)**, and **Android (Smartphones and Tablets)** from a single, unified Flutter codebase.

Key achievements:
1. **Adaptive Multi-Platform Layout**: Built with Flutter's `LayoutBuilder` switching seamlessly between 1-Pane (Mobile), 2-Pane (Tablet), and 3-Pane (Desktop) layouts.
2. **Rich-Text WYSIWYG Editor**: Integrated `flutter_quill: ^11.6.0` using Quill Delta JSON persistence.
3. **Robust Debounced Auto-Save Coordinator**: 1500ms debounce timer with local-first SQLite persistence, Cloud Firestore synchronization, status badges, and explicit flushing on note-switch, route exit, and background lifecycle transitions.
4. **Data Layer & SQLite Migration**: Created domain `Note` model, added Drift SQLite `NotesTable` (schema version 13), generated Drift code with `build_runner`, and added Firestore push/sync mechanisms.
5. **Instant Local Search & Organization**: Substring search running locally in Dart on cached fields (`title`, `plainText`, `preview`, `tags`) with zero Firestore read-quota cost.
6. **Cross-Platform Keyboard Shortcuts**: Native shortcut maps (Ctrl on Windows/Android, Cmd on Apple) for quick authoring.

---

## 2. Adaptive Multi-Platform Architecture

```mermaid
flowchart TD
    Screen["NotesScreen (LayoutBuilder)"]
    Screen -->|< 600px| Mobile["MobileNoteListScreen (1-Pane)"]
    Screen -->|600px - 1023px| Tablet["TwoPaneTabletLayout (2-Pane)"]
    Screen -->|>= 1024px| Desktop["ThreePaneDesktopLayout (3-Pane)"]

    Mobile --> MobileDrawer["Drawer: NotebookSidebar"]
    Mobile --> MobileList["NoteListPane"]
    Mobile -->|Tap Note| MobileEditor["MobileNoteEditorScreen"]
    MobileEditor --> DockedToolbar["Docked Keyboard Toolbar"]

    Tablet --> CollapsibleList["Collapsible NoteListPane"]
    Tablet --> TabletEditor["NoteEditorView (Expanded)"]

    Desktop --> LeftPane["NotebookSidebar (260px)"]
    Desktop --> MidPane["NoteListPane (320px)"]
    Desktop --> RightPane["NoteEditorView (Canvas)"]
```

### Layout Specifications

| Screen Width | Target Device | Layout Structure | Key Interactions |
| :--- | :--- | :--- | :--- |
| **< 600 px** | Android Phones, iPhone | **1-Pane** | Note list primary view; slide-out Drawer for notebooks and tags; FAB for new notes; tapping a note pushes dedicated `MobileNoteEditorScreen`; docked toolbar above software keyboard. |
| **600 – 1023 px** | iPad Portrait, Android Tablets | **2-Pane** | Collapsible Note list on left (animated width toggle) + Active Note Editor on right; slide-out drawer or top switcher for notebooks; external keyboard shortcut support. |
| **>= 1024 px** | Windows, macOS, iPad Landscape | **3-Pane** | **Left Pane (260px):** Notebooks, Pinned, Favorites, Tags, Archive, Trash, Settings.<br>**Middle Pane (320px):** Instant search bar, sorting menu, note cards with previews, timestamps, badges.<br>**Right Pane (Expanded):** WYSIWYG Quill canvas, title, tags, status indicator, top formatting toolbar. |

---

## 3. Rich Text Note Editor (`flutter_quill`)

- **Package:** `flutter_quill: ^11.6.0` (with `dart_quill_delta: 10.8.3`).
- **Persistence:** Stored as structured Quill Delta JSON string (`contentDelta`).
- **Plaintext Extraction & Previews:** `Note.extractPlainText(deltaJson)` generates body text for search indexing, while `Note.generatePreview(plainText)` creates single-line snippets for card previews.
- **Formatting Capabilities:**
  - Font styling: Bold, Italic, Underline, Strikethrough, Code, Code Block, Quote.
  - Structure: Headings (H1–H3), Numbered Lists, Bullet Lists, Checklists, Indentation, Text Alignment.
  - Colors: Text color picker, background highlight color picker.
  - Actions: Undo, Redo, Clear Formatting, Hyperlinks.
- **Responsive Toolbar Positioning:**
  - **Desktop / Tablet:** Top-mounted `QuillSimpleToolbar` placed above the document canvas.
  - **Mobile:** Docked compact toolbar pinned at the bottom, adjusting with keyboard insets.

---

## 4. Debounced Auto-Save Engine

```mermaid
sequenceDiagram
    participant User as User Typing
    participant Editor as NoteEditorView
    participant Coord as NoteAutoSaveCoordinator
    participant SQLite as Local SQLite (Drift)
    participant Cloud as Cloud Firestore

    User->>Editor: Enters keystroke
    Editor->>Coord: onNoteChanged(delta, title)
    Note over Coord: Reset 1500ms Timer<br/>Set status: Saving
    User->>Editor: Pauses typing (1500ms elapsed)
    Coord->>SQLite: saveNote(updatedNote) [Offline First]
    Coord->>Cloud: pushNote(uid, updatedNote)
    alt Cloud Push Succeeded
        Coord-->>Editor: status = Saved (Timestamp)
    else Cloud Push Failed / Offline
        Coord-->>Editor: status = Saved locally (Offline)
    end
```

### Critical Auto-Save Guarantees
1. **Debounce Interval:** 1500 milliseconds. Rapid typing never triggers intermediate writes.
2. **Explicit Flush Coordinator:** Unsaved changes are immediately flushed when:
   - User switches notes in the middle pane (`selectedNoteProvider.notifier.selectNote`).
   - User navigates back (`MobileNoteEditorScreen.onPopInvokedWithResult`).
   - App enters background (`didChangeAppLifecycleState` pauses/inactivates).
   - User presses `Ctrl/Cmd + S`.
3. **Offline-First Resilience:** Notes write first to local SQLite. If network or Firebase push fails, local edits are safely preserved and retried.

---

## 5. Database Schema & Synchronization

### Drift SQLite Table (`NotesTable` - Schema v13)
```sql
CREATE TABLE notes (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL,
  notebook_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content_delta TEXT NOT NULL,
  plain_text TEXT NOT NULL,
  preview TEXT NOT NULL,
  tags TEXT NOT NULL,          -- JSON encoded List<String>
  is_pinned INTEGER NOT NULL,  -- Boolean
  is_favorite INTEGER NOT NULL,-- Boolean
  is_archived INTEGER NOT NULL,-- Boolean
  is_deleted INTEGER NOT NULL, -- Boolean (Soft delete)
  created_at INTEGER NOT NULL, -- Unix timestamp ms
  updated_at INTEGER NOT NULL, -- Unix timestamp ms
  deleted_at INTEGER,          -- Nullable Unix timestamp ms
  last_synced_at INTEGER       -- Nullable Unix timestamp ms
);
```

### Cloud Firestore Schema
Collection: `/users/{uid}/notes/{noteId}`
- Fields: `id`, `notebookId`, `title`, `contentDelta`, `plainText`, `preview`, `tags`, `isPinned`, `isFavorite`, `isArchived`, `isDeleted`, `createdAt`, `updatedAt`, `deletedAt`, `lastSyncedAt`.

---

## 6. Instant Search, Tagging & CRUD

- **Instant Local Search:** Filters cached notes in Dart over `title`, `plainText`, `preview`, and `tags` using lowercase substring matching with zero Firestore read quotas consumed.
- **Tag Management:** Tags stored as `List<String>`. Filter by tag displays matching notes across all notebooks.
- **Soft Deletion & Recovery:** Deleting moves notes to Trash (`isDeleted = true`, `deletedAt = timestamp`). Notes can be restored or permanently purged with confirmation.
- **Sorting Options:** Date Modified (Newest), Date Created (Newest), Alphabetical Title (A–Z), with pinned notes pinned at the top.

---

## 7. Cross-Platform Keyboard Shortcuts

Wrapped at the root of the editor layouts via `NoteShortcuts`:

| Shortcut (Windows / Android) | Shortcut (macOS / iPad) | Action |
| :--- | :--- | :--- |
| `Ctrl + N` | `Cmd + N` | Create New Note |
| `Ctrl + S` | `Cmd + S` | Force Save / Flush Pending Edits |
| `Ctrl + F` | `Cmd + F` | Focus Search Bar |
| `Ctrl + B` | `Cmd + B` | Toggle Bold Formatting |
| `Ctrl + I` | `Cmd + I` | Toggle Italic Formatting |
| `Ctrl + U` | `Cmd + U` | Toggle Underline Formatting |
| `Ctrl + Z` | `Cmd + Z` | Undo |
| `Ctrl + Shift + Z` / `Ctrl + Y` | `Cmd + Shift + Z` | Redo |
| `Ctrl + A` | `Cmd + A` | Select All |

---

## 8. Centralized Deletion System, Tombstones & Trash Retention

### Architecture Overview
1. **Immutable Globally Unique IDs:** Every notebook and note uses stable, immutable UUIDs (`id`, `ownerId`/`userId`, `createdAt`, `updatedAt`, `deletedAt`, `deletionId`, `syncStatus`, `lastSyncedAt`). The same ID is preserved across Android, iPad, Windows, Firebase, and Google Drive.
2. **Persistent Tombstone Ledger:** Permanently deleted items record a tombstone in `tombstonesTable` (SQLite), sync to `/users/{uid}/tombstones/{id}` in Firestore, and persist in `tombstones_manifest.json` on Google Drive. Incoming synchronization payloads are checked against the tombstone registry; tombstoned entities are rejected and can never be resurrected by stale offline devices.
3. **30-Day Trash Retention:** Moving a notebook or note to Trash sets `deletedAt = now()` and `deletionId`. In Google Drive, cloud recovery files are retained. The auto-retention policy (`cleanupExpiredTrash`) automatically calculates expiration (`now - deletedAt >= 30 days`), permanently purging expired files and recording tombstones.
4. **Elimination of `(Cloud Copy)` Duplication:** Removed conflict renaming logic that previously minted new UUIDs. Remote files and local files are unified through `driveFileMappingsTable` (`entityId` <-> `driveFileId`), with deterministic Last-Write-Wins and Tombstone priority.
5. **Dedicated Trash Screen:** Accessible via `/trash` with tabs for Notebooks and Notes, dynamic 30-day countdown chips ("Deleted X days ago · Y days left"), gallery-style multi-selection toolbar, individual/bulk restoration, and irreversible permanent deletion.

---

## 9. Test Verification & Code Quality

### Automated Test Results
- **Phase 2 Note Suite:** 31 tests passed.
- **Tombstones & 30-Day Retention Suite:** 7 tests passed.
- **Sync Deduplication & Conflict Suite:** 3 tests passed.
- **Gallery Multi-Selection Suite:** 12 tests passed.
- **Pre-existing App & Regression Suite:** 20 tests passed.
- **Static Analysis:** `flutter analyze` completed with **0 warnings and 0 errors**.

