// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Promotion _$PromotionFromJson(Map<String, dynamic> json) => Promotion(
  id: json['id'] as String,
  code: json['code'] as String,
  description: json['description'] as String,
  discountType: $enumDecode(_$PromotionTypeEnumMap, json['discountType']),
  discountValue: (json['discountValue'] as num).toDouble(),
  minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toDouble(),
  validFrom: DateTime.parse(json['validFrom'] as String),
  validUntil: DateTime.parse(json['validUntil'] as String),
  usageLimit: (json['usageLimit'] as num?)?.toInt(),
  usedCount: (json['usedCount'] as num).toInt(),
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$PromotionToJson(Promotion instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'description': instance.description,
  'discountType': _$PromotionTypeEnumMap[instance.discountType]!,
  'discountValue': instance.discountValue,
  'minimumOrderAmount': instance.minimumOrderAmount,
  'validFrom': instance.validFrom.toIso8601String(),
  'validUntil': instance.validUntil.toIso8601String(),
  'usageLimit': instance.usageLimit,
  'usedCount': instance.usedCount,
  'isActive': instance.isActive,
};

const _$PromotionTypeEnumMap = {
  PromotionType.percentage: 'percentage',
  PromotionType.fixedAmount: 'fixedAmount',
};
