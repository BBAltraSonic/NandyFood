import 'package:json_annotation/json_annotation.dart';

part 'restaurant_owner.g.dart';

/// Enum for owner types
enum OwnerType {
  @JsonValue('primary')
  primary,
  @JsonValue('co-owner')
  coOwner,
  @JsonValue('manager')
  manager,
}

/// Enum for owner status
enum OwnerStatus {
  @JsonValue('active')
  active,
  @JsonValue('pending')
  pending,
  @JsonValue('suspended')
  suspended,
  @JsonValue('removed')
  removed,
}

@JsonSerializable()
class RestaurantOwnerPermissions {
  @JsonKey(name: 'manage_menu')
  final bool manageMenu;
  @JsonKey(name: 'manage_orders')
  final bool manageOrders;
  @JsonKey(name: 'manage_staff')
  final bool manageStaff;
  @JsonKey(name: 'view_analytics')
  final bool viewAnalytics;
  @JsonKey(name: 'manage_settings')
  final bool manageSettings;

  RestaurantOwnerPermissions({
    required this.manageMenu,
    required this.manageOrders,
    required this.manageStaff,
    required this.viewAnalytics,
    required this.manageSettings,
  });

  factory RestaurantOwnerPermissions.fromJson(Map<String, dynamic> json) =>
      _$RestaurantOwnerPermissionsFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantOwnerPermissionsToJson(this);

  /// Default permissions for primary owner
  factory RestaurantOwnerPermissions.primary() {
    return RestaurantOwnerPermissions(
      manageMenu: true,
      manageOrders: true,
      manageStaff: true,
      viewAnalytics: true,
      manageSettings: true,
    );
  }

  /// Default permissions for co-owner
  factory RestaurantOwnerPermissions.coOwner() {
    return RestaurantOwnerPermissions(
      manageMenu: true,
      manageOrders: true,
      manageStaff: false,
      viewAnalytics: true,
      manageSettings: false,
    );
  }

  /// Default permissions for manager
  factory RestaurantOwnerPermissions.manager() {
    return RestaurantOwnerPermissions(
      manageMenu: true,
      manageOrders: true,
      manageStaff: false,
      viewAnalytics: true,
      manageSettings: false,
    );
  }
}

@JsonSerializable()
class RestaurantOwner {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  @JsonKey(name: 'owner_type')
  final OwnerType ownerType;
  final RestaurantOwnerPermissions permissions;
  final OwnerStatus status;
  @JsonKey(name: 'verification_documents')
  final List<Map<String, dynamic>>? verificationDocuments;
  @JsonKey(name: 'verified_at')
  final DateTime? verifiedAt;
  @JsonKey(name: 'verified_by')
  final String? verifiedBy;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  RestaurantOwner({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.ownerType,
    required this.permissions,
    required this.status,
    this.verificationDocuments,
    this.verifiedAt,
    this.verifiedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RestaurantOwner.fromJson(Map<String, dynamic> json) =>
      _$RestaurantOwnerFromJson(json);

  Map<String, dynamic> toJson() => _$RestaurantOwnerToJson(this);

  RestaurantOwner copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    OwnerType? ownerType,
    RestaurantOwnerPermissions? permissions,
    OwnerStatus? status,
    List<Map<String, dynamic>>? verificationDocuments,
    DateTime? verifiedAt,
    String? verifiedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantOwner(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      ownerType: ownerType ?? this.ownerType,
      permissions: permissions ?? this.permissions,
      status: status ?? this.status,
      verificationDocuments: verificationDocuments ?? this.verificationDocuments,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper getters
  bool get isPrimary => ownerType == OwnerType.primary;
  bool get isCoOwner => ownerType == OwnerType.coOwner;
  bool get isManager => ownerType == OwnerType.manager;
  bool get isActive => status == OwnerStatus.active;
  bool get isPending => status == OwnerStatus.pending;
  bool get isVerified => verifiedAt != null;

  String get ownerTypeDisplayName {
    switch (ownerType) {
      case OwnerType.primary:
        return 'Primary Owner';
      case OwnerType.coOwner:
        return 'Co-Owner';
      case OwnerType.manager:
        return 'Manager';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case OwnerStatus.active:
        return 'Active';
      case OwnerStatus.pending:
        return 'Pending Verification';
      case OwnerStatus.suspended:
        return 'Suspended';
      case OwnerStatus.removed:
        return 'Removed';
    }
  }
}
