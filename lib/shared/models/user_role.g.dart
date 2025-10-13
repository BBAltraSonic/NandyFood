// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRole _$UserRoleFromJson(Map<String, dynamic> json) => UserRole(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  role: $enumDecode(_$UserRoleTypeEnumMap, json['role']),
  isPrimary: json['is_primary'] as bool,
  metadata: json['metadata'] as Map<String, dynamic>?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserRoleToJson(UserRole instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'role': _$UserRoleTypeEnumMap[instance.role]!,
  'is_primary': instance.isPrimary,
  'metadata': instance.metadata,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$UserRoleTypeEnumMap = {
  UserRoleType.consumer: 'consumer',
  UserRoleType.restaurantOwner: 'restaurant_owner',
  UserRoleType.restaurantStaff: 'restaurant_staff',
  UserRoleType.admin: 'admin',
  UserRoleType.deliveryDriver: 'delivery_driver',
};
