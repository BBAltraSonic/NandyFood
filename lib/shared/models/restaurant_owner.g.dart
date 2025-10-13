// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_owner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestaurantOwnerPermissions _$RestaurantOwnerPermissionsFromJson(
  Map<String, dynamic> json,
) => RestaurantOwnerPermissions(
  manageMenu: json['manage_menu'] as bool,
  manageOrders: json['manage_orders'] as bool,
  manageStaff: json['manage_staff'] as bool,
  viewAnalytics: json['view_analytics'] as bool,
  manageSettings: json['manage_settings'] as bool,
);

Map<String, dynamic> _$RestaurantOwnerPermissionsToJson(
  RestaurantOwnerPermissions instance,
) => <String, dynamic>{
  'manage_menu': instance.manageMenu,
  'manage_orders': instance.manageOrders,
  'manage_staff': instance.manageStaff,
  'view_analytics': instance.viewAnalytics,
  'manage_settings': instance.manageSettings,
};

RestaurantOwner _$RestaurantOwnerFromJson(Map<String, dynamic> json) =>
    RestaurantOwner(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      ownerType: $enumDecode(_$OwnerTypeEnumMap, json['owner_type']),
      permissions: RestaurantOwnerPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
      status: $enumDecode(_$OwnerStatusEnumMap, json['status']),
      verificationDocuments: (json['verification_documents'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      verifiedBy: json['verified_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RestaurantOwnerToJson(RestaurantOwner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'restaurant_id': instance.restaurantId,
      'owner_type': _$OwnerTypeEnumMap[instance.ownerType]!,
      'permissions': instance.permissions,
      'status': _$OwnerStatusEnumMap[instance.status]!,
      'verification_documents': instance.verificationDocuments,
      'verified_at': instance.verifiedAt?.toIso8601String(),
      'verified_by': instance.verifiedBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$OwnerTypeEnumMap = {
  OwnerType.primary: 'primary',
  OwnerType.coOwner: 'co-owner',
  OwnerType.manager: 'manager',
};

const _$OwnerStatusEnumMap = {
  OwnerStatus.active: 'active',
  OwnerStatus.pending: 'pending',
  OwnerStatus.suspended: 'suspended',
  OwnerStatus.removed: 'removed',
};
