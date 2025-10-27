import 'package:json_annotation/json_annotation.dart';
import 'restaurant.dart';
import 'menu_item.dart';

part 'favourite.g.dart';

/// Favourite type enum
enum FavouriteType {
  @JsonValue('restaurant')
  restaurant,
  @JsonValue('menu_item')
  menuItem,
}

/// Favourite model
@JsonSerializable(explicitToJson: true)
class Favourite {
  const Favourite({
    required this.id,
    required this.userId,
    required this.type,
    this.restaurantId,
    this.menuItemId,
    required this.createdAt,
    required this.updatedAt,
    this.restaurant,
    this.menuItem,
  });

  final String id;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  final FavouriteType type;
  
  @JsonKey(name: 'restaurant_id')
  final String? restaurantId;
  
  @JsonKey(name: 'menu_item_id')
  final String? menuItemId;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // Nested objects (loaded with joins)
  final Restaurant? restaurant;

  @JsonKey(name: 'menu_item')
  final MenuItem? menuItem;

  factory Favourite.fromJson(Map<String, dynamic> json) =>
      _$FavouriteFromJson(json);

  Map<String, dynamic> toJson() => _$FavouriteToJson(this);

  Favourite copyWith({
    String? id,
    String? userId,
    FavouriteType? type,
    String? restaurantId,
    String? menuItemId,
    DateTime? createdAt,
    DateTime? updatedAt,
    Restaurant? restaurant,
    MenuItem? menuItem,
  }) {
    return Favourite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      restaurantId: restaurantId ?? this.restaurantId,
      menuItemId: menuItemId ?? this.menuItemId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      restaurant: restaurant ?? this.restaurant,
      menuItem: menuItem ?? this.menuItem,
    );
  }
}
