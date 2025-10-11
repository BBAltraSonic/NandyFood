import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

void main() {
  group('Dietary Filtering Tests', () {
    test('Restaurant filtering by dietary restrictions', () async {
      // Create test restaurants
      final restaurant1 = Restaurant(
        id: 'rest1',
        name: 'Veggie Delight',
        cuisineType: 'Vegetarian',
        address: {'street': '123 Veggie St'},
        openingHours: {},
        rating: 4.5,
        deliveryRadius: 10.0,
        estimatedDeliveryTime: 30,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final restaurant2 = Restaurant(
        id: 'rest2',
        name: 'Meat Palace',
        cuisineType: 'Steakhouse',
        address: {'street': '456 Meat Ave'},
        openingHours: {},
        rating: 4.2,
        deliveryRadius: 10.0,
        estimatedDeliveryTime: 35,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create test menu items
      final veggieBurger = MenuItem(
        id: 'item1',
        restaurantId: 'rest1',
        name: 'Veggie Burger',
        price: 12.99,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: ['vegetarian', 'vegan'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final chickenBurger = MenuItem(
        id: 'item2',
        restaurantId: 'rest2',
        name: 'Chicken Burger',
        price: 14.99,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create a notifier instance and set up initial state
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(restaurantProvider.notifier);

      // Set up the state with restaurants and menu items
      notifier.state = notifier.state.copyWith(
        restaurants: [restaurant1, restaurant2],
        menuItems: [veggieBurger, chickenBurger],
      );

      // Apply vegetarian filter - this will trigger the filtering
      notifier.toggleDietaryRestriction('vegetarian');

      // Since toggleDietaryRestriction is async, we need to wait for the state to update
      await Future.delayed(Duration.zero); // Process microtasks

      // Verify that only restaurants with vegetarian options are shown
      final state = container.read(restaurantProvider);
      expect(state.filteredRestaurants.length, 1);
      expect(state.filteredRestaurants.first.id, 'rest1');
    });

    test('Menu item filtering by dietary restrictions', () {
      // Create test menu items
      final veggieBurger = MenuItem(
        id: 'item1',
        restaurantId: 'rest1',
        name: 'Veggie Burger',
        price: 12.99,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: ['vegetarian', 'vegan'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final chickenBurger = MenuItem(
        id: 'item2',
        restaurantId: 'rest1',
        name: 'Chicken Burger',
        price: 14.99,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create a notifier instance and set up initial state
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(restaurantProvider.notifier);

      // Set up the state with menu items
      final restaurant = Restaurant(
        id: 'rest1',
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

      notifier.selectRestaurant(restaurant);
      notifier.state = notifier.state.copyWith(
        menuItems: [veggieBurger, chickenBurger],
        selectedDietaryRestrictions: ['vegetarian'],
      );

      // Apply the menu item filters
      notifier.applyMenuItemFilters();

      // Verify that only vegetarian items are shown
      final state = container.read(restaurantProvider);
      expect(state.filteredMenuItems.length, 1);
      expect(state.filteredMenuItems.first.name, 'Veggie Burger');
    });
  });
}
