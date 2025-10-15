// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payfast_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PayFastResponse _$PayFastResponseFromJson(Map<String, dynamic> json) =>
    PayFastResponse(
      paymentId: json['m_payment_id'] as String,
      pfPaymentId: json['pf_payment_id'] as String?,
      paymentStatus: json['payment_status'] as String,
      itemName: json['item_name'] as String,
      itemDescription: json['item_description'] as String?,
      amountGross: json['amount_gross'] as String?,
      amountFee: json['amount_fee'] as String?,
      amountNet: json['amount_net'] as String?,
      merchantId: json['merchant_id'] as String,
      signature: json['signature'] as String?,
      emailAddress: json['email_address'] as String?,
      nameFirst: json['name_first'] as String?,
      nameLast: json['name_last'] as String?,
    );

Map<String, dynamic> _$PayFastResponseToJson(PayFastResponse instance) =>
    <String, dynamic>{
      'm_payment_id': instance.paymentId,
      'pf_payment_id': instance.pfPaymentId,
      'payment_status': instance.paymentStatus,
      'item_name': instance.itemName,
      'item_description': instance.itemDescription,
      'amount_gross': instance.amountGross,
      'amount_fee': instance.amountFee,
      'amount_net': instance.amountNet,
      'merchant_id': instance.merchantId,
      'signature': instance.signature,
      'email_address': instance.emailAddress,
      'name_first': instance.nameFirst,
      'name_last': instance.nameLast,
    };
