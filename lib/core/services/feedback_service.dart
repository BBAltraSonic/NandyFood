import 'package:food_delivery_app/core/utils/app_logger.dart';

/// User feedback collection service
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final List<FeedbackItem> _feedbackQueue = [];

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

    // TODO: Send to backend/support system
    await _sendToBackend(feedback);

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

      // TODO: Notify user of status change
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

  Future<void> _sendToBackend(FeedbackItem feedback) async {
    try {
      // TODO: Implement API call to send feedback to backend
      // For now, just log it
      AppLogger.debug('Feedback queued for backend submission', details: feedback.toJson().toString());
      
      // Simulate async operation
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e, stack) {
      AppLogger.error('Failed to send feedback to backend', error: e, stack: stack);
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
