import 'dart:async';

import 'package:flutter/material.dart';
import 'package:naik_notes/platform/models/stylus_event.dart';
import 'package:naik_notes/platform/platform_input_adapter.dart';

/// Windows 10/11 Pen, Surface Digitizer, and desktop input adapter.
/// Directly maps Windows Ink pointer kinds, inverted pen eraser tips,
/// barrel buttons, and high-precision digitizer hover data.
class WindowsPenAdapter implements PlatformInputAdapter {
  final StreamController<StylusEvent> _eventController =
      StreamController<StylusEvent>.broadcast();

  @override
  Stream<StylusEvent> get events => _eventController.stream;

  @override
  Future<void> initialize() async {
    // Windows digitizer events are delivered with high fidelity via Flutter's
    // native PointerEventListener on the Windows runner.
  }

  @override
  Future<StylusCapabilities> getCapabilities() async {
    return const StylusCapabilities(
      hasPressure: true,
      hasTilt: true,
      hasHover: true,
      hasEraserTip: true,
      hasBarrelButtons: true,
      hasDoubleTap: false,
      hasSqueeze: false,
      stylusType: StylusType.surfacePen,
    );
  }

  /// Processes Windows pointer down/move/hover/up events to emit unified StylusEvents.
  void handlePointerData({
    required StylusEventType type,
    Offset? position,
    double pressure = 0.0,
    double tilt = 0.0,
    double distance = 0.0,
    int button = 0,
  }) {
    _eventController.add(
      StylusEvent(
        type: type,
        position: position,
        pressure: pressure,
        tilt: tilt,
        distance: distance,
        button: button,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Sends a simulated event for unit/widget tests.
  @visibleForTesting
  void emitTestEvent(StylusEvent event) {
    _eventController.add(event);
  }

  @override
  void dispose() {
    _eventController.close();
  }
}
