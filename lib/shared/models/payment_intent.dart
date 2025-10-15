import 'package:json_annotation/json_annotation.dart';

part 'payment_intent.g.dart';

@JsonSerializable()
class PaymentIntent {
  final String orderId;
  final String userId;
  final double amount;
  final String itemName;
  final String? itemDescription;
  final String? customerEmail;
  final String? customerFirstName;
  final String? customerLastName;
  final String? customerPhone;
  final PaymentMethod paymentMethod;
  final Map<String, dynamic>? metadata;

  PaymentIntent({
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.itemName,
    this.itemDescription,
    this.customerEmail,
    this.customerFirstName,
    this.customerLastName,
    this.customerPhone,
    required this.paymentMethod,
    this.metadata,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) =>
      _$PaymentIntentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentIntentToJson(this);

  PaymentIntent copyWith({
    String? orderId,
    String? userId,
    double? amount,
    String? itemName,
    String? itemDescription,
    String? customerEmail,
    String? customerFirstName,
    String? customerLastName,
    String? customerPhone,
    PaymentMethod? paymentMethod,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentIntent(
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      itemName: itemName ?? this.itemName,
      itemDescription: itemDescription ?? this.itemDescription,
      customerEmail: customerEmail ?? this.customerEmail,
      customerFirstName: customerFirstName ?? this.customerFirstName,
      customerLastName: customerLastName ?? this.customerLastName,
      customerPhone: customerPhone ?? this.customerPhone,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Helper getters
  bool get isCash => paymentMethod == PaymentMethod.cash;
  bool get isPayFast => paymentMethod == PaymentMethod.payfast;
}

enum PaymentMethod {
  @JsonValue('cash')
  cash,
  @JsonValue('payfast')
  payfast,
}
