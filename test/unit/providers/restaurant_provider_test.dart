import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

void main() {
  group('RestaurantProvider Tests', () {
    late ProviderContainer container;
    late RestaurantNotifier notifier;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Override with a mock implementation if needed
        ],
      );
      addTearDown(container.dispose);
      notifier = container.read(restaurantProvider.notifier);
    });

    test(
      'toggleDietaryRestriction should add restriction to selected list',
      () {
        // Initially no restrictions
        expect(
          container.read(restaurantProvider).selectedDietaryRestrictions,
          isEmpty,
        );

        // Add vegetarian restriction
        notifier.toggleDietaryRestriction('vegetarian');

        // Verify vegetarian is added
        expect(
          container.read(restaurantProvider).selectedDietaryRestrictions,
          contains('vegetarian'),
        );
      },
    );

    test(
      'toggleDietaryRestriction should remove restriction from selected list',
      () {
        // Add a restriction first
        notifier.toggleDietaryRestriction('vegan');
        expect(
          container.read(restaurantProvider).selectedDietaryRestrictions,
          contains('vegan'),
        );

        // Remove the restriction
        notifier.toggleDietaryRestriction('vegan');

        // Verify it's removed
        expect(
          container.read(restaurantProvider).selectedDietaryRestrictions,
          isNot(contains('vegan')),
        );
      },
    );

    test(
      'applyMenuItemFilters should filter menu items based on dietary restrictions',
      () {
        // Create mock restaurant and menu items
        final restaurant = Restaurant(
          id: 'restaurant_1',
          name: 'Test Restaurant',
          cuisineType: 'Test',
          address: {'street': '123 Test St'},
          openingHours: {},
          rating: 4.5,
          deliveryRadius: 10.0,
          estimatedDeliveryTime: 30,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final menuItem1 = MenuItem(
          id: 'item_1',
          restaurantId: 'restaurant_1',
          name: 'Veggie Burger',
          price: 12.99,
          category: 'Main',
          isAvailable: true,
          dietaryRestrictions: ['vegetarian'],
          preparationTime: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final menuItem2 = MenuItem(
          id: 'item_2',
          restaurantId: 'restaurant_1',
          name: 'Chicken Burger',
          price: 14.99,
          category: 'Main',
          isAvailable: true,
          dietaryRestrictions: ['gluten-free'],
          preparationTime: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Set up the provider state with menu items
        notifier.selectRestaurant(restaurant);
        notifier.state = notifier.state.copyWith(
          menuItems: [menuItem1, menuItem2],
          filteredMenuItems: [menuItem1, menuItem2], // Initially show all
        );

        // Apply vegetarian filter
        notifier.applyMenuItemFilters();

        // Update the state to simulate dietary restriction being selected
        notifier.state = notifier.state.copyWith(
          selectedDietaryRestrictions: ['vegetarian'],
        );

        // Now filter based on the selected dietary restriction
        final itemsToFilter = notifier.state.menuItems
            .where((item) => item.restaurantId == restaurant.id)
            .toList();

        final filtered = itemsToFilter.where((item) {
          return ['vegetarian'].every(
            (restriction) => item.dietaryRestrictions
                .map((s) => s.toLowerCase())
                .contains(restriction.toLowerCase()),
          );
        }).toList();

        // Verify that only vegetarian items are shown
        expect(filtered.length, 1);
        expect(filtered.first.name, 'Veggie Burger');
      },
    );

    test('clearDietaryRestrictionsFilter should clear all filters', () {
      // Set up initial state with filters
      notifier.state = notifier.state.copyWith(
        selectedDietaryRestrictions: ['vegetarian', 'vegan'],
        filteredRestaurants: [],
        filteredMenuItems: [],
      );

      // Clear the filters
      notifier.clearDietaryRestrictionsFilter();

      // Verify filters are cleared
      final state = container.read(restaurantProvider);
      expect(state.selectedDietaryRestrictions, isEmpty);
    });
  });
}
