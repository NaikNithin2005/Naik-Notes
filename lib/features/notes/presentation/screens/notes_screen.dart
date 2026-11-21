import 'package:flutter/material.dart';

import '../widgets/mobile_note_list_screen.dart';
import '../widgets/three_pane_desktop_layout.dart';
import '../widgets/two_pane_tablet_layout.dart';

/// Primary adaptive entry point for the Naik Notes rich-text note engine.
///
/// Uses [LayoutBuilder] to seamlessly switch between:
/// - Desktop / Large Tablet (> 1024px): 3-Pane (Notebooks + Notes + Active Editor)
/// - Tablet (600px - 1023px): 2-Pane (Collapsible Notes list + Editor)
/// - Mobile (< 600px): 1-Pane (Note list with Drawer; pushing dedicated MobileNoteEditorScreen)
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1024) {
          return const ThreePaneDesktopLayout();
        } else if (constraints.maxWidth >= 600) {
          return const TwoPaneTabletLayout();
        }
        return const MobileNoteListScreen();
      },
    );
  }
}

