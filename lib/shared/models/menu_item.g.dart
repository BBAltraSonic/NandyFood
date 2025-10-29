// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => MenuItem(
  id: json['id'] as String,
  restaurantId: json['restaurant_id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  category: json['category'] as String,
  isAvailable: json['is_available'] as bool,
  dietaryRestrictions: (json['dietary_tags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  imageUrl: json['image_url'] as String?,
  preparationTime: (json['prep_time'] as num).toInt(),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$MenuItemToJson(MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'restaurant_id': instance.restaurantId,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'category': instance.category,
  'is_available': instance.isAvailable,
  'dietary_tags': instance.dietaryRestrictions,
  'image_url': instance.imageUrl,
  'prep_time': instance.preparationTime,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
