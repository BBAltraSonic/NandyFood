// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Delivery _$DeliveryFromJson(Map<String, dynamic> json) => Delivery(
  id: json['id'] as String,
  orderId: json['order_id'] as String,
  driverId: json['driver_id'] as String?,
  driverName: json['driver_name'] as String?,
  driverPhone: json['driver_phone'] as String?,
  driverPhotoUrl: json['driver_photo_url'] as String?,
  vehicleType: json['vehicle_type'] as String?,
  vehicleNumber: json['vehicle_number'] as String?,
  currentLat: (json['current_lat'] as num?)?.toDouble(),
  currentLng: (json['current_lng'] as num?)?.toDouble(),
  lastLocationUpdate: json['last_location_update'] == null
      ? null
      : DateTime.parse(json['last_location_update'] as String),
  pickupLat: (json['pickup_lat'] as num?)?.toDouble(),
  pickupLng: (json['pickup_lng'] as num?)?.toDouble(),
  dropoffLat: (json['dropoff_lat'] as num?)?.toDouble(),
  dropoffLng: (json['dropoff_lng'] as num?)?.toDouble(),
  estimatedDistance: (json['estimated_distance'] as num?)?.toDouble(),
  estimatedDuration: (json['estimated_duration'] as num?)?.toInt(),
  status: $enumDecode(_$DeliveryStatusEnumMap, json['status']),
  assignedAt: json['assigned_at'] == null
      ? null
      : DateTime.parse(json['assigned_at'] as String),
  pickedUpAt: json['picked_up_at'] == null
      ? null
      : DateTime.parse(json['picked_up_at'] as String),
  deliveredAt: json['delivered_at'] == null
      ? null
      : DateTime.parse(json['delivered_at'] as String),
  deliveryPhotoUrl: json['delivery_photo_url'] as String?,
  deliverySignature: json['delivery_signature'] as String?,
  deliveryNotes: json['delivery_notes'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$DeliveryToJson(Delivery instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'driver_id': instance.driverId,
  'driver_name': instance.driverName,
  'driver_phone': instance.driverPhone,
  'driver_photo_url': instance.driverPhotoUrl,
  'vehicle_type': instance.vehicleType,
  'vehicle_number': instance.vehicleNumber,
  'current_lat': instance.currentLat,
  'current_lng': instance.currentLng,
  'last_location_update': instance.lastLocationUpdate?.toIso8601String(),
  'pickup_lat': instance.pickupLat,
  'pickup_lng': instance.pickupLng,
  'dropoff_lat': instance.dropoffLat,
  'dropoff_lng': instance.dropoffLng,
  'estimated_distance': instance.estimatedDistance,
  'estimated_duration': instance.estimatedDuration,
  'status': _$DeliveryStatusEnumMap[instance.status]!,
  'assigned_at': instance.assignedAt?.toIso8601String(),
  'picked_up_at': instance.pickedUpAt?.toIso8601String(),
  'delivered_at': instance.deliveredAt?.toIso8601String(),
  'delivery_photo_url': instance.deliveryPhotoUrl,
  'delivery_signature': instance.deliverySignature,
  'delivery_notes': instance.deliveryNotes,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.assigned: 'assigned',
  DeliveryStatus.pickedUp: 'pickedUp',
  DeliveryStatus.inTransit: 'inTransit',
  DeliveryStatus.delivered: 'delivered',
};
