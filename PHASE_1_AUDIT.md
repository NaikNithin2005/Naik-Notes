# Naik Notes — Phase 1 Project Audit Report
**Production Architecture, Authentication, Security & Synchronization Audit**

**Target Platforms:** Windows Desktop (Win32), Apple iPad / iPadOS, Android  
**Core Technologies:** Flutter 3.x, Dart SDK ^3.14.0, Firebase Authentication, Cloud Firestore, Firebase Storage, Drift SQLite ORM, Flutter Riverpod  

---

## 1. Executive Summary

An exhaustive technical audit of the **Naik Notes** codebase was conducted across configuration files, native platform harnesses (Android, iOS/iPadOS, Windows), Riverpod state management, Drift SQLite persistence layer, Firestore security rules, and synchronization services.

While the application features an extensive digital stationery, handwriting, and PDF editing UI with over 214 passing unit and widget tests, its **Authentication, Multi-Device Synchronization, and User Account Isolation architectures suffer from critical structural weaknesses**. These weaknesses are directly responsible for the authentication timeouts, cross-user data leakage, missing Google Sign-In on Windows, and synchronization failures observed in production.

This audit report details the findings, answers the 11 key architectural questions, and outlines the required redesign.

---

## 2. Analysis of the 11 Core Questions

### Q1: Why Google login is not consistently working across platforms
1. **Windows Desktop Complete Exclusion:**  
   In `lib/data/repositories/firebase_auth_repository.dart` (lines 336–340), Google Sign-In is explicitly blocked by throwing an exception:
   ```dart
   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
     throw Exception('Google Sign-In is supported on Android and iPadOS. On Windows, please sign in with your Email and Password.');
   }
   ```
   The UI also suppresses Google Sign-In on Windows via `AuthErrorHandler.isGoogleSupported()`. No desktop OAuth 2.0 loopback authorization flow was implemented for Windows.
2. **iPadOS / iOS Missing URL Schemes:**  
   In `ios/Runner/Info.plist`, the `CFBundleURLTypes` configuration is **completely missing**. On iOS/iPadOS, Google Sign-In uses ASWebAuthenticationSession / Safari and redirects back to the app using the reversed client ID URL scheme (`com.googleusercontent.apps.437907946486-...`). Without this entry in `Info.plist`, the redirect fails and the sign-in flow terminates unhandled or hangs indefinitely.
3. **Android OAuth & Play Integrity:**  
   In `android/app/google-services.json`, the SHA-1 fingerprint (`BB:42:0F:07:F9:08:43:69:3D:54:93:1A:02:A8:09:9B:46:F8:66:E7`) and Web Client ID (`437907946486-...apps.googleusercontent.com`) are configured. However, `GoogleSignIn` is instantiated without error recovery or interactive account prompting, causing silent reuse of previous tokens or unhandled cancellation exceptions.

---

### Q2: Why email and password authentication is unreliable
1. **Dual Repositories & Mock Fallbacks:**  
   The codebase contains two competing implementations: `RemoteAuthRepository` and `FirebaseAuthRepository`. In `RemoteAuthRepository`, failed HTTP requests fall back to creating mock user objects (`usr_${sanitizedEmail.hashCode}`), masking network errors in tests and confusing production routing.
2. **Unvalidated Async Initialization:**  
   In `FirebaseAuthRepository.register()`, profile creation (`_syncUserProfile`) and device registration (`_registerDevice`) were executed as unawaited background futures (`unawaited(...)`). The registration method returns immediately before ensuring that Firestore documents are written, resulting in orphaned Firebase Auth accounts missing their corresponding Firestore profile.
3. **Missing Synchronization & Account Metadata:**  
   New user registration did not initialize the user's `syncMetadata` or account configuration in Firestore, leading to null-pointer errors during subsequent synchronization attempts.

---

### Q3: Why login and registration sometimes remain in loading states
1. **Competing Navigation & Router Race Conditions:**  
   In `LoginScreen._submitLogin()` and `RegisterScreen._submitRegister()`:
   ```dart
   final success = await ref.read(authProvider.notifier).login(...);
   if (success && mounted && GoRouterState.of(context).matchedLocation != RouteNames.dashboard) {
     context.go(RouteNames.dashboard);
   }
   ```
   Concurrently, `appRouterProvider` watches `authProvider` and contains a top-level `redirect` callback that triggers `context.go(RouteNames.dashboard)` automatically upon `isAuthenticated == true`. When both trigger simultaneously, route transition collisions occur while `isLoading` is still true or resetting, locking the UI in a loading state.
2. **Unhandled Exceptions in Async Callbacks:**  
   Certain network errors and timeout conditions in Firebase calls failed to execute the state-resetting `finally` block in `AuthNotifier`, leaving `state.isLoading == true` indefinitely.

---

### Q4: Why authentication takes too long
1. **Sequential Network Handshakes:**  
   During login, sequential network round-trips were performed: Firebase Auth credential exchange -> Firestore device document write -> Firestore profile document update.
2. **Unbounded Firestore Timeouts:**  
   Default Firestore connection timeouts (up to 60 seconds) were active when the device had poor connectivity, blocking the authentication flow rather than failing fast with actionable diagnostics.

---

### Q5: Why Google login sometimes automatically selects the previous account
1. **Incomplete Client Sign-Out:**  
   In `FirebaseAuthRepository.signInWithGoogle()`, `googleSignIn.signOut()` only clears the in-memory cache of the plugin, but does not revoke access or disconnect from Google Play Services on Android or Keychain on iOS.
2. **Missing `select_account` Prompt:**  
   Google OAuth provides a `prompt=select_account` parameter. On mobile, calling `googleSignIn.disconnect()` forces the Google Play Services / ASWebAuthenticationSession account picker to display, allowing users to choose another account.

---

### Q6: Why logging out does not properly clear the session
1. **No Local SQLite Database Cleanup:**  
   `AuthNotifier.logout()` called `ref.invalidate(notebooksProvider)` and `ref.invalidate(syncProvider)`, but **never cleared or closed the Drift SQLite database**. All previously cached notebooks, pages, strokes, sticky notes, and audio records remained in the shared SQLite database file.
2. **Orphaned Child Providers:**  
   `pageProvider`, `strokeProvider`, `folderProvider`, `stickyNoteProvider`, and `audioProvider` were not invalidated during logout, retaining active in-memory state from the previous user.
3. **Immediate Re-Query Leak:**  
   When `notebooksProvider` was invalidated, its Riverpod `build()` method executed `loadForUser(null)`. As shown below, querying with `ownerId == null` retrieves all records from all accounts!

---

### Q7: Why different accounts can sometimes see previously created notebooks
1. **Repository Query Bypass on Null `ownerId`:**  
   In `lib/data/repositories/notebook_repository.dart` (lines 100–105 & 117–122):
   ```dart
   final ownerFilter = ownerId != null ? tbl.ownerId.equals(ownerId) : const Constant(true);
   ```
   Whenever `ownerId` is `null` (e.g., during logout, startup, or when unauthenticated), `ownerFilter` becomes `const Constant(true)` — which **queries and returns every single notebook belonging to every user in the database**!
2. **Single Shared SQLite Database File:**  
   In `lib/data/local/app_database.dart`:
   ```dart
   static QueryExecutor _openConnection() {
     return driftDatabase(name: 'naik_notes_local');
   }
   ```
   All users on the same physical device share a single `naik_notes_local.sqlite` file.
3. **Aggressive Orphan Claiming in Sync Service:**  
   In `lib/features/sync/data/sync_provider.dart` (lines 165–177):
   ```dart
   final unassignedNotebooks = await notebookRepo.getAllNotebooks(
     ownerId: 'local_user',
     includeArchived: true,
   );
   for (final unassigned in unassignedNotebooks) {
     final claimed = unassigned.copyWith(
       ownerId: uid,
       updatedAt: DateTime.now(),
     );
     await notebookRepo.saveNotebook(claimed);
     await fbSync.pushNotebook(uid, claimed);
   }
   ```
   If User A created a notebook while offline or unauthenticated (with owner `'local_user'`), and User B logs in next, User B's sync engine **claims User A's notebook, re-assigns ownership to User B, and uploads it to User B's Firestore account**!

---

### Q8: Why notes are not consistently synchronized across devices
1. **Real-Time Listeners Were Never Started:**  
   Although `FirebaseSyncService.listenToNotebooks()` was implemented, **it was never invoked anywhere in the application**. The app had zero real-time Firestore synchronization active.
2. **Incomplete Synchronization Scope:**  
   The 45-second timer in `SyncNotifier` only synchronized Notebooks metadata. It **never pushed or pulled Pages, Strokes, Sticky Notes, Folders, or Audio Recordings**.
3. **Disconnected Offline Mutation Queue:**  
   Although `SyncQueueTable` existed in Drift SQLite, mutations in `notebook_provider`, `page_provider`, and `stroke_provider` did not enqueue operations into `SyncQueueTable`. Modifications made while offline were not recorded in the queue and were never pushed upon reconnection.
4. **Deletions Never Propagated:**  
   `syncNow()` only fetched remote notebooks `where('deletedAt', isNull: true)`. If a notebook was deleted on Device A, Device B never received the deletion and kept the local SQLite row intact.

---

### Q9: Whether the current database architecture supports multiple users
**No.**  
- The local SQLite database has no UID partitioning.
- `SyncQueueTable` lacks an `ownerId` column, meaning operations queued by User A offline would be executed under User B's credentials if User B logged in.
- All default values across Drift tables fall back to `'local_user'`, contaminating the data layer.

---

### Q10: Whether existing local caches are leaking data between accounts
**Yes.**  
- SQLite tables share a single database file.
- Riverpod state is not scoped to the active UID.
- Local attachment storage and thumbnail caches lack UID path isolation.

---

### Q11: Whether the existing Firestore SDK supports the intended persistence and synchronization functionality on each target platform
- **Android & iPadOS:** Native Firestore SDKs have full disk-based offline persistence enabled by default.
- **Windows Desktop:** `cloud_firestore` for Windows runs on the Firebase C++ SDK. Offline caching and reconnection semantics on desktop differ from mobile.
- **Architectural Solution:** To achieve 100% reliability, deterministic conflict resolution, and consistent offline-first performance across all three platforms (Windows, iPad, Android), **Drift SQLite must serve as the authoritative local-first database on all platforms**, with a centralized **Sync Engine** handling bidirectional push/pull with Firestore.

---

## 3. Platform Configuration Audit

| Platform | Firebase Auth Status | Google OAuth Status | Firestore Status | Key Audit Issues Found |
| :--- | :--- | :--- | :--- | :--- |
| **Android** | Configured (`google-services.json`) | Configured (SHA-1: `BB:42:0F:...`) | Supported | Needs `disconnect()` on account switch; sync queue disconnected |
| **iPadOS** | Configured (`GoogleService-Info.plist`) | **Failing** | Supported | `CFBundleURLTypes` missing in `Info.plist`; OAuth redirect crashes |
| **Windows** | Configured (`firebase_options.dart`) | **Disabled in code** | C++ SDK active | Google Sign-In throwing exception; no desktop loopback flow |

---

## 4. Remediation Plan (Phases 1B through 1J)

1. **Phase 1B (Architecture Redesign):** Design UID-partitioned SQLite, centralized Auth Manager, and robust Sync Engine.
2. **Phase 1C (Authentication Implementation):** Implement Windows OAuth loopback flow, fix iPad URL schemes, add Google account chooser, enforce strict email/password lifecycle.
3. **Phase 1D (Database & Security):** Harden Firestore security rules and update composite indexes.
4. **Phase 1E (Local Persistence):** Implement UID-partitioned Drift databases and add `ownerId` to `SyncQueueTable`.
5. **Phase 1F (Sync Engine):** Wire real-time listeners for notebooks, pages, and strokes; implement FIFO queue processor with exponential backoff and deterministic conflict resolution.
6. **Phase 1G (Account Isolation):** Enforce clean session teardown on logout and account switching.
7. **Phase 1H (Automated Testing):** Build comprehensive unit, integration, and security test suites.
8. **Phase 1I (Performance Optimization):** Optimize startup and sync latency.
9. **Phase 1J (Final Validation):** Verify all acceptance criteria and document migration.

