import 'package:json_annotation/json_annotation.dart';

part 'promotion.g.dart';

@JsonSerializable()
class Promotion {
  final String id;
  final String code;
  final String description;
  final PromotionType discountType;
  final double discountValue;
  final double? minimumOrderAmount;
  final DateTime validFrom;
  final DateTime validUntil;
  final int? usageLimit;
  final int usedCount;
  final bool isActive;

  Promotion({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumOrderAmount,
    required this.validFrom,
    required this.validUntil,
    this.usageLimit,
    required this.usedCount,
    required this.isActive,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) =>
      _$PromotionFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionToJson(this);

  Promotion copyWith({
    String? id,
    String? code,
    String? description,
    PromotionType? discountType,
    double? discountValue,
    double? minimumOrderAmount,
    DateTime? validFrom,
    DateTime? validUntil,
    int? usageLimit,
    int? usedCount,
    bool? isActive,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      usageLimit: usageLimit ?? this.usageLimit,
      usedCount: usedCount ?? this.usedCount,
      isActive: isActive ?? this.isActive,
    );
  }
}

enum PromotionType { percentage, fixedAmount }
