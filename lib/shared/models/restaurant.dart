import 'package:json_annotation/json_annotation.dart';

part 'restaurant.g.dart';

@JsonSerializable()
class Restaurant {
  final String id;
  final String name;
  final String? description;
  final String cuisineType;
  final Map<String, dynamic> address;
  final String? phoneNumber;
  final String? email;
  final Map<String, dynamic> openingHours;
  final double rating;
  final double deliveryRadius;
  final int estimatedDeliveryTime;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    required this.cuisineType,
    required this.address,
    this.phoneNumber,
    this.email,
    required this.openingHours,
    required this.rating,
    required this.deliveryRadius,
    required this.estimatedDeliveryTime,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) =>
      _$RestaurantFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantToJson(this);

 Restaurant copyWith({
    String? id,
    String? name,
    String? description,
    String? cuisineType,
    Map<String, dynamic>? address,
    String? phoneNumber,
    String? email,
    Map<String, dynamic>? openingHours,
    double? rating,
    double? deliveryRadius,
    int? estimatedDeliveryTime,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisineType: cuisineType ?? this.cuisineType,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}