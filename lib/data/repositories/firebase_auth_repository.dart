import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

/// Production Firebase Authentication Repository for Naik Notes.
///
/// Implements Email/Password, Google Sign-In, Apple Sign-In, Phone/OTP,
/// registered device session tracking in Firestore, account deletion,
/// and explicit request timeouts to eliminate infinite loading loops.
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth? _customFirebaseAuth;
  final FirebaseFirestore? _customFirestore;
  final _uuid = const Uuid();

  AppUser? _currentUser;
  late final String _deviceId;

  FirebaseAuthRepository({
    fb.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    String? deviceId,
  }) : _customFirebaseAuth = firebaseAuth,
       _customFirestore = firestore,
       _deviceId = deviceId ?? 'dev_${const Uuid().v4().substring(0, 8)}' {
    _initCurrentUser();
  }

  fb.FirebaseAuth? get _firebaseAuth {
    if (_customFirebaseAuth != null) return _customFirebaseAuth;
    try {
      return fb.FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    if (_customFirestore != null) return _customFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  void _initCurrentUser() {
    try {
      final fbUser = _firebaseAuth?.currentUser;
      if (fbUser != null) {
        _currentUser = _mapFirebaseUser(fbUser);
      }
    } catch (_) {
      // In test / offline environments where Firebase instance is not ready
    }
  }

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges {
    try {
      final auth = _firebaseAuth;
      if (auth == null) return Stream.value(_currentUser);
      return auth.authStateChanges().map((fbUser) {
        if (fbUser == null) {
          _currentUser = null;
          return null;
        }
        _currentUser = _mapFirebaseUser(fbUser);
        return _currentUser;
      });
    } catch (_) {
      return Stream.value(_currentUser);
    }
  }

  AppUser _mapFirebaseUser(fb.User user) {
    final now = DateTime.now();
    return AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName:
          user.displayName ??
          (user.email != null && user.email!.contains('@')
              ? user.email!.split('@').first
              : (user.phoneNumber?.isNotEmpty == true
                    ? user.phoneNumber!
                    : 'Naik Writer')),
      photoUrl: user.photoURL,
      token: user.uid,
      isGuest: false,
      createdAt: user.metadata.creationTime ?? now,
      updatedAt: user.metadata.lastSignInTime ?? now,
    );
  }

  String _getPlatformName() {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iPad / Apple Device';
      if (Platform.isWindows) return 'Windows 10/11 PC';
      if (Platform.isMacOS) return 'macOS Workstation';
      if (Platform.isLinux) return 'Linux Workstation';
    } catch (_) {}
    return 'Desktop / Mobile Client';
  }

  /// Registers or updates device record in Cloud Firestore under `users/{uid}/devices/{deviceId}`
  Future<void> _registerDevice(String uid) async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(_deviceId)
          .set({
            'deviceId': _deviceId,
            'deviceName': _getPlatformName(),
            'platform': defaultTargetPlatform.name,
            'lastActiveAt': FieldValue.serverTimestamp(),
            'registrationStatus': 'active',
            'appVersion': '1.0.0',
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Device registration note: $e');
    }
  }

  /// Updates or creates the user profile document in Firestore under `users/{uid}`
  Future<void> _syncUserProfile(
    String uid,
    String email,
    String displayName, {
    String? photoUrl,
    String? phoneNumber,
  }) async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db
          .collection('users')
          .doc(uid)
          .set({
            'uid': uid,
            'email': email,
            'displayName': displayName,
            'photoUrl': photoUrl,
            'phoneNumber': phoneNumber,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('User profile sync note: $e');
    }
  }

  @override
  Future<AppUser> login(String email, String password) async {
    final sanitizedEmail = email.trim();
    if (sanitizedEmail.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required.');
    }

    final auth = _firebaseAuth;
    if (auth == null) {
      final appUser = AppUser(
        id: 'usr_${sanitizedEmail.hashCode}',
        email: sanitizedEmail,
        displayName: sanitizedEmail.split('@').first,
        token: 'local_token',
        isGuest: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _currentUser = appUser;
      return appUser;
    }

    try {
      final credential = await auth
          .signInWithEmailAndPassword(email: sanitizedEmail, password: password)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Authentication request timed out. Please try again.',
            ),
          );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Login failed. Please verify credentials.');
      }

      final appUser = _mapFirebaseUser(fbUser);
      _currentUser = appUser;

      await _registerDevice(appUser.id);
      await _syncUserProfile(appUser.id, appUser.email, appUser.displayName);

      return appUser;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } on TimeoutException catch (e) {
      throw Exception(
        e.message ?? 'Authentication timed out. Check your connection.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Authentication error: $e');
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

    final effectiveName = sanitizedName.isEmpty
        ? sanitizedEmail.split('@').first
        : sanitizedName;

    final auth = _firebaseAuth;
    if (auth == null) {
      final appUser = AppUser(
        id: 'usr_${sanitizedEmail.hashCode}',
        email: sanitizedEmail,
        displayName: effectiveName,
        token: 'local_token',
        isGuest: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _currentUser = appUser;
      return appUser;
    }

    try {
      final credential = await auth
          .createUserWithEmailAndPassword(
            email: sanitizedEmail,
            password: password,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException(
              'Registration timed out. Please try again.',
            ),
          );

      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('User registration failed.');
      }

      try {
        await fbUser.updateDisplayName(effectiveName);
      } catch (_) {}

      final appUser = AppUser(
        id: fbUser.uid,
        email: sanitizedEmail,
        displayName: effectiveName,
        token: fbUser.uid,
        isGuest: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _currentUser = appUser;

      await _syncUserProfile(appUser.id, appUser.email, appUser.displayName);
      await _registerDevice(appUser.id);

      return appUser;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Registration timed out.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Registration error: $e');
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    final auth = _firebaseAuth;
    if (auth == null) {
      final appUser = AppUser(
        id: 'google_${_uuid.v4().substring(0, 8)}',
        email: 'user.google@gmail.com',
        displayName: 'Google User',
        token: 'google_token',
        isGuest: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _currentUser = appUser;
      return appUser;
    }

    try {
      fb.UserCredential credential;

      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        // Native Google Play Services on Android / iOS
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          serverClientId:
              '437907946486-u57rove455sh9afj25hvf7nb4f3ngt5l.apps.googleusercontent.com',
        );

        final GoogleSignInAccount? googleAccount = await googleSignIn.signIn();
        if (googleAccount == null) {
          throw Exception('Google Sign-In was cancelled.');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleAccount.authentication;

        final fb.AuthCredential authCredential =
            fb.GoogleAuthProvider.credential(
              accessToken: googleAuth.accessToken,
              idToken: googleAuth.idToken,
            );

        credential = await auth
            .signInWithCredential(authCredential)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Google Sign-In timed out.'),
            );
      } else if (kIsWeb) {
        final fb.GoogleAuthProvider googleProvider = fb.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        credential = await auth
            .signInWithPopup(googleProvider)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Google Sign-In timed out.'),
            );
      } else {
        // Desktop platforms (Windows, macOS, Linux)
        final fb.GoogleAuthProvider googleProvider = fb.GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        credential = await auth
            .signInWithProvider(googleProvider)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Google Sign-In timed out.'),
            );
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Google Sign-In was cancelled.');
      }

      final appUser = _mapFirebaseUser(fbUser);
      _currentUser = appUser;

      await _registerDevice(appUser.id);
      await _syncUserProfile(
        appUser.id,
        appUser.email,
        appUser.displayName,
        photoUrl: appUser.photoUrl,
      );

      return appUser;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Google Sign-In timed out.');
    } catch (e) {
      if (e is Exception) {
        final msg = e.toString();
        if (msg.contains('ApiException: 10') ||
            msg.contains('12500') ||
            msg.contains('certificate hash')) {
          throw Exception(
            'Google Sign-In configuration required: Please add the SHA-1 and SHA-256 fingerprints to your Firebase Console under Project Settings > Your apps (com.naiknotes.app.naik_notes).\n'
            'SHA-1: BB:42:0F:07:F9:08:43:69:3D:54:93:1A:02:A8:09:9B:46:F8:66:E7\n'
            'SHA-256: 12:4B:88:AD:FC:BC:FD:40:46:6F:AE:12:97:27:4B:C7:14:05:E0:0A:93:1A:2D:A9:3F:44:56:A6:C7:72:ED:C7',
          );
        }
        rethrow;
      }
      throw Exception('Google Sign-In failed: $e');
    }
  }

  @override
  Future<AppUser> signInWithApple() async {
    final auth = _firebaseAuth;
    if (auth == null) {
      final appUser = AppUser(
        id: 'apple_${_uuid.v4().substring(0, 8)}',
        email: 'user.apple@icloud.com',
        displayName: 'Apple User',
        token: 'apple_token',
        isGuest: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _currentUser = appUser;
      return appUser;
    }

    // On Android and Windows, Apple Sign In requires Apple Services ID in Firebase Console.
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.windows)) {
      try {
        final appleProvider = fb.OAuthProvider('apple.com');
        appleProvider.addScope('email');
        appleProvider.addScope('name');

        final credential = await auth
            .signInWithProvider(appleProvider)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Apple Sign-In timed out.'),
            );

        final fbUser = credential.user;
        if (fbUser == null) {
          throw Exception('Apple Sign-In was cancelled.');
        }

        final appUser = _mapFirebaseUser(fbUser);
        _currentUser = appUser;

        await _registerDevice(appUser.id);
        await _syncUserProfile(
          appUser.id,
          appUser.email,
          appUser.displayName,
          photoUrl: appUser.photoUrl,
        );

        return appUser;
      } catch (e) {
        throw Exception(
          'Apple Sign-In is configured natively for iPadOS and Apple devices. On Android and Windows, please use Email or Google Sign-In.',
        );
      }
    }

    try {
      final appleProvider = fb.OAuthProvider('apple.com');
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      fb.UserCredential credential;
      if (kIsWeb) {
        credential = await auth
            .signInWithPopup(appleProvider)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Apple Sign-In timed out.'),
            );
      } else {
        credential = await auth
            .signInWithProvider(appleProvider)
            .timeout(
              const Duration(seconds: 45),
              onTimeout: () =>
                  throw TimeoutException('Apple Sign-In timed out.'),
            );
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Apple Sign-In was cancelled.');
      }

      final appUser = _mapFirebaseUser(fbUser);
      _currentUser = appUser;

      await _registerDevice(appUser.id);
      await _syncUserProfile(
        appUser.id,
        appUser.email,
        appUser.displayName,
        photoUrl: appUser.photoUrl,
      );

      return appUser;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'Apple Sign-In timed out.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Apple Sign-In failed: $e');
    }
  }

  @override
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(AppUser user)? onVerificationCompleted,
  }) async {
    final sanitizedPhone = phoneNumber.trim();
    if (sanitizedPhone.length < 8) {
      onError(
        'Please enter a valid phone number with country code (e.g. +1234567890).',
      );
      return;
    }

    final auth = _firebaseAuth;
    if (auth == null) {
      // Offline / Test mock fallback
      final mockId = 'mock_verif_${_uuid.v4().substring(0, 8)}';
      onCodeSent(mockId, 999999);
      return;
    }

    // Windows C++ SDK verification compatibility check
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      onError(
        'Phone SMS verification is supported natively on Android, iOS and Web. '
        'On Windows, please use Email, Google, or Apple sign-in.',
      );
      return;
    }

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: sanitizedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          try {
            final userCredential = await auth.signInWithCredential(credential);
            final fbUser = userCredential.user;
            if (fbUser != null) {
              final appUser = _mapFirebaseUser(fbUser);
              _currentUser = appUser;
              await _registerDevice(appUser.id);
              await _syncUserProfile(
                appUser.id,
                appUser.email,
                appUser.displayName,
              );
              onVerificationCompleted?.call(appUser);
            }
          } catch (_) {}
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          String mapped = _mapAuthError(e.code, e.message);
          if (e.message != null &&
              (e.message!.contains('SHA-1') ||
                  e.message!.contains('fingerprint') ||
                  e.message!.contains('Play Integrity') ||
                  e.code == 'missing-client-identifier' ||
                  e.code == 'app-not-authorized')) {
            mapped =
                'Phone Authentication configuration required:\n'
                '1. Go to Firebase Console > Project Settings > Your apps (com.naiknotes.app.naik_notes)\n'
                '2. Add SHA-1: BB:42:0F:07:F9:08:43:69:3D:54:93:1A:02:A8:09:9B:46:F8:66:E7\n'
                '3. Add SHA-256: 12:4B:88:AD:FC:BC:FD:40:46:6F:AE:12:97:27:4B:C7:14:05:E0:0A:93:1A:2D:A9:3F:44:56:A6:C7:72:ED:C7\n'
                '4. Ensure Phone provider is enabled in Firebase Authentication > Sign-in method.';
          }
          onError(mapped);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError('Failed to initiate phone verification: $e');
    }
  }

  @override
  Future<AppUser> verifyPhoneOtp(String verificationId, String smsCode) async {
    final sanitizedCode = smsCode.trim();
    if (sanitizedCode.length < 6) {
      throw Exception('Please enter a valid 6-digit SMS verification code.');
    }

    final auth = _firebaseAuth;
    if (auth == null) {
      final appUser = AppUser(
        id: 'phone_${_uuid.v4().substring(0, 8)}',
        email: '',
        displayName: 'Phone User',
        token: 'phone_token',
        isGuest: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _currentUser = appUser;
      return appUser;
    }

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: sanitizedCode,
      );

      final userCredential = await auth
          .signInWithCredential(credential)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('OTP verification timed out.'),
          );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Phone verification failed.');
      }

      final appUser = _mapFirebaseUser(fbUser);
      _currentUser = appUser;

      await _registerDevice(appUser.id);
      await _syncUserProfile(appUser.id, appUser.email, appUser.displayName);

      return appUser;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } on TimeoutException catch (e) {
      throw Exception(e.message ?? 'OTP verification timed out.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Phone verification error: $e');
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    final sanitized = email.trim();
    if (sanitized.isEmpty) {
      throw Exception('Please provide an email address.');
    }
    final auth = _firebaseAuth;
    if (auth == null) return;
    try {
      await auth
          .sendPasswordResetEmail(email: sanitized)
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () =>
                throw TimeoutException('Password reset request timed out.'),
          );
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e.code, e.message));
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  @override
  Future<void> deleteAccount() async {
    final auth = _firebaseAuth;
    final fbUser = auth?.currentUser;
    if (fbUser != null) {
      final uid = fbUser.uid;
      // Delete user data from Firestore
      try {
        await _firestore?.collection('users').doc(uid).delete();
      } catch (_) {}

      // Delete Firebase Auth account
      await fbUser.delete().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Account deletion timed out.'),
      );
    }
    _currentUser = null;
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth?.signOut().timeout(const Duration(seconds: 10));
    } catch (_) {}
    _currentUser = null;
  }

  @override
  Future<AppUser?> restoreSession() async {
    try {
      final fbUser = _firebaseAuth?.currentUser;
      if (fbUser != null) {
        _currentUser = _mapFirebaseUser(fbUser);
        await _registerDevice(_currentUser!.id);
        return _currentUser;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getRegisteredDevices(String uid) async {
    final db = _firestore;
    if (db == null) {
      return [
        {
          'deviceId': _deviceId,
          'deviceName': _getPlatformName(),
          'platform': defaultTargetPlatform.name,
          'lastActiveAt': DateTime.now().toIso8601String(),
          'registrationStatus': 'active',
          'isCurrent': true,
        },
      ];
    }

    try {
      final snapshot = await db
          .collection('users')
          .doc(uid)
          .collection('devices')
          .get()
          .timeout(const Duration(seconds: 10));

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final devId = data['deviceId'] as String? ?? doc.id;
        final timestamp = data['lastActiveAt'];
        String formattedTime = 'Recently active';
        if (timestamp is Timestamp) {
          formattedTime = timestamp
              .toDate()
              .toLocal()
              .toString()
              .split('.')
              .first;
        }

        return {
          'deviceId': devId,
          'deviceName': data['deviceName'] as String? ?? 'Client Device',
          'platform': data['platform'] as String? ?? 'Device',
          'lastActiveAt': formattedTime,
          'registrationStatus':
              data['registrationStatus'] as String? ?? 'active',
          'isCurrent': devId == _deviceId,
        };
      }).toList();
    } catch (e) {
      return [
        {
          'deviceId': _deviceId,
          'deviceName': _getPlatformName(),
          'platform': defaultTargetPlatform.name,
          'lastActiveAt': 'Active now',
          'registrationStatus': 'active',
          'isCurrent': true,
        },
      ];
    }
  }

  @override
  Future<void> removeRegisteredDevice(String uid, String deviceId) async {
    final db = _firestore;
    if (db == null) return;
    try {
      await db
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .delete()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Error removing device $deviceId: $e');
    }
  }

  String _mapAuthError(String code, String? message) {
    switch (code) {
      case 'user-not-found':
        return 'No account exists for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email address.';
      case 'invalid-email':
        return 'The email address format is invalid.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'The SMS verification code entered is incorrect or expired.';
      case 'invalid-verification-id':
        return 'Invalid verification session. Please request a new code.';
      case 'app-not-authorized':
      case 'missing-client-identifier':
        return 'App certificate verification required. Ensure SHA-1 and SHA-256 fingerprints are added in Firebase Console.';
      case 'quota-exceeded':
        return 'SMS quota exceeded for this Firebase project. Please try again later or use Email/Google sign-in.';
      case 'session-expired':
        return 'The authentication session has expired. Please try again.';
      default:
        return message ?? 'Authentication operation failed.';
    }
  }
}
