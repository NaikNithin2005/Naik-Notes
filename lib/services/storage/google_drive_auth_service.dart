import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/google_drive_connection_model.dart';
import '../authentication/desktop_auth_service.dart';
import '../authentication/desktop_window_helper.dart';

/// Credentials container for authorized Google Drive session.
class GoogleDriveCredentials {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiry;
  final String accountEmail;
  final String? subjectId;

  const GoogleDriveCredentials({
    required this.accessToken,
    this.refreshToken,
    this.expiry,
    required this.accountEmail,
    this.subjectId,
  });

  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry!.subtract(const Duration(seconds: 60)));
  }
}

/// Thrown when a user attempts to connect a Google account that does not match
/// the existing linked Google Drive account for their Firebase UID.
class GoogleDriveAccountMismatchException implements Exception {
  final String expectedEmail;
  final String attemptedEmail;

  GoogleDriveAccountMismatchException({
    required this.expectedEmail,
    required this.attemptedEmail,
  });

  @override
  String toString() =>
      'Google Drive Account Mismatch: The current notebook attachments belong to '
      '$expectedEmail. Attempted to connect $attemptedEmail. Disconnect the existing '
      'account first if you wish to switch storage providers.';
}

/// Service managing OAuth 2.0 authorization, PKCE, token refresh, and account linking
/// for Google Drive API v3 (`https://www.googleapis.com/auth/drive.appdata`) across
/// Windows Desktop, Android, and iPadOS/iOS.
class GoogleDriveAuthService {
  /// The single, non-sensitive least-privilege OAuth scope for hidden application storage.
  static const String appDataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  final FlutterSecureStorage _secureStorage;
  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  FlutterSecureStorage get secureStorage => _secureStorage;

  GoogleDriveAuthService({
    FlutterSecureStorage? secureStorage,
    FirebaseFirestore? firestore,
    http.Client? httpClient,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _firestore = firestore ?? FirebaseFirestore.instance,
        _httpClient = httpClient ?? http.Client();

  /// Retrieves the current Google Drive connection metadata stored locally or in Firestore.
  /// Follows Local-First architecture: local secure storage is checked first.
  Future<GoogleDriveConnectionModel?> getConnectionMetadata(String uid) async {
    // 1. Check local secure storage first for instant zero-latency offline availability
    try {
      final localCreds = await _loadSecureCredentials(uid);
      if (localCreds != null && localCreds.accessToken.isNotEmpty) {
        final connectedAtStr =
            await _secureStorage.read(key: '${uid}_drive_connected_at');
        final lastVerifiedStr =
            await _secureStorage.read(key: '${uid}_drive_last_verified_at');
        return GoogleDriveConnectionModel(
          provider: 'google_drive',
          connected: true,
          googleAccountEmail: localCreds.accountEmail,
          googleAccountSubjectId: localCreds.subjectId,
          connectedAt: connectedAtStr != null
              ? DateTime.tryParse(connectedAtStr)
              : DateTime.now(),
          lastVerifiedAt: lastVerifiedStr != null
              ? DateTime.tryParse(lastVerifiedStr)
              : DateTime.now(),
          storageProvider: 'google_drive_appdata',
          schemaVersion: 1,
        );
      }
    } catch (e) {
      debugPrint('[GoogleDriveAuthService] Local secure storage read note: $e');
    }

    // 2. Fall back to Cloud Firestore if local credentials are not found
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('integrations')
          .doc('googleDrive')
          .get()
          .timeout(const Duration(seconds: 4));

      if (doc.exists && doc.data() != null) {
        return GoogleDriveConnectionModel.fromFirestore(doc.data()!);
      }
    } catch (e) {
      debugPrint('[GoogleDriveAuthService] Failed to load connection doc from Firestore: $e');
    }
    return null;
  }

  /// Authorizes Google Drive for the given [uid].
  ///
  /// On Windows: Runs an ephemeral loopback PKCE OAuth flow.
  /// On Android & iOS: Uses native [GoogleSignIn].
  ///
  /// Enforces account linking: if this Firebase UID already has a linked Drive account,
  /// verifies that the authorized Google account matches before saving credentials.
  Future<GoogleDriveCredentials> authorizeDrive({
    required String uid,
    bool forceAccountSelection = true,
  }) async {
    GoogleDriveCredentials credentials;

    if (!kIsWeb && Platform.isWindows) {
      credentials = await _authorizeWindows(
        forceAccountSelection: forceAccountSelection,
      );
    } else {
      credentials = await _authorizeMobile(
        forceAccountSelection: forceAccountSelection,
      );
    }

    // Account linking validation
    final existingMeta = await getConnectionMetadata(uid);
    if (existingMeta != null &&
        existingMeta.connected &&
        existingMeta.googleAccountEmail != null &&
        existingMeta.googleAccountEmail!.isNotEmpty) {
      final existingEmail = existingMeta.googleAccountEmail!.toLowerCase().trim();
      final currentEmail = credentials.accountEmail.toLowerCase().trim();

      if (existingEmail != currentEmail) {
        throw GoogleDriveAccountMismatchException(
          expectedEmail: existingEmail,
          attemptedEmail: currentEmail,
        );
      }
    }

    // Persist credentials in platform secure storage (NEVER in Firestore)
    await _saveSecureCredentials(uid, credentials);

    // Update Firestore connection metadata
    final updatedMeta = GoogleDriveConnectionModel(
      provider: 'google_drive',
      connected: true,
      googleAccountEmail: credentials.accountEmail,
      googleAccountSubjectId: credentials.subjectId,
      connectedAt: existingMeta?.connectedAt ?? DateTime.now(),
      lastVerifiedAt: DateTime.now(),
      storageProvider: 'google_drive_appdata',
      schemaVersion: 1,
    );

    // Update Firestore connection metadata with a safe timeout
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('integrations')
          .doc('googleDrive')
          .set(updatedMeta.toFirestore(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('[GoogleDriveAuthService] Non-critical warning: Firestore metadata sync deferred/timed out: $e');
    }

    return credentials;
  }

  /// Actively validates that Google Drive API is reachable and authorized with the required scope.
  /// Returns null if access is verified, or a descriptive error message if access failed.
  Future<String?> validateDriveAccess(String uid, {String? accessToken}) async {
    try {
      final token = accessToken ?? await getValidAccessToken(uid);
      if (token == null || token.isEmpty) {
        return 'No Google access token found. Please connect your Google Drive account.';
      }

      // 1. Primary check: list files in the application's private appDataFolder
      final res = await _httpClient.get(
        Uri.parse(
          'https://www.googleapis.com/drive/v3/files?spaces=appDataFolder&pageSize=1&fields=files(id)',
        ),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      debugPrint('[GoogleDriveAuthService] validateDriveAccess (files.list): HTTP ${res.statusCode}');

      if (res.statusCode == 200) {
        await _secureStorage.write(
          key: '${uid}_drive_last_verified_at',
          value: DateTime.now().toIso8601String(),
        );
        return null; // Valid
      }

      debugPrint('[GoogleDriveAuthService] validateDriveAccess failed body: ${res.body}');

      // 2. Secondary fallback check: inspect appDataFolder container metadata
      final folderRes = await _httpClient.get(
        Uri.parse('https://www.googleapis.com/drive/v3/files/appDataFolder?fields=id,name'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 8));

      debugPrint('[GoogleDriveAuthService] validateDriveAccess (files.get appDataFolder): HTTP ${folderRes.statusCode}');

      if (folderRes.statusCode == 200) {
        await _secureStorage.write(
          key: '${uid}_drive_last_verified_at',
          value: DateTime.now().toIso8601String(),
        );
        return null; // Valid
      }

      // Analyze specific Google API error causes
      final bodyLower = res.body.toLowerCase();
      if (res.statusCode == 403) {
        if (bodyLower.contains('service_disabled') ||
            bodyLower.contains('has not been used in project') ||
            bodyLower.contains('disabled')) {
          return 'Google Drive API is disabled in Google Cloud Project #437907946486.\n'
              'Enable it at: https://console.cloud.google.com/apis/library/drive.googleapis.com?project=437907946486';
        }
        if (bodyLower.contains('insufficient') ||
            bodyLower.contains('appdatafolderaccessdenied') ||
            bodyLower.contains('access_token_scope_insufficient') ||
            bodyLower.contains('not granted')) {
          return 'Google Drive permission was not granted by your Google Account.\n'
              'When the browser sign-in screen opens, please make sure to check the box next to Google Drive before continuing.';
        }
      } else if (res.statusCode == 401) {
        return 'Google authorization expired or was revoked. Please reconnect.';
      }

      return 'Google Drive access could not be verified (HTTP ${res.statusCode}). Please check permissions.';
    } catch (e) {
      debugPrint('[GoogleDriveAuthService] validateDriveAccess exception: $e');
      return 'Could not connect to Google Drive: $e';
    }
  }

  /// Returns a valid, non-expired access token for calling Google Drive API v3.
  /// Automatically refreshes the token if it has expired or is nearing expiration.
  Future<String?> getValidAccessToken(String uid) async {
    final credentials = await _loadSecureCredentials(uid);
    if (credentials == null) return null;

    if (!credentials.isExpired) {
      return credentials.accessToken;
    }

    // Token is expired, try to refresh
    if (credentials.refreshToken != null && credentials.refreshToken!.isNotEmpty) {
      try {
        final refreshed = await _refreshAccessToken(
          uid: uid,
          refreshToken: credentials.refreshToken!,
          accountEmail: credentials.accountEmail,
          subjectId: credentials.subjectId,
        );
        return refreshed.accessToken;
      } catch (e) {
        debugPrint('[GoogleDriveAuthService] Token refresh failed: $e');
      }
    }

    // On mobile platforms, silent sign in can renew the token
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final renewed = await _authorizeMobile(forceAccountSelection: false);
        await _saveSecureCredentials(uid, renewed);
        return renewed.accessToken;
      } catch (e) {
        debugPrint('[GoogleDriveAuthService] Mobile silent renewal failed: $e');
      }
    }

    return null;
  }

  /// Disconnects Google Drive storage for [uid].
  ///
  /// Clears secure credentials and marks the connection as inactive in Firestore.
  /// Local files and existing note references remain intact.
  Future<void> disconnectDrive(String uid) async {
    await _clearSecureCredentials(uid);

    // On mobile platforms, sign out from native Google Sign-In instance
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', appDataScope],
        );
        await googleSignIn.signOut();
      } catch (e) {
        debugPrint('[GoogleDriveAuthService] Native Google sign out note: $e');
      }
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('integrations')
          .doc('googleDrive')
          .set({
        'connected': false,
        'disconnectedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[GoogleDriveAuthService] Failed to update disconnect in Firestore: $e');
    }
  }

  // ===========================================================================
  // Windows Desktop OAuth (RFC 8252 Loopback + RFC 7636 PKCE)
  // ===========================================================================

  Future<GoogleDriveCredentials> _authorizeWindows({
    required bool forceAccountSelection,
  }) async {
    HttpServer? server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUri = 'http://127.0.0.1:$port/oauth2callback';

      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);
      final stateToken = _generateRandomString(24);

      final clientId = DesktopAuthService.effectiveDesktopClientId;
      final clientSecret = DesktopAuthService.desktopClientSecret;

      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile $appDataScope',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': stateToken,
        'access_type': 'offline', // Requests refresh_token
        'include_granted_scopes': 'true',
        'prompt': forceAccountSelection ? 'consent select_account' : 'consent',
      });

      // Launch default web browser
      await _launchBrowser(authUri.toString());

      // Listen for incoming authorization code
      final authCode = await _captureAuthorizationCode(
        server: server,
        expectedState: stateToken,
      ).timeout(
        const Duration(seconds: 120),
        onTimeout: () => throw TimeoutException(
          'Google Drive authorization timed out. Please try again.',
        ),
      );

      // Exchange code for tokens
      return await _exchangeCodeForDriveTokens(
        code: authCode,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
        clientId: clientId,
        clientSecret: clientSecret,
      );
    } finally {
      try {
        await server?.close(force: true);
      } catch (_) {}
    }
  }

  Future<String> _captureAuthorizationCode({
    required HttpServer server,
    required String expectedState,
  }) async {
    await for (final HttpRequest request in server) {
      final uri = request.uri;
      if (uri.path == '/oauth2callback') {
        final queryParams = uri.queryParameters;
        final error = queryParams['error'];
        final code = queryParams['code'];
        final state = queryParams['state'];

        if (error != null) {
          _respondWithHtml(
            request,
            success: false,
            message: 'Drive authorization was denied or cancelled ($error).',
          );
          throw Exception('Google Drive authorization denied: $error');
        }

        if (state != expectedState) {
          _respondWithHtml(
            request,
            success: false,
            message: 'Security validation failed (CSRF mismatch).',
          );
          throw Exception('Invalid OAuth state parameter.');
        }

        if (code == null || code.isEmpty) {
          _respondWithHtml(
            request,
            success: false,
            message: 'No authorization code received from Google.',
          );
          throw Exception('Missing authorization code.');
        }

        _respondWithHtml(
          request,
          success: true,
          message: 'Google Drive connected successfully! Returning to Naik Notes...',
        );

        // Bring the Naik Notes window back into focus immediately
        DesktopWindowHelper.bringToFront('Naik Notes');

        return code;
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('Not found')
          ..close();
      }
    }
    throw Exception('Server closed before receiving authorization code.');
  }

  Future<GoogleDriveCredentials> _exchangeCodeForDriveTokens({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
    required String clientSecret,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': code,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange code for Drive tokens (HTTP ${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String;
    final refreshToken = data['refresh_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    final idToken = data['id_token'] as String?;
    final grantedScope = data['scope'] as String?;

    debugPrint('[GoogleDriveAuthService] Granted OAuth scopes: $grantedScope');

    if (grantedScope != null && !grantedScope.contains('drive.appdata')) {
      throw Exception(
        'Google Drive permission was not granted by your Google Account.\n'
        'When the sign-in window opens, please make sure the Google Drive checkbox is checked.',
      );
    }

    final parsedIdentity = _parseIdToken(idToken);
    final expiry = DateTime.now().add(Duration(seconds: expiresIn));

    return GoogleDriveCredentials(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiry: expiry,
      accountEmail: parsedIdentity['email'] ?? 'unknown_google_user',
      subjectId: parsedIdentity['sub'],
    );
  }

  Future<GoogleDriveCredentials> _refreshAccessToken({
    required String uid,
    required String refreshToken,
    required String accountEmail,
    String? subjectId,
  }) async {
    final clientId = DesktopAuthService.effectiveDesktopClientId;
    final clientSecret = DesktopAuthService.desktopClientSecret;

    final response = await _httpClient.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'refresh_token': refreshToken,
        'grant_type': 'refresh_token',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to refresh Google Drive access token (HTTP ${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final newAccessToken = data['access_token'] as String;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    final newRefreshToken = data['refresh_token'] as String? ?? refreshToken;

    final expiry = DateTime.now().add(Duration(seconds: expiresIn));

    final credentials = GoogleDriveCredentials(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiry: expiry,
      accountEmail: accountEmail,
      subjectId: subjectId,
    );

    await _saveSecureCredentials(uid, credentials);
    return credentials;
  }

  // ===========================================================================
  // Mobile OAuth (Android & iPadOS / iOS)
  // ===========================================================================

  Future<GoogleDriveCredentials> _authorizeMobile({
    required bool forceAccountSelection,
  }) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', appDataScope],
      serverClientId: DesktopAuthService.defaultClientId,
      clientId: defaultTargetPlatform == TargetPlatform.iOS
          ? DesktopAuthService.iosClientId
          : null,
    );

    if (forceAccountSelection) {
      try {
        await googleSignIn.signOut();
      } catch (_) {}
    }

    final GoogleSignInAccount? account = await googleSignIn.signIn().timeout(
      const Duration(seconds: 90),
      onTimeout: () => throw TimeoutException(
        'Google Sign-In timed out. Please try again.',
      ),
    );
    if (account == null) {
      throw Exception('Google Drive authorization was cancelled.');
    }

    final GoogleSignInAuthentication auth = await account.authentication.timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException(
        'Failed to retrieve authentication tokens from Google.',
      ),
    );
    final accessToken = auth.accessToken;

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Google Sign-In did not return an access token for Drive.');
    }

    final idTokenPayload = _parseIdToken(auth.idToken);

    return GoogleDriveCredentials(
      accessToken: accessToken,
      refreshToken: null,
      expiry: DateTime.now().add(const Duration(hours: 1)),
      accountEmail: account.email,
      subjectId: idTokenPayload['sub'] ?? account.id,
    );
  }

  // ===========================================================================
  // Platform Secure Storage (Encrypted on Device)
  // ===========================================================================

  Future<void> _saveSecureCredentials(
    String uid,
    GoogleDriveCredentials credentials,
  ) async {
    await _secureStorage.write(
      key: '${uid}_drive_access_token',
      value: credentials.accessToken,
    );
    if (credentials.refreshToken != null) {
      await _secureStorage.write(
        key: '${uid}_drive_refresh_token',
        value: credentials.refreshToken,
      );
    }
    if (credentials.expiry != null) {
      await _secureStorage.write(
        key: '${uid}_drive_token_expiry',
        value: credentials.expiry!.toIso8601String(),
      );
    }
    await _secureStorage.write(
      key: '${uid}_drive_account_email',
      value: credentials.accountEmail,
    );
    if (credentials.subjectId != null) {
      await _secureStorage.write(
        key: '${uid}_drive_account_sub',
        value: credentials.subjectId,
      );
    }
    await _secureStorage.write(
      key: '${uid}_drive_connected',
      value: 'true',
    );
    await _secureStorage.write(
      key: '${uid}_drive_connected_at',
      value: DateTime.now().toIso8601String(),
    );
    await _secureStorage.write(
      key: '${uid}_drive_last_verified_at',
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<GoogleDriveCredentials?> _loadSecureCredentials(String uid) async {
    final token = await _secureStorage.read(key: '${uid}_drive_access_token');
    if (token == null || token.isEmpty) return null;

    final refreshToken = await _secureStorage.read(key: '${uid}_drive_refresh_token');
    final expiryStr = await _secureStorage.read(key: '${uid}_drive_token_expiry');
    final email = await _secureStorage.read(key: '${uid}_drive_account_email') ?? 'unknown';
    final sub = await _secureStorage.read(key: '${uid}_drive_account_sub');

    final expiry = expiryStr != null ? DateTime.tryParse(expiryStr) : null;

    return GoogleDriveCredentials(
      accessToken: token,
      refreshToken: refreshToken,
      expiry: expiry,
      accountEmail: email,
      subjectId: sub,
    );
  }

  Future<void> _clearSecureCredentials(String uid) async {
    await _secureStorage.delete(key: '${uid}_drive_access_token');
    await _secureStorage.delete(key: '${uid}_drive_refresh_token');
    await _secureStorage.delete(key: '${uid}_drive_token_expiry');
    await _secureStorage.delete(key: '${uid}_drive_account_email');
    await _secureStorage.delete(key: '${uid}_drive_account_sub');
    await _secureStorage.delete(key: '${uid}_drive_connected');
    await _secureStorage.delete(key: '${uid}_drive_connected_at');
    await _secureStorage.delete(key: '${uid}_drive_last_verified_at');
  }

  // ===========================================================================
  // Utilities
  // ===========================================================================

  Map<String, String> _parseIdToken(String? idToken) {
    if (idToken == null || idToken.isEmpty) return {};
    try {
      final parts = idToken.split('.');
      if (parts.length >= 2) {
        final payload = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(payload));
        final json = jsonDecode(decoded) as Map<String, dynamic>;
        return {
          'email': json['email'] as String? ?? '',
          'sub': json['sub'] as String? ?? '',
        };
      }
    } catch (_) {}
    return {};
  }

  void _respondWithHtml(
    HttpRequest request, {
    required bool success,
    required String message,
  }) {
    final response = request.response;
    response.headers.contentType = ContentType.html;
    response.statusCode = success ? HttpStatus.ok : HttpStatus.badRequest;

    final icon = success ? '&#10004;' : '&#10006;';
    final iconColor = success ? '#22C55E' : '#EF4444';
    final title = success ? 'Google Drive Connected' : 'Connection Failed';

    response.write('''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Naik Notes - $title</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      background-color: #0F172A;
      color: #E2E8F0;
      text-align: center;
      padding: 24px;
    }
    .card {
      background: #1E293B;
      padding: 48px 36px;
      border-radius: 20px;
      box-shadow: 0 16px 48px rgba(0,0,0,0.6);
      max-width: 440px;
      width: 100%;
      border: 1px solid #334155;
    }
    .icon-container {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: ${success ? 'rgba(34, 197, 94, 0.15)' : 'rgba(239, 68, 68, 0.15)'};
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
      border: 1px solid ${success ? 'rgba(34, 197, 94, 0.3)' : 'rgba(239, 68, 68, 0.3)'};
    }
    .icon {
      font-size: 36px;
      color: $iconColor;
      line-height: 1;
    }
    h1 {
      font-family: Georgia, serif;
      color: #F8FAFC;
      margin: 0 0 12px;
      font-size: 26px;
      font-weight: 600;
    }
    p {
      color: #94A3B8;
      font-size: 15px;
      line-height: 1.6;
      margin: 8px 0;
    }
    .btn {
      display: inline-block;
      margin-top: 24px;
      background: #E07A5F;
      color: #FFFFFF;
      text-decoration: none;
      padding: 12px 28px;
      border-radius: 10px;
      font-weight: 600;
      font-size: 15px;
      border: none;
      cursor: pointer;
    }
    .hint {
      font-size: 13px;
      color: #64748B;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon-container">
      <div class="icon">$icon</div>
    </div>
    <h1>$title</h1>
    <p>$message</p>
    <button class="btn" onclick="closeTab()">Return to Naik Notes</button>
    <p class="hint">Returning to application automatically...</p>
  </div>
  <script>
    function closeTab() {
      try {
        window.opener = null;
        window.open('', '_self', '');
        window.close();
      } catch (e) {}
    }
    if ($success) {
      setTimeout(closeTab, 1200);
    }
  </script>
</body>
</html>
''');
    response.close();
  }

  Future<void> _launchBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {}

    try {
      if (Platform.isWindows) {
        await Process.run('rundll32', ['url.dll,FileProtocolHandler', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (_) {}
  }

  String _generateCodeVerifier() => _generateRandomString(64);

  String _generateCodeChallenge(String verifier) {
    final bytes = ascii.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}

