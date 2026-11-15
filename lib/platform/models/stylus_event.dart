import 'package:flutter/material.dart';

/// Hardware stylus event types across iPadOS, Android, and Windows.
enum StylusEventType {
  doubleTap,
  squeeze,
  buttonDown,
  buttonUp,
  hoverEnter,
  hoverMove,
  hoverExit,
  invertedTipDown,
  invertedTipUp,
}

/// Known digitizer and stylus hardware technologies.
enum StylusType {
  applePencil,
  sPen,
  surfacePen,
  genericStylus,
  none;

  String get displayName {
    switch (this) {
      case StylusType.applePencil:
        return 'Apple Pencil';
      case StylusType.sPen:
        return 'Samsung S-Pen';
      case StylusType.surfacePen:
        return 'Surface Pen / Windows Ink';
      case StylusType.genericStylus:
        return 'Active Stylus / Digitizer';
      case StylusType.none:
        return 'Touch / Mouse';
    }
  }
}

/// Hardware capabilities reported by the platform digitizer adapter.
@immutable
class StylusCapabilities {
  final bool hasPressure;
  final bool hasTilt;
  final bool hasHover;
  final bool hasEraserTip;
  final bool hasBarrelButtons;
  final bool hasDoubleTap;
  final bool hasSqueeze;
  final StylusType stylusType;

  const StylusCapabilities({
    this.hasPressure = false,
    this.hasTilt = false,
    this.hasHover = false,
    this.hasEraserTip = false,
    this.hasBarrelButtons = false,
    this.hasDoubleTap = false,
    this.hasSqueeze = false,
    this.stylusType = StylusType.none,
  });

  /// Factory for standard desktop or unknown environments.
  factory StylusCapabilities.fallback() {
    return const StylusCapabilities(
      hasPressure: true,
      hasTilt: true,
      hasHover: true,
      hasEraserTip: true,
      hasBarrelButtons: true,
      hasDoubleTap: false,
      hasSqueeze: false,
      stylusType: StylusType.genericStylus,
    );
  }

  Map<String, dynamic> toJson() => {
    'hasPressure': hasPressure,
    'hasTilt': hasTilt,
    'hasHover': hasHover,
    'hasEraserTip': hasEraserTip,
    'hasBarrelButtons': hasBarrelButtons,
    'hasDoubleTap': hasDoubleTap,
    'hasSqueeze': hasSqueeze,
    'stylusType': stylusType.name,
  };

  factory StylusCapabilities.fromJson(Map<String, dynamic> json) {
    return StylusCapabilities(
      hasPressure: json['hasPressure'] as bool? ?? false,
      hasTilt: json['hasTilt'] as bool? ?? false,
      hasHover: json['hasHover'] as bool? ?? false,
      hasEraserTip: json['hasEraserTip'] as bool? ?? false,
      hasBarrelButtons: json['hasBarrelButtons'] as bool? ?? false,
      hasDoubleTap: json['hasDoubleTap'] as bool? ?? false,
      hasSqueeze: json['hasSqueeze'] as bool? ?? false,
      stylusType: StylusType.values.firstWhere(
        (t) => t.name == json['stylusType'],
        orElse: () => StylusType.none,
      ),
    );
  }

  @override
  String toString() =>
      'StylusCapabilities(type: ${stylusType.displayName}, pressure: $hasPressure, tilt: $hasTilt, hover: $hasHover, doubleTap: $hasDoubleTap)';
}

/// Unified hardware stylus event received from native platform channels or pointer hooks.
@immutable
class StylusEvent {
  final StylusEventType type;
  final Offset? position;
  final double pressure;
  final double tilt;
  final double distance;
  final int button;
  final String? preferredAction;
  final DateTime timestamp;

  const StylusEvent({
    required this.type,
    this.position,
    this.pressure = 0.0,
    this.tilt = 0.0,
    this.distance = 0.0,
    this.button = 0,
    this.preferredAction,
    required this.timestamp,
  });

  @override
  String toString() =>
      'StylusEvent(type: $type, pos: $position, pressure: $pressure, btn: $button, action: $preferredAction)';
}
