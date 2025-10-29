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
  @JsonKey(name: 'delivery_address')
  final Map<String, dynamic> deliveryAddress;
  final OrderStatus status;
  final List<OrderItem>? orderItems;
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  final double? subtotal;
  @JsonKey(name: 'delivery_fee')
  final double deliveryFee;
  @JsonKey(name: 'tax_amount')
  final double taxAmount;
  @JsonKey(name: 'tip_amount')
  final double? tipAmount;
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
  @JsonKey(name: 'estimated_delivery_at')
  final DateTime? estimatedDeliveryAt;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  final String? notes;
  @JsonKey(name: 'special_instructions')
  final String? specialInstructions;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    this.customerName,
    required this.restaurantId,
    this.restaurantName,
    required this.deliveryAddress,
    required this.status,
    this.orderItems,
    required this.totalAmount,
    this.subtotal,
    required this.deliveryFee,
    required this.taxAmount,
    this.tipAmount,
    this.discountAmount,
    this.promoCode,
    required this.paymentMethod,
    required this.paymentStatus,
    this.payfastTransactionId,
    this.payfastSignature,
    this.paymentGateway,
    this.paymentReference,
    required this.placedAt,
    this.estimatedDeliveryAt,
    this.deliveredAt,
    this.notes,
    this.specialInstructions,
    DateTime? createdAt,
    DateTime? updatedAt,
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

  /// Getter for deliveryInstructions - returns specialInstructions
  String? get deliveryInstructions => specialInstructions;

  Order copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? restaurantId,
    String? restaurantName,
    Map<String, dynamic>? deliveryAddress,
    OrderStatus? status,
    List<OrderItem>? orderItems,
    double? totalAmount,
    double? subtotal,
    double? deliveryFee,
    double? taxAmount,
    double? tipAmount,
    double? discountAmount,
    String? promoCode,
    String? paymentMethod,
    PaymentStatus? paymentStatus,
    String? payfastTransactionId,
    String? payfastSignature,
    String? paymentGateway,
    String? paymentReference,
    DateTime? placedAt,
    DateTime? estimatedDeliveryAt,
    DateTime? deliveredAt,
    String? notes,
    String? specialInstructions,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      restaurantId: restaurantId ?? this.restaurantId,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      status: status ?? this.status,
      orderItems: orderItems ?? this.orderItems,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      taxAmount: taxAmount ?? this.taxAmount,
      tipAmount: tipAmount ?? this.tipAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      promoCode: promoCode ?? this.promoCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      payfastTransactionId: payfastTransactionId ?? this.payfastTransactionId,
      payfastSignature: payfastSignature ?? this.payfastSignature,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      paymentReference: paymentReference ?? this.paymentReference,
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
  cancelled,
}

enum PaymentStatus { pending, completed, failed, refunded }
