// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItem _$MenuItemFromJson(Map<String, dynamic> json) => MenuItem(
  id: json['id'] as String,
  restaurantId: json['restaurantId'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  category: json['category'] as String,
  isAvailable: json['isAvailable'] as bool,
  dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  imageUrl: json['imageUrl'] as String?,
  preparationTime: (json['preparationTime'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$MenuItemToJson(MenuItem instance) => <String, dynamic>{
  'id': instance.id,
  'restaurantId': instance.restaurantId,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'category': instance.category,
  'isAvailable': instance.isAvailable,
  'dietaryRestrictions': instance.dietaryRestrictions,
  'imageUrl': instance.imageUrl,
  'preparationTime': instance.preparationTime,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
