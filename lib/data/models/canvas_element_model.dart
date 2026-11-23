import 'dart:ui';
import 'package:flutter/material.dart';

enum CanvasElementType {
  text,
  stickyNote,
  image,
  mathFormula;

  String get id => name;
}

/// Unified Canvas Element representing any non-ink object placed on the document canvas:
/// - Editable Text Boxes
/// - Colorful Sticky Notes
/// - Movable / Rotatable Images
/// - LaTeX Math Equations
class CanvasElement {
  final String id;
  final String pageId;
  final CanvasElementType type;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final int zIndex;
  final bool isLocked;
  final String content; // text string, note content, or LaTeX equation
  final String? imagePath;
  final String colorHex;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final TextAlign textAlign;
  final bool isCollapsed;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CanvasElement({
    required this.id,
    required this.pageId,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.isLocked = false,
    this.content = '',
    this.imagePath,
    this.colorHex = '#FEF08A',
    this.fontSize = 16.0,
    this.isBold = false,
    this.isItalic = false,
    this.textAlign = TextAlign.left,
    this.isCollapsed = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Offset get position => Offset(x, y);
  Rect get boundingBox => Rect.fromLTWH(x, y, width, height);

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    try {
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFFFEF08A);
  }

  CanvasElement copyWith({
    String? id,
    String? pageId,
    CanvasElementType? type,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    String? content,
    String? imagePath,
    String? colorHex,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    TextAlign? textAlign,
    bool? isCollapsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CanvasElement(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      type: type ?? this.type,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      colorHex: colorHex ?? this.colorHex,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      textAlign: textAlign ?? this.textAlign,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'page_id': pageId,
    'type': type.name,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'z_index': zIndex,
    'is_locked': isLocked,
    'content': content,
    'image_path': imagePath,
    'color_hex': colorHex,
    'font_size': fontSize,
    'is_bold': isBold,
    'is_italic': isItalic,
    'text_align': textAlign.name,
    'is_collapsed': isCollapsed,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CanvasElement.fromJson(Map<String, dynamic> json) {
    return CanvasElement(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      type: CanvasElementType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => CanvasElementType.text,
      ),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
      isLocked: json['is_locked'] as bool? ?? false,
      content: json['content'] as String? ?? '',
      imagePath: json['image_path'] as String?,
      colorHex: json['color_hex'] as String? ?? '#FEF08A',
      fontSize: (json['font_size'] as num?)?.toDouble() ?? 16.0,
      isBold: json['is_bold'] as bool? ?? false,
      isItalic: json['is_italic'] as bool? ?? false,
      textAlign: TextAlign.values.firstWhere(
        (a) => a.name == json['text_align'],
        orElse: () => TextAlign.left,
      ),
      isCollapsed: json['is_collapsed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

