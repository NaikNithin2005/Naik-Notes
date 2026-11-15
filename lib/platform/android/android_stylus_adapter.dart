import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naik_notes/platform/models/stylus_event.dart';
import 'package:naik_notes/platform/platform_input_adapter.dart';

/// Android S-Pen and active stylus integration adapter.
/// Receives native MotionEvent hardware signals including barrel button clicks,
/// hover coordinates, distance, and tilt via Flutter platform channels.
class AndroidStylusAdapter implements PlatformInputAdapter {
  static const MethodChannel _methodChannel = MethodChannel(
    'naik_notes/android_stylus',
  );
  static const EventChannel _eventChannel = EventChannel(
    'naik_notes/android_stylus/events',
  );

  final StreamController<StylusEvent> _eventController =
      StreamController<StylusEvent>.broadcast();
  StreamSubscription? _eventSubscription;

  @override
  Stream<StylusEvent> get events => _eventController.stream;

  @override
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic data) {
          if (data is Map) {
            final map = Map<String, dynamic>.from(data);
            final event = _parseNativeEvent(map);
            if (event != null) {
              _eventController.add(event);
            }
          }
        },
        onError: (dynamic error) {
          debugPrint('AndroidStylusAdapter event error: $error');
        },
      );
    } catch (e) {
      debugPrint('AndroidStylusAdapter initialization warning: $e');
    }
  }

  StylusEvent? _parseNativeEvent(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? '';
    final x = (map['x'] as num?)?.toDouble() ?? 0.0;
    final y = (map['y'] as num?)?.toDouble() ?? 0.0;
    final pressure = (map['pressure'] as num?)?.toDouble() ?? 0.0;
    final tilt = (map['tilt'] as num?)?.toDouble() ?? 0.0;
    final distance = (map['distance'] as num?)?.toDouble() ?? 0.0;
    final button = map['button'] as int? ?? 0;
    final timestamp = DateTime.now();

    StylusEventType eventType;
    switch (typeStr) {
      case 'buttonDown':
        eventType = StylusEventType.buttonDown;
        break;
      case 'buttonUp':
        eventType = StylusEventType.buttonUp;
        break;
      case 'hoverEnter':
        eventType = StylusEventType.hoverEnter;
        break;
      case 'hoverMove':
        eventType = StylusEventType.hoverMove;
        break;
      case 'hoverExit':
        eventType = StylusEventType.hoverExit;
        break;
      case 'invertedTipDown':
        eventType = StylusEventType.invertedTipDown;
        break;
      case 'invertedTipUp':
        eventType = StylusEventType.invertedTipUp;
        break;
      default:
        return null;
    }

    return StylusEvent(
      type: eventType,
      position: Offset(x, y),
      pressure: pressure,
      tilt: tilt,
      distance: distance,
      button: button,
      timestamp: timestamp,
    );
  }

  @override
  Future<StylusCapabilities> getCapabilities() async {
    if (kIsWeb) {
      return const StylusCapabilities(
        hasPressure: true,
        hasTilt: true,
        hasHover: true,
        hasEraserTip: true,
        hasBarrelButtons: true,
        hasDoubleTap: false,
        hasSqueeze: false,
        stylusType: StylusType.sPen,
      );
    }

    try {
      final result = await _methodChannel.invokeMethod<Map>(
        'getStylusCapabilities',
      );
      if (result != null) {
        return StylusCapabilities.fromJson(Map<String, dynamic>.from(result));
      }
    } catch (_) {
      // Fallback if platform channel is not active
    }

    return const StylusCapabilities(
      hasPressure: true,
      hasTilt: true,
      hasHover: true,
      hasEraserTip: true,
      hasBarrelButtons: true,
      hasDoubleTap: false,
      hasSqueeze: false,
      stylusType: StylusType.sPen,
    );
  }

  /// Sends a simulated event (useful for tests).
  @visibleForTesting
  void emitTestEvent(StylusEvent event) {
    _eventController.add(event);
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _eventController.close();
  }
}
