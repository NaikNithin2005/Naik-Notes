/// Feedback submission data model for user bug reports and suggestions.
class FeedbackSubmission {
  final String id;
  final String userId;
  final String userEmail;
  final String category;
  final int rating;
  final String description;
  final String platform;
  final String appVersion;
  final DateTime createdAt;

  const FeedbackSubmission({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.category,
    required this.rating,
    required this.description,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'category': category,
      'rating': rating,
      'description': description,
      'platform': platform,
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FeedbackSubmission.fromMap(Map<String, dynamic> map) {
    return FeedbackSubmission(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      description: map['description'] as String? ?? '',
      platform: map['platform'] as String? ?? 'Unknown',
      appVersion: map['appVersion'] as String? ?? '1.0.0',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
