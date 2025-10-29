import 'package:json_annotation/json_annotation.dart';

part 'menu_item.g.dart';

@JsonSerializable()
class MenuItem {
  final String id;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  final String name;
  final String? description;
  final double price;
  final String category;
  @JsonKey(name: 'is_available')
  final bool isAvailable;
  @JsonKey(name: 'dietary_tags')
  final List<String>? dietaryRestrictions;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'prep_time')
  final int preparationTime; // in minutes
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    required this.isAvailable,
    required this.dietaryRestrictions,
    this.imageUrl,
    required this.preparationTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) =>
      _$MenuItemFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemToJson(this);

  MenuItem copyWith({
    String? id,
    String? restaurantId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isAvailable,
    List<String>? dietaryRestrictions,
    String? imageUrl,
    int? preparationTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      imageUrl: imageUrl ?? this.imageUrl,
      preparationTime: preparationTime ?? this.preparationTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
