# Feature Implementation Specifications — Naik Notes

This document provides technical design specifications for the core features implemented during the production upgrade of **Naik Notes**.

---

## 1. Interactive Welcome Notebook (`WelcomeNotebookService`)
* **File Location**: `lib/features/notebooks/data/welcome_notebook_service.dart`
* **Purpose**: Automatically onboard new users with an interactive, offline-first 9-page tutorial notebook featuring pre-rendered vector flourishes, guided activities, and sticky note callouts.
* **Duplicate Protection**:
  * Scans local SQLite library by owner ID (`welcome_notebook_$userId`) and title (`Welcome to Naik Notes`).
  * Prevents duplicate generation across multiple app restarts or profile switches.
* **The 9 Guided Tutorial Activities**:
  1. **Page 1 (College Ruled)**: Pen writing activity with pre-rendered welcoming calligraphic stroke.
  2. **Page 2 (College Ruled)**: Stroke customization: 3 sample lines of varying widths (thin 1.5pt emerald, medium 3.5pt indigo, bold 6.0pt crimson).
  3. **Page 3 (College Ruled)**: Highlighter & contrast: Translucent yellow highlighter overlapping dark handwritten notes to demonstrate ink blending.
  4. **Page 4 (Blank Paper)**: Vector & partial erasers: Colorful scribble for the user to practice erasing individual vector strokes.
  5. **Page 5 (Square Grid)**: Lasso selection & transform: Geometric box for practicing lasso loops, move, scale, duplicate, and recolor.
  6. **Page 6 (Dotted Paper)**: Page navigation: Guided instructions for the bottom scrubber and thumbnail sidebar.
  7. **Page 7 (Cornell Notes)**: Stationery templates: Overview of Cornell cue columns, summary zones, and template switching.
  8. **Page 8 (Blank Paper)**: Stylus & Palm Rejection: Infinite canvas pan, pinch-to-zoom (up to 500%), and palm rejection controls.
  9. **Page 9 (College Ruled)**: Export & Cloud Sync: Vector PDF compilation, PNG rasterization, and multi-device cloud synchronization.

---

## 2. Document & Page Export Suite (`PdfService` & `ExportNotebookDialog`)
* **File Locations**:
  * `lib/services/pdf/pdf_service.dart`
  * `lib/features/notebooks/presentation/widgets/export_notebook_dialog.dart`
* **Capabilities**:
  * **Vector Flattened PDF Export**:
    * Generates pure PDF vector objects from `Stroke` points with exact widths, cap styles, and colors.
    * Inverts Y-coordinates for the PDF coordinate space.
    * Flattens sticky notes and page backgrounds.
    * `exportSinglePagePdf(...)` & `exportPageRangePdf(...)`.
  * **High-DPI Canvas PNG Rasterization**:
    * Vector-to-raster renderer using Flutter's `dart:ui.PictureRecorder` and `Canvas`.
    * Configurable pixel ratio (default 2.5x, 300 DPI equivalent) for print-ready image snapshots.
  * **Export Scope Selection**:
    * "Entire Notebook" (all N pages).
    * "Current Page Only".
    * "Custom Page Range" (with parser supporting syntax like `1-3, 5, 7-9`).
  * **File System Persistence**:
    * Desktop (Windows/macOS/Linux): Native file dialog via `FilePicker.saveFile`.
    * Mobile (Android/iOS): Automatically writes to `getApplicationDocumentsDirectory()` with notification and path reporting.

---

## 3. Customizable Floating Toolbar
* **File Locations**:
  * `lib/features/canvas/data/toolbar_preferences.dart`
  * `lib/features/canvas/presentation/widgets/handwriting_toolbar.dart`
  * `lib/features/canvas/presentation/widgets/toolbar_customizer_dialog.dart`
* **Catalog of 19 Tools across 5 Categories**:
  * **Pens**: Fountain Pen, Ballpoint Pen, Pencil, Brush Pen.
  * **Brushes & Ink**: Marker, Highlighter, Calligraphy Pen, Technical Pen, Custom Artistic Brush, Fill Bucket.
  * **Editing**: Vector Eraser, Selection Lasso, Clear Page Ink.
  * **Shapes**: Geometric Shapes Library (27 shapes), Shape Snapping.
  * **Controls**: Style Customizer Pill, Undo / Redo, Palm Rejection, Stylus-Only Inking.
* **Layout Customization**:
  * Dock position: Top, Bottom, Left, Right.
  * Compact Mode toggle.
  * Individual tool visibility checkboxes with local persistence in `SharedPreferences`.

---

## 4. Reusable Empty States (`NaikEmptyState`)
* **File Location**: `lib/core/widgets/naik_empty_state.dart`
* **Capabilities**:
  * Standalone widget replacing boilerplate Column/Icon code across screens.
  * 7 factory constructors for Library, Folders, Search, Favorites, Recent, Sync, and Archive.
  * Full theme adaptation for Dark Mode and Reading Mode.
  * 48x48 logical pixels accessible action buttons.

