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
  websiteUrl: json['websiteUrl'] as String?,
  addressLine1: json['addressLine1'] as String?,
  addressLine2: json['addressLine2'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  postalCode: json['postalCode'] as String?,
  openingHours: json['openingHours'] as Map<String, dynamic>,
  rating: (json['rating'] as num).toDouble(),
  deliveryRadius: (json['deliveryRadius'] as num).toDouble(),
  estimatedDeliveryTime: (json['estimatedDeliveryTime'] as num).toInt(),
  deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
  minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toDouble(),
  isActive: json['isActive'] as bool,
  dietaryOptions: (json['dietaryOptions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  features: (json['features'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  logoUrl: json['logoUrl'] as String?,
  coverImageUrl: json['coverImageUrl'] as String?,
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
      'websiteUrl': instance.websiteUrl,
      'addressLine1': instance.addressLine1,
      'addressLine2': instance.addressLine2,
      'city': instance.city,
      'state': instance.state,
      'postalCode': instance.postalCode,
      'openingHours': instance.openingHours,
      'rating': instance.rating,
      'deliveryRadius': instance.deliveryRadius,
      'estimatedDeliveryTime': instance.estimatedDeliveryTime,
      'deliveryFee': instance.deliveryFee,
      'minimumOrderAmount': instance.minimumOrderAmount,
      'isActive': instance.isActive,
      'dietaryOptions': instance.dietaryOptions,
      'features': instance.features,
      'logoUrl': instance.logoUrl,
      'coverImageUrl': instance.coverImageUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
