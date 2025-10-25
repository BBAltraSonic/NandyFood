import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/core/services/notification_service.dart';

/// User feedback collection service
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final List<FeedbackItem> _feedbackQueue = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  /// Initialize feedback service
  void initialize() {
    AppLogger.info('Feedback service initialized');
  }

  // ==================== FEEDBACK SUBMISSION ====================

  /// Submit general feedback
  Future<String> submitFeedback({
    required String userId,
    required String email,
    required FeedbackType type,
    required String message,
    int? rating,
    Map<String, dynamic>? metadata,
  }) async {
    final feedbackId = 'FB-${DateTime.now().millisecondsSinceEpoch}';

    final feedback = FeedbackItem(
      id: feedbackId,
      userId: userId,
      email: email,
      type: type,
      message: message,
      rating: rating,
      metadata: metadata,
      submittedAt: DateTime.now(),
      status: FeedbackStatus.pending,
    );

    _feedbackQueue.add(feedback);

    AppLogger.info(
      'Feedback submitted',
      details: 'ID: $feedbackId, Type: ${type.name}, User: $userId',
    );

    // Send to backend
    final success = await _sendToBackend(feedback);

    if (success) {
      // Notify user of successful submission
      await _notifyUserSuccess(feedback);
    } else {
      feedback.status = FeedbackStatus.pending;
      AppLogger.warning('Feedback submission failed, will retry later');
    }

    return feedbackId;
  }

  /// Submit bug report
  Future<String> submitBugReport({
    required String userId,
    required String email,
    required String description,
    required String stepsToReproduce,
    String? expectedBehavior,
    String? actualBehavior,
    String? deviceInfo,
    String? appVersion,
    List<String>? screenshots,
  }) async {
    final metadata = {
      'steps_to_reproduce': stepsToReproduce,
      'expected_behavior': expectedBehavior,
      'actual_behavior': actualBehavior,
      'device_info': deviceInfo,
      'app_version': appVersion,
      'screenshots': screenshots,
    };

    return await submitFeedback(
      userId: userId,
      email: email,
      type: FeedbackType.bug,
      message: description,
      metadata: metadata,
    );
  }

  /// Submit feature request
  Future<String> submitFeatureRequest({
    required String userId,
    required String email,
    required String featureDescription,
    String? useCase,
    int? priority,
  }) async {
    final metadata = {
      'use_case': useCase,
      'priority': priority,
    };

    return await submitFeedback(
      userId: userId,
      email: email,
      type: FeedbackType.featureRequest,
      message: featureDescription,
      metadata: metadata,
    );
  }

  /// Submit app rating
  Future<String> submitAppRating({
    required String userId,
    required String email,
    required int rating,
    String? review,
  }) async {
    return await submitFeedback(
      userId: userId,
      email: email,
      type: FeedbackType.rating,
      message: review ?? 'App rating submitted',
      rating: rating,
    );
  }

  /// Submit support request
  Future<String> submitSupportRequest({
    required String userId,
    required String email,
    required String subject,
    required String message,
    SupportCategory? category,
    String? orderId,
  }) async {
    final metadata = {
      'subject': subject,
      'category': category?.name,
      'order_id': orderId,
    };

    return await submitFeedback(
      userId: userId,
      email: email,
      type: FeedbackType.support,
      message: message,
      metadata: metadata,
    );
  }

  // ==================== FEEDBACK MANAGEMENT ====================

  /// Get feedback by ID
  FeedbackItem? getFeedback(String feedbackId) {
    try {
      return _feedbackQueue.firstWhere((f) => f.id == feedbackId);
    } catch (e) {
      return null;
    }
  }

  /// Get user's feedback history
  List<FeedbackItem> getUserFeedback(String userId) {
    return _feedbackQueue
        .where((f) => f.userId == userId)
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  /// Update feedback status
  Future<void> updateFeedbackStatus(String feedbackId, FeedbackStatus status) async {
    final feedback = getFeedback(feedbackId);
    if (feedback != null) {
      feedback.status = status;
      feedback.updatedAt = DateTime.now();

      AppLogger.info('Feedback status updated: $feedbackId -> ${status.name}');

      // Notify user of status change
      await _notifyUserStatusChange(feedback);

      // Update in backend
      try {
        await _supabase
            .from('feedback')
            .update({
              'status': status.name,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', feedbackId);
      } catch (e) {
        AppLogger.error('Failed to update feedback status in backend', error: e);
      }
    }
  }

  // ==================== IN-APP FEEDBACK ====================

  /// Show feedback prompt
  bool shouldShowFeedbackPrompt(String userId) {
    // Logic to determine if user should see feedback prompt
    // - After successful order
    // - After using app for a while
    // - Not shown too frequently

    final userFeedback = getUserFeedback(userId);
    final lastFeedback = userFeedback.isNotEmpty ? userFeedback.first : null;

    if (lastFeedback == null) {
      return true; // First time user
    }

    // Don't show if feedback was submitted recently (within 7 days)
    final daysSinceLastFeedback = DateTime.now().difference(lastFeedback.submittedAt).inDays;
    return daysSinceLastFeedback >= 7;
  }

  // ==================== ANALYTICS ====================

  /// Generate feedback report
  Map<String, dynamic> generateReport() {
    final totalFeedback = _feedbackQueue.length;
    final byType = <String, int>{};
    final byStatus = <String, int>{};

    for (final feedback in _feedbackQueue) {
      byType[feedback.type.name] = (byType[feedback.type.name] ?? 0) + 1;
      byStatus[feedback.status.name] = (byStatus[feedback.status.name] ?? 0) + 1;
    }

    final ratings = _feedbackQueue
        .where((f) => f.rating != null)
        .map((f) => f.rating!)
        .toList();

    final avgRating = ratings.isNotEmpty
        ? ratings.reduce((a, b) => a + b) / ratings.length
        : 0.0;

    return {
      'total_feedback': totalFeedback,
      'by_type': byType,
      'by_status': byStatus,
      'average_rating': avgRating.toStringAsFixed(2),
      'total_ratings': ratings.length,
    };
  }

  // ==================== PRIVATE METHODS ====================

  /// Send feedback to backend (Supabase)
  Future<bool> _sendToBackend(FeedbackItem feedback) async {
    try {
      AppLogger.info('Sending feedback to backend: ${feedback.id}');

      await _supabase.from('feedback').insert({
        'id': feedback.id,
        'user_id': feedback.userId,
        'email': feedback.email,
        'type': feedback.type.name,
        'message': feedback.message,
        'rating': feedback.rating,
        'metadata': feedback.metadata,
        'status': feedback.status.name,
        'submitted_at': feedback.submittedAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      feedback.status = FeedbackStatus.inReview;
      feedback.updatedAt = DateTime.now();

      AppLogger.success('Feedback successfully sent to backend: ${feedback.id}');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to send feedback to backend', error: e, stack: stack);
      return false;
    }
  }

  /// Notify user of successful feedback submission
  Future<void> _notifyUserSuccess(FeedbackItem feedback) async {
    try {
      String title = 'Feedback Received';
      String body = 'Thank you for your feedback! We\'ll review it shortly.';

      switch (feedback.type) {
        case FeedbackType.bug:
          title = 'Bug Report Received';
          body = 'Thank you for reporting the issue. Our team will investigate.';
          break;
        case FeedbackType.featureRequest:
          title = 'Feature Request Received';
          body = 'Thank you for the suggestion! We\'ll consider it for future updates.';
          break;
        case FeedbackType.support:
          title = 'Support Request Received';
          body = 'Our support team will get back to you within 24 hours.';
          break;
        case FeedbackType.rating:
          if (feedback.rating != null && feedback.rating! >= 4) {
            title = 'Thank You!';
            body = 'We\'re glad you\'re enjoying the app!';
          } else {
            title = 'Thank You for Your Feedback';
            body = 'We\'re sorry to hear you had issues. We\'ll work on improving.';
          }
          break;
        default:
          break;
      }

      await _notificationService.showNotification(
        id: feedback.id.hashCode,
        title: title,
        body: body,
        payload: 'feedback:${feedback.id}',
      );
    } catch (e) {
      debugPrint('Failed to notify user of feedback submission: $e');
    }
  }

  /// Notify user of feedback status change
  Future<void> _notifyUserStatusChange(FeedbackItem feedback) async {
    try {
      String title = 'Feedback Update';
      String body = 'Your feedback status has been updated.';

      switch (feedback.status) {
        case FeedbackStatus.acknowledged:
          title = 'Feedback Acknowledged';
          body = 'We\'ve acknowledged your feedback and are looking into it.';
          break;
        case FeedbackStatus.resolved:
          title = 'Issue Resolved';
          body = 'Great news! Your feedback has been addressed.';
          break;
        case FeedbackStatus.closed:
          title = 'Feedback Closed';
          body = 'Your feedback has been reviewed and closed.';
          break;
        default:
          break;
      }

      await _notificationService.showNotification(
        id: feedback.id.hashCode,
        title: title,
        body: body,
        payload: 'feedback:${feedback.id}',
      );
    } catch (e) {
      debugPrint('Failed to notify user of status change: $e');
    }
  }
}

// ==================== MODELS ====================

enum FeedbackType {
  bug,
  featureRequest,
  improvement,
  complaint,
  compliment,
  support,
  rating,
  other,
}

enum FeedbackStatus {
  pending,
  inReview,
  acknowledged,
  resolved,
  closed,
}

enum SupportCategory {
  order,
  payment,
  delivery,
  account,
  technical,
  restaurant,
  other,
}

class FeedbackItem {
  final String id;
  final String userId;
  final String email;
  final FeedbackType type;
  final String message;
  final int? rating;
  final Map<String, dynamic>? metadata;
  final DateTime submittedAt;
  FeedbackStatus status;
  DateTime? updatedAt;

  FeedbackItem({
    required this.id,
    required this.userId,
    required this.email,
    required this.type,
    required this.message,
    this.rating,
    this.metadata,
    required this.submittedAt,
    required this.status,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'email': email,
    'type': type.name,
    'message': message,
    'rating': rating,
    'metadata': metadata,
    'submittedAt': submittedAt.toIso8601String(),
    'status': status.name,
    'updatedAt': updatedAt?.toIso8601String(),
  };
}
