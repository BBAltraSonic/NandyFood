// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'restaurant_staff.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestaurantStaff _$RestaurantStaffFromJson(Map<String, dynamic> json) =>
    RestaurantStaff(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      role: $enumDecode(_$StaffRoleTypeEnumMap, json['role']),
      permissions: StaffPermissions.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
      employmentType: $enumDecode(
        _$EmploymentTypeEnumMap,
        json['employment_type'],
      ),
      status: $enumDecode(_$StaffStatusEnumMap, json['status']),
      hiredDate: DateTime.parse(json['hired_date'] as String),
      terminationDate: json['termination_date'] == null
          ? null
          : DateTime.parse(json['termination_date'] as String),
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userProfile: json['userProfile'] == null
          ? null
          : UserProfile.fromJson(json['userProfile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$RestaurantStaffToJson(RestaurantStaff instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'restaurant_id': instance.restaurantId,
      'role': _$StaffRoleTypeEnumMap[instance.role]!,
      'permissions': instance.permissions,
      'employment_type': _$EmploymentTypeEnumMap[instance.employmentType]!,
      'status': _$StaffStatusEnumMap[instance.status]!,
      'hired_date': instance.hiredDate.toIso8601String(),
      'termination_date': instance.terminationDate?.toIso8601String(),
      'hourly_rate': instance.hourlyRate,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'userProfile': instance.userProfile,
    };

const _$StaffRoleTypeEnumMap = {
  StaffRoleType.manager: 'manager',
  StaffRoleType.chef: 'chef',
  StaffRoleType.cashier: 'cashier',
  StaffRoleType.server: 'server',
  StaffRoleType.deliveryCoordinator: 'delivery_coordinator',
  StaffRoleType.basicStaff: 'basic_staff',
};

const _$EmploymentTypeEnumMap = {
  EmploymentType.fullTime: 'full-time',
  EmploymentType.partTime: 'part-time',
  EmploymentType.contractor: 'contractor',
};

const _$StaffStatusEnumMap = {
  StaffStatus.active: 'active',
  StaffStatus.onLeave: 'on_leave',
  StaffStatus.suspended: 'suspended',
  StaffStatus.terminated: 'terminated',
  StaffStatus.pending: 'pending',
};
