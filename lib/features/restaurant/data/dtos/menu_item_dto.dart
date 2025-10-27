import 'dart:convert';
import 'menu_modifier_dto.dart';

/// DTO that augments MenuItem model with parsed customization options from DB
class MenuItemDTO {
  final String id;
  final String name;
  final double basePrice;
  final List<MenuModifierGroup> modifierGroups;

  const MenuItemDTO({
    required this.id,
    required this.name,
    required this.basePrice,
    this.modifierGroups = const [],
  });

  bool get hasModifiers => modifierGroups.isNotEmpty;

  factory MenuItemDTO.fromSupabaseRow(Map<String, dynamic> row) {
    final customization = row['customization_options'];

    // Parse groups from a variety of possible shapes
    List<MenuModifierGroup> groups = [];
    if (customization != null) {
      dynamic parsed = customization;
      // Supabase may return JSONB as Map or encoded String
      if (customization is String) {
        try {
          parsed = customization.isNotEmpty ? jsonDecode(customization) : null;
        } catch (_) {
          parsed = null;
        }
      }

      if (parsed is Map && parsed['groups'] is List) {
        groups = (parsed['groups'] as List)
            .map((g) => MenuModifierGroup.fromDynamic(g))
            .toList();
      } else if (parsed is List) {
        groups = parsed.map((g) => MenuModifierGroup.fromDynamic(g)).toList();
      } else if (parsed is Map && parsed['modifiers'] is List) {
        groups = (parsed['modifiers'] as List)
            .map((g) => MenuModifierGroup.fromDynamic(g))
            .toList();
      }
    }

    return MenuItemDTO(
      id: (row['id'] ?? '').toString(),
      name: (row['name'] ?? '').toString(),
      basePrice: _toDouble(row['price']),
      modifierGroups: groups,
    );
  }

  /// Compute final price based on selected options
  /// selections: map of groupId -> list of optionIds
  double computeFinalPrice(Map<String, List<String>> selections) {
    double price = basePrice;

    // Apply multiplicative factors first (e.g., Size multipliers)
    for (final group in modifierGroups) {
      final selectedIds = selections[group.id] ?? const [];
      if (selectedIds.isEmpty) continue;

      for (final option in group.options) {
        if (selectedIds.contains(option.id)) {
          // multiply base price only; additive deltas will be applied later
          if (option.multiplier != 1.0) {
            price = price * option.multiplier;
          }
        }
      }
    }

    // Then apply additive price deltas
    for (final group in modifierGroups) {
      final selectedIds = selections[group.id] ?? const [];
      if (selectedIds.isEmpty) continue;
      for (final option in group.options) {
        if (selectedIds.contains(option.id)) {
          price += option.priceDelta;
        }
      }
    }

    return price;
  }
}

double _toDouble(dynamic v, {double fallback = 0.0}) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? fallback;
}

