import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naik_notes/platform/android/android_stylus_adapter.dart';
import 'package:naik_notes/platform/ios/apple_pencil_adapter.dart';
import 'package:naik_notes/platform/models/stylus_event.dart';
import 'package:naik_notes/platform/windows/windows_pen_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StylusCapabilities Model Tests', () {
    test('instantiates with expected default values', () {
      const caps = StylusCapabilities(
        hasPressure: true,
        hasTilt: true,
        hasHover: true,
        hasEraserTip: true,
        hasBarrelButtons: true,
        hasDoubleTap: true,
        hasSqueeze: false,
        stylusType: StylusType.applePencil,
      );

      expect(caps.hasPressure, isTrue);
      expect(caps.hasTilt, isTrue);
      expect(caps.hasHover, isTrue);
      expect(caps.hasEraserTip, isTrue);
      expect(caps.hasBarrelButtons, isTrue);
      expect(caps.hasDoubleTap, isTrue);
      expect(caps.hasSqueeze, isFalse);
      expect(caps.stylusType, StylusType.applePencil);
      expect(caps.stylusType.displayName, 'Apple Pencil');
    });

    test('serializes to JSON and deserializes correctly', () {
      const original = StylusCapabilities(
        hasPressure: true,
        hasTilt: false,
        hasHover: true,
        hasEraserTip: false,
        hasBarrelButtons: true,
        hasDoubleTap: false,
        hasSqueeze: true,
        stylusType: StylusType.sPen,
      );

      final json = original.toJson();
      final restored = StylusCapabilities.fromJson(json);

      expect(restored.hasPressure, original.hasPressure);
      expect(restored.hasTilt, original.hasTilt);
      expect(restored.hasHover, original.hasHover);
      expect(restored.hasEraserTip, original.hasEraserTip);
      expect(restored.hasBarrelButtons, original.hasBarrelButtons);
      expect(restored.hasDoubleTap, original.hasDoubleTap);
      expect(restored.hasSqueeze, original.hasSqueeze);
      expect(restored.stylusType, StylusType.sPen);
      expect(restored.stylusType.displayName, 'Samsung S-Pen');
    });

    test('fallback returns active generic digitizer capabilities', () {
      final fallback = StylusCapabilities.fallback();
      expect(fallback.hasPressure, isTrue);
      expect(fallback.hasTilt, isTrue);
      expect(fallback.hasHover, isTrue);
      expect(fallback.stylusType, StylusType.genericStylus);
    });
  });

  group('ApplePencilAdapter Tests', () {
    late ApplePencilAdapter adapter;

    setUp(() {
      adapter = ApplePencilAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('reports Apple Pencil capabilities', () async {
      final caps = await adapter.getCapabilities();
      expect(caps.stylusType, StylusType.applePencil);
      expect(caps.hasPressure, isTrue);
      expect(caps.hasTilt, isTrue);
      expect(caps.hasHover, isTrue);
      expect(caps.hasDoubleTap, isTrue);
    });

    test('emits doubleTap and squeeze events on stream', () async {
      final events = <StylusEvent>[];
      final sub = adapter.events.listen(events.add);

      adapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.doubleTap,
          preferredAction: 'switchEraser',
          timestamp: DateTime.now(),
        ),
      );

      adapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.squeeze,
          preferredAction: 'switchPrevious',
          timestamp: DateTime.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events.length, 2);
      expect(events[0].type, StylusEventType.doubleTap);
      expect(events[0].preferredAction, 'switchEraser');
      expect(events[1].type, StylusEventType.squeeze);
      expect(events[1].preferredAction, 'switchPrevious');

      await sub.cancel();
    });
  });

  group('AndroidStylusAdapter Tests', () {
    late AndroidStylusAdapter adapter;

    setUp(() {
      adapter = AndroidStylusAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('reports Samsung S-Pen capabilities', () async {
      final caps = await adapter.getCapabilities();
      expect(caps.stylusType, StylusType.sPen);
      expect(caps.hasPressure, isTrue);
      expect(caps.hasTilt, isTrue);
      expect(caps.hasHover, isTrue);
      expect(caps.hasBarrelButtons, isTrue);
    });

    test('emits barrel button and hover events on stream', () async {
      final events = <StylusEvent>[];
      final sub = adapter.events.listen(events.add);

      adapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.buttonDown,
          position: const Offset(120, 240),
          button: 1,
          timestamp: DateTime.now(),
        ),
      );

      adapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.hoverMove,
          position: const Offset(125, 245),
          distance: 0.4,
          tilt: 0.15,
          timestamp: DateTime.now(),
        ),
      );

      adapter.emitTestEvent(
        StylusEvent(
          type: StylusEventType.buttonUp,
          position: const Offset(125, 245),
          button: 0,
          timestamp: DateTime.now(),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events.length, 3);
      expect(events[0].type, StylusEventType.buttonDown);
      expect(events[0].position, const Offset(120, 240));
      expect(events[1].type, StylusEventType.hoverMove);
      expect(events[1].distance, 0.4);
      expect(events[2].type, StylusEventType.buttonUp);

      await sub.cancel();
    });
  });

  group('WindowsPenAdapter Tests', () {
    late WindowsPenAdapter adapter;

    setUp(() {
      adapter = WindowsPenAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('reports Surface Pen and Windows Ink capabilities', () async {
      final caps = await adapter.getCapabilities();
      expect(caps.stylusType, StylusType.surfacePen);
      expect(caps.hasPressure, isTrue);
      expect(caps.hasTilt, isTrue);
      expect(caps.hasHover, isTrue);
      expect(caps.hasEraserTip, isTrue);
      expect(caps.hasBarrelButtons, isTrue);
    });

    test('handlePointerData dispatches formatted StylusEvent', () async {
      final events = <StylusEvent>[];
      final sub = adapter.events.listen(events.add);

      adapter.handlePointerData(
        type: StylusEventType.invertedTipDown,
        position: const Offset(300, 450),
        pressure: 0.8,
        tilt: 0.25,
      );

      adapter.handlePointerData(
        type: StylusEventType.invertedTipUp,
        position: const Offset(310, 455),
        pressure: 0.0,
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events.length, 2);
      expect(events[0].type, StylusEventType.invertedTipDown);
      expect(events[0].position, const Offset(300, 450));
      expect(events[0].pressure, 0.8);
      expect(events[1].type, StylusEventType.invertedTipUp);

      await sub.cancel();
    });
  });
}
