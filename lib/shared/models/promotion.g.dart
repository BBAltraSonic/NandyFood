// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Promotion _$PromotionFromJson(Map<String, dynamic> json) => Promotion(
  id: json['id'] as String,
  code: json['code'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  promotionType: $enumDecode(_$PromotionTypeEnumMap, json['promotion_type']),
  discountValue: (json['discount_value'] as num).toDouble(),
  minOrderAmount: (json['min_order_amount'] as num?)?.toDouble(),
  maxDiscountAmount: (json['max_discount_amount'] as num?)?.toDouble(),
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  usageLimit: (json['usage_limit'] as num?)?.toInt(),
  usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
  userUsageLimit: (json['user_usage_limit'] as num?)?.toInt(),
  restaurantId: json['restaurant_id'] as String?,
  isFirstOrderOnly: json['is_first_order_only'] as bool? ?? false,
  status: $enumDecode(_$PromotionStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$PromotionToJson(Promotion instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'title': instance.title,
  'description': instance.description,
  'promotion_type': _$PromotionTypeEnumMap[instance.promotionType]!,
  'discount_value': instance.discountValue,
  'min_order_amount': instance.minOrderAmount,
  'max_discount_amount': instance.maxDiscountAmount,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'usage_limit': instance.usageLimit,
  'usage_count': instance.usageCount,
  'user_usage_limit': instance.userUsageLimit,
  'restaurant_id': instance.restaurantId,
  'is_first_order_only': instance.isFirstOrderOnly,
  'status': _$PromotionStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
};

const _$PromotionTypeEnumMap = {
  PromotionType.percentage: 'percentage',
  PromotionType.fixedAmount: 'fixed_amount',
  PromotionType.freeDelivery: 'free_delivery',
  PromotionType.bogo: 'bogo',
};

const _$PromotionStatusEnumMap = {
  PromotionStatus.active: 'active',
  PromotionStatus.inactive: 'inactive',
  PromotionStatus.expired: 'expired',
  PromotionStatus.upcoming: 'upcoming',
};
