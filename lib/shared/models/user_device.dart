import 'package:json_annotation/json_annotation.dart';

part 'user_device.g.dart';

/// Device platform enum
enum DevicePlatform {
  @JsonValue('ios')
  ios,
  @JsonValue('android')
  android,
  @JsonValue('web')
  web,
}

/// User device model for FCM tokens
@JsonSerializable()
class UserDevice {
  const UserDevice({
    required this.id,
    required this.userId,
    required this.fcmToken,
    required this.platform,
    this.deviceName,
    this.appVersion,
    this.isActive = true,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  
  @JsonKey(name: 'user_id')
  final String userId;
  
  @JsonKey(name: 'fcm_token')
  final String fcmToken;
  
  final DevicePlatform platform;
  
  @JsonKey(name: 'device_name')
  final String? deviceName;
  
  @JsonKey(name: 'app_version')
  final String? appVersion;
  
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @JsonKey(name: 'last_used_at')
  final DateTime? lastUsedAt;
  
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  factory UserDevice.fromJson(Map<String, dynamic> json) =>
      _$UserDeviceFromJson(json);

  Map<String, dynamic> toJson() => _$UserDeviceToJson(this);

  UserDevice copyWith({
    String? id,
    String? userId,
    String? fcmToken,
    DevicePlatform? platform,
    String? deviceName,
    String? appVersion,
    bool? isActive,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fcmToken: fcmToken ?? this.fcmToken,
      platform: platform ?? this.platform,
      deviceName: deviceName ?? this.deviceName,
      appVersion: appVersion ?? this.appVersion,
      isActive: isActive ?? this.isActive,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
