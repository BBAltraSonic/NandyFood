import 'package:json_annotation/json_annotation.dart';

part 'payfast_response.g.dart';

@JsonSerializable()
class PayFastResponse {
  @JsonKey(name: 'm_payment_id')
  final String paymentId;
  @JsonKey(name: 'pf_payment_id')
  final String? pfPaymentId;
  @JsonKey(name: 'payment_status')
  final String paymentStatus;
  @JsonKey(name: 'item_name')
  final String itemName;
  @JsonKey(name: 'item_description')
  final String? itemDescription;
  @JsonKey(name: 'amount_gross')
  final String? amountGross;
  @JsonKey(name: 'amount_fee')
  final String? amountFee;
  @JsonKey(name: 'amount_net')
  final String? amountNet;
  @JsonKey(name: 'merchant_id')
  final String merchantId;
  final String? signature;
  @JsonKey(name: 'email_address')
  final String? emailAddress;
  @JsonKey(name: 'name_first')
  final String? nameFirst;
  @JsonKey(name: 'name_last')
  final String? nameLast;

  PayFastResponse({
    required this.paymentId,
    this.pfPaymentId,
    required this.paymentStatus,
    required this.itemName,
    this.itemDescription,
    this.amountGross,
    this.amountFee,
    this.amountNet,
    required this.merchantId,
    this.signature,
    this.emailAddress,
    this.nameFirst,
    this.nameLast,
  });

  factory PayFastResponse.fromJson(Map<String, dynamic> json) =>
      _$PayFastResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PayFastResponseToJson(this);

  /// Convert to Map<String, String> for signature verification
  Map<String, String> toStringMap() {
    final map = toJson();
    return map.map((key, value) => MapEntry(key, value.toString()));
  }

  /// Helper getters
  bool get isComplete => paymentStatus.toUpperCase() == 'COMPLETE';
  bool get isFailed => paymentStatus.toUpperCase() == 'FAILED';
  bool get isCancelled => paymentStatus.toUpperCase() == 'CANCELLED';

  double? get grossAmount {
    if (amountGross == null) return null;
    return double.tryParse(amountGross!);
  }

  double? get feeAmount {
    if (amountFee == null) return null;
    return double.tryParse(amountFee!);
  }

  double? get netAmount {
    if (amountNet == null) return null;
    return double.tryParse(amountNet!);
  }

  String get statusDisplayName {
    switch (paymentStatus.toUpperCase()) {
      case 'COMPLETE':
        return 'Payment Successful';
      case 'FAILED':
        return 'Payment Failed';
      case 'CANCELLED':
        return 'Payment Cancelled';
      default:
        return 'Payment Processing';
    }
  }
}
