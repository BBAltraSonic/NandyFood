import 'package:json_annotation/json_annotation.dart';

part 'delivery.g.dart';

@JsonSerializable()
class Delivery {
  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'driver_id')
  final String? driverId;
  @JsonKey(name: 'driver_name')
  final String? driverName;
  @JsonKey(name: 'driver_phone')
  final String? driverPhone;
  @JsonKey(name: 'driver_photo_url')
  final String? driverPhotoUrl;
  @JsonKey(name: 'vehicle_type')
  final String? vehicleType;
  @JsonKey(name: 'vehicle_number')
  final String? vehicleNumber;
  @JsonKey(name: 'current_lat')
  final double? currentLat;
  @JsonKey(name: 'current_lng')
  final double? currentLng;
  @JsonKey(name: 'last_location_update')
  final DateTime? lastLocationUpdate;
  @JsonKey(name: 'pickup_lat')
  final double? pickupLat;
  @JsonKey(name: 'pickup_lng')
  final double? pickupLng;
  @JsonKey(name: 'dropoff_lat')
  final double? dropoffLat;
  @JsonKey(name: 'dropoff_lng')
  final double? dropoffLng;
  @JsonKey(name: 'estimated_distance')
  final double? estimatedDistance;
  @JsonKey(name: 'estimated_duration')
  final int? estimatedDuration;
  final DeliveryStatus status;
  @JsonKey(name: 'assigned_at')
  final DateTime? assignedAt;
  @JsonKey(name: 'picked_up_at')
  final DateTime? pickedUpAt;
  @JsonKey(name: 'delivered_at')
  final DateTime? deliveredAt;
  @JsonKey(name: 'delivery_photo_url')
  final String? deliveryPhotoUrl;
  @JsonKey(name: 'delivery_signature')
  final String? deliverySignature;
  @JsonKey(name: 'delivery_notes')
  final String? deliveryNotes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Delivery({
    required this.id,
    required this.orderId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverPhotoUrl,
    this.vehicleType,
    this.vehicleNumber,
    this.currentLat,
    this.currentLng,
    this.lastLocationUpdate,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.estimatedDistance,
    this.estimatedDuration,
    required this.status,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.deliveryPhotoUrl,
    this.deliverySignature,
    this.deliveryNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) =>
      _$DeliveryFromJson(json);

  Map<String, dynamic> toJson() => _$DeliveryToJson(this);

  Delivery copyWith({
    String? id,
    String? orderId,
    String? driverId,
    String? driverName,
    String? driverPhone,
    String? driverPhotoUrl,
    String? vehicleType,
    String? vehicleNumber,
    double? currentLat,
    double? currentLng,
    DateTime? lastLocationUpdate,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    double? estimatedDistance,
    int? estimatedDuration,
    DeliveryStatus? status,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    String? deliveryPhotoUrl,
    String? deliverySignature,
    String? deliveryNotes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverPhotoUrl: driverPhotoUrl ?? this.driverPhotoUrl,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      status: status ?? this.status,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveryPhotoUrl: deliveryPhotoUrl ?? this.deliveryPhotoUrl,
      deliverySignature: deliverySignature ?? this.deliverySignature,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Compatibility getter for legacy code expecting currentLocation map
  Map<String, dynamic>? get currentLocation {
    if (currentLat != null && currentLng != null) {
      return {
        'lat': currentLat,
        'lng': currentLng,
      };
    }
    return null;
  }

  // Compatibility getter for legacy estimatedArrival field
  DateTime? get estimatedArrival => deliveredAt;
}

enum DeliveryStatus { assigned, pickedUp, inTransit, delivered }
