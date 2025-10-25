import 'package:json_annotation/json_annotation.dart';

part 'feedback.g.dart';

/// Feedback type enum
enum FeedbackType {
  @JsonValue('bug')
  bug,
  @JsonValue('feature_request')
  featureRequest,
  @JsonValue('improvement')
  improvement,
  @JsonValue('complaint')
  complaint,
  @JsonValue('compliment')
  compliment,
  @JsonValue('support')
  support,
  @JsonValue('rating')
  rating,
  @JsonValue('other')
  other,
}

/// Feedback status enum
enum FeedbackStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_review')
  inReview,
  @JsonValue('acknowledged')
  acknowledged,
  @JsonValue('resolved')
  resolved,
  @JsonValue('closed')
  closed,
}

/// Feedback model
@JsonSerializable()
class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.type,
    required this.message,
    this.rating,
    this.metadata,
    required this.status,
    required this.submittedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  final String email;
  
  final FeedbackType type;
  
  final String message;
  
  final int? rating;
  
  final Map<String, dynamic>? metadata;
  
  final FeedbackStatus status;
  
  @JsonKey(name: 'submitted_at')
  final DateTime submittedAt;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  factory FeedbackModel.fromJson(Map<String, dynamic> json) =>
      _$FeedbackModelFromJson(json);

  Map<String, dynamic> toJson() => _$FeedbackModelToJson(this);

  FeedbackModel copyWith({
    String? id,
    String? userId,
    String? email,
    FeedbackType? type,
    String? message,
    int? rating,
    Map<String, dynamic>? metadata,
    FeedbackStatus? status,
    DateTime? submittedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      type: type ?? this.type,
      message: message ?? this.message,
      rating: rating ?? this.rating,
      metadata: metadata ?? this.metadata,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Support category enum (for support requests)
enum SupportCategory {
  order,
  payment,
  delivery,
  account,
  technical,
  restaurant,
  other,
}
