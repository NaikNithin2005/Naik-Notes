import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'paper_template_model.dart';

/// Represents a downloadable or user-created custom paper template.
@immutable
class CustomTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final String author;
  final PaperProperties properties;
  final String? thumbnailBase64;
  final bool isInstalled;
  final bool isBuiltIn;
  final int downloadCount;
  final double rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    required this.properties,
    this.thumbnailBase64,
    this.isInstalled = true,
    this.isBuiltIn = false,
    this.downloadCount = 0,
    this.rating = 5.0,
    required this.createdAt,
    required this.updatedAt,
  });

  CustomTemplate copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? author,
    PaperProperties? properties,
    String? thumbnailBase64,
    bool? isInstalled,
    bool? isBuiltIn,
    int? downloadCount,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomTemplate(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      author: author ?? this.author,
      properties: properties ?? this.properties,
      thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
      isInstalled: isInstalled ?? this.isInstalled,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      downloadCount: downloadCount ?? this.downloadCount,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'author': author,
    'paper_properties': properties.toJson(),
    'thumbnail_base64': thumbnailBase64,
    'is_installed': isInstalled,
    'is_built_in': isBuiltIn,
    'download_count': downloadCount,
    'rating': rating,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CustomTemplate.fromJson(Map<String, dynamic> json) => CustomTemplate(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? 'General',
    author: json['author'] as String? ?? 'Community',
    properties: json['paper_properties'] != null
        ? PaperProperties.fromJson(
            json['paper_properties'] is String
                ? jsonDecode(json['paper_properties'] as String)
                : json['paper_properties'] as Map<String, dynamic>,
          )
        : const PaperProperties(),
    thumbnailBase64: json['thumbnail_base64'] as String?,
    isInstalled: json['is_installed'] as bool? ?? true,
    isBuiltIn: json['is_built_in'] as bool? ?? false,
    downloadCount: json['download_count'] as int? ?? 0,
    rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : DateTime.now(),
  );
}
