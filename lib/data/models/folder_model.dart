/// Domain model representing a notebook folder.
class Folder {
  final String id;
  final String ownerId;
  final String? parentId;
  final String name;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const Folder({
    required this.id,
    this.ownerId = 'local_user',
    this.parentId,
    required this.name,
    this.colorHex = '#8B4513',
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  Folder copyWith({
    String? id,
    String? ownerId,
    String? parentId,
    String? name,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return Folder(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'parentId': parentId,
      'name': name,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? 'local_user',
      parentId: json['parentId'] as String?,
      name: json['name'] as String,
      colorHex: json['colorHex'] as String? ?? '#8B4513',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'] as String)
          : null,
    );
  }
}
