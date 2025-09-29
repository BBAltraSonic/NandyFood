import 'package:json_annotation/json_annotation.dart';

part 'delivery.g.dart';

@JsonSerializable()
class Delivery {
  final String id;
  final String orderId;
  final String? driverId;
  final DateTime? estimatedArrival;
  final DateTime? actualArrival;
  final Map<String, dynamic>? currentLocation;
  final DeliveryStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Delivery({
    required this.id,
    required this.orderId,
    this.driverId,
    this.estimatedArrival,
    this.actualArrival,
    this.currentLocation,
    required this.status,
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
    DateTime? estimatedArrival,
    DateTime? actualArrival,
    Map<String, dynamic>? currentLocation,
    DeliveryStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Delivery(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      estimatedArrival: estimatedArrival ?? this.estimatedArrival,
      actualArrival: actualArrival ?? this.actualArrival,
      currentLocation: currentLocation ?? this.currentLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum DeliveryStatus { assigned, pickedUp, inTransit, delivered }