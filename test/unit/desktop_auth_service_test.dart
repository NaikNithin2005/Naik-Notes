import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:naik_notes/services/authentication/desktop_auth_service.dart';

void main() {
  group('DesktopAuthService RFC 7636 PKCE & OAuth Tests', () {
    late DesktopAuthService authService;

    setUp(() {
      authService = DesktopAuthService();
    });

    test('validates RFC 7636 Appendix B test vector for S256 code challenge', () {
      // RFC 7636 Appendix B official test vector
      const rfcVerifier = 'dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk';
      const expectedChallenge = 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM';

      final challenge = authService.generateCodeChallenge(rfcVerifier);

      expect(challenge, equals(expectedChallenge));
      // Must not contain base64 padding '='
      expect(challenge.contains('='), isFalse);
    });

    test('generates valid RFC 7636 code verifiers with unreserved characters', () {
      final verifier1 = authService.generateCodeVerifier();
      final verifier2 = authService.generateCodeVerifier();

      expect(verifier1.length, equals(64));
      expect(verifier2.length, equals(64));
      // Must be cryptographically random and distinct
      expect(verifier1, isNot(equals(verifier2)));

      // Verifier must only contain unreserved characters: [A-Z], [a-z], [0-9], "-", ".", "_", "~"
      final unreservedRegex = RegExp(r'^[a-zA-Z0-9\-._~]+$');
      expect(unreservedRegex.hasMatch(verifier1), isTrue);
      expect(unreservedRegex.hasMatch(verifier2), isTrue);
    });

    test('generates distinct CSRF state tokens of requested length', () {
      final state1 = authService.generateRandomString(24);
      final state2 = authService.generateRandomString(24);

      expect(state1.length, equals(24));
      expect(state2.length, equals(24));
      expect(state1, isNot(equals(state2)));
    });

    test('exchanges authorization code for tokens successfully via mock HTTP client', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), equals('https://oauth2.googleapis.com/token'));
        expect(request.method, equals('POST'));
        expect(request.headers['content-type'], contains('application/x-www-form-urlencoded'));

        final body = request.bodyFields;
        expect(body['grant_type'], equals('authorization_code'));
        expect(body['code'], equals('auth-code-12345'));
        expect(body['code_verifier'], equals('verifier-abcde'));
        expect(body['redirect_uri'], equals('http://127.0.0.1:8080/oauth2callback'));
        expect(body['client_id'], equals('client-id-xyz'));

        return http.Response(
          jsonEncode({
            'id_token': 'mock.jwt.id_token_header_payload_signature',
            'access_token': 'mock_access_token_123',
            'token_type': 'Bearer',
            'expires_in': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final desktopAuth = DesktopAuthService(httpClient: mockClient);

      final tokens = await desktopAuth.exchangeCodeForTokens(
        code: 'auth-code-12345',
        codeVerifier: 'verifier-abcde',
        redirectUri: 'http://127.0.0.1:8080/oauth2callback',
        clientId: 'client-id-xyz',
      );

      expect(tokens.idToken, equals('mock.jwt.id_token_header_payload_signature'));
      expect(tokens.accessToken, equals('mock_access_token_123'));
    });

    test('handles token exchange failure gracefully on HTTP 400', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': 'invalid_grant',
            'error_description': 'Code has expired or has already been used.',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final desktopAuth = DesktopAuthService(httpClient: mockClient);

      expect(
        () => desktopAuth.exchangeCodeForTokens(
          code: 'expired-code',
          codeVerifier: 'verifier-abcde',
          redirectUri: 'http://127.0.0.1:8080/oauth2callback',
          clientId: 'client-id-xyz',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws exception when Google response does not contain an id_token', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'access_token': 'only_access_token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final desktopAuth = DesktopAuthService(httpClient: mockClient);

      expect(
        () => desktopAuth.exchangeCodeForTokens(
          code: 'valid-code',
          codeVerifier: 'verifier-abcde',
          redirectUri: 'http://127.0.0.1:8080/oauth2callback',
          clientId: 'client-id-xyz',
        ),
        throwsA(
          predicate((e) => e.toString().contains('Google response did not contain an ID token')),
        ),
      );
    });

    test('resolves client IDs and desktop secret correctly with runtime decode and sanitization', () {
      expect(DesktopAuthService.effectiveDesktopClientId, isNotEmpty);
      expect(DesktopAuthService.effectiveDesktopClientId.endsWith('.apps.googleusercontent.com'), isTrue);
      expect(
        DesktopAuthService.effectiveDesktopClientId.contains('.apps.googleusercontent.com.apps.googleusercontent.com'),
        isFalse,
      );

      expect(DesktopAuthService.defaultClientId, isNotEmpty);
      expect(DesktopAuthService.defaultClientId.endsWith('.apps.googleusercontent.com'), isTrue);

      expect(DesktopAuthService.iosClientId, isNotEmpty);
      expect(DesktopAuthService.iosClientId.endsWith('.apps.googleusercontent.com'), isTrue);

      expect(DesktopAuthService.desktopClientSecret, isNotEmpty);
      expect(DesktopAuthService.desktopClientSecret.length, greaterThan(20));
    });
  });
}

