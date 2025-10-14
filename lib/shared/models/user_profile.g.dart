// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  preferences: json['preferences'] as Map<String, dynamic>?,
  defaultAddress: json['defaultAddress'] as Map<String, dynamic>?,
  avatarUrl: json['avatarUrl'] as String?,
  dietaryPreferences: (json['dietaryPreferences'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  addresses: json['addresses'] as List<dynamic>?,
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'preferences': instance.preferences,
      'defaultAddress': instance.defaultAddress,
      'avatarUrl': instance.avatarUrl,
      'dietaryPreferences': instance.dietaryPreferences,
      'addresses': instance.addresses,
    };
