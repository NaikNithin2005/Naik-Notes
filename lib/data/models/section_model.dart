/// Domain model representing a notebook section / tabbed divider.
class NotebookSection {
  final String id;
  final String notebookId;
  final String name;
  final int orderIndex;
  final String colorHex;
  final DateTime createdAt;

  const NotebookSection({
    required this.id,
    required this.notebookId,
    required this.name,
    this.orderIndex = 0,
    this.colorHex = '#1E2A38',
    required this.createdAt,
  });

  NotebookSection copyWith({
    String? id,
    String? notebookId,
    String? name,
    int? orderIndex,
    String? colorHex,
    DateTime? createdAt,
  }) {
    return NotebookSection(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      name: name ?? this.name,
      orderIndex: orderIndex ?? this.orderIndex,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notebookId': notebookId,
      'name': name,
      'orderIndex': orderIndex,
      'colorHex': colorHex,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory NotebookSection.fromJson(Map<String, dynamic> json) {
    return NotebookSection(
      id: json['id'] as String,
      notebookId: json['notebookId'] as String,
      name: json['name'] as String,
      orderIndex: json['orderIndex'] as int? ?? 0,
      colorHex: json['colorHex'] as String? ?? '#1E2A38',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
