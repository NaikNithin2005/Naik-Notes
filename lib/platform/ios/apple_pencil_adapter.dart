import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:naik_notes/platform/models/stylus_event.dart';
import 'package:naik_notes/platform/platform_input_adapter.dart';

/// Apple Pencil hardware integration adapter for iPadOS.
/// Bridges native UIPencilInteraction, UIPencilHoverPose, and squeeze gestures
/// via Flutter platform channels.
class ApplePencilAdapter implements PlatformInputAdapter {
  static const MethodChannel _methodChannel = MethodChannel(
    'naik_notes/apple_pencil',
  );
  static const EventChannel _eventChannel = EventChannel(
    'naik_notes/apple_pencil/events',
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
          debugPrint('ApplePencilAdapter event channel error: $error');
        },
      );
    } catch (e) {
      debugPrint('ApplePencilAdapter initialization warning: $e');
    }
  }

  StylusEvent? _parseNativeEvent(Map<String, dynamic> map) {
    final typeStr = map['type'] as String? ?? '';
    final action = map['action'] as String?;
    final timestamp = DateTime.now();

    StylusEventType eventType;
    switch (typeStr) {
      case 'doubleTap':
        eventType = StylusEventType.doubleTap;
        break;
      case 'squeeze':
        eventType = StylusEventType.squeeze;
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
      default:
        return null;
    }

    return StylusEvent(
      type: eventType,
      preferredAction: action,
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
        hasEraserTip: false,
        hasBarrelButtons: false,
        hasDoubleTap: false,
        hasSqueeze: false,
        stylusType: StylusType.applePencil,
      );
    }

    try {
      final result = await _methodChannel.invokeMethod<Map>(
        'getPencilCapabilities',
      );
      if (result != null) {
        return StylusCapabilities.fromJson(Map<String, dynamic>.from(result));
      }
    } catch (_) {
      // Fallback if running on simulator or unsupported iOS version
    }

    return const StylusCapabilities(
      hasPressure: true,
      hasTilt: true,
      hasHover: true,
      hasEraserTip: false,
      hasBarrelButtons: false,
      hasDoubleTap: true,
      hasSqueeze: true,
      stylusType: StylusType.applePencil,
    );
  }

  /// Sends a simulated event (useful for unit tests and simulator).
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
