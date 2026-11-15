import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:naik_notes/platform/android/android_stylus_adapter.dart';
import 'package:naik_notes/platform/ios/apple_pencil_adapter.dart';
import 'package:naik_notes/platform/models/stylus_event.dart';
import 'package:naik_notes/platform/windows/windows_pen_adapter.dart';

/// Base contract for native hardware stylus, pen digitizer, and touch integration.
abstract class PlatformInputAdapter {
  /// Stream of hardware stylus events (double tap, squeeze, side button, hover).
  Stream<StylusEvent> get events;

  /// Detects and queries platform digitizer capabilities.
  Future<StylusCapabilities> getCapabilities();

  /// Initializes native platform channels and hardware listeners.
  Future<void> initialize();

  /// Cleans up listeners and platform channels.
  void dispose();

  /// Creates the appropriate platform-specific adapter based on runtime target.
  static PlatformInputAdapter create() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ApplePencilAdapter();
      case TargetPlatform.android:
        return AndroidStylusAdapter();
      case TargetPlatform.windows:
        return WindowsPenAdapter();
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return DefaultInputAdapter();
    }
  }
}

/// Fallback input adapter for platforms without specialized hardware digitizer SDKs.
class DefaultInputAdapter implements PlatformInputAdapter {
  final _controller = StreamController<StylusEvent>.broadcast();

  @override
  Stream<StylusEvent> get events => _controller.stream;

  @override
  Future<StylusCapabilities> getCapabilities() async {
    return StylusCapabilities.fallback();
  }

  @override
  Future<void> initialize() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

/// Global provider for the active platform input adapter.
final platformInputAdapterProvider = Provider<PlatformInputAdapter>((ref) {
  final adapter = PlatformInputAdapter.create();
  adapter.initialize();
  ref.onDispose(() => adapter.dispose());
  return adapter;
});

/// Future provider exposing the hardware capabilities of the connected digitizer.
final stylusCapabilitiesProvider = FutureProvider<StylusCapabilities>((ref) {
  final adapter = ref.watch(platformInputAdapterProvider);
  return adapter.getCapabilities();
});

/// Stream provider for hardware stylus events.
final stylusEventsProvider = StreamProvider<StylusEvent>((ref) {
  final adapter = ref.watch(platformInputAdapterProvider);
  return adapter.events;
});
