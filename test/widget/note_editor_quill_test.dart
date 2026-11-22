import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/models/user_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/data/repositories/note_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/notes/data/note_provider.dart';
import 'package:naik_notes/features/notes/presentation/widgets/note_editor_view.dart';

class _MockAuthRepo implements AuthRepository {
  final AppUser _user = AppUser(
    id: 'test_uid',
    email: 'test@naiknotes.com',
    displayName: 'Test User',
    token: 'token',
    isGuest: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  @override
  AppUser? get currentUser => _user;
  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_user);
  @override
  Future<AppUser> updateDisplayName(String newDisplayName) async => _user.copyWith(displayName: newDisplayName);
  @override
  Future<AppUser> login(String email, String password) async => _user;
  @override
  Future<AppUser> register(String email, String password, String displayName, {String? confirmPassword}) async => _user;
  @override
  Future<AppUser> signInWithGoogle({bool promptAccountSelection = true}) async => _user;
  @override
  Future<AppUser> signInWithApple() async => _user;
  @override
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(String errorMessage) onError,
    void Function(AppUser user)? onVerificationCompleted,
  }) async => onCodeSent('id', null);
  @override
  Future<AppUser> verifyPhoneOtp(String verificationId, String smsCode) async => _user;
  @override
  Future<void> logout() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  Future<List<Map<String, dynamic>>> getRegisteredDevices(String uid) async => [];
  @override
  Future<void> removeRegisteredDevice(String uid, String deviceId) async {}
  @override
  Future<AppUser?> restoreSession() async => _user;
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<String> verifyPasswordResetCode(String code) async => 'test@naiknotes.com';
  @override
  Future<void> confirmPasswordReset({required String code, required String newPassword}) async {}
  @override
  Future<void> sendEmailVerification() async {}
}

void main() {
  late AppDatabase db;
  late Note testNote;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    testNote = Note(
      id: 'quill_note_1',
      ownerId: 'test_uid',
      notebookId: 'nb_1',
      title: 'Rich Text Architecture',
      contentDelta: jsonEncode([
        {'insert': 'Phase 2 Editor implementation\n'}
      ]),
      plainText: 'Phase 2 Editor implementation\n',
      preview: 'Phase 2 Editor implementation',
      tags: ['architecture', 'quill'],
      isPinned: false,
      isFavorite: false,
      isArchived: false,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  Widget createWidget({required bool isMobile}) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
        appDatabaseProvider.overrideWithValue(db),
        noteRepositoryProvider.overrideWithValue(DriftNoteRepository(db)),
        selectedNoteProvider.overrideWith(() => _PreloadedSelectedNoteNotifier(testNote)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          FlutterQuillLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: FlutterQuillLocalizations.supportedLocales,
        home: Scaffold(
          body: NoteEditorView(
            note: testNote,
            isMobile: isMobile,
          ),
        ),
      ),
    );
  }

  group('NoteEditorView flutter_quill Integration Tests', () {
    testWidgets('Renders Title, Quill Editor, Tags, and Toolbar on Desktop/iPad',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(isMobile: false));
      await tester.pump();

      // Title field is populated
      expect(find.text('Rich Text Architecture'), findsOneWidget);

      // QuillEditor is present
      expect(find.byType(QuillEditor), findsOneWidget);

      // Tags are rendered
      expect(find.text('#architecture'), findsOneWidget);
      expect(find.text('#quill'), findsOneWidget);

      // Word count / character count footer is present
      expect(find.textContaining('words'), findsOneWidget);
      expect(find.textContaining('chars'), findsOneWidget);

      // Status badge (Last modified / Saved) is visible
      expect(find.textContaining('Last modified'), findsOneWidget);

      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Changing title updates text and triggers reactive update',
        (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createWidget(isMobile: false));
      await tester.pump();

      final titleFinder = find.byType(TextField).first;
      await tester.enterText(titleFinder, 'Updated Sprint Goals');
      await tester.pump();

      expect(find.text('Updated Sprint Goals'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}

class _PreloadedSelectedNoteNotifier extends SelectedNoteNotifier {
  final Note _initial;
  _PreloadedSelectedNoteNotifier(this._initial);
  @override
  Note? build() => _initial;
}
