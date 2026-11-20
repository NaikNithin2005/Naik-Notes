# Naik Notes — Phase 1 Security Architecture & Rules Report

## 1. Security Overview

Naik Notes enforces multi-tier security across all target platforms (Windows, iPadOS, Android) to ensure that:
1. No unauthenticated client can access private user data.
2. User A can never access, read, modify, or delete User B's notebooks, pages, strokes, or metadata.
3. Client-side ID spoofing or tampering cannot alter document ownership.
4. Local device caches are physically isolated between accounts.
5. All OAuth operations adhere to standard security best practices without hardcoding secrets.

---

## 2. Cloud Firestore Security Rules

The security rules are deployed at `firebase/firestore.rules`.

### 2.1 Core Invariants
- **Primary Authorization Check:** `request.auth.uid == userId`.
- **Ownership Immutability:** On create and update, `request.resource.data.ownerId == userId` and `request.resource.data.ownerId == resource.data.ownerId`. An attacker cannot change the `ownerId` of an existing document to re-assign ownership.
- **Strict User Namespacing:** All data is nested under `/users/{userId}/`. Top-level document reads or collection group queries across all users are rejected by the catch-all `allow read, write: false`.

### 2.2 Collection Rules Summary

| Collection Path | Read Rule | Write / Create / Update / Delete Rule | Description |
| :--- | :--- | :--- | :--- |
| `/users/{userId}` | `isOwner(userId)` | `isOwner(userId)` & validate `uid == userId` | User profile document |
| `/users/{userId}/devices/{deviceId}` | `isOwner(userId)` | `isOwner(userId)` | Device session records |
| `/users/{userId}/syncMetadata/{recordId}` | `isOwner(userId)` | `isOwner(userId)` | Sync watermarks and client config |
| `/users/{userId}/folders/{folderId}` | `isOwner(userId)` | `isOwner(userId)` & validate `ownerId == userId` | Notebook folder organization |
| `/users/{userId}/notebooks/{notebookId}` | `isOwner(userId)` | `isOwner(userId)` & validate `ownerId == userId` | Notebook document |
| `/users/{userId}/notebooks/{notebookId}/pages/{pageId}` | `isOwner(userId)` | `isOwner(userId)` | Page dimensions & template info |
| `.../pages/{pageId}/strokes/{strokeId}` | `isOwner(userId)` | `isOwner(userId)` | Vector handwriting stroke points |
| `.../pages/{pageId}/sticky_notes/{noteId}` | `isOwner(userId)` | `isOwner(userId)` | Sticky note text annotations |
| `.../pages/{pageId}/snapshots/{snapshotId}` | `isOwner(userId)` | `isOwner(userId)` | Recoverable page snapshots |
| `/{document=**}` (catch-all) | `false` | `false` | Default deny for all other paths |

---

## 3. OAuth & Client Security

### 3.1 Windows Desktop Loopback Security (RFC 8252 & RFC 7636)
- **Proof Key for Code Exchange (PKCE):** Generated using cryptographically secure random bytes (`Random.secure()`). The code challenge is generated via SHA-256 (`code_challenge_method=S256`).
- **CSRF Protection:** A cryptographically random `state` token is generated and validated upon callback.
- **Zero Secrets in Binary:** Desktop OAuth does not require or embed client secrets. Only the public Web Client ID is used.
- **Local Loopback Binding:** The callback server binds strictly to `127.0.0.1` (loopback IPv4) on an ephemeral port assigned by the OS. It shuts down immediately after receiving the authorization code or upon timeout.

### 3.2 Android & iPadOS OAuth
- Uses official Google Play Services SDK and GoogleSignIn iOS SDK with SHA-1 fingerprint certificate pinning and registered URL schemes.
- Forces explicit account selection via `disconnect()` on account switch.

---

## 4. Local Database & Cache Isolation
- Database files are partitioned by user: `naik_notes_user_${uid}.sqlite`.
- On logout or account switch, the active database connection is closed, in-memory repositories are cleared, and subsequent queries without a valid UID are rejected.

