# iPadOS Bug Audit & Diagnostic Report — Naik Notes

**Target Platform:** iPadOS 16.0 – 18.x (iPad, iPad Air, iPad Pro, iPad Mini)  
**Cross-Platform Targets:** Android Tablets, Windows Desktop  
**Date:** November 22, 2026  
**Auditor:** Senior Flutter iPadOS Engineer, Native iOS Specialist & Systems Architect  
**Status:** Completed Diagnostic Audit  

---

## 1. Executive Summary

A comprehensive forensic audit of the **Naik Notes** codebase was conducted to diagnose, isolate, and document the root causes of six critical system failures on iPadOS:
1. **Navigation Failures:** Inability or erratic behavior when routing to Settings, User Account/Profile, Backup & Restore, History, Reading Mode, Home (Dashboard), and Search.
2. **Notebook Loading Failures:** Indefinite spinning loaders (`CircularProgressIndicator`) when opening notebooks, with the writing canvas failing to load or render.
3. **Writing Board & Canvas Failures:** Canvas lifecycle, page boundary calculations, and document rendering stalling on page initialization.
4. **Apple Pencil & Stylus Integration:** Apple Pencil input working erratically, gesture collisions freezing surrounding UI controls (AppBar, Toolbar, NavigationRail), and native `UIPencilInteraction` channels disconnected in `SceneDelegate`.
5. **Responsive Layout & Orientation Problems:** Overcrowded AppBar action items (14+ buttons) overflowing viewports under 1100px (standard iPad portrait and split-view modes), breaking hit-testing on controls.
6. **Feedback System Failures:** Absence of any feedback submission model, service, or interactive UI dialog/screen.

The audit established that these issues stem from architectural disconnects between native iOS lifecycle events, Flutter gesture arena arbitration, unhandled asynchronous state transitions in Riverpod, and malformed navigation parameters.

---

## 2. Forensic Breakdown of Identified Issues

### 2.1 Notebook Loading & Infinite Spinners (Issue 2 & 3)

#### Observed Symptoms
Opening a notebook from the dashboard or via deep link results in an indefinite progress spinner (`Loading notebook...` or an empty white canvas with a center spinner). The writing canvas never initializes, and the user is trapped unless they tap the back arrow.

#### Root Cause Analysis
1. **Missing Initial Page Record on Notebook Creation:**
   In [lib/features/notebooks/data/notebook_provider.dart](file:///d:/WORKS/Naik%20Notes/lib/features/notebooks/data/notebook_provider.dart), `NotebooksNotifier.addNotebook` persisted a record to `notebooksTable` with `pageCount: 1`, but **did not create or persist Page 1** to `pagesTable` in Drift SQLite.
2. **Asynchronous Race & Unhandled Missing State in View Screen:**
   In [lib/features/notebooks/presentation/screens/notebook_view_screen.dart](file:///d:/WORKS/Naik%20Notes/lib/features/notebooks/presentation/screens/notebook_view_screen.dart):
   ```dart
   final notebooks = ref.watch(notebooksProvider);
   final notebook = notebooks.where((nb) => nb.id == widget.notebookId).firstOrNull;
   if (notebook == null) {
     return Scaffold(body: Center(child: CircularProgressIndicator()));
   }
   ```
   If `notebooksProvider` had not yet completed its initial SQLite stream emission, or if the user navigated directly via URL, `notebook` evaluated to `null`. The screen had no local fallback query (`notebookRepository.getNotebookById(...)`) and no timeout or error state, holding the user in an infinite spinner.
3. **Indefinite Spinner on Empty Page Set:**
   Inside `build()`:
   ```dart
   Expanded(
     child: activePage == null
         ? const Center(child: CircularProgressIndicator())
         : ...
   )
   ```
   If `notebookPagesProvider.loadPages` encountered an empty page set or delayed foreign key resolution, `activePage` remained `null` with no error recovery or retry action.
4. **Stale Page Index Retention:**
   `currentPageIndexProvider` was not reset to 1 upon opening a new notebook. If a previous notebook was navigated to page 15, opening a single-page notebook initially queried page 15, resulting in out-of-bounds page access.

---

### 2.2 Apple Pencil Native Disconnect & Surrounding Controls Freeze (Issue 4)

#### Observed Symptoms
Apple Pencil draws strokes intermittently, but touching toolbar buttons, AppBar icons, or navigating tabs freezes or fails to respond while the pencil or hand rests on the iPad display. Apple Pencil double-tap and squeeze gestures do not fire.

#### Root Cause Analysis
1. **SceneDelegate Native Channel Disconnection:**
   In [ios/Runner/AppDelegate.swift](file:///d:/WORKS/Naik%20Notes/ios/Runner/AppDelegate.swift):
   ```swift
   override func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
   ) -> Bool {
     let controller = window?.rootViewController as? FlutterViewController
     if let flutterViewController = controller {
       setupApplePencilChannels(controller: flutterViewController)
     }
     return super.application(application, didFinishLaunchingWithOptions: launchOptions)
   }
   ```
   The application defines `UIApplicationSceneManifest` in `Info.plist`, which routes UI lifecycle through `SceneDelegate.swift`. In modern iOS/iPadOS, `window` on `AppDelegate` is `nil` during `didFinishLaunchingWithOptions`. Consequently, `setupApplePencilChannels` was **never invoked**, the `naik_notes/apple_pencil` platform channels were never registered, and native `UIPencilInteraction` was never attached to the view controller.
2. **Missing iOS 17.5+ Squeeze and Tap Delegates:**
   `AppDelegate` implemented the legacy `pencilInteractionDidTap(_:)` method, which is deprecated in iOS 17.5+, and lacked `pencilInteraction(_:didReceiveTap:)` and `pencilInteraction(_:didReceiveSqueeze:)` for Apple Pencil Pro.
3. **Flawed Multi-Touch Gesture Arbitration:**
   In [lib/features/canvas/presentation/widgets/handwriting_canvas.dart](file:///d:/WORKS/Naik%20Notes/lib/features/canvas/presentation/widgets/handwriting_canvas.dart):
   ```dart
   _activePointerIds.add(event.pointer);
   if (_activePointerIds.length > 1) {
     _isMultiTouchActive = true;
     _activeStroke = null;
     return;
   }
   ```
   When an artist rests their palm on the glass while inking with the Apple Pencil, iOS emits a `touch` event for the palm and a `stylus` event for the pencil tip. The canvas logic treated any 2+ pointers as a multi-touch pinch-to-zoom gesture regardless of whether one was a stylus and the other a rejected palm touch. This caused `_isMultiTouchActive` to trigger continuously, aborting strokes, while holding the inking pointer lock and starving surrounding UI buttons of touch events.

---

### 2.3 Navigation & Routing Inconsistencies (Issue 1)

#### Observed Symptoms
Certain buttons fail to navigate or pass broken route parameters:
- Opening imported PDF notebooks results in a blank screen.
- Notes History items are not interactive.
- Returning from `NotebookViewScreen` fails when triggered by native iPad edge-swipe gestures.
- Account settings in `SettingsScreen` lacks clear route navigation to the dedicated `ProfileScreen`.

#### Root Cause Analysis
1. **Malformed Route String in PDF Import:**
   In [lib/features/dashboard/presentation/screens/dashboard_screen.dart](file:///d:/WORKS/Naik%20Notes/lib/features/dashboard/presentation/screens/dashboard_screen.dart#L269):
   ```dart
   context.go('${RouteNames.notebookView}?id=${newNotebook.id}');
   ```
   `RouteNames.notebookView` is defined as `'/notebook/:id'`. Passing `?id=...` constructed `/notebook/:id?id=<guid>`, matching parameter `:id` literally as `':id'` instead of the actual notebook GUID.
2. **Non-Interactive History Sheet:**
   In [lib/features/history/presentation/widgets/notes_history_sheet.dart](file:///d:/WORKS/Naik%20Notes/lib/features/history/presentation/widgets/notes_history_sheet.dart#L330-L380), history cards were rendered within static `Container` widgets with no `InkWell` or navigation callback to open the referenced note.
3. **Absence of `PopScope` Protection in Notebook Screen:**
   `NotebookViewScreen` did not implement a `PopScope`. On iPadOS with trackpad/gesture navigation, swiping back attempted to pop the root navigator, leaving the app in a desynchronized or blank state.

---

### 2.4 Responsive iPad Layout & AppBar Overflow (Issue 5)

#### Observed Symptoms
In iPad portrait mode (768px, 834px) or Split View (1/2 or 1/3 screen), the top action bar in `NotebookViewScreen` clips, overflows, and causes hit-test misses on essential tools.

#### Root Cause Analysis
`NotebookViewScreen` checked `if (context.isCompact)` (where `isCompact` is `< 600px`). When screen width was between 600px and 1100px (which covers iPad Mini, iPad 10.9", and iPad Pro in portrait):
- It rendered 14 individual `IconButton` widgets plus Title, leading back button, and dividers in a single non-scrollable `AppBar.actions` row.
- The minimum horizontal width required exceeded 920px, causing visual overflow and pushing buttons off-screen or making them unresponsive.

---

### 2.5 Complete Absence of Feedback Feature (Issue 6)

#### Observed Symptoms
User feedback submission mechanism is non-existent. There is no route, UI screen, or backend synchronization handler for user feedback.

#### Root Cause Analysis
The project specification required user feedback handling, but no files in `lib/features/feedback/` existed, and no menu item in `SettingsScreen` or `AppShell` provided entry into feedback submission.

---

## 3. Targeted Repair Plan

1. **Phase 2 — Navigation & Routing:**
   - Fix PDF route construction to use `RouteNames.notebookPath(newNotebook.id)`.
   - Add `InkWell` with direct navigation in `NotesHistorySheet`.
   - Wrap `NotebookViewScreen` in `PopScope` to guarantee safe navigation back to Library.
   - Add direct navigation link from `SettingsScreen` to `ProfileScreen`.
2. **Phase 3 & 4 — Notebook Loading & Writing Board:**
   - In `addNotebook`, immediately insert Page 1 via `pageRepository.ensurePagesExist`.
   - Implement resilient loading state machine in `NotebookViewScreen` with local database fallback and clean Error/Retry UI (eliminating infinite spinners).
   - Reset `currentPageIndexProvider` to 1 on `initState`.
3. **Phase 5 — Apple Pencil & Stylus Integration:**
   - Wire `SceneDelegate.swift` to invoke `setupApplePencilChannels(controller:)` upon `UIWindowScene` connection.
   - Implement iOS 17.5+ squeeze and tap delegate methods in `AppDelegate.swift`.
   - Update `HandwritingCanvas` pointer tracking: isolate stylus pointers from touch pointers; ignore palm touch from canceling stylus strokes.
4. **Phase 6 — Responsive iPad Layout:**
   - Adaptive AppBar in `NotebookViewScreen`: collapse secondary actions into a neat overflow menu whenever width < 1100px.
5. **Phase 7 — Feedback & Account:**
   - Implement `FeedbackService`, `FeedbackDialog` / `FeedbackScreen`, and register `/feedback` route.
   - Add "Edit Display Name" dialog in `ProfileScreen`.
6. **Phase 10 — Automated Test Verification:**
   - Implement comprehensive tests for Workflows A through L.

