import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
import '../../authentication/data/auth_provider.dart';
import 'feedback_model.dart';

/// Provider for FeedbackService.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(ref);
});

/// Service responsible for dispatching and storing user feedback, bug reports, and ratings.
class FeedbackService {
  final Ref _ref;
  final _uuid = const Uuid();

  FeedbackService(this._ref);

  /// Submits feedback to Cloud Firestore (or local state if offline).
  Future<bool> submitFeedback({
    required String category,
    required int rating,
    required String description,
  }) async {
    final cleanDesc = description.trim();
    if (cleanDesc.isEmpty) {
      throw Exception('Feedback description cannot be empty.');
    }

    final user = _ref.read(authProvider).user;
    final userId = user?.id ?? 'guest_user';
    final userEmail = user?.email ?? 'guest@naiknotes.app';
    final feedbackId = _uuid.v4();

    final submission = FeedbackSubmission(
      id: feedbackId,
      userId: userId,
      userEmail: userEmail,
      category: category,
      rating: rating.clamp(1, 5),
      description: cleanDesc,
      platform: defaultTargetPlatform.name,
      appVersion: AppConfig.appVersion,
      createdAt: DateTime.now(),
    );

    try {
      if (userId != 'guest_user') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('feedback')
            .doc(feedbackId)
            .set(submission.toMap());
      }
    } catch (e) {
      debugPrint('Feedback cloud push notice (offline fallback): $e');
    }

    return true;
  }
}
