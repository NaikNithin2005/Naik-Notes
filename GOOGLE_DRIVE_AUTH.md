# Naik Notes – Google Drive Authorization & Account Linking Specification

This document details the authentication and identity architecture governing Google Drive attachment storage in Naik Notes.

---

## 1. Decoupled Identity Architecture

A core design principle of Naik Notes is the strict separation between:
1. **Application Identity (Firebase UID):** Governs who the user is, their notebook ownership, profile information, and Cloud Firestore security rules.
2. **Storage Ownership (Google Account):** Governs whose Google Drive storage quota is used to host binary attachments.

```
       Firebase User (UID: usr_abc123)
                      │
     ┌────────────────┴────────────────┐
     ▼                                 ▼
Email / Password              Google Sign-In
Registration                  Authentication
     │                                 │
     └──────────────┬──────────────────┘
                    │
                    ▼
     Connected Google Drive Storage
        (users/{uid}/integrations/googleDrive)
                    │
                    ├── Windows: PKCE Loopback OAuth
                    ├── iPad:    GoogleSignIn SDK
                    └── Android: GoogleSignIn SDK
                    │
                    ▼
          Target Google Account
          (e.g., nithinnaikr2005@gmail.com)
                    │
                    ▼
          Shared appDataFolder
```

---

## 2. Authentication Scenarios

### Scenario A: User Registers / Signs In via Google
1. User logs in with Google on the Landing or Login screen.
2. Firebase Authentication creates a Firebase user and returns a Firebase UID.
3. The user can authorize Google Drive immediately or through Settings.
4. When authorized, the Google account email and subject identifier (`sub`) are linked to the Firebase UID in Firestore at `users/{uid}/integrations/googleDrive`.

### Scenario B: User Registers via Email & Password
1. User registers with email and password.
2. Firebase Authentication creates the account without requiring Google authorization.
3. The user can create, edit, and organize notebooks completely offline or with Firestore synchronization.
4. When the user attempts to attach a file, Naik Notes displays an informative notice explaining that Google Drive must be connected for cross-device attachment synchronization.
5. The user can connect Google Drive anytime under `Settings -> Cloud Storage -> Google Drive`.

### Scenario C: Signing In on Another Device
1. User signs in to Naik Notes on Windows after previously attaching files on Android.
2. The Firebase session is restored using the same Firebase UID.
3. Naik Notes checks `users/{uid}/integrations/googleDrive`:
   - Detects that Google Drive was linked to `user@example.com`.
4. On Windows, the user authorizes their Google account.
5. Naik Notes checks the authorized account:
   - If the email/sub matches `user@example.com`, authorization succeeds and tokens are stored securely in Windows Credential Locker.
   - If a different Google account is selected, Naik Notes throws `GoogleDriveAccountMismatchException` and prevents unauthorized storage hijacking.

### Scenario D: Disconnecting Google Drive
1. User taps "Disconnect" in Settings.
2. Naik Notes clears encrypted tokens from local `FlutterSecureStorage`.
3. Marks `connected = false` in Firestore (`users/{uid}/integrations/googleDrive`).
4. **Preserves** all local cached attachments on the device.
5. **Preserves** all Firestore attachment metadata references.
6. Does not delete any files from the user's Google Drive.

---

## 3. Token Security & Storage

### Storage Mechanism
- **Windows Desktop:** Windows Credential Manager / DPAPI via `flutter_secure_storage_windows`.
- **iPadOS / iOS:** Apple Keychain via `flutter_secure_storage_darwin`.
- **Android:** Android Keystore + EncryptedSharedPreferences via `flutter_secure_storage`.

### Storage Keys
All keys are prefixed by the authenticated Firebase UID to guarantee total isolation between local accounts:
- `${uid}_drive_access_token`
- `${uid}_drive_refresh_token`
- `${uid}_drive_token_expiry`
- `${uid}_drive_account_email`
- `${uid}_drive_account_sub`

> [!CAUTION]
> OAuth access tokens, refresh tokens, and client secrets are **NEVER** stored in Cloud Firestore or sent over application sync streams.

