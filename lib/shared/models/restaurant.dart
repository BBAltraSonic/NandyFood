import 'package:json_annotation/json_annotation.dart';

part 'restaurant.g.dart';

@JsonSerializable()
class Restaurant {
  final String id;
  final String name;
  final String? description;
  @JsonKey(name: 'cuisine_type')
  final String cuisineType;
  final Map<String, dynamic> address;
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;
  final String? email;
  @JsonKey(name: 'website_url')
  final String? websiteUrl;
  @JsonKey(name: 'address_line1')
  final String? addressLine1;
  @JsonKey(name: 'address_line2')
  final String? addressLine2;
  final String? city;
  final String? state;
  @JsonKey(name: 'postal_code')
  final String? postalCode;
  @JsonKey(name: 'opening_hours')
  final Map<String, dynamic> openingHours;
  final double rating;
  @JsonKey(name: 'total_reviews')
  final int? totalReviews;
  @JsonKey(name: 'delivery_radius')
  final double deliveryRadius;
  @JsonKey(name: 'estimated_delivery_time')
  final int estimatedDeliveryTime;
  @JsonKey(name: 'delivery_fee')
  final double? deliveryFee;
  @JsonKey(name: 'minimum_order_amount')
  final double? minimumOrderAmount;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_featured')
  final bool isFeatured;
  @JsonKey(name: 'latitude')
  final double? latitude;
  @JsonKey(name: 'longitude')
  final double? longitude;
  @JsonKey(name: 'dietary_options')
  final List<String>? dietaryOptions;
  final List<String>? features;
  @JsonKey(name: 'logo_url')
  final String? logoUrl;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Restaurant({
    required this.id,
    required this.name,
    this.description,
    required this.cuisineType,
    required this.address,
    this.phoneNumber,
    this.email,
    this.websiteUrl,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    required this.openingHours,
    required this.rating,
    this.totalReviews,
    required this.deliveryRadius,
    required this.estimatedDeliveryTime,
    this.deliveryFee,
    this.minimumOrderAmount,
    required this.isActive,
    this.isFeatured = false,
    this.latitude,
    this.longitude,
    this.dietaryOptions,
    this.features,
    this.logoUrl,
    this.coverImageUrl,
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
    String? websiteUrl,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    Map<String, dynamic>? openingHours,
    double? rating,
    int? totalReviews,
    double? deliveryRadius,
    int? estimatedDeliveryTime,
    double? deliveryFee,
    double? minimumOrderAmount,
    bool? isActive,
    bool? isFeatured,
    double? latitude,
    double? longitude,
    List<String>? dietaryOptions,
    List<String>? features,
    String? logoUrl,
    String? coverImageUrl,
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
      websiteUrl: websiteUrl ?? this.websiteUrl,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      openingHours: openingHours ?? this.openingHours,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      deliveryRadius: deliveryRadius ?? this.deliveryRadius,
      estimatedDeliveryTime:
          estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      dietaryOptions: dietaryOptions ?? this.dietaryOptions,
      features: features ?? this.features,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
