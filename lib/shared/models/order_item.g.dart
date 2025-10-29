// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  menuItemId: json['menu_item_id'] as String,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unit_price'] as num).toDouble(),
  customizations: json['customizations'] as Map<String, dynamic>?,
  specialInstructions: json['specialInstructions'] as String?,
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'menu_item_id': instance.menuItemId,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'customizations': instance.customizations,
  'specialInstructions': instance.specialInstructions,
};
