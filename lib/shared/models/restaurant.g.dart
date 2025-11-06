// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Restaurant _$RestaurantFromJson(Map<String, dynamic> json) => Restaurant(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  cuisineType: json['cuisine_type'] as String,
  address: json['address'] as Map<String, dynamic>,
  phoneNumber: json['phone_number'] as String?,
  email: json['email'] as String?,
  websiteUrl: json['website_url'] as String?,
  addressLine1: json['address_line1'] as String?,
  addressLine2: json['address_line2'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  postalCode: json['postal_code'] as String?,
  openingHours: json['opening_hours'] as Map<String, dynamic>,
  rating: (json['rating'] as num).toDouble(),
  totalReviews: (json['total_reviews'] as num?)?.toInt(),
  deliveryRadius: (json['delivery_radius'] as num).toDouble(),
  estimatedDeliveryTime: (json['estimated_delivery_time'] as num).toInt(),
  deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
  minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble(),
  isActive: json['is_active'] as bool,
  isFeatured: json['is_featured'] as bool? ?? false,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  dietaryOptions: (json['dietary_options'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  features: (json['features'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  logoUrl: json['logo_url'] as String?,
  coverImageUrl: json['cover_image_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$RestaurantToJson(Restaurant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'cuisine_type': instance.cuisineType,
      'address': instance.address,
      'phone_number': instance.phoneNumber,
      'email': instance.email,
      'website_url': instance.websiteUrl,
      'address_line1': instance.addressLine1,
      'address_line2': instance.addressLine2,
      'city': instance.city,
      'state': instance.state,
      'postal_code': instance.postalCode,
      'opening_hours': instance.openingHours,
      'rating': instance.rating,
      'total_reviews': instance.totalReviews,
      'delivery_radius': instance.deliveryRadius,
      'estimated_delivery_time': instance.estimatedDeliveryTime,
      'delivery_fee': instance.deliveryFee,
      'minimum_order_amount': instance.minimumOrderAmount,
      'is_active': instance.isActive,
      'is_featured': instance.isFeatured,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'dietary_options': instance.dietaryOptions,
      'features': instance.features,
      'logo_url': instance.logoUrl,
      'cover_image_url': instance.coverImageUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
