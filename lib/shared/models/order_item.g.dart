// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  menuItemId: json['menuItemId'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unitPrice'] as num).toDouble(),
  customizations: json['customizations'] as Map<String, dynamic>?,
  specialInstructions: json['specialInstructions'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'menuItemId': instance.menuItemId,
  'quantity': instance.quantity,
  'unitPrice': instance.unitPrice,
  'customizations': instance.customizations,
  'specialInstructions': instance.specialInstructions,
};
