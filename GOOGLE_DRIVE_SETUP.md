# Naik Notes – Google Drive Setup & Google Cloud Console Configuration Guide

This guide documents the step-by-step Google Cloud Console and Firebase configuration required to enable Google Drive API v3 attachment storage for Naik Notes across **Windows Desktop**, **iPadOS**, and **Android**.

---

## 1. Project Selection
Always use your existing Google Cloud project linked to Firebase (`naik-notes`, Project `#437907946486`). Do **not** create a separate project for Google Drive, ensuring that all platform OAuth clients share the exact same `appDataFolder` application namespace.

---

## 2. Enable Google Drive API v3
1. Open [Google Cloud Console - API Library](https://console.cloud.google.com/apis/library).
2. Ensure project `naik-notes` is selected.
3. Search for **Google Drive API**.
4. Click **Enable**.

---

## 3. Google Auth Platform Configuration

### A. Branding
1. Navigate to **Google Auth Platform** -> **Branding**.
2. Configure:
   - **App name:** `Naik Notes`
   - **User support email:** Select your developer/support email.
   - **App logo:** Upload Naik Notes square icon (512x512 PNG).
   - **Application home page:** `https://github.com/NaikNithin2005/Naik-Notes`
   - **Developer contact information:** Your developer email.
3. Save changes.

### B. Audience & Test Users
1. Under **Audience**, select **External**.
2. Keep Publishing status in **Testing** during active development.
3. Under **Test Users**, add:
   - Your primary Google account
   - Any test accounts used across Android, iPad, or Windows.
> [!NOTE]
> In Testing mode, Google limits the application to 100 test users, and refresh tokens expire after 7 days when testing scopes. When ready for broad distribution, submit the OAuth verification request.

### C. Data Access (Required OAuth Scope)
1. Go to **Data Access** -> **Add or Remove Scopes**.
2. Manually add this exact scope:
   ```
   https://www.googleapis.com/auth/drive.appdata
   ```
3. Save.
> [!IMPORTANT]
> Do NOT add `drive` or `drive.file`. The `drive.appdata` scope is non-sensitive, provides full read/write access to Naik Notes' hidden directory only, and does not require extensive security tier verification.

---

## 4. Platform OAuth Clients

### Android Client
1. In Google Cloud Console, open **Clients** -> **Create Client** -> **Android**.
2. Package name: `com.example.naik_notes` (from `android/app/build.gradle`).
3. SHA-1 Fingerprint:
   - Retrieve via PowerShell:
     ```powershell
     cd android
     .\gradlew signingReport
     ```
   - Register the `SHA-1` from the debug and release keys.

### iPad / iOS Client
1. Open **Clients** -> **Create Client** -> **iOS**.
2. Bundle ID: `com.example.naikNotes` (from `ios/Runner.xcodeproj`).
3. Note the Client ID and Reversed Client ID:
   - Reversed Client ID scheme is already registered in `ios/Runner/Info.plist` under `CFBundleURLSchemes`.

### Windows Desktop Client
1. Open **Clients** -> **Create Client** -> **Desktop app**.
2. Name: `Naik Notes Windows Desktop`.
3. Save client.
4. Obtain the Client ID and Client Secret:
   - Client ID: `YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com`
   - Client Secret: Configure in git-ignored `secrets.json` or pass via `--dart-define`.
5. Desktop App clients in Google Cloud Console automatically allow all dynamic loopback IP redirect URIs (`http://127.0.0.1:<port>/oauth2callback`) without pre-registering static ports.

---

## 5. Local Workspace Configuration (`secrets.json`)
Create `secrets.json` in the root of your project (already included in `.gitignore`):
```json
{
  "GOOGLE_DESKTOP_CLIENT_ID": "YOUR_DESKTOP_CLIENT_ID.apps.googleusercontent.com",
  "GOOGLE_DESKTOP_CLIENT_SECRET": "YOUR_DESKTOP_CLIENT_SECRET"
}
```
Naik Notes will load these credentials at build time or runtime automatically.
