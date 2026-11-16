# Bug Fixes & Technical Repairs — Naik Notes

This document details the issues identified during the comprehensive audit and the technical fixes implemented across the Android, iOS, Windows, and Flutter codebase.

---

## 1. Native Launch & Splash Screen White Flash
* **Issue**: On cold app launch, Android and iOS devices briefly flashed a stark white screen before Flutter rendered the dark UI theme.
* **Root Cause**:
  * Android's `launch_background.xml` was set to `#FFFFFF` and `styles.xml` used `Theme.Light.NoTitleBar`.
  * iOS's `LaunchScreen.storyboard` had view background `(1, 1, 1, 1)` (pure white).
* **Fix**:
  * Created `android/app/src/main/res/values/colors.xml` with `<color name="splash_color">#121212</color>`.
  * Updated Android `launch_background.xml` (and `drawable-v21`) to use `@color/splash_color` with centered `@mipmap/ic_launcher`.
  * Updated `styles.xml` & `values-night/styles.xml` to inherit from `@android:style/Theme.Black.NoTitleBar` and set `android:windowBackground` to `@color/splash_color`.
  * Updated `LaunchScreen.storyboard` background color to `0.070588, 0.070588, 0.070588` (`#121212`).

---

## 2. Create Notebook Dialog Layout & Dynamic Color Contrast
* **Issue**:
  * In `CreateNotebookDialog`, notebook cover preview card had overlapping and rotated text labels with rigid constraints (`left: 24, right: 12` on a 140px card).
  * Color presets did not adapt their selection checkmark: white checkmarks on light yellow/cream covers were completely invisible.
* **Fix**:
  * Redesigned preview card (150x200) with a centered horizontal title plate (`top: 65, left: 28, right: 14`), max 3 lines, and Georgia typography.
  * Added dynamic luminance calculation using `ThemeData.estimateBrightnessForColor(color)`:
    * Light covers display a dark checkmark (`#1E293B`) with high contrast.
    * Dark covers display a crisp white checkmark (`#FFFFFF`).
  * Added accessible semantics and 48x48 logical pixel minimum touch constraints.

---

## 3. Reading Mode Page Transition Tearing & Bleed-Through
* **Issue**: In Reading Mode 3D page flip view (`reading_mode_page_flip_view.dart`), flipping between pages caused rotated geometry to bleed outside the viewport and show tearing edges.
* **Root Cause**:
  * `PageView.builder` elements lacked explicit `ValueKey` identifiers, leading to widget recycling confusion.
  * The 3D matrix transform lacked a boundary clipping box.
  * Transparent canvas layers allowed underlying viewport elements to bleed through.
* **Fix**:
  * Wrapped each page in `ClipRect` to prevent 3D rotation projection beyond the viewport.
  * Added `key: ValueKey('reading_page_${page.id}')` to ensure proper element lifecycle management.
  * Added a 100% opaque backing layer `Positioned.fill(child: ColoredBox(color: Color(0xFFFFFDF8)))` underneath the canvas.
  * Clamped rotation angles to `[-pi/4, pi/4]` to eliminate backface inversion tearing.

---

## 4. Authentication Screens Keyboard Navigation & 48x48 Hit Targets
* **Issue**:
  * Text fields on mobile had small hit areas and cramped padding.
  * Password toggle icons were smaller than the 48x48 pt accessibility guideline.
  * Pressing "Enter" on keyboard did not navigate to the next field or submit the form.
* **Fix**:
  * Applied `contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16)` and rounded borders (`borderRadius: 12`).
  * Added `BoxConstraints(minWidth: 48, minHeight: 48)` on all suffix icon buttons.
  * Configured `TextInputAction.next` on email/username fields and `TextInputAction.done` on password fields with `onFieldSubmitted` auto-login.

---

## 5. Synchronization Indicator Missing "Pending" State
* **Issue**: Sync badge in dashboard did not visually convey when changes were stored locally awaiting upload to Cloud Firestore.
* **Fix**:
  * Added `SyncUiStatus.pending` to sync domain model.
  * Updated `SyncStatusBadge` and `SyncDetailsDialog` to display all 5 states:
    1. **Synced**: Green cloud (`#10B981`)
    2. **Syncing**: Active circular progress spinner
    3. **Offline**: Grey cloud off
    4. **Sync Failed**: Red alert icon (`#EF4444`)
    5. **Pending Changes**: Amber upload cloud (`#F59E0B`) with queued mutation counter.

---

## 6. Drawing Toolbar WCAG Touch Accessibility
* **Issue**: Drawing toolbar icon buttons were 32x32 pt, violating touch accessibility standards for stylus and finger input.
* **Fix**:
  * Encapsulated every toolbar button in a `BoxConstraints(minWidth: 48, minHeight: 48)` touch container.
  * Added collapsible Primary vs. Secondary tool segregation with a dedicated toggle pill.

