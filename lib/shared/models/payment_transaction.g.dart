// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentTransaction _$PaymentTransactionFromJson(Map<String, dynamic> json) =>
    PaymentTransaction(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentReference: json['payment_reference'] as String?,
      paymentGateway: json['payment_gateway'] as String?,
      status: $enumDecode(_$PaymentTransactionStatusEnumMap, json['status']),
      metadata: json['metadata'] as Map<String, dynamic>?,
      paymentResponse: json['payment_response'] as Map<String, dynamic>?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
    );

Map<String, dynamic> _$PaymentTransactionToJson(PaymentTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'user_id': instance.userId,
      'amount': instance.amount,
      'payment_method': instance.paymentMethod,
      'payment_reference': instance.paymentReference,
      'payment_gateway': instance.paymentGateway,
      'status': _$PaymentTransactionStatusEnumMap[instance.status]!,
      'metadata': instance.metadata,
      'payment_response': instance.paymentResponse,
      'error_message': instance.errorMessage,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'completed_at': instance.completedAt?.toIso8601String(),
    };

const _$PaymentTransactionStatusEnumMap = {
  PaymentTransactionStatus.pending: 'pending',
  PaymentTransactionStatus.completed: 'completed',
  PaymentTransactionStatus.failed: 'failed',
  PaymentTransactionStatus.cancelled: 'cancelled',
  PaymentTransactionStatus.refunded: 'refunded',
};
