import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  final String id;
  final String userId;
 final String restaurantId;
  final Map<String, dynamic> deliveryAddress;
  final OrderStatus status;
  final double totalAmount;
  final double? subtotal;
  final double deliveryFee;
  final double taxAmount;
 final double? tipAmount;
  final double? discountAmount;
 final String? promoCode;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime placedAt;
  final DateTime? estimatedDeliveryAt;
  final DateTime? deliveredAt;
  final String? notes;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.deliveryAddress,
    required this.status,
    required this.totalAmount,
    this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    this.tipAmount,
    this.discountAmount,
    this.promoCode,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.placedAt,
    this.estimatedDeliveryAt,
    this.deliveredAt,
    this.notes,
    this.specialInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  Order copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    Map<String, dynamic>? deliveryAddress,
    OrderStatus? status,
    double? totalAmount,
    double? subtotal,
    double? deliveryFee,
    double? taxAmount,
    double? tipAmount,
    double? discountAmount,
    String? promoCode,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    DateTime? placedAt,
    DateTime? estimatedDeliveryAt,
    DateTime? deliveredAt,
    String? notes,
    String? specialInstructions,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      promoCode: promoCode ?? this.promoCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      placedAt: placedAt ?? this.placedAt,
      estimatedDeliveryAt: estimatedDeliveryAt ?? this.estimatedDeliveryAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }
}

enum OrderStatus { 
  placed, 
  confirmed, 
  preparing, 
  ready_for_pickup, 
  out_for_delivery, 
  delivered, 
  cancelled 
}

enum PaymentStatus { pending, completed, failed, refunded }