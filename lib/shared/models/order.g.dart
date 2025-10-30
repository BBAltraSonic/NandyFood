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
  pickupAddress: json['pickup_address'] as Map<String, dynamic>,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  orderItems: (json['orderItems'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  totalAmount: (json['total_amount'] as num).toDouble(),
  subtotal: (json['subtotal'] as num?)?.toDouble(),
  taxAmount: (json['tax_amount'] as num).toDouble(),
  discountAmount: (json['discount_amount'] as num?)?.toDouble(),
  promoCode: json['promo_code'] as String?,
  paymentMethod: json['payment_method'] as String,
  paymentStatus: $enumDecode(_$PaymentStatusEnumMap, json['payment_status']),
  payfastTransactionId: json['payfast_transaction_id'] as String?,
  payfastSignature: json['payfast_signature'] as String?,
  paymentGateway: json['payment_gateway'] as String?,
  paymentReference: json['payment_reference'] as String?,
  placedAt: DateTime.parse(json['placed_at'] as String),
  notes: json['notes'] as String?,
  pickupInstructions: json['pickup_instructions'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  estimatedPreparationTime:
      (json['estimated_preparation_time'] as num?)?.toInt() ?? 15,
  actualPreparationTime: (json['actual_preparation_time'] as num?)?.toInt(),
  preparationStartedAt: json['preparation_started_at'] == null
      ? null
      : DateTime.parse(json['preparation_started_at'] as String),
  preparationCompletedAt: json['preparation_completed_at'] == null
      ? null
      : DateTime.parse(json['preparation_completed_at'] as String),
  customerNotifiedAt: json['customer_notified_at'] == null
      ? null
      : DateTime.parse(json['customer_notified_at'] as String),
  pickupReadyConfirmedAt: json['pickup_ready_confirmed_at'] == null
      ? null
      : DateTime.parse(json['pickup_ready_confirmed_at'] as String),
  confirmedAt: json['confirmed_at'] == null
      ? null
      : DateTime.parse(json['confirmed_at'] as String),
  preparingAt: json['preparing_at'] == null
      ? null
      : DateTime.parse(json['preparing_at'] as String),
  readyAt: json['ready_at'] == null
      ? null
      : DateTime.parse(json['ready_at'] as String),
  cancelledAt: json['cancelled_at'] == null
      ? null
      : DateTime.parse(json['cancelled_at'] as String),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'customerName': instance.customerName,
  'restaurant_id': instance.restaurantId,
  'restaurantName': instance.restaurantName,
  'pickup_address': instance.pickupAddress,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'orderItems': instance.orderItems,
  'total_amount': instance.totalAmount,
  'subtotal': instance.subtotal,
  'tax_amount': instance.taxAmount,
  'discount_amount': instance.discountAmount,
  'promo_code': instance.promoCode,
  'payment_method': instance.paymentMethod,
  'payment_status': _$PaymentStatusEnumMap[instance.paymentStatus]!,
  'payfast_transaction_id': instance.payfastTransactionId,
  'payfast_signature': instance.payfastSignature,
  'payment_gateway': instance.paymentGateway,
  'payment_reference': instance.paymentReference,
  'placed_at': instance.placedAt.toIso8601String(),
  'notes': instance.notes,
  'pickup_instructions': instance.pickupInstructions,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
  'estimated_preparation_time': instance.estimatedPreparationTime,
  'actual_preparation_time': instance.actualPreparationTime,
  'preparation_started_at': instance.preparationStartedAt?.toIso8601String(),
  'preparation_completed_at': instance.preparationCompletedAt
      ?.toIso8601String(),
  'customer_notified_at': instance.customerNotifiedAt?.toIso8601String(),
  'pickup_ready_confirmed_at': instance.pickupReadyConfirmedAt
      ?.toIso8601String(),
  'confirmed_at': instance.confirmedAt?.toIso8601String(),
  'preparing_at': instance.preparingAt?.toIso8601String(),
  'ready_at': instance.readyAt?.toIso8601String(),
  'cancelled_at': instance.cancelledAt?.toIso8601String(),
};

const _$OrderStatusEnumMap = {
  OrderStatus.placed: 'placed',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.preparing: 'preparing',
  OrderStatus.ready_for_pickup: 'ready_for_pickup',
  OrderStatus.cancelled: 'cancelled',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.pending: 'pending',
  PaymentStatus.completed: 'completed',
  PaymentStatus.failed: 'failed',
  PaymentStatus.refunded: 'refunded',
};
