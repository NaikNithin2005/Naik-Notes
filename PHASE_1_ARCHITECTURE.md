# Naik Notes — Phase 1 Architecture Specification
**Complete Authentication, Multi-Device Synchronization & Strict User Isolation Redesign**

---

## 1. Architectural Philosophy: Local-First with Multi-Device Cloud Sync

Naik Notes operates on a **Local-First Architecture** across Windows Desktop, iPadOS, and Android.

```
┌────────────────────────────────────────────────────────────────────────┐
│                   Naik Notes Application (Flutter)                    │
│                 Windows Desktop · iPadOS · Android                     │
└────────────────────────────────────┬───────────────────────────────────┘
                                     │
                  ┌──────────────────┴──────────────────┐
                  ▼                                     ▼
     ┌────────────────────────┐            ┌────────────────────────┐
     │  Authentication State  │            │  Presentation & UI     │
     │  Notifier (Riverpod)   │            │  (Stationery, Canvas)  │
     └────────────┬───────────┘            └────────────┬───────────┘
                  │                                     │
                  ▼                                     ▼
     ┌────────────────────────┐            ┌────────────────────────┐
     │   Auth Repository      │            │   Domain Repositories  │
     │   Firebase Auth /      │            │   (Notebook, Page,     │
     │   OAuth Desktop Flow   │            │    Stroke, Folder)     │
     └────────────┬───────────┘            └────────────┬───────────┘
                  │                                     │
                  │                              ┌──────┴──────┐
                  │                              ▼             ▼
                  │                    ┌──────────────┐ ┌──────────────┐
                  │                    │ Local Drift  │ │ Sync Queue   │
                  │                    │ SQLite DB    │ │ (Drift FIFO) │
                  │                    │ (UID-Scoped) │ │ (UID-Scoped) │
                  │                    └──────┬───────┘ └──────┬───────┘
                  │                           │                │
                  └──────────────────┐ ┌──────┘                │
                                     ▼ ▼                       ▼
                             ┌───────────────────────────────────────┐
                             │       Sync Engine (Coordinator)       │
                             │   Push Queue · Pull Reconciler ·     │
                             │   Real-Time Listeners · Conflicts     │
                             └──────────────────┬────────────────────┘
                                                │
                                                ▼
                             ┌───────────────────────────────────────┐
                             │     Cloud Firestore & Auth Backend    │
                             │       /users/{uid}/... Isolation      │
                             └───────────────────────────────────────┘
```

### Core Principles
1. **Immediate Local Responsiveness:** Every user action (creating a notebook, writing handwriting strokes, moving folders) writes immediately to the local SQLite database via Drift. The UI never waits for a cloud round-trip.
2. **Strict Multi-Level User Isolation:**
   - **Local DB Level:** Each user's local database is stored in an independent SQLite file partitioned by Firebase UID (`naik_notes_user_${uid}.sqlite`). Switching accounts switches database instances cleanly.
   - **Data Layer Level:** Repositories reject queries without an authenticated `ownerId`.
   - **Sync Queue Level:** Every queued mutation is tagged with `ownerId`. Operations belonging to one account can never be pushed under another account.
   - **Cloud Level:** All Firestore operations target `/users/{uid}/...` and are enforced by Firestore Security Rules `request.auth.uid == userId`.
3. **Continuous Background Synchronization:**
   - Real-time listeners stream remote updates to the local database, updating Riverpod providers automatically without requiring manual pulls.
   - An offline queue processor retries pending writes with exponential backoff and jitter whenever network connectivity is available.
4. **Data Preservation & Conflict Handling:**
   - Note metadata resolves deterministically using revision counters and server timestamps.
   - Note page content (handwriting strokes and annotations) generates page snapshots (`PageSnapshotsTable`) before merging remote updates, preventing destructive overwrites.

---

## 2. Authentication Architecture

### 2.1 Identity Provider: Firebase Authentication
Firebase Authentication serves as the authoritative identity provider. The application supports:
1. **Email & Password Authentication** (Registration, Login, Password Recovery).
2. **Google Sign-In** (Tailored per platform: Android, iPadOS/iOS, and Windows).
3. **Apple Sign-In** (Supported natively on iPadOS/macOS).
4. **Session Restoration** (Seamless restoration of valid Firebase user tokens across app restarts).

### 2.2 Platform-Specific Google Sign-In Implementation

#### A. Android
- Implemented via `google_sign_in` plugin interacting with native Google Play Services.
- **Account Selection Enforced:** When the user initiates Google login or requests account selection, `googleSignIn.disconnect()` or `signOut()` is called to invalidate cached sessions, ensuring the Google account chooser dialog is presented.
- **Web Client ID:** Uses Firebase Web Client ID `437907946486-...apps.googleusercontent.com` to acquire Google ID tokens for Firebase exchange.

#### B. iPadOS / iOS
- Registered URL Scheme in `ios/Runner/Info.plist`:
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
      <dict>
          <key>CFBundleTypeRole</key>
          <string>Editor</string>
          <key>CFBundleURLSchemes</key>
          <array>
              <string>com.googleusercontent.apps.437907946486-...</string>
          </array>
      </dict>
  </array>
  ```
- Implemented via `GoogleSignIn` with `clientId` configured from `GoogleService-Info.plist`.

#### C. Windows Desktop (RFC 8252 OAuth 2.0 Loopback Flow)
- Because `google_sign_in` does not provide native Windows C++ plugin support, Windows uses a secure OAuth 2.0 Loopback Flow conforming to RFC 8252 (OAuth 2.0 for Native Apps):
  1. The app binds an ephemeral loopback HTTP server: `HttpServer.bind(InternetAddress.loopbackIPv4, 0)`.
  2. Generates a cryptographically random PKCE code verifier and SHA-256 code challenge.
  3. Generates a unique `state` nonce to protect against CSRF attacks.
  4. Launches the system browser to Google's OAuth 2.0 authorization endpoint:
     `https://accounts.google.com/o/oauth2/v2/auth?client_id=...&redirect_uri=http://127.0.0.1:$port/oauth2callback&response_type=code&scope=openid%20email%20profile&code_challenge=$challenge&code_challenge_method=S256&state=$state&prompt=select_account`
  5. The loopback server receives the authorization `code` at `/oauth2callback`, responds with an HTML success confirmation page, and closes the server.
  6. Exchanges the authorization `code` and `code_verifier` with Google's token endpoint (`https://oauth2.googleapis.com/token`) for `id_token` and `access_token`.
  7. Exchanges credentials with Firebase Auth: `FirebaseAuth.instance.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken, accessToken: accessToken))`.
  8. Zero client secrets embedded; full PKCE security.

### 2.3 Centralized Authentication State Machine

The authentication state is managed by a single `AuthNotifier` producing immutable `AuthState`:

```
   ┌─────────────────┐
   │ Unauthenticated │
   └────────┬────────┘
            │
            ├──────────────────────────────────────────┐
            ▼                                          ▼
   ┌─────────────────┐                        ┌─────────────────┐
   │ Validating Form │                        │ SessionRestore  │
   └────────┬────────┘                        └────────┬────────┘
            │                                          │
            ▼                                          │
   ┌─────────────────┐                                 │
   │ Authenticating  │                                 │
   └────────┬────────┘                                 │
            │                                          │
            ├───────────────┬──────────────┐           │
            ▼               ▼              ▼           │
     [Success UID]    [Auth Error]    [Timeout]        │
            │               │              │           │
            │               └──────┬───────┘           │
            │                      ▼                   │
            │              ┌───────────────┐           │
            │              │ Display Error │           │
            │              └───────┬───────┘           │
            │                      │                   │
            ▼                      ▼                   │
   ┌────────────────────────────────────────────────┐  │
   │ Initialize Firestore Profile & Sync Metadata   │  │
   └───────────────────────┬────────────────────────┘  │
                           │                           │
                           ▼                           ▼
                 ┌───────────────────┐       ┌───────────────────┐
                 │   Authenticated   │◄──────┤ Session Restored  │
                 └─────────┬─────────┘       └───────────────────┘
                           │
                           ▼ (User clicks Logout)
                 ┌───────────────────┐
                 │  Logging Out /    │
                 │  Teardown Session │
                 └─────────┬─────────┘
                           │
                           ▼
                 ┌───────────────────┐
                 │  Unauthenticated  │
                 └───────────────────┘
```

---

## 3. User Data Architecture in Firestore

All application data resides under strict user namespaces:

```
users/
  {uid}/
    profile/                 <-- User profile details
    devices/
      {deviceId}/            <-- Registered client devices & platforms
    syncMetadata/
      config                 <-- Client sync watermark & schema version
    folders/
      {folderId}/            <-- Notebook hierarchy
    notebooks/
      {notebookId}/          <-- Notebook document
        pages/
          {pageId}/          <-- Page stationery and dimensions
            strokes/
              {strokeId}/    <-- Vector handwriting points
            sticky_notes/
              {noteId}/      <-- Positioned sticky notes
            snapshots/
              {snapshotId}/  <-- Recoverable revision snapshots
```

### Document Schemas

#### User Profile (`/users/{uid}`)
```json
{
  "uid": "USER_UID_STRING",
  "email": "user@example.com",
  "displayName": "User Name",
  "photoUrl": "https://...",
  "provider": "google.com | password",
  "createdAt": "TIMESTAMP",
  "updatedAt": "TIMESTAMP",
  "lastLoginAt": "TIMESTAMP",
  "accountStatus": "active",
  "schemaVersion": 2
}
```

#### Notebook (`/users/{uid}/notebooks/{notebookId}`)
```json
{
  "id": "NOTEBOOK_UUID",
  "ownerId": "USER_UID_STRING",
  "folderId": "FOLDER_UUID or null",
  "title": "Calculus Notes",
  "description": "Fall Semester 2026",
  "coverId": "classic_leather",
  "coverColorHex": "#8B4513",
  "coverImageUrl": null,
  "paperTemplateId": "college_ruled",
  "orientation": "portrait",
  "pageSize": "A4",
  "pageCount": 5,
  "isFavorite": false,
  "isArchived": false,
  "isPdf": false,
  "pdfPath": null,
  "revision": 3,
  "createdAt": "2026-11-19T10:00:00.000Z",
  "updatedAt": "SERVER_TIMESTAMP",
  "deletedAt": null
}
```

#### Page (`/users/{uid}/notebooks/{notebookId}/pages/{pageId}`)
```json
{
  "id": "PAGE_UUID",
  "notebookId": "NOTEBOOK_UUID",
  "sectionId": null,
  "pageNumber": 1,
  "templateId": "college_ruled",
  "properties": {
    "lineSpacing": 28.0,
    "gridSize": 20.0,
    "lineColor": "#E2E8F0",
    "marginColor": "#EF4444"
  },
  "width": 595.28,
  "height": 841.89,
  "isBookmarked": false,
  "pdfPageIndex": null,
  "revision": 2,
  "createdAt": "2026-11-19T10:00:00.000Z",
  "updatedAt": "SERVER_TIMESTAMP"
}
```

#### Stroke (`/users/{uid}/notebooks/{notebookId}/pages/{pageId}/strokes/{strokeId}`)
```json
{
  "id": "STROKE_UUID",
  "pageId": "PAGE_UUID",
  "tool": "fountainPen",
  "colorValue": 4279970338,
  "width": 3.0,
  "opacity": 1.0,
  "points": [
    {"x": 120.5, "y": 200.1, "pressure": 0.6, "tilt": 0.0, "timestamp": 1732028400000}
  ],
  "revision": 1,
  "createdAt": "2026-11-19T10:05:00.000Z",
  "deletedAt": null
}
```

---

## 4. Local Persistence Architecture (Drift SQLite)

### 4.1 UID-Partitioned Database Instances
Instead of a single global `naik_notes_local.sqlite` file, database files are scoped per user:
- For authenticated user `abc123`: `naik_notes_user_abc123.sqlite`.
- When switching users, the previous `AppDatabase` is safely closed and disposed, and a new `AppDatabase` pointing to the new user's file is opened.
- This guarantees **hardware-level isolation** between accounts on the same device.

### 4.2 Sync Queue with Owner Tagging
`SyncQueueTable` in Drift includes `ownerId`:
```dart
class SyncQueueTable extends Table {
  TextColumn get id => text()();
  TextColumn get ownerId => text()(); // Enforces strict user isolation
  TextColumn get entityType => text()(); // notebook, page, stroke, sticky_note, folder
  TextColumn get entityId => text()();
  TextColumn get parentId => text().nullable()(); // notebookId or pageId
  TextColumn get operationType => text()(); // insert, update, delete
  TextColumn get payloadJson => text()();
  IntColumn get revision => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
```

---

## 5. Synchronization Engine

### 5.1 Real-Time Firestore Synchronization
- When authenticated, `SyncEngine` registers real-time snapshot listeners for the active user's notebooks:
  `FirebaseFirestore.instance.collection('users').doc(uid).collection('notebooks').where('deletedAt', isNull: true).snapshots()`
- As remote changes arrive:
  1. The listener updates or inserts rows into the user's local Drift database.
  2. Riverpod `notebooksProvider` watches Drift and automatically reflects remote changes in the UI.
  3. Zero manual refresh is required.

### 5.2 Offline Mutation Queue Processor
1. Whenever the user modifies data locally:
   - The operation is committed immediately to Drift SQLite.
   - A `SyncOperation` record is appended to `SyncQueueTable` tagged with the user's `ownerId`.
2. The `SyncEngine` monitors connectivity via `ConnectivityService`.
3. When connected:
   - Operations are pushed in FIFO order to Cloud Firestore.
   - Successful operations are marked as `synced` and cleared.
   - Network errors trigger exponential backoff (1s, 2s, 4s, 8s, up to 30s) with random jitter to avoid thundering herd spikes.
   - All operations are idempotent using deterministic document IDs.

### 5.3 Deterministic Conflict Resolution
- For metadata (titles, covers, templates, folder IDs):
  - Merge strategy compares `revision` and server `updatedAt`. The higher revision wins.
- For page content (handwriting strokes and annotations):
  - Prior to merging conflicting edits, a page snapshot is automatically saved to `PageSnapshotsTable` with device and timestamp tags.
  - Non-destructive union: Strokes deleted on one device are soft-deleted; newly added strokes from both devices are preserved.

---

## 6. Account Isolation & Session Teardown

### Logout Sequence
1. **Cancel Listeners:** Disconnect active Firestore `StreamSubscription`s for notebooks and pages.
2. **Halt Sync Engine:** Stop the background sync queue processor and timers.
3. **Flush In-Memory State:** Invalidate all user-specific Riverpod notifiers:
   - `notebooksProvider`
   - `pageProvider`
   - `strokeProvider`
   - `folderProvider`
   - `stickyNoteProvider`
   - `audioProvider`
   - `syncProvider`
4. **Close Local Database:** Safely close the active user's `AppDatabase` connection.
5. **Firebase Sign-Out:** Invoke `FirebaseAuth.instance.signOut()` and `GoogleSignIn.signOut()`.
6. **Navigate Cleanly:** Transition GoRouter state to `/landing` with empty credentials.

### Account Switching Sequence
1. Execute full Logout Sequence.
2. Initialize authentication for the new account.
3. Open the new account's SQLite database (`naik_notes_user_${newUid}.sqlite`).
4. Attach new authenticated Firestore listeners for `newUid`.
5. Trigger initial bidirectional synchronization.

