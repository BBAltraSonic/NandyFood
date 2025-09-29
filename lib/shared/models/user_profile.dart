import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
 final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;
  final Map<String, dynamic>? defaultAddress;

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
    this.defaultAddress,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

 UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? defaultAddress,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
      defaultAddress: defaultAddress ?? this.defaultAddress,
    );
 }
}