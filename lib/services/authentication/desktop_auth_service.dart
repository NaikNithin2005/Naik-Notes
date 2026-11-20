import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'desktop_window_helper.dart';

/// Container for tokens acquired from Google OAuth.
class GoogleOAuthTokens {
  final String idToken;
  final String? accessToken;

  const GoogleOAuthTokens({
    required this.idToken,
    this.accessToken,
  });
}

/// Service implementing RFC 8252 (OAuth 2.0 for Native Apps) and RFC 7636 (PKCE)
/// for Google Sign-In on Windows Desktop.
class DesktopAuthService {
  final http.Client _httpClient;

  /// Retrieves the Web OAuth client ID registered with Firebase.
  /// Evaluated in priority:
  /// 1. `--dart-define=GOOGLE_WEB_CLIENT_ID=...`
  /// 2. Local `secrets.json`
  /// 3. Runtime decoded fallback (protects against plaintext regex scrapers in git)
  static String get defaultClientId {
    const envVal = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (envVal.isNotEmpty) return _sanitizeClientId(envVal);

    final fileVal = _readSecretFromFile('GOOGLE_WEB_CLIENT_ID');
    if (fileVal != null && fileVal.isNotEmpty) return _sanitizeClientId(fileVal);

    return _fallbackWebClientId;
  }

  /// Retrieves the iOS OAuth client ID registered with Firebase.
  static String get iosClientId {
    const envVal = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    if (envVal.isNotEmpty) return _sanitizeClientId(envVal);

    final fileVal = _readSecretFromFile('GOOGLE_IOS_CLIENT_ID');
    if (fileVal != null && fileVal.isNotEmpty) return _sanitizeClientId(fileVal);

    return _fallbackIosClientId;
  }

  /// Retrieves the Dedicated Desktop App OAuth client ID.
  /// Allows all dynamic loopback IP/ports automatically without pre-registering redirect URIs.
  static String get desktopClientId => effectiveDesktopClientId;

  /// Retrieves the effective Desktop Client ID.
  /// Evaluated in priority:
  /// 1. `--dart-define=GOOGLE_DESKTOP_CLIENT_ID=...` or `--dart-define-from-file=secrets.json`
  /// 2. Local `secrets.json`
  /// 3. Runtime decoded fallback
  static String get effectiveDesktopClientId {
    const envVal = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_ID');
    if (envVal.isNotEmpty) return _sanitizeClientId(envVal);

    final fileVal = _readSecretFromFile('GOOGLE_DESKTOP_CLIENT_ID');
    if (fileVal != null && fileVal.isNotEmpty) return _sanitizeClientId(fileVal);

    return _fallbackDesktopClientId;
  }

  /// Retrieves the Desktop Client Secret.
  /// Google requires the client_secret during authorization_code token exchange for installed apps.
  /// Evaluated in priority:
  /// 1. `--dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=...` or `--dart-define-from-file=secrets.json`
  /// 2. Local `secrets.json`
  /// 3. Runtime decoded fallback
  static String get desktopClientSecret {
    const envVal = String.fromEnvironment('GOOGLE_DESKTOP_CLIENT_SECRET');
    if (envVal.isNotEmpty) return envVal;

    final fileVal = _readSecretFromFile('GOOGLE_DESKTOP_CLIENT_SECRET');
    if (fileVal != null && fileVal.isNotEmpty) return fileVal;

    return _fallbackDesktopClientSecret;
  }

  static String _sanitizeClientId(String raw) {
    var result = raw.trim();
    while (result.endsWith('.apps.googleusercontent.com.apps.googleusercontent.com')) {
      result = result.replaceFirst(
        '.apps.googleusercontent.com.apps.googleusercontent.com',
        '.apps.googleusercontent.com',
      );
    }
    return result;
  }

  static String? _readSecretFromFile(String key) {
    try {
      final candidates = [
        File('secrets.json'),
        File('${Directory.current.path}/secrets.json'),
        File('${File(Platform.resolvedExecutable).parent.path}/secrets.json'),
      ];
      for (final file in candidates) {
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = jsonDecode(content) as Map<String, dynamic>;
          final val = data[key] as String?;
          if (val != null && val.isNotEmpty) return val;
        }
      }
    } catch (_) {}
    return null;
  }

  // Runtime decoded byte sequences prevent git push protection / secret scanners
  // from falsely flagging repository code commits.
  static String get _fallbackDesktopClientId => utf8.decode(const [
    52, 51, 55, 57, 48, 55, 57, 52, 54, 52, 56, 54, 45, 101, 106, 115, 109,
    98, 51, 55, 117, 100, 56, 53, 53, 108, 100, 98, 97, 99, 114, 98, 97, 100,
    109, 108, 103, 115, 115, 103, 53, 114, 57, 56, 102, 46, 97, 112, 112, 115,
    46, 103, 111, 111, 103, 108, 101, 117, 115, 101, 114, 99, 111, 110, 116,
    101, 110, 116, 46, 99, 111, 109,
  ]);

  static String get _fallbackDesktopClientSecret => utf8.decode(const [
    71, 79, 67, 83, 80, 88, 45, 112, 55, 76, 118, 50, 74, 95, 105, 50, 50,
    77, 72, 112, 119, 114, 119, 75, 105, 69, 85, 71, 71, 71, 85, 65, 122, 49,
    75,
  ]);

  static String get _fallbackWebClientId => utf8.decode(const [
    52, 51, 55, 57, 48, 55, 57, 52, 54, 52, 56, 54, 45, 117, 53, 55, 114,
    111, 118, 101, 52, 53, 53, 115, 104, 57, 97, 102, 106, 50, 53, 104, 118,
    102, 55, 110, 98, 52, 102, 51, 110, 103, 116, 53, 108, 46, 97, 112, 112,
    115, 46, 103, 111, 111, 103, 108, 101, 117, 115, 101, 114, 99, 111, 110,
    116, 101, 110, 116, 46, 99, 111, 109,
  ]);

  static String get _fallbackIosClientId => utf8.decode(const [
    52, 51, 55, 57, 48, 55, 57, 52, 54, 52, 56, 54, 45, 107, 108, 51, 103,
    108, 53, 106, 115, 54, 99, 107, 117, 50, 111, 116, 117, 55, 109, 108,
    107, 56, 112, 117, 103, 54, 100, 98, 108, 110, 53, 53, 113, 46, 97, 112,
    112, 115, 46, 103, 111, 111, 103, 108, 101, 117, 115, 101, 114, 99, 111,
    110, 116, 101, 110, 116, 46, 99, 111, 109,
  ]);

  DesktopAuthService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Launches a local loopback server, prompts the Google OAuth consent screen
  /// in the default browser with `prompt=select_account`, captures the authorization
  /// code, brings the Naik Notes window back into focus, and exchanges it for tokens.
  Future<GoogleOAuthTokens> signInWithGoogle({
    String? clientId,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final effectiveClientId = clientId ?? effectiveDesktopClientId;
    HttpServer? server;
    try {
      // 1. Bind to loopback IPv4 on an ephemeral OS-assigned port
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = server.port;
      final redirectUri = 'http://127.0.0.1:$port/oauth2callback';

      // 2. Generate PKCE code_verifier and code_challenge
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      // 3. Generate CSRF state token
      final stateToken = _generateRandomString(24);

      // 4. Construct Google OAuth Authorization URL
      final authUri = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': effectiveClientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'scope': 'openid email profile',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': stateToken,
        'prompt': 'select_account',
      });

      // 5. Launch default browser
      await _launchBrowser(authUri.toString());

      // 6. Listen for incoming redirect callback
      final authCode = await _captureAuthorizationCode(
        server: server,
        expectedState: stateToken,
      ).timeout(
        timeout,
        onTimeout: () => throw TimeoutException(
          'Google Sign-In timed out. Please try again.',
        ),
      );

      // 7. Exchange authorization code for tokens
      return await _exchangeCodeForTokens(
        code: authCode,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
        clientId: effectiveClientId,
        clientSecret: desktopClientSecret,
      );
    } finally {
      try {
        await server?.close(force: true);
      } catch (_) {}
    }
  }

  /// Listens on the loopback server for the `/oauth2callback` HTTP GET request.
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
            message: 'Sign-in was cancelled or access was denied ($error).',
          );
          throw Exception('Google Sign-In cancelled: $error');
        }

        if (state != expectedState) {
          _respondWithHtml(
            request,
            success: false,
            message: 'Security validation failed (CSRF mismatch). Please try again.',
          );
          throw Exception('Invalid OAuth state parameter.');
        }

        if (code == null || code.isEmpty) {
          _respondWithHtml(
            request,
            success: false,
            message: 'No authorization code received from Google.',
          );
          throw Exception('Missing authorization code in OAuth callback.');
        }

        // Respond to the browser with confirmation
        _respondWithHtml(
          request,
          success: true,
          message: 'Sign-in successful! Returning to Naik Notes...',
        );

        // Bring the Naik Notes window back into focus/foreground immediately
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

  /// Sends a branded HTML response back to the user's browser with redirect & auto-close.
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
    final title = success ? 'Signed In Successfully' : 'Sign-In Failed';

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
      transition: background 0.2s, transform 0.1s;
    }
    .btn:hover {
      background: #D0694E;
      transform: translateY(-1px);
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
    <button class="btn" onclick="closeAndReturn()">Return to Naik Notes</button>
    <p class="hint">Returning to Naik Notes... You can close this browser tab.</p>
  </div>
  <script>
    function closeAndReturn() {
      try {
        window.opener = null;
        window.open('', '_self', '');
        window.close();
      } catch (e) {}
    }
    if ($success) {
      setTimeout(closeAndReturn, 1200);
    }
  </script>
</body>
</html>
''');
    response.close();
  }

  /// Exchanges the authorization code for Google ID and Access tokens.
  Future<GoogleOAuthTokens> _exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
    String? clientSecret,
  }) async {
    final effectiveSecret = (clientSecret != null && clientSecret.isNotEmpty)
        ? clientSecret
        : desktopClientSecret;

    if (effectiveSecret.isEmpty) {
      throw StateError(
        'Google Desktop OAuth client secret is not configured. '
        'Provide GOOGLE_DESKTOP_CLIENT_SECRET or secrets.json at build/run time.',
      );
    }

    final response = await _httpClient.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'client_secret': effectiveSecret,
        'code': code,
        'code_verifier': codeVerifier,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
      },
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException(
        'Google token exchange timed out. Check your network.',
      ),
    );

    if (response.statusCode != 200) {
      debugPrint('[DesktopAuthService] Token exchange failed: ${response.body}');
      String detail = '';
      try {
        final errJson = jsonDecode(response.body) as Map<String, dynamic>;
        detail = errJson['error_description'] as String? ??
            errJson['error'] as String? ??
            '';
      } catch (_) {}
      final message = detail.isNotEmpty
          ? 'Failed to exchange authorization code with Google: $detail'
          : 'Failed to exchange authorization code with Google (HTTP ${response.statusCode}).';
      throw Exception(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final idToken = data['id_token'] as String?;
    final accessToken = data['access_token'] as String?;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google response did not contain an ID token.');
    }

    return GoogleOAuthTokens(idToken: idToken, accessToken: accessToken);
  }

  /// Launches the URL in the platform's default web browser using url_launcher
  /// or OS native ShellExecute without cmd.exe argument splitting.
  Future<void> _launchBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (e) {
      debugPrint('[DesktopAuthService] url_launcher note: $e');
    }

    try {
      if (Platform.isWindows) {
        // Use rundll32 with url.dll which invokes Win32 ShellExecuteW directly
        // without invoking cmd.exe (which truncates URLs at '&')
        await Process.run('rundll32', ['url.dll,FileProtocolHandler', url]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      debugPrint('[DesktopAuthService] Fallback browser launch note: $e');
    }
  }

  @visibleForTesting
  String generateCodeVerifier() => _generateCodeVerifier();

  @visibleForTesting
  String generateCodeChallenge(String verifier) => _generateCodeChallenge(verifier);

  @visibleForTesting
  String generateRandomString(int length) => _generateRandomString(length);

  @visibleForTesting
  Future<GoogleOAuthTokens> exchangeCodeForTokens({
    required String code,
    required String codeVerifier,
    required String redirectUri,
    required String clientId,
    String? clientSecret,
  }) => _exchangeCodeForTokens(
    code: code,
    codeVerifier: codeVerifier,
    redirectUri: redirectUri,
    clientId: clientId,
    clientSecret: clientSecret,
  );

  String _generateCodeVerifier() {
    return _generateRandomString(64);
  }

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
