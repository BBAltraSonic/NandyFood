// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackModel _$FeedbackModelFromJson(Map<String, dynamic> json) =>
    FeedbackModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
      type: $enumDecode(_$FeedbackTypeEnumMap, json['type']),
      message: json['message'] as String,
      rating: (json['rating'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: $enumDecode(_$FeedbackStatusEnumMap, json['status']),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$FeedbackModelToJson(FeedbackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'email': instance.email,
      'type': _$FeedbackTypeEnumMap[instance.type]!,
      'message': instance.message,
      'rating': instance.rating,
      'metadata': instance.metadata,
      'status': _$FeedbackStatusEnumMap[instance.status]!,
      'submitted_at': instance.submittedAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$FeedbackTypeEnumMap = {
  FeedbackType.bug: 'bug',
  FeedbackType.featureRequest: 'feature_request',
  FeedbackType.improvement: 'improvement',
  FeedbackType.complaint: 'complaint',
  FeedbackType.compliment: 'compliment',
  FeedbackType.support: 'support',
  FeedbackType.rating: 'rating',
  FeedbackType.other: 'other',
};

const _$FeedbackStatusEnumMap = {
  FeedbackStatus.pending: 'pending',
  FeedbackStatus.inReview: 'in_review',
  FeedbackStatus.acknowledged: 'acknowledged',
  FeedbackStatus.resolved: 'resolved',
  FeedbackStatus.closed: 'closed',
};
