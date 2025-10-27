// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['full_name'] as String?,
  phoneNumber: json['phone_number'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  preferences: json['preferences'] as Map<String, dynamic>?,
  defaultAddress: json['default_address'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'phone_number': instance.phoneNumber,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'preferences': instance.preferences,
      'default_address': instance.defaultAddress,
    };
