import 'dart:ui';

/// Represents a draggable sticky note annotation placed on a notebook or PDF page.
class StickyNote {
  final String id;
  final String pageId;
  final double x;
  final double y;
  final double width;
  final double height;
  final String content;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StickyNote({
    required this.id,
    required this.pageId,
    required this.x,
    required this.y,
    this.width = 180.0,
    this.height = 150.0,
    required this.content,
    this.colorHex = '#FEF08A', // Soft canary yellow
    required this.createdAt,
    required this.updatedAt,
  });

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  Offset get position => Offset(x, y);
  Rect get boundingBox => Rect.fromLTWH(x, y, width, height);

  StickyNote copyWith({
    String? id,
    String? pageId,
    double? x,
    double? y,
    double? width,
    double? height,
    String? content,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StickyNote(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      content: content ?? this.content,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pageId': pageId,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'content': content,
    'colorHex': colorHex,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory StickyNote.fromJson(Map<String, dynamic> json) => StickyNote(
    id: json['id'] as String,
    pageId: json['pageId'] as String,
    x: (json['x'] as num).toDouble(),
    y: (json['y'] as num).toDouble(),
    width: (json['width'] as num?)?.toDouble() ?? 180.0,
    height: (json['height'] as num?)?.toDouble() ?? 150.0,
    content: json['content'] as String,
    colorHex: json['colorHex'] as String? ?? '#FEF08A',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// Palette of available sticky note colors.
class StickyNoteColors {
  static const canaryYellow = '#FEF08A';
  static const skyBlue = '#BAE6FD';
  static const pastelPink = '#FBCFE8';
  static const mintGreen = '#BBF7D0';
  static const lavender = '#E9D5FF';
  static const peachOrange = '#FED7AA';

  static const List<String> all = [
    canaryYellow,
    skyBlue,
    pastelPink,
    mintGreen,
    lavender,
    peachOrange,
  ];
}
