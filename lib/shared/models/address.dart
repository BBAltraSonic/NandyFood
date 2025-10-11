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
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: _typeFromJson(json['type'] as String?),
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      apartment: json['apartment'] as String?,
      deliveryInstructions: json['deliveryInstructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'apartment': apartment,
      'deliveryInstructions': deliveryInstructions,
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
        other.deliveryInstructions == deliveryInstructions;
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
      );
}
