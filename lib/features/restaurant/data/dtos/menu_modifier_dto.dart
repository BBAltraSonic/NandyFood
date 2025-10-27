import 'dart:convert';

/// Represents the selection behavior for a modifier group
/// - single: exactly one option should be selected (if required)
/// - multiple: zero or more options can be selected
enum MenuModifierType { single, multiple }

MenuModifierType _parseModifierType(dynamic value) {
  final v = (value ?? '').toString().toLowerCase();
  switch (v) {
    case 'single':
    case 'radio':
      return MenuModifierType.single;
    case 'multi':
    case 'multiple':
    case 'checkbox':
      return MenuModifierType.multiple;
    default:
      return MenuModifierType.multiple;
  }
}

/// A single selectable option within a modifier group
class MenuModifierOption {
  final String id;
  final String name;
  final double priceDelta; // absolute delta added to base price
  final double multiplier; // multiplicative factor applied to base price

  const MenuModifierOption({
    required this.id,
    required this.name,
    this.priceDelta = 0.0,
    this.multiplier = 1.0,
  });

  factory MenuModifierOption.fromDynamic(dynamic data) {
    if (data is String) {
      return MenuModifierOption(id: _slugify(data), name: data);
    }
    if (data is Map) {
      final name = (data['name'] ?? data['label'] ?? '').toString();
      final id = (data['id'] ?? _slugify(name)).toString();
      // Try multiple common keys for price delta
      final price = data['price'] ?? data['price_delta'] ?? data['additional_price'] ?? 0;
      final multiplier = (data['multiplier'] ?? data['factor'] ?? 1.0);
      return MenuModifierOption(
        id: id,
        name: name,
        priceDelta: _toDouble(price),
        multiplier: _toDouble(multiplier, fallback: 1.0),
      );
    }
    return const MenuModifierOption(id: 'unknown', name: 'Unknown');
  }
}

/// A group of options (e.g., Size, Toppings)
class MenuModifierGroup {
  final String id;
  final String name;
  final MenuModifierType type;
  final bool required;
  final int? min;
  final int? max;
  final List<MenuModifierOption> options;

  const MenuModifierGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.required,
    this.min,
    this.max,
    this.options = const [],
  });

  factory MenuModifierGroup.fromDynamic(dynamic data) {
    if (data is Map) {
      final name = (data['name'] ?? data['title'] ?? '').toString();
      final id = (data['id'] ?? _slugify(name)).toString();
      final type = _parseModifierType(data['type']);
      final required = (data['required'] ?? data['is_required'] ?? false) == true;
      final min = _toIntOrNull(data['min']);
      final max = _toIntOrNull(data['max']);
      final rawOptions = data['options'] ?? data['values'] ?? [];
      final options = (rawOptions as List)
          .map((o) => MenuModifierOption.fromDynamic(o))
          .toList();
      return MenuModifierGroup(
        id: id,
        name: name.isEmpty ? id : name,
        type: type,
        required: required,
        min: min,
        max: max,
        options: options,
      );
    }
    return const MenuModifierGroup(
      id: 'group',
      name: 'Group',
      type: MenuModifierType.multiple,
      required: false,
      options: [],
    );
  }
}

// Helpers
String _slugify(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

double _toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  final s = v.toString();
  return double.tryParse(s) ?? fallback;
}

int? _toIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

