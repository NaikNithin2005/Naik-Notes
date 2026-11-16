# UI / UX Refinements & Design System — Naik Notes

This document provides a comprehensive overview of the design system, visual typography, color palette, and interface refinements implemented in **Naik Notes**.

---

## 1. Design System & Theme Foundations

Naik Notes features two primary visual modes tuned for focused creative work and prolonged reading comfort:

### 1.1 Dark Creative Mode (Primary)
- **Background**: `#121212` (True deep surface for OLED efficiency and eye relaxation)
- **Surface Elevation 1**: `#1E1E1E` (Cards, sidebars, sheets)
- **Surface Elevation 2**: `#252525` (Dialogs, toolbars, popovers)
- **Primary Accent**: `#0284C7` (Sky blue, high vibrancy)
- **Secondary Accent**: `#10B981` (Emerald green for success, bookmarks, and sync)
- **Text High Emphasis**: `#F8FAFC` (Luminance ratio > 14:1)
- **Text Medium Emphasis**: `#94A3B8` (Luminance ratio > 7:1)

### 1.2 Reading Comfort Mode (Warm Stationery Paper)
- **Canvas Base**: `#F3EEDC` (Warm parchment tone inspired by archival paper)
- **Page Background**: `#FFFDF8` (Soft cream white)
- **Text & Stroke Contrast**: `#1C1917` (Warm charcoal black)
- **Page Flip Shadow**: Gentle ambient occlusion along the binding spine

---

## 2. Notebook Cover & Stationery Aesthetics
- Inspired by handcrafted archival notebooks (Moleskine, Leuchtturm1917).
- Each notebook in the library displays a realistic textured cover card with:
  - Embossed left spine margin (width: 14pt).
  - Centered horizontal title plate with Georgia serif typography and dual-tone border.
  - Dynamic contrast detection: Automatically computes luminance to ensure white text and plates on dark leather, and dark charcoal plates on light pastel covers.
  - Contextual options menu: Rename, Duplicate, Move to Folder, Archive, Change Cover Image, Export as PDF, and Delete.

---

## 3. Floating & Collapsible Drawing Toolbar
- **Dock Positioning**: Supports docking to Top, Bottom, Left, or Right edge based on user preference.
- **Primary vs. Secondary Segmentation**:
  - **Primary Tools**: Fountain Pen, Ballpoint Pen, Pencil, Brush Pen, Highlighter, Quick Customizer Pill, Vector Eraser, Lasso Selection, Undo / Redo.
  - **Secondary Tools**: Marker, Calligraphy Pen, Technical Pen, Custom Brush, Fill Bucket, Shapes Library, Snapping, Clear Page, Palm Rejection, Stylus-Only Inking, and Toolbar Customizer.
- **Collapsible Toggle Pill**: A sleek pill button (`More` / `Less`) allows users to collapse the toolbar to essential writing tools on smaller screens or expand it on demand.
- **Touch Target Accessibility**: Every single icon and tool button provides a minimum **48x48 logical pixels** hit area, conforming to WCAG 2.1 Level AA touch criteria.

---

## 4. Reusable Contextual Empty States (`NaikEmptyState`)
Unified empty state component across the entire app with branded iconography, clear descriptions, and 48x48 action triggers:
1. `NaikEmptyState.notebooks()`: Empty library state with "Create Notebook" action.
2. `NaikEmptyState.folder()`: Contextual empty folder state with "Add Notebook to Folder".
3. `NaikEmptyState.search()`: Search with no matches, with "Clear Search" trigger.
4. `NaikEmptyState.favorites()`: Empty starred notebooks view with "Browse Library" trigger.
5. `NaikEmptyState.recent()`: Empty recent notebooks view.
6. `NaikEmptyState.syncHistory()`: Clean synchronization state with "Sync Now".
7. `NaikEmptyState.archive()`: Clean archive state for stored notebooks.

---

## 5. Export Dialog (`ExportNotebookDialog`)
- Accessible modal dialog for exporting notes to:
  - **Vector Flattened PDF** (`.pdf`)
  - **High-Resolution Raster PNG** (`.png`)
- Page selection options:
  - Entire Notebook
  - Current Page Only
  - Custom Page Range (e.g. `1-3, 5`)
- Customization toggles:
  - Include paper template background & grid lines
  - Include sticky note annotations
- File system persistence via `FilePicker.saveFile` on desktop and app documents storage on mobile.

