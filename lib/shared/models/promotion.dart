import 'package:json_annotation/json_annotation.dart';

part 'promotion.g.dart';

enum PromotionType {
  @JsonValue('percentage')
  percentage,
  @JsonValue('fixed_amount')
  fixedAmount,
  @JsonValue('free_delivery')
  freeDelivery,
  @JsonValue('bogo')
  bogo, // Buy One Get One
}

enum PromotionStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('expired')
  expired,
  @JsonValue('upcoming')
  upcoming,
}

@JsonSerializable()
class Promotion {
  final String id;
  final String code;
  final String title;
  final String description;
  @JsonKey(name: 'promotion_type')
  final PromotionType promotionType;
  @JsonKey(name: 'discount_value')
  final double discountValue;
  @JsonKey(name: 'min_order_amount')
  final double? minOrderAmount;
  @JsonKey(name: 'max_discount_amount')
  final double? maxDiscountAmount;
  @JsonKey(name: 'start_date')
  final DateTime startDate;
  @JsonKey(name: 'end_date')
  final DateTime endDate;
  @JsonKey(name: 'usage_limit')
  final int? usageLimit;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'user_usage_limit')
  final int? userUsageLimit;
  @JsonKey(name: 'restaurant_id')
  final String? restaurantId;
  @JsonKey(name: 'is_first_order_only')
  final bool isFirstOrderOnly;
  final PromotionStatus status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Promotion({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.promotionType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscountAmount,
    required this.startDate,
    required this.endDate,
    this.usageLimit,
    this.usageCount = 0,
    this.userUsageLimit,
    this.restaurantId,
    this.isFirstOrderOnly = false,
    required this.status,
    required this.createdAt,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) =>
      _$PromotionFromJson(json);

  Map<String, dynamic> toJson() => _$PromotionToJson(this);

  /// Check if promotion is currently valid
  bool get isValid {
    final now = DateTime.now();
    return status == PromotionStatus.active &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        (usageLimit == null || usageCount < usageLimit!);
  }

  /// Check if promotion has expired
  bool get isExpired {
    return DateTime.now().isAfter(endDate) ||
        status == PromotionStatus.expired ||
        (usageLimit != null && usageCount >= usageLimit!);
  }

  /// Calculate discount amount for a given order total
  double calculateDiscount(double orderAmount) {
    if (!isValid) return 0.0;
    if (minOrderAmount != null && orderAmount < minOrderAmount!) return 0.0;

    double discount = 0.0;

    switch (promotionType) {
      case PromotionType.percentage:
        discount = orderAmount * (discountValue / 100);
        break;
      case PromotionType.fixedAmount:
        discount = discountValue;
        break;
      case PromotionType.freeDelivery:
        // Delivery fee should be passed separately
        discount = discountValue;
        break;
      case PromotionType.bogo:
        // BOGO logic would need item details
        discount = discountValue;
        break;
    }

    // Apply max discount cap if specified
    if (maxDiscountAmount != null && discount > maxDiscountAmount!) {
      discount = maxDiscountAmount!;
    }

    return discount;
  }

  /// Get formatted discount text
  String get discountText {
    switch (promotionType) {
      case PromotionType.percentage:
        return '${discountValue.toInt()}% OFF';
      case PromotionType.fixedAmount:
        return 'R${discountValue.toStringAsFixed(2)} OFF';
      case PromotionType.freeDelivery:
        return 'FREE DELIVERY';
      case PromotionType.bogo:
        return 'BUY 1 GET 1';
    }
  }

  /// Get time remaining text
  String get timeRemainingText {
    final now = DateTime.now();
    final difference = endDate.difference(now);

    if (difference.isNegative) return 'Expired';

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} left';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} left';
    }
  }

  Promotion copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    PromotionType? promotionType,
    double? discountValue,
    double? minOrderAmount,
    double? maxDiscountAmount,
    DateTime? startDate,
    DateTime? endDate,
    int? usageLimit,
    int? usageCount,
    int? userUsageLimit,
    String? restaurantId,
    bool? isFirstOrderOnly,
    PromotionStatus? status,
    DateTime? createdAt,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      promotionType: promotionType ?? this.promotionType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      userUsageLimit: userUsageLimit ?? this.userUsageLimit,
      restaurantId: restaurantId ?? this.restaurantId,
      isFirstOrderOnly: isFirstOrderOnly ?? this.isFirstOrderOnly,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
