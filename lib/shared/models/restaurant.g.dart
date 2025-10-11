// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Restaurant _$RestaurantFromJson(Map<String, dynamic> json) => Restaurant(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  cuisineType: json['cuisineType'] as String,
  address: json['address'] as Map<String, dynamic>,
  phoneNumber: json['phoneNumber'] as String?,
  email: json['email'] as String?,
  openingHours: json['openingHours'] as Map<String, dynamic>,
  rating: (json['rating'] as num).toDouble(),
  deliveryRadius: (json['deliveryRadius'] as num).toDouble(),
  estimatedDeliveryTime: (json['estimatedDeliveryTime'] as num).toInt(),
  isActive: json['isActive'] as bool,
  dietaryOptions: (json['dietaryOptions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$RestaurantToJson(Restaurant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'cuisineType': instance.cuisineType,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'openingHours': instance.openingHours,
      'rating': instance.rating,
      'deliveryRadius': instance.deliveryRadius,
      'estimatedDeliveryTime': instance.estimatedDeliveryTime,
      'isActive': instance.isActive,
      'dietaryOptions': instance.dietaryOptions,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
