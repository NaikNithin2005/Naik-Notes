import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/data/local/app_database.dart';
import 'package:naik_notes/data/local/database_provider.dart';
import 'package:naik_notes/data/models/note_model.dart';
import 'package:naik_notes/data/models/notebook_model.dart';
import 'package:naik_notes/data/models/user_model.dart';
import 'package:naik_notes/data/repositories/auth_repository.dart';
import 'package:naik_notes/data/repositories/note_repository.dart';
import 'package:naik_notes/data/repositories/notebook_repository.dart';
import 'package:naik_notes/features/authentication/data/auth_provider.dart';
import 'package:naik_notes/features/notebooks/data/notebook_provider.dart';
import 'package:naik_notes/features/notes/data/note_provider.dart';
import 'package:naik_notes/features/notes/presentation/screens/notes_screen.dart';
import 'package:naik_notes/features/notes/presentation/widgets/mobile_note_list_screen.dart';
import 'package:naik_notes/features/notes/presentation/widgets/note_list_pane.dart';
import 'package:naik_notes/features/notes/presentation/widgets/notebook_sidebar.dart';
import 'package:naik_notes/features/notes/presentation/widgets/three_pane_desktop_layout.dart';
import 'package:naik_notes/features/notes/presentation/widgets/two_pane_tablet_layout.dart';

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

Widget _buildTestApp({
  required Size screenSize,
  required List<Note> testNotes,
  required List<Notebook> testNotebooks,
  required AppDatabase db,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_MockAuthRepo()),
      appDatabaseProvider.overrideWithValue(db),
      noteRepositoryProvider.overrideWithValue(DriftNoteRepository(db)),
      notebookRepositoryProvider.overrideWithValue(DriftNotebookRepository(db)),
      notesProvider.overrideWith(() => _PreloadedNotesNotifier(testNotes)),
      notebooksProvider.overrideWith(() => _PreloadedNotebooksNotifier(testNotebooks)),
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
      home: MediaQuery(
        data: MediaQueryData(size: screenSize),
        child: const Scaffold(
          body: NotesScreen(),
        ),
      ),
    ),
  );
}

class _PreloadedNotesNotifier extends NotesNotifier {
  final List<Note> _initial;
  _PreloadedNotesNotifier(this._initial);
  @override
  List<Note> build() => _initial;
}

class _PreloadedNotebooksNotifier extends NotebooksNotifier {
  final List<Notebook> _initial;
  _PreloadedNotebooksNotifier(this._initial);
  @override
  List<Notebook> build() => _initial;
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  final testNotebooks = [
    Notebook(
      id: 'nb_1',
      ownerId: 'test_uid',
      title: 'Work Notes',
      coverId: 'c1',
      coverColorHex: '#1E2A38',
      paperTemplateId: 't1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  final testNotes = [
    Note.createBlank(
      ownerId: 'test_uid',
      notebookId: 'nb_1',
      title: 'First Architecture Note',
      tags: ['flutter', 'architecture'],
    ),
    Note.createBlank(
      ownerId: 'test_uid',
      notebookId: 'nb_1',
      title: 'Second Design Note',
      tags: ['ui'],
    ),
  ];

  group('Adaptive Multi-Platform Responsive Layout Tests', () {
    testWidgets(
        'Screen width < 600px renders Mobile 1-Pane layout with drawer and FAB',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(
        screenSize: const Size(390, 844),
        testNotes: testNotes,
        testNotebooks: testNotebooks,
        db: db,
      ));
      await tester.pump();

      // Mobile 1-Pane should be present
      expect(find.byType(MobileNoteListScreen), findsOneWidget);
      expect(find.byType(TwoPaneTabletLayout), findsNothing);
      expect(find.byType(ThreePaneDesktopLayout), findsNothing);

      // Search bar and Note items are visible
      expect(find.byType(NoteListPane), findsOneWidget);
      expect(find.text('First Architecture Note'), findsOneWidget);
      expect(find.text('Second Design Note'), findsOneWidget);

      // Mobile FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Zero RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Screen width 600px - 1023px renders Tablet 2-Pane layout with toggle',
        (tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(
        screenSize: const Size(768, 1024),
        testNotes: testNotes,
        testNotebooks: testNotebooks,
        db: db,
      ));
      await tester.pump();

      // Tablet 2-Pane should be present
      expect(find.byType(TwoPaneTabletLayout), findsOneWidget);
      expect(find.byType(MobileNoteListScreen), findsNothing);
      expect(find.byType(ThreePaneDesktopLayout), findsNothing);

      // NoteListPane on the left
      expect(find.byType(NoteListPane), findsOneWidget);
      expect(find.text('First Architecture Note'), findsOneWidget);

      // Zero RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Screen width >= 1024px renders Desktop 3-Pane layout with Sidebar, List & Editor',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp(
        screenSize: const Size(1280, 800),
        testNotes: testNotes,
        testNotebooks: testNotebooks,
        db: db,
      ));
      await tester.pump();

      // Desktop 3-Pane should be present
      expect(find.byType(ThreePaneDesktopLayout), findsOneWidget);
      expect(find.byType(TwoPaneTabletLayout), findsNothing);
      expect(find.byType(MobileNoteListScreen), findsNothing);

      // Left pane: NotebookSidebar
      expect(find.byType(NotebookSidebar), findsOneWidget);

      // Middle pane: NoteListPane
      expect(find.byType(NoteListPane), findsOneWidget);
      expect(find.text('First Architecture Note'), findsOneWidget);

      // Right pane: Placeholder prompt "Select a Note"
      expect(find.text('Select a Note'), findsOneWidget);

      // Zero RenderFlex overflow
      expect(tester.takeException(), isNull);
    });
  });
}
