import 'package:json_annotation/json_annotation.dart';

part 'user_role.g.dart';

/// Enum for user role types
enum UserRoleType {
  @JsonValue('consumer')
  consumer,
  @JsonValue('restaurant_owner')
  restaurantOwner,
  @JsonValue('restaurant_staff')
  restaurantStaff,
  @JsonValue('admin')
  admin,
  @JsonValue('delivery_driver')
  deliveryDriver,
}

@JsonSerializable()
class UserRole {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final UserRoleType role;
  @JsonKey(name: 'is_primary')
  final bool isPrimary;
  final Map<String, dynamic>? metadata;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  UserRole({
    required this.id,
    required this.userId,
    required this.role,
    required this.isPrimary,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) =>
      _$UserRoleFromJson(json);

  Map<String, dynamic> toJson() => _$UserRoleToJson(this);

  UserRole copyWith({
    String? id,
    String? userId,
    UserRoleType? role,
    bool? isPrimary,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRole(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isPrimary: isPrimary ?? this.isPrimary,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper getters
  bool get isConsumer => role == UserRoleType.consumer;
  bool get isRestaurantOwner => role == UserRoleType.restaurantOwner;
  bool get isRestaurantStaff => role == UserRoleType.restaurantStaff;
  bool get isAdmin => role == UserRoleType.admin;
  bool get isDeliveryDriver => role == UserRoleType.deliveryDriver;

  String get roleDisplayName {
    switch (role) {
      case UserRoleType.consumer:
        return 'Consumer';
      case UserRoleType.restaurantOwner:
        return 'Restaurant Owner';
      case UserRoleType.restaurantStaff:
        return 'Restaurant Staff';
      case UserRoleType.admin:
        return 'Admin';
      case UserRoleType.deliveryDriver:
        return 'Delivery Driver';
    }
  }
}
