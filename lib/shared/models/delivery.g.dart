// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Delivery _$DeliveryFromJson(Map<String, dynamic> json) => Delivery(
  id: json['id'] as String,
  orderId: json['orderId'] as String,
  driverId: json['driverId'] as String?,
  estimatedArrival: json['estimatedArrival'] == null
      ? null
      : DateTime.parse(json['estimatedArrival'] as String),
  actualArrival: json['actualArrival'] == null
      ? null
      : DateTime.parse(json['actualArrival'] as String),
  currentLocation: json['currentLocation'] as Map<String, dynamic>?,
  status: $enumDecode(_$DeliveryStatusEnumMap, json['status']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$DeliveryToJson(Delivery instance) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'driverId': instance.driverId,
  'estimatedArrival': instance.estimatedArrival?.toIso8601String(),
  'actualArrival': instance.actualArrival?.toIso8601String(),
  'currentLocation': instance.currentLocation,
  'status': _$DeliveryStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.assigned: 'assigned',
  DeliveryStatus.pickedUp: 'pickedUp',
  DeliveryStatus.inTransit: 'inTransit',
  DeliveryStatus.delivered: 'delivered',
};
