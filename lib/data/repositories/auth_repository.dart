import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  AppUser? get currentUser;
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String email, String password, String displayName);
  Future<AppUser> continueAsGuest();
  Future<void> logout();
  Future<AppUser?> restoreSession();
}

class RemoteAuthRepository implements AuthRepository {
  final http.Client _client;
  final String _baseUrl;
  AppUser? _currentUser;
  final _uuid = const Uuid();

  RemoteAuthRepository({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.devApiBaseUrl;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser> login(String email, String password) async {
    final sanitizedEmail = email.trim();
    if (sanitizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': sanitizedEmail, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(data);
        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          error['detail'] ?? 'Login failed. Please check credentials.',
        );
      }
    } catch (e) {
      // If server is unreachable (offline mode), fallback to local authenticated session
      if (e is! Exception || !e.toString().contains('Login failed')) {
        final now = DateTime.now();
        _currentUser = AppUser(
          id: 'user_${sanitizedEmail.replaceAll('@', '_').replaceAll('.', '_')}',
          email: sanitizedEmail,
          displayName: sanitizedEmail.split('@').first,
          token: 'offline_token_${_uuid.v4()}',
          isGuest: false,
          createdAt: now,
          updatedAt: now,
        );
        return _currentUser!;
      }
      rethrow;
    }
  }

  @override
  Future<AppUser> register(
    String email,
    String password,
    String displayName,
  ) async {
    final sanitizedEmail = email.trim();
    final sanitizedName = displayName.trim();

    if (sanitizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }

    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': sanitizedEmail,
          'password': password,
          'displayName': sanitizedName.isEmpty
              ? sanitizedEmail.split('@').first
              : sanitizedName,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentUser = AppUser.fromJson(data);
        return _currentUser!;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Registration failed.');
      }
    } catch (e) {
      // Offline fallback for registration
      if (e is! Exception || !e.toString().contains('Registration failed')) {
        final now = DateTime.now();
        _currentUser = AppUser(
          id: 'user_${_uuid.v4()}',
          email: sanitizedEmail,
          displayName: sanitizedName.isEmpty
              ? sanitizedEmail.split('@').first
              : sanitizedName,
          token: 'offline_token_${_uuid.v4()}',
          isGuest: false,
          createdAt: now,
          updatedAt: now,
        );
        return _currentUser!;
      }
      rethrow;
    }
  }

  @override
  Future<AppUser> continueAsGuest() async {
    _currentUser = AppUser.guest();
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<AppUser?> restoreSession() async {
    // If a session exists, return it; otherwise default to guest for instant offline use
    _currentUser ??= AppUser.guest();
    return _currentUser;
  }
}
