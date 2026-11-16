import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/features/canvas/data/toolbar_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ToolbarDockPosition', () {
    test('fromString returns correct values', () {
      expect(ToolbarDockPosition.fromString('top'), ToolbarDockPosition.top);
      expect(
        ToolbarDockPosition.fromString('bottom'),
        ToolbarDockPosition.bottom,
      );
      expect(ToolbarDockPosition.fromString('left'), ToolbarDockPosition.left);
      expect(
        ToolbarDockPosition.fromString('right'),
        ToolbarDockPosition.right,
      );
      expect(
        ToolbarDockPosition.fromString('unknown'),
        ToolbarDockPosition.top,
      );
      expect(ToolbarDockPosition.fromString(null), ToolbarDockPosition.top);
    });

    test('label property is descriptive', () {
      expect(ToolbarDockPosition.top.label, 'Top Dock');
      expect(ToolbarDockPosition.bottom.label, 'Bottom Dock');
      expect(ToolbarDockPosition.left.label, 'Left Dock');
      expect(ToolbarDockPosition.right.label, 'Right Dock');
    });
  });

  group('ToolbarCatalog', () {
    test('contains writing, editing, drawing, and canvas tools', () {
      expect(ToolbarCatalog.allTools.isNotEmpty, true);
      expect(ToolbarCatalog.defaultVisibleToolIds.isNotEmpty, true);

      final categories = ToolbarCatalog.allTools.map((t) => t.category).toSet();
      expect(categories.contains('Writing Tools'), true);
      expect(categories.contains('Editing Tools'), true);
      expect(categories.contains('Drawing & Shapes'), true);
      expect(categories.contains('Canvas Controls'), true);
    });
  });

  group('ToolbarPreferences JSON serialization', () {
    test('serializes and deserializes accurately', () {
      const prefs = ToolbarPreferences(
        dockPosition: ToolbarDockPosition.bottom,
        isCompact: true,
        visibleToolIds: {'fountainPen', 'pencil', 'eraser'},
        favoriteToolIds: {'pencil'},
      );

      final json = prefs.toJson();
      expect(json['dockPosition'], 'bottom');
      expect(json['isCompact'], true);

      final restored = ToolbarPreferences.fromJson(json);
      expect(restored.dockPosition, ToolbarDockPosition.bottom);
      expect(restored.isCompact, true);
      expect(restored.isToolVisible('fountainPen'), true);
      expect(restored.isToolVisible('marker'), false);
      expect(restored.isFavorite('pencil'), true);
      expect(restored.isFavorite('fountainPen'), false);
    });
  });

  group('ToolbarPreferencesNotifier', () {
    test('toggles visibility and favorites correctly in container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(toolbarPreferencesProvider.notifier);

      // Verify defaults
      expect(
        container.read(toolbarPreferencesProvider).isToolVisible('fountainPen'),
        true,
      );

      // Hide fountain pen
      notifier.setToolVisibility('fountainPen', false);
      expect(
        container.read(toolbarPreferencesProvider).isToolVisible('fountainPen'),
        false,
      );

      // Toggle fountain pen back on
      notifier.toggleToolVisibility('fountainPen');
      expect(
        container.read(toolbarPreferencesProvider).isToolVisible('fountainPen'),
        true,
      );

      // Favorite toggle
      notifier.toggleFavorite('technicalPen');
      expect(
        container.read(toolbarPreferencesProvider).isFavorite('technicalPen'),
        true,
      );

      // Dock position
      notifier.setDockPosition(ToolbarDockPosition.bottom);
      expect(
        container.read(toolbarPreferencesProvider).dockPosition,
        ToolbarDockPosition.bottom,
      );

      // Compact mode
      notifier.toggleCompactMode(true);
      expect(container.read(toolbarPreferencesProvider).isCompact, true);

      // Reset
      notifier.resetDefaults();
      expect(
        container.read(toolbarPreferencesProvider).dockPosition,
        ToolbarDockPosition.top,
      );
      expect(container.read(toolbarPreferencesProvider).isCompact, false);
    });
  });
}
