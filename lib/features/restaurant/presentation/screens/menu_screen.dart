import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/menu_item_card.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';
import 'package:food_delivery_app/shared/widgets/filter_widget.dart';

class MenuScreen extends ConsumerWidget {
  final Restaurant restaurant;

  const MenuScreen({
    super.key,
    required this.restaurant,
  });

  @override
 Widget build(BuildContext context, WidgetRef ref) {
    final restaurantState = ref.watch(restaurantProvider);
    
    // Load menu items for this restaurant
    ref.listen<RestaurantState>(restaurantProvider, (previous, next) {
      if (previous?.selectedRestaurant?.id != restaurant.id &&
          next.selectedRestaurant?.id == restaurant.id) {
        ref.read(restaurantProvider.notifier).loadMenuItems(restaurant.id);
      }
    });

    // Select this restaurant in the provider
    ref.read(restaurantProvider.notifier).selectRestaurant(restaurant);

    // Define dietary restriction options
    final dietaryOptions = [
      FilterOption(
        id: 'vegetarian',
        label: 'Vegetarian',
        isSelected: restaurantState.selectedDietaryRestrictions.contains('vegetarian'),
      ),
      FilterOption(
        id: 'vegan',
        label: 'Vegan',
        isSelected: restaurantState.selectedDietaryRestrictions.contains('vegan'),
      ),
      FilterOption(
        id: 'gluten-free',
        label: 'Gluten-Free',
        isSelected: restaurantState.selectedDietaryRestrictions.contains('gluten-free'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('${restaurant.name} Menu'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter widget for dietary restrictions
          FilterWidget(
            options: dietaryOptions,
            onFiltersChanged: (selectedOptions) {
              // Extract the selected dietary restrictions
              final selectedRestrictions = selectedOptions.map((option) => option.id).toList();
              
              // Update the provider with the selected dietary restrictions
              final currentRestrictions = restaurantState.selectedDietaryRestrictions;
              final newRestrictions = selectedOptions.map((option) => option.id).toList();
              
              // Find added restrictions
              for (final restriction in newRestrictions) {
                if (!currentRestrictions.contains(restriction)) {
                  ref.read(restaurantProvider.notifier).toggleDietaryRestriction(restriction);
                }
              }
              
              // Find removed restrictions
              for (final restriction in currentRestrictions) {
                if (!newRestrictions.contains(restriction)) {
                  ref.read(restaurantProvider.notifier).toggleDietaryRestriction(restriction);
                }
              }
              
              // Apply the filters to menu items
              ref.read(restaurantProvider.notifier).applyMenuItemFilters();
            },
          ),
          const SizedBox(height: 8),
          // Expanded menu content
          Expanded(
            child: restaurantState.isLoading
                ? const LoadingIndicator()
                : restaurantState.errorMessage != null
                    ? ErrorMessageWidget(
                        message: restaurantState.errorMessage!,
                        onRetry: () => ref.read(restaurantProvider.notifier).loadMenuItems(restaurant.id),
                      )
                    : _buildMenuContent(restaurantState, context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuContent(RestaurantState restaurantState, BuildContext context) {
    // Use filtered menu items from state
    final menuItems = restaurantState.filteredMenuItems.isEmpty && restaurantState.selectedDietaryRestrictions.isNotEmpty
        ? [] // If filters are active but no results, show empty
        : restaurantState.filteredMenuItems.isEmpty
            ? restaurantState.menuItems // If no filters, show all
            : restaurantState.filteredMenuItems; // If filters and results, show filtered

    if (menuItems.isEmpty) {
      return const Center(
        child: Text(
          'No menu items available',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    // Group menu items by category
    final Map<String, List> categories = {};
    for (final item in menuItems) {
      final category = item.category ?? 'Other';
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(item);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
        await Future.microtask(() =>
          ProviderScope.containerOf(context).read(restaurantProvider.notifier).loadMenuItems(restaurant.id)
        );
      },
      child: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final categoryName = categories.keys.elementAt(index);
          final items = categories[categoryName] as List;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: MenuItemCard(
                  menuItem: item,
                  onAddToCart: () {
                    // TODO: Add to cart functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to cart')),
                    );
                  },
                ),
              )).toList(),
            ],
          );
        },
      ),
    );
  }
}