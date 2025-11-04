import 'package:flutter/material.dart';

/// Categories that users can filter restaurants by
class RestaurantCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const RestaurantCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// Common restaurant categories
class RestaurantCategories {
  static const List<RestaurantCategory> all = [
    RestaurantCategory(
      id: 'all',
      name: 'All',
      icon: Icons.restaurant,
      color: Colors.deepPurple,
    ),
    RestaurantCategory(
      id: 'pizza',
      name: 'Pizza',
      icon: Icons.local_pizza,
      color: Colors.black87,
    ),
    RestaurantCategory(
      id: 'sushi',
      name: 'Sushi',
      icon: Icons.set_meal,
      color: Colors.pink,
    ),
    RestaurantCategory(
      id: 'burgers',
      name: 'Burgers',
      icon: Icons.lunch_dining,
      color: Colors.black87,
    ),
    RestaurantCategory(
      id: 'healthy',
      name: 'Healthy',
      icon: Icons.eco,
      color: Colors.black87,
    ),
    RestaurantCategory(
      id: 'indian',
      name: 'Indian',
      icon: Icons.food_bank,
      color: Colors.black87,
    ),
    RestaurantCategory(
      id: 'chinese',
      name: 'Chinese',
      icon: Icons.ramen_dining,
      color: Colors.black87,
    ),
    RestaurantCategory(
      id: 'mexican',
      name: 'Mexican',
      icon: Icons.takeout_dining,
      color: Colors.black87,
    ),
    RestaurantCategory(
      id: 'italian',
      name: 'Italian',
      icon: Icons.dining,
      color: Colors.black87,
    ),
    RestaurantCategory(
      id: 'dessert',
      name: 'Dessert',
      icon: Icons.cake,
      color: Colors.pinkAccent,
    ),
  ];
}

/// A horizontal scrollable list of category chips for filtering restaurants
class CategoriesHorizontalList extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;

  const CategoriesHorizontalList({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: RestaurantCategories.all.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = RestaurantCategories.all[index];
          final isSelected = selectedCategoryId == category.id;

          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () => onCategorySelected(category.id),
            theme: theme,
          );
        },
      ),
    );
  }
}

/// Individual category chip widget
class _CategoryChip extends StatelessWidget {
  final RestaurantCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : theme.colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 20,
              color: isSelected ? Colors.white : category.color,
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
