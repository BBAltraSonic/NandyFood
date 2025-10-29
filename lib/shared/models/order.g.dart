// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  customerName: json['customerName'] as String?,
  restaurantId: json['restaurant_id'] as String,
  restaurantName: json['restaurantName'] as String?,
  deliveryAddress: json['delivery_address'] as Map<String, dynamic>,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  orderItems: (json['orderItems'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['total_amount'] as num).toDouble(),
  subtotal: (json['subtotal'] as num?)?.toDouble(),
  deliveryFee: (json['delivery_fee'] as num).toDouble(),
  taxAmount: (json['tax_amount'] as num).toDouble(),
  tipAmount: (json['tip_amount'] as num?)?.toDouble(),
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
  promoCode: json['promo_code'] as String?,
  paymentMethod: json['payment_method'] as String,
  paymentStatus: $enumDecode(_$PaymentStatusEnumMap, json['payment_status']),
  payfastTransactionId: json['payfast_transaction_id'] as String?,
  payfastSignature: json['payfast_signature'] as String?,
  paymentGateway: json['payment_gateway'] as String?,
  paymentReference: json['payment_reference'] as String?,
  placedAt: DateTime.parse(json['placed_at'] as String),
  estimatedDeliveryAt: json['estimated_delivery_at'] == null
      ? null
      : DateTime.parse(json['estimated_delivery_at'] as String),
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  notes: json['notes'] as String?,
  specialInstructions: json['special_instructions'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'customerName': instance.customerName,
  'restaurant_id': instance.restaurantId,
  'restaurantName': instance.restaurantName,
  'delivery_address': instance.deliveryAddress,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'orderItems': instance.orderItems,
  'total_amount': instance.totalAmount,
  'subtotal': instance.subtotal,
  'delivery_fee': instance.deliveryFee,
  'tax_amount': instance.taxAmount,
  'tip_amount': instance.tipAmount,
  'discount_amount': instance.discountAmount,
  'promo_code': instance.promoCode,
  'payment_method': instance.paymentMethod,
  'payment_status': _$PaymentStatusEnumMap[instance.paymentStatus]!,
  'payfast_transaction_id': instance.payfastTransactionId,
  'payfast_signature': instance.payfastSignature,
  'payment_gateway': instance.paymentGateway,
  'payment_reference': instance.paymentReference,
  'placed_at': instance.placedAt.toIso8601String(),
  'estimated_delivery_at': instance.estimatedDeliveryAt?.toIso8601String(),
  'delivered_at': instance.deliveredAt?.toIso8601String(),
  'notes': instance.notes,
  'special_instructions': instance.specialInstructions,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.placed: 'placed',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready_for_pickup: 'ready_for_pickup',
  OrderStatus.out_for_delivery: 'out_for_delivery',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
};
