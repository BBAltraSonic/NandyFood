import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/core/utils/accessibility_utils.dart';

class AccessibleRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;
  final bool isSelected;

  const AccessibleRestaurantCard({
    super.key,
    required this.restaurant,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: true,
      label:
          '${restaurant.name}, ${restaurant.cuisineType}, '
          'Rating: ${restaurant.rating}, '
          'Delivery time: ${restaurant.estimatedDeliveryTime} minutes',
      selected: isSelected,
      focusable: true,
      enabled: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: isSelected ? 8 : 2,
        shadowColor: isSelected ? colorScheme.primary : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Restaurant image placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),

                // Restaurant details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant name
                      Accessibility.accessibleHeading(
                        restaurant.name,
                        level: 3,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Cuisine type and delivery time
                      Text(
                        '${restaurant.cuisineType} • ${restaurant.estimatedDeliveryTime} min',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Rating and distance
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            restaurant.rating.toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text('2.5 km', style: TextStyle(fontSize: 14)),
                        ],
                      ),

                      // Dietary restrictions badges
                      if (restaurant.dietaryOptions?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: restaurant.dietaryOptions!.map((option) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getDietaryBadgeColor(
                                  option,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getDietaryBadgeColor(option),
                                ),
                              ),
                              child: Text(
                                _getDietaryBadgeText(option),
                                style: TextStyle(
                                  color: _getDietaryBadgeColor(option),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  Icon(Icons.check_circle, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Get color for dietary restriction badge
  Color _getDietaryBadgeColor(String option) {
    switch (option.toLowerCase()) {
      case 'vegetarian':
        return Colors.green;
      case 'vegan':
        return Colors.green.shade800;
      case 'gluten-free':
        return Colors.blue;
      case 'dairy-free':
        return Colors.purple;
      case 'nut-free':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get text for dietary restriction badge
  String _getDietaryBadgeText(String option) {
    switch (option.toLowerCase()) {
      case 'vegetarian':
        return 'Veg';
      case 'vegan':
        return 'Vegan';
      case 'gluten-free':
        return 'GF';
      case 'dairy-free':
        return 'DF';
      case 'nut-free':
        return 'NF';
      default:
        return option;
    }
  }
}
