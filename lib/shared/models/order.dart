import 'package:json_annotation/json_annotation.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String? customerName;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final String? restaurantName;
  @JsonKey(name: 'pickup_address')
  final Map<String, dynamic> pickupAddress;
  final OrderStatus status;
  final List<OrderItem>? orderItems;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  final double? subtotal;
  @JsonKey(name: 'tax_amount')
  final double taxAmount;
  @JsonKey(name: 'discount_amount')
  final double? discountAmount;
  @JsonKey(name: 'promo_code')
  final String? promoCode;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_status')
  final PaymentStatus paymentStatus;
  @JsonKey(name: 'payfast_transaction_id')
  final String? payfastTransactionId;
  @JsonKey(name: 'payfast_signature')
  final String? payfastSignature;
  @JsonKey(name: 'payment_gateway')
  final String? paymentGateway;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;
  @JsonKey(name: 'placed_at')
  final DateTime placedAt;
  final String? notes;
  @JsonKey(name: 'pickup_instructions')
  final String? pickupInstructions;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Preparation tracking fields
  @JsonKey(name: 'estimated_preparation_time')
  final int estimatedPreparationTime; // in minutes
  @JsonKey(name: 'actual_preparation_time')
  final int? actualPreparationTime; // in minutes
  @JsonKey(name: 'preparation_started_at')
  final DateTime? preparationStartedAt;
  @JsonKey(name: 'preparation_completed_at')
  final DateTime? preparationCompletedAt;
  @JsonKey(name: 'customer_notified_at')
  final DateTime? customerNotifiedAt;
  @JsonKey(name: 'pickup_ready_confirmed_at')
  final DateTime? pickupReadyConfirmedAt;

  // Status timestamps
  @JsonKey(name: 'confirmed_at')
  final DateTime? confirmedAt;
  @JsonKey(name: 'preparing_at')
  final DateTime? preparingAt;
  @JsonKey(name: 'ready_at')
  final DateTime? readyAt;
  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  Order({
    required this.id,
    required this.userId,
    this.customerName,
    required this.restaurantId,
    this.restaurantName,
    required this.pickupAddress,
    required this.status,
    this.orderItems,
    required this.totalAmount,
    this.subtotal,
    required this.taxAmount,
    this.discountAmount,
    this.promoCode,
    required this.paymentMethod,
    required this.paymentStatus,
    this.payfastTransactionId,
    this.payfastSignature,
    this.paymentGateway,
    this.paymentReference,
    required this.placedAt,
    this.notes,
    this.pickupInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.estimatedPreparationTime = 15,
    this.actualPreparationTime,
    this.preparationStartedAt,
    this.preparationCompletedAt,
    this.customerNotifiedAt,
    this.pickupReadyConfirmedAt,
    this.confirmedAt,
    this.preparingAt,
    this.readyAt,
    this.cancelledAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  /// Getter for items - returns orderItems or empty list
  List<OrderItem> get items => orderItems ?? [];

  /// Getter for tax - returns taxAmount
  double get tax => taxAmount;

  /// Getter for total - returns totalAmount
  double get total => totalAmount;

  /// Getter for pickupInstructions - returns pickupInstructions
  String? get pickupInstructionsText => pickupInstructions;

  /// Check if order is currently being prepared
  bool get isBeingPrepared => status == OrderStatus.preparing;

  /// Check if order is ready for pickup
  bool get isReadyForPickup => status == OrderStatus.ready_for_pickup;

  /// Check if preparation has started
  bool get hasPreparationStarted => preparationStartedAt != null;

  /// Check if preparation is completed
  bool get isPreparationCompleted => preparationCompletedAt != null;

  /// Get remaining preparation time in minutes
  int get remainingPreparationMinutes {
    if (!isBeingPrepared || preparationStartedAt == null) return 0;

    final elapsed = DateTime.now().difference(preparationStartedAt!).inMinutes;
    return (estimatedPreparationTime - elapsed).clamp(0, estimatedPreparationTime);
  }

  /// Get preparation efficiency percentage
  double? get preparationEfficiency {
    if (actualPreparationTime == null || actualPreparationTime == 0) return null;
    return (estimatedPreparationTime / actualPreparationTime!) * 100;
  }

  /// Get formatted preparation status text
  String get preparationStatusText {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Order confirmed - Preparing soon';
      case OrderStatus.preparing:
        final remaining = remainingPreparationMinutes;
        if (remaining > 0) {
          return 'Preparing - $remaining min remaining';
        }
        return 'Preparing - Almost ready';
      case OrderStatus.ready_for_pickup:
        return 'Ready for pickup!';
      case OrderStatus.cancelled:
        return 'Order cancelled';
      case OrderStatus.placed:
        return 'Order placed - Awaiting confirmation';
    }
  }

  Order copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? restaurantId,
    String? restaurantName,
    Map<String, dynamic>? pickupAddress,
    OrderStatus? status,
    List<OrderItem>? orderItems,
    double? totalAmount,
    double? subtotal,
    double? taxAmount,
    double? discountAmount,
    String? promoCode,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    String? payfastTransactionId,
    String? payfastSignature,
    String? paymentGateway,
    String? paymentReference,
    DateTime? placedAt,
    String? notes,
    String? pickupInstructions,
    int? estimatedPreparationTime,
    int? actualPreparationTime,
    DateTime? preparationStartedAt,
    DateTime? preparationCompletedAt,
    DateTime? customerNotifiedAt,
    DateTime? pickupReadyConfirmedAt,
    DateTime? confirmedAt,
    DateTime? preparingAt,
    DateTime? readyAt,
    DateTime? cancelledAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      restaurantId: restaurantId ?? this.restaurantId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      status: status ?? this.status,
      orderItems: orderItems ?? this.orderItems,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      promoCode: promoCode ?? this.promoCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      payfastTransactionId: payfastTransactionId ?? this.payfastTransactionId,
      payfastSignature: payfastSignature ?? this.payfastSignature,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      paymentReference: paymentReference ?? this.paymentReference,
      placedAt: placedAt ?? this.placedAt,
      notes: notes ?? this.notes,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      estimatedPreparationTime: estimatedPreparationTime ?? this.estimatedPreparationTime,
      actualPreparationTime: actualPreparationTime ?? this.actualPreparationTime,
      preparationStartedAt: preparationStartedAt ?? this.preparationStartedAt,
      preparationCompletedAt: preparationCompletedAt ?? this.preparationCompletedAt,
      customerNotifiedAt: customerNotifiedAt ?? this.customerNotifiedAt,
      pickupReadyConfirmedAt: pickupReadyConfirmedAt ?? this.pickupReadyConfirmedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      preparingAt: preparingAt ?? this.preparingAt,
      readyAt: readyAt ?? this.readyAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}

enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready_for_pickup,
  cancelled,
}

enum PaymentStatus { pending, completed, failed, refunded }
