# Security Audit & Identity Protection — Naik Notes

This document provides a technical security evaluation of authentication providers, credential management, local storage isolation, and remote Firestore rules in **Naik Notes**.

---

## 1. Authentication Security

### 1.1 Multi-Provider Authentication Matrix
Naik Notes supports four authentication mechanisms via **Firebase Authentication**:
1. **Email / Password**: With validation, minimum length constraints, and password reset flows.
2. **Google Sign-In**: Authenticates via OAuth 2.0 and SHA certificate hash matching.
3. **Apple Sign-In**: Standard Sign in with Apple for iPadOS / iOS.
4. **Phone Authentication**: SMS OTP verification.

### 1.2 Android Certificate Fingerprint Configuration
* **Application ID**: `com.naiknotes.app`
* **Debug Keystore Fingerprints**:
  * **SHA-1**: `25:31:73:9A:3D:03:62:3F:8A:4F:CA:27:0B:53:E7:DE:D2:39:68:57`
  * **SHA-256**: `6F:1D:95:F4:A4:BA:C1:25:BF:7D:C2:22:98:B7:24:F0:B8:31:CA:C9:DF:11:13:B9:62:01:DF:72:63:F5:ED:05`
* **Release Keystore**:
  * Generated with 2048-bit RSA key and stored in `android/app/key.properties` (excluded from git tracking).
  * Keystore fingerprints are configured in the Google Cloud Console and Firebase Project Settings to authorize OAuth clients.

---

## 2. Local Storage & File Sandboxing

### 2.1 Database Isolation
* Drift SQLite database (`naik_notes.sqlite`) is stored inside the platform's protected sandbox directory:
  * **Android**: `/data/user/0/com.naiknotes.app/app_flutter/`
  * **iOS/iPadOS**: `~/Library/Application Support/com.naiknotes.app/`
  * **Windows**: `%LOCALAPPDATA%\com.naiknotes.app\`
* No other application on the host device can read or manipulate the SQLite database files.

### 2.2 Audio & Document Export Isolation
* Recorded lecture audio clips (`.m4a`) are saved in the app's internal documents sandbox.
* Document exports via `ExportNotebookDialog` request explicit user approval for destination paths via the native platform file picker on desktop, preventing unauthorized filesystem modifications.

---

## 3. Remote Cloud Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Enforce user-level sandboxing
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Public community stationery templates (read-only for normal users)
    match /templates/{templateId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```
* Every user document is isolated beneath `/users/{userId}/...`.
* Unauthenticated requests are rejected by Firebase server-side rules.

