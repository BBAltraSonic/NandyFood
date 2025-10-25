// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favourite.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Favourite _$FavouriteFromJson(Map<String, dynamic> json) => Favourite(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  type: $enumDecode(_$FavouriteTypeEnumMap, json['type']),
  restaurantId: json['restaurant_id'] as String?,
  menuItemId: json['menu_item_id'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  restaurant: json['restaurant'] == null
      ? null
      : Restaurant.fromJson(json['restaurant'] as Map<String, dynamic>),
  menuItem: json['menu_item'] == null
      ? null
      : MenuItem.fromJson(json['menu_item'] as Map<String, dynamic>),
);

Map<String, dynamic> _$FavouriteToJson(Favourite instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'type': _$FavouriteTypeEnumMap[instance.type]!,
  'restaurant_id': instance.restaurantId,
  'menu_item_id': instance.menuItemId,
  'created_at': instance.createdAt.toIso8601String(),
  'restaurant': instance.restaurant?.toJson(),
  'menu_item': instance.menuItem?.toJson(),
};

const _$FavouriteTypeEnumMap = {
  FavouriteType.restaurant: 'restaurant',
  FavouriteType.menuItem: 'menu_item',
};
