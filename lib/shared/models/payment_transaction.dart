import 'package:json_annotation/json_annotation.dart';

part 'payment_transaction.g.dart';

@JsonSerializable()
class PaymentTransaction {
  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'user_id')
  final String userId;
  final double amount;
  @JsonKey(name: 'payment_method')
  final String paymentMethod;
  @JsonKey(name: 'payment_reference')
  final String? paymentReference;
  @JsonKey(name: 'payment_gateway')
  final String? paymentGateway;
  final PaymentTransactionStatus status;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'payment_response')
  final Map<String, dynamic>? paymentResponse;
  @JsonKey(name: 'error_message')
  final String? errorMessage;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'completed_at')
  final DateTime? completedAt;

  PaymentTransaction({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.paymentReference,
    this.paymentGateway,
    required this.status,
    this.metadata,
    this.paymentResponse,
    this.errorMessage,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) =>
      _$PaymentTransactionFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentTransactionToJson(this);

  PaymentTransaction copyWith({
    String? id,
    String? orderId,
    String? userId,
    double? amount,
    String? paymentMethod,
    String? paymentReference,
    String? paymentGateway,
    PaymentTransactionStatus? status,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? paymentResponse,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentGateway: paymentGateway ?? this.paymentGateway,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      paymentResponse: paymentResponse ?? this.paymentResponse,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Helper getters
  bool get isPending => status == PaymentTransactionStatus.pending;
  bool get isCompleted => status == PaymentTransactionStatus.completed;
  bool get isFailed => status == PaymentTransactionStatus.failed;
  bool get isCancelled => status == PaymentTransactionStatus.cancelled;
  bool get isRefunded => status == PaymentTransactionStatus.refunded;

  String get statusDisplayName {
    switch (status) {
      case PaymentTransactionStatus.pending:
        return 'Pending';
      case PaymentTransactionStatus.completed:
        return 'Completed';
      case PaymentTransactionStatus.failed:
        return 'Failed';
      case PaymentTransactionStatus.cancelled:
        return 'Cancelled';
      case PaymentTransactionStatus.refunded:
        return 'Refunded';
    }
  }
}

enum PaymentTransactionStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('refunded')
  refunded,
}
