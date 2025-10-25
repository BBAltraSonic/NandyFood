// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_device.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDevice _$UserDeviceFromJson(Map<String, dynamic> json) => UserDevice(
  id: json['id'] as String,
  userId: json['user_id'] as String,
  fcmToken: json['fcm_token'] as String,
  platform: $enumDecode(_$DevicePlatformEnumMap, json['platform']),
  deviceName: json['device_name'] as String?,
  appVersion: json['app_version'] as String?,
  isActive: json['is_active'] as bool? ?? true,
  lastUsedAt: json['last_used_at'] == null
      ? null
      : DateTime.parse(json['last_used_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserDeviceToJson(UserDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'fcm_token': instance.fcmToken,
      'platform': _$DevicePlatformEnumMap[instance.platform]!,
      'device_name': instance.deviceName,
      'app_version': instance.appVersion,
      'is_active': instance.isActive,
      'last_used_at': instance.lastUsedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$DevicePlatformEnumMap = {
  DevicePlatform.ios: 'ios',
  DevicePlatform.android: 'android',
  DevicePlatform.web: 'web',
};
