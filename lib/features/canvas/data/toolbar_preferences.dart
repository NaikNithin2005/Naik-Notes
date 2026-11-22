import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Position where the toolbar docks on the canvas screen.
enum ToolbarDockPosition {
  top('Top Dock', Icons.vertical_align_top_rounded),
  bottom('Bottom Dock', Icons.vertical_align_bottom_rounded),
  left('Left Dock', Icons.align_horizontal_left_rounded),
  right('Right Dock', Icons.align_horizontal_right_rounded);

  final String label;
  final IconData icon;

  const ToolbarDockPosition(this.label, this.icon);

  static ToolbarDockPosition fromString(String? val) {
    switch (val) {
      case 'bottom':
        return ToolbarDockPosition.bottom;
      case 'left':
        return ToolbarDockPosition.left;
      case 'right':
        return ToolbarDockPosition.right;
      default:
        return ToolbarDockPosition.top;
    }
  }
}

/// Metadata description for each configurable toolbar item.
class ToolbarItemDef {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final String description;

  const ToolbarItemDef({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.description,
  });
}

/// Master catalog of all tools that can be configured on the toolbar.
class ToolbarCatalog {
  static const List<ToolbarItemDef> allTools = [
    // 1. Writing Tools Group
    ToolbarItemDef(
      id: 'fountainPen',
      name: 'Fountain Pen',
      category: 'Writing Tools',
      icon: Icons.edit,
      description: 'Calligraphic stroke with velocity thinning',
    ),
    ToolbarItemDef(
      id: 'ballpointPen',
      name: 'Ballpoint Pen',
      category: 'Writing Tools',
      icon: Icons.border_color,
      description: 'Consistent uniform monoline ballpoint ink',
    ),
    ToolbarItemDef(
      id: 'pencil',
      name: 'Pencil',
      category: 'Writing Tools',
      icon: Icons.mode_edit_outline,
      description: 'Textured graphite pencil with pressure response',
    ),
    ToolbarItemDef(
      id: 'brushPen',
      name: 'Brush Pen',
      category: 'Writing Tools',
      icon: Icons.brush,
      description: 'Organic expressive artistic brush stroke',
    ),
    ToolbarItemDef(
      id: 'highlighter',
      name: 'Highlighter',
      category: 'Writing Tools',
      icon: Icons.highlight,
      description: 'Semi-transparent wide stroke that preserves text below',
    ),
    ToolbarItemDef(
      id: 'marker',
      name: 'Marker',
      category: 'Writing Tools',
      icon: Icons.draw,
      description: 'Bold solid chisel marker',
    ),
    ToolbarItemDef(
      id: 'calligraphyPen',
      name: 'Calligraphy Pen',
      category: 'Writing Tools',
      icon: Icons.brush_outlined,
      description: '45-degree angle chisel calligraphy pen',
    ),
    ToolbarItemDef(
      id: 'technicalPen',
      name: 'Technical Pen',
      category: 'Writing Tools',
      icon: Icons.architecture_rounded,
      description: 'Precision draftsman technical pen with zero jitter',
    ),
    ToolbarItemDef(
      id: 'customBrush',
      name: 'Artistic Brush',
      category: 'Writing Tools',
      icon: Icons.auto_fix_high_rounded,
      description: 'Multi-bristle painterly brush with texture',
    ),

    // 2. Editing Tools Group
    ToolbarItemDef(
      id: 'eraser',
      name: 'Eraser',
      category: 'Editing Tools',
      icon: Icons.cleaning_services_outlined,
      description: 'Stroke, partial, and object eraser',
    ),
    ToolbarItemDef(
      id: 'lasso',
      name: 'Selection / Lasso',
      category: 'Editing Tools',
      icon: Icons.gesture,
      description: 'Freehand lasso selection, move, scale, and rotate',
    ),
    ToolbarItemDef(
      id: 'clearPage',
      name: 'Clear Page Ink',
      category: 'Editing Tools',
      icon: Icons.delete_sweep_outlined,
      description: 'Wipe all drawing strokes on the current page',
    ),

    // 3. Drawing & Shape Tools Group
    ToolbarItemDef(
      id: 'shape',
      name: 'Shapes Library',
      category: 'Drawing & Shapes',
      icon: Icons.category_outlined,
      description: 'Library of 27 geometric shapes and lines',
    ),
    ToolbarItemDef(
      id: 'snapping',
      name: 'Shape Snapping',
      category: 'Drawing & Shapes',
      icon: Icons.grid_4x4,
      description: 'Auto-align to grid and geometric constraints',
    ),
    ToolbarItemDef(
      id: 'fillBucket',
      name: 'Fill Bucket',
      category: 'Drawing & Shapes',
      icon: Icons.format_color_fill_rounded,
      description: 'Flood fill enclosed areas with color',
    ),

    // 4. Color & Style Controls Group
    ToolbarItemDef(
      id: 'styleCustomizer',
      name: 'Active Style Pill',
      category: 'Color & Style',
      icon: Icons.palette_outlined,
      description: 'Quick color dot and stroke width customizer',
    ),

    // 5. Stylus & Canvas Controls Group
    ToolbarItemDef(
      id: 'undoRedo',
      name: 'Undo / Redo',
      category: 'Canvas Controls',
      icon: Icons.undo,
      description: 'History step forward and backwards',
    ),
    ToolbarItemDef(
      id: 'pan',
      name: 'Pan & Zoom',
      category: 'Canvas Controls',
      icon: Icons.pan_tool_outlined,
      description: 'Pan and navigate around the canvas with touch, pen, or mouse',
    ),
    ToolbarItemDef(
      id: 'palmRejection',
      name: 'Palm Rejection',
      category: 'Canvas Controls',
      icon: Icons.pan_tool_alt,
      description: 'Hardware palm rejection toggle',
    ),
    ToolbarItemDef(
      id: 'stylusOnly',
      name: 'Stylus-Only Mode',
      category: 'Canvas Controls',
      icon: Icons.edit_note,
      description: 'Restrict ink strokes to stylus; finger navigates',
    ),
  ];

  static const List<String> defaultVisibleToolIds = [
    'fountainPen',
    'ballpointPen',
    'pencil',
    'brushPen',
    'highlighter',
    'marker',
    'calligraphyPen',
    'technicalPen',
    'customBrush',
    'fillBucket',
    'styleCustomizer',
    'shape',
    'snapping',
    'eraser',
    'lasso',
    'pan',
    'undoRedo',
    'clearPage',
    'palmRejection',
    'stylusOnly',
  ];
}

/// User's persistent preferences for the drawing toolbar.
class ToolbarPreferences {
  final ToolbarDockPosition dockPosition;
  final bool isCompact;
  final Set<String> visibleToolIds;
  final Set<String> favoriteToolIds;
  final List<String> toolOrder;

  const ToolbarPreferences({
    this.dockPosition = ToolbarDockPosition.top,
    this.isCompact = false,
    this.visibleToolIds = const {
      'fountainPen',
      'ballpointPen',
      'pencil',
      'brushPen',
      'highlighter',
      'marker',
      'calligraphyPen',
      'technicalPen',
      'customBrush',
      'fillBucket',
      'styleCustomizer',
      'shape',
      'snapping',
      'eraser',
      'lasso',
      'pan',
      'undoRedo',
      'clearPage',
      'palmRejection',
      'stylusOnly',
    },
    this.favoriteToolIds = const {'fountainPen', 'highlighter', 'eraser'},
    this.toolOrder = const [],
  });

  bool isToolVisible(String toolId) => visibleToolIds.contains(toolId);
  bool isFavorite(String toolId) => favoriteToolIds.contains(toolId);

  ToolbarPreferences copyWith({
    ToolbarDockPosition? dockPosition,
    bool? isCompact,
    Set<String>? visibleToolIds,
    Set<String>? favoriteToolIds,
    List<String>? toolOrder,
  }) {
    return ToolbarPreferences(
      dockPosition: dockPosition ?? this.dockPosition,
      isCompact: isCompact ?? this.isCompact,
      visibleToolIds: visibleToolIds ?? this.visibleToolIds,
      favoriteToolIds: favoriteToolIds ?? this.favoriteToolIds,
      toolOrder: toolOrder ?? this.toolOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dockPosition': dockPosition.name,
      'isCompact': isCompact,
      'visibleToolIds': visibleToolIds.toList(),
      'favoriteToolIds': favoriteToolIds.toList(),
      'toolOrder': toolOrder,
    };
  }

  factory ToolbarPreferences.fromJson(Map<String, dynamic> json) {
    final dockStr = json['dockPosition'] as String?;
    final compact = json['isCompact'] as bool? ?? false;
    final visibleList =
        (json['visibleToolIds'] as List<dynamic>?)?.cast<String>() ??
        ToolbarCatalog.defaultVisibleToolIds;
    final favList =
        (json['favoriteToolIds'] as List<dynamic>?)?.cast<String>() ??
        ['fountainPen', 'highlighter', 'eraser'];
    final orderList =
        (json['toolOrder'] as List<dynamic>?)?.cast<String>() ?? [];

    return ToolbarPreferences(
      dockPosition: ToolbarDockPosition.fromString(dockStr),
      isCompact: compact,
      visibleToolIds: visibleList.toSet(),
      favoriteToolIds: favList.toSet(),
      toolOrder: orderList,
    );
  }
}

/// State notifier managing toolbar user preferences with local persistence.
class ToolbarPreferencesNotifier extends Notifier<ToolbarPreferences> {
  static const _fileName = 'toolbar_preferences.json';

  @override
  ToolbarPreferences build() {
    _loadPreferences();
    return const ToolbarPreferences();
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _loadPreferences() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = ToolbarPreferences.fromJson(json);
      }
    } catch (_) {}
  }

  Future<void> _savePreferences() async {
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (_) {}
  }

  void setDockPosition(ToolbarDockPosition position) {
    state = state.copyWith(dockPosition: position);
    _savePreferences();
  }

  void toggleCompactMode([bool? force]) {
    state = state.copyWith(isCompact: force ?? !state.isCompact);
    _savePreferences();
  }

  void toggleToolVisibility(String toolId) {
    final current = Set<String>.from(state.visibleToolIds);
    if (current.contains(toolId)) {
      current.remove(toolId);
    } else {
      current.add(toolId);
    }
    state = state.copyWith(visibleToolIds: current);
    _savePreferences();
  }

  void setToolVisibility(String toolId, bool visible) {
    final current = Set<String>.from(state.visibleToolIds);
    if (visible) {
      current.add(toolId);
    } else {
      current.remove(toolId);
    }
    state = state.copyWith(visibleToolIds: current);
    _savePreferences();
  }

  void toggleFavorite(String toolId) {
    final current = Set<String>.from(state.favoriteToolIds);
    if (current.contains(toolId)) {
      current.remove(toolId);
    } else {
      current.add(toolId);
    }
    state = state.copyWith(favoriteToolIds: current);
    _savePreferences();
  }

  void resetDefaults() {
    state = const ToolbarPreferences();
    _savePreferences();
  }
}

/// Global provider for user-customizable drawing toolbar preferences.
final toolbarPreferencesProvider =
    NotifierProvider<ToolbarPreferencesNotifier, ToolbarPreferences>(
      ToolbarPreferencesNotifier.new,
    );
