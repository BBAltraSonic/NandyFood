// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: json['id'] as String,
  userId: json['userId'] as String,
  restaurantId: json['restaurantId'] as String,
  deliveryAddress: json['deliveryAddress'] as Map<String, dynamic>,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  orderItems: (json['orderItems'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  subtotal: (json['subtotal'] as num?)?.toDouble(),
  deliveryFee: (json['deliveryFee'] as num).toDouble(),
  taxAmount: (json['taxAmount'] as num).toDouble(),
  tipAmount: (json['tipAmount'] as num?)?.toDouble(),
  discountAmount: (json['discountAmount'] as num?)?.toDouble(),
  promoCode: json['promoCode'] as String?,
  paymentMethod: json['paymentMethod'] as String,
  paymentStatus: $enumDecode(_$PaymentStatusEnumMap, json['paymentStatus']),
  payfastTransactionId: json['payfast_transaction_id'] as String?,
  payfastSignature: json['payfast_signature'] as String?,
  paymentGateway: json['payment_gateway'] as String?,
  paymentReference: json['payment_reference'] as String?,
  placedAt: DateTime.parse(json['placedAt'] as String),
  estimatedDeliveryAt: json['estimatedDeliveryAt'] == null
      ? null
      : DateTime.parse(json['estimatedDeliveryAt'] as String),
  deliveredAt: json['deliveredAt'] == null
      ? null
      : DateTime.parse(json['deliveredAt'] as String),
  notes: json['notes'] as String?,
  specialInstructions: json['specialInstructions'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'restaurantId': instance.restaurantId,
  'deliveryAddress': instance.deliveryAddress,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'orderItems': instance.orderItems,
  'totalAmount': instance.totalAmount,
  'subtotal': instance.subtotal,
  'deliveryFee': instance.deliveryFee,
  'taxAmount': instance.taxAmount,
  'tipAmount': instance.tipAmount,
  'discountAmount': instance.discountAmount,
  'promoCode': instance.promoCode,
  'paymentMethod': instance.paymentMethod,
  'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
  'payfast_transaction_id': instance.payfastTransactionId,
  'payfast_signature': instance.payfastSignature,
  'payment_gateway': instance.paymentGateway,
  'payment_reference': instance.paymentReference,
  'placedAt': instance.placedAt.toIso8601String(),
  'estimatedDeliveryAt': instance.estimatedDeliveryAt?.toIso8601String(),
  'deliveredAt': instance.deliveredAt?.toIso8601String(),
  'notes': instance.notes,
  'specialInstructions': instance.specialInstructions,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
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
