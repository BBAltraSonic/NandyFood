enum AddressType { home, work, other }

class Address {
  final String id;
  final String userId;
  final AddressType type;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? apartment;
  final String? deliveryInstructions;
  final double? latitude;
  final double? longitude;

  const Address({
    required this.id,
    required this.userId,
    required this.type,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
    this.apartment,
    this.deliveryInstructions,
    this.latitude,
    this.longitude,
  });

  Address copyWith({
    String? id,
    String? userId,
    AddressType? type,
    String? street,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? apartment,
    String? deliveryInstructions,
    double? latitude,
    double? longitude,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      street: street ?? this.street,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      apartment: apartment ?? this.apartment,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _typeFromJson(json['type'] as String?),
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String,
      country: json['country'] as String,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      apartment: json['apartment'] as String?,
      deliveryInstructions: json['delivery_instructions'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'street': street,
      'city': city,
      'state': state,
      'zip_code': zipCode,
      'country': country,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'apartment': apartment,
      'delivery_instructions': deliveryInstructions,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static AddressType _typeFromJson(String? value) {
    switch (value) {
      case 'work':
        return AddressType.work;
      case 'other':
        return AddressType.other;
      case 'home':
      default:
        return AddressType.home;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.street == street &&
        other.city == city &&
        other.state == state &&
        other.zipCode == zipCode &&
        other.country == country &&
        other.isDefault == isDefault &&
        other.apartment == apartment &&
        other.deliveryInstructions == deliveryInstructions &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    street,
    city,
    state,
    zipCode,
    country,
    isDefault,
    apartment,
    deliveryInstructions,
    latitude,
    longitude,
  );
}
