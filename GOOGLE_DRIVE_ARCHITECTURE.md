# Naik Notes – Google Drive Hybrid Storage Architecture

## 1. Executive Summary & Purpose

Naik Notes implements a hybrid cloud architecture designed for zero storage infrastructure costs, infinite user scalability, and uncompromising cross-platform reliability across **Windows Desktop**, **iPadOS**, and **Android**.

Rather than storing massive binary attachments (PDF textbooks, high-resolution diagrams, photos) in developer-managed cloud buckets (such as Firebase Storage or AWS S3), Naik Notes stores binaries directly in each user's **personal Google Drive account** under the hidden, private application storage space (`appDataFolder`), while maintaining metadata and synchronization records in **Cloud Firestore** and **Firebase Authentication**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Naik Notes Flutter App                          │
│               Windows Desktop  ·  iPadOS  ·  Android                   │
└───────────────────┬───────────────────────────────┬────────────────────┘
                    │                               │
                    ▼                               ▼
     ┌─────────────────────────────┐  ┌─────────────────────────────┐
     │   Identity & Synchronizer   │  │   Personal Storage Layer    │
     │   Firebase Authentication   │  │   Google Drive API v3       │
     │   + Cloud Firestore         │  │   (appDataFolder Scope)     │
     └──────────────┬──────────────┘  └─────────────┬───────────────┘
                    │                               │
                    ▼                               ▼
       • User registration & login     • User's personal Drive
       • /users/{uid}/notebooks/...    • Hidden from regular UI
       • Attachment references         • PDFs, PNGs, JPEGs, WebP
       • Checksums & file IDs          • Zero server storage cost
                    │                               │
                    └───────────────┬───────────────┘
                                    │
                                    ▼
                     ┌─────────────────────────────┐
                     │    Local Storage & Cache    │
                     │  Drift SQLite + Local Disk  │
                     │  Offline Queue & Cache      │
                     └─────────────────────────────┘
```

---

## 2. Component Separation & Responsibilities

| Component | Technology | Primary Responsibilities |
| :--- | :--- | :--- |
| **Identity Layer** | Firebase Authentication | User account management, email/password & Google login, session tokens, Firebase UID generation. |
| **Metadata & Sync Layer** | Cloud Firestore | User profiles, folders, notebook metadata, page hierarchies, vector strokes, attachment references, sync timestamps. |
| **Attachment Storage Layer** | Google Drive API v3 | Actual binary files (images, PDFs, documents) stored inside each user's hidden `appDataFolder`. |
| **Local Database Layer** | Drift / SQLite | Local note cache, stroke caching, attachment manifest table, offline queues for uploads/downloads, sync status. |
| **Local Filesystem** | `path_provider` | User-partitioned cache directory (`/users/{uid}/attachments/{id}.ext`) for immediate offline viewing. |
| **Secure Token Storage** | `flutter_secure_storage` | Platform-native encrypted storage (Windows Credential Locker, Apple Keychain, Android Keystore) for OAuth tokens. |

---

## 3. Why `appDataFolder`?

Google Drive provides a specialized hidden directory alias called `appDataFolder`:
1. **Zero Visibility in Regular Drive:** Files created with `parents = ['appDataFolder']` do **not** appear in the user's Google Drive web or mobile interface, preventing accidental file deletions, renaming, or moves.
2. **Strict Privacy:** Accessible **only** by Naik Notes via the exact OAuth scope `https://www.googleapis.com/auth/drive.appdata`. Other applications cannot view or touch these files.
3. **No Unrestricted Access:** The app never asks for broad Drive permissions (`drive` or `drive.file`), giving users complete confidence that their personal files remain untouched.
4. **Infinite Scale & Zero Infrastructure Cost:** Each user utilizes their own 15 GB+ Google Drive quota. The application developer incurs \$0 in storage egress or hosting costs.

---

## 4. Multi-Device Synchronization Flow

### Scenario: Android Upload -> Cross-Device View
1. **Android Tablet:**
   - User attaches a research diagram `diagram.png` to a notebook page.
   - Naik Notes immediately copies the file to the local user cache directory.
   - Generates a unique attachment UUID (`att_12345`) and calculates its SHA-256 integrity checksum.
   - Records attachment in SQLite `AttachmentsTable` with status `pending`.
   - Uploads binary stream to Google Drive `appDataFolder` with metadata properties.
   - Google Drive returns a permanent `driveFileId` (e.g., `1a2b3c4d5e6f`).
   - Naik Notes writes the attachment reference to Cloud Firestore: `users/{uid}/notebooks/{notebookId}` in the `attachments` array.
   - Local SQLite status updates to `uploaded`.

2. **Windows Desktop & iPad:**
   - Real-time Firestore snapshot listener detects the new attachment reference in the notebook.
   - Inserts the metadata record into the local SQLite database.
   - The user opens the page containing the attachment.
   - Naik Notes checks local disk: file not yet cached locally.
   - Requests binary stream on-demand from Google Drive using `drive.files.get(driveFileId, downloadOptions: DownloadOptions.fullMedia)`.
   - Validates the received stream against the expected SHA-256 checksum.
   - Saves file to local cache (`/users/{uid}/attachments/att_12345.png`).
   - Renders the image instantly on the canvas.
   - Subsequent viewings read directly from the local disk cache with zero network calls.

---

## 5. Architectural Invariants

1. **Decoupled Identity:** Firebase Auth UID identifies the Naik Notes user; the Google Drive account identifies the storage bucket owner. A user registering via Email/Password can connect Google Drive at any time through Settings.
2. **Zero Credentials in Firestore:** OAuth tokens, client secrets, and refresh tokens are **never** stored in Cloud Firestore or Git commits. They reside exclusively in platform secure storage.
3. **Offline-First:** Users can attach files, create notes, and view cached attachments without network connectivity. Offline uploads automatically queue and sync when network and authorization are available.
4. **Data Isolation:** Every local database and cache directory is partitioned by sanitized Firebase UID (`naik_notes_user_${uid}.sqlite`), preventing data leakage upon account switching.

