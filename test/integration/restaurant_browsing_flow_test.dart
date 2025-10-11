import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

void main() {
  group('Restaurant Browsing Flow Integration Tests', () {
    late DatabaseService dbService;
    late ProviderContainer container;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();
      
      // Create a provider container for testing
      container = ProviderContainer();
    });

    tearDown(() {
      // Dispose of the provider container
      container.dispose();
      
      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    test('restaurant listing and filtering', () async {
      // Get the restaurant provider
      final restaurantNotifier = container.read(restaurantProvider.notifier);
      
      // Load restaurants
      await restaurantNotifier.loadRestaurants();
      
      // Verify restaurants are loaded
      var restaurantState = container.read(restaurantProvider);
      expect(restaurantState.restaurants, isNotEmpty);
      expect(restaurantState.filteredRestaurants, isNotEmpty);
      expect(restaurantState.filteredRestaurants.length, 
             restaurantState.restaurants.length);
      
      // Apply rating filter
      await restaurantNotifier.applyRestaurantFilters(minRating: 4.0);
      
      // Verify restaurants are filtered by rating
      restaurantState = container.read(restaurantProvider);
      for (final restaurant in restaurantState.filteredRestaurants) {
        expect(restaurant.rating, greaterThanOrEqualTo(4.0));
      }
      
      // Apply cuisine type filter
      await restaurantNotifier.applyRestaurantFilters(cuisineType: 'Italian');
      
      // Verify restaurants are filtered by cuisine type
      restaurantState = container.read(restaurantProvider);
      for (final restaurant in restaurantState.filteredRestaurants) {
        expect(restaurant.cuisineType.toLowerCase(), contains('italian'));
      }
      
      // Clear filters
      await restaurantNotifier.clearRestaurantFilters();
      
      // Verify all restaurants are shown again
      restaurantState = container.read(restaurantProvider);
      expect(restaurantState.filteredRestaurants.length, 
             restaurantState.restaurants.length);
    });

    test('restaurant search functionality', () async {
      // Get the restaurant provider
      final restaurantNotifier = container.read(restaurantProvider.notifier);
      
      // Load restaurants
      await restaurantNotifier.loadRestaurants();
      
      // Verify initial state
      var restaurantState = container.read(restaurantProvider);
      final initialRestaurantCount = restaurantState.restaurants.length;
      expect(initialRestaurantCount, greaterThan(0));
      
      // Search for restaurants by name
      await restaurantNotifier.setSearchQuery('Pizza');
      
      // Verify search results
      restaurantState = container.read(restaurantProvider);
      expect(restaurantState.filteredRestaurants, isNotEmpty);
      
      // Clear search
      await restaurantNotifier.setSearchQuery('');
      
      // Verify all restaurants are shown again
      restaurantState = container.read(restaurantProvider);
      expect(restaurantState.filteredRestaurants.length, initialRestaurantCount);
    });

    test('menu item listing and filtering', () async {
      // Get the restaurant provider
      final restaurantNotifier = container.read(restaurantProvider.notifier);
      
      // Load restaurants first
      await restaurantNotifier.loadRestaurants();
      
      // Select a restaurant
      final restaurantState = container.read(restaurantProvider);
      final testRestaurant = restaurantState.restaurants.first;
      await restaurantNotifier.selectRestaurant(testRestaurant);
      
      // Load menu items for the selected restaurant
      await restaurantNotifier.loadMenuItems(testRestaurant.id);
      
      // Verify menu items are loaded
      var updatedRestaurantState = container.read(restaurantProvider);
      expect(updatedRestaurantState.menuItems, isNotEmpty);
      expect(updatedRestaurantState.filteredMenuItems, isNotEmpty);
      
      // Apply category filter
      await restaurantNotifier.applyMenuItemFilters(category: 'Main Course');
      
      // Verify menu items are filtered by category
      updatedRestaurantState = container.read(restaurantProvider);
      for (final menuItem in updatedRestaurantState.filteredMenuItems) {
        expect(menuItem.category, 'Main Course');
      }
      
      // Apply dietary restriction filter
      await restaurantNotifier.applyMenuItemFilters(dietaryRestrictions: ['vegetarian']);
      
      // Verify menu items are filtered by dietary restrictions
      updatedRestaurantState = container.read(restaurantProvider);
      for (final menuItem in updatedRestaurantState.filteredMenuItems) {
        expect(menuItem.dietaryRestrictions, contains('vegetarian'));
      }
      
      // Clear menu item filters
      await restaurantNotifier.clearMenuItemFilters();
      
      // Verify all menu items are shown again
      updatedRestaurantState = container.read(restaurantProvider);
      expect(updatedRestaurantState.filteredMenuItems.length, 
             updatedRestaurantState.menuItems.length);
    });

    test('combined restaurant and menu item filtering', () async {
      // Get the restaurant provider
      final restaurantNotifier = container.read(restaurantProvider.notifier);
      
      // Load restaurants
      await restaurantNotifier.loadRestaurants();
      
      // Select a restaurant
      final restaurantState = container.read(restaurantProvider);
      final testRestaurant = restaurantState.restaurants.first;
      await restaurantNotifier.selectRestaurant(testRestaurant);
      
      // Load menu items
      await restaurantNotifier.loadMenuItems(testRestaurant.id);
      
      // Apply combined filters
      await restaurantNotifier.applyRestaurantFilters(minRating: 4.0);
      await restaurantNotifier.applyMenuItemFilters(
        category: 'Main Course',
        dietaryRestrictions: ['vegetarian'],
      );
      
      // Verify combined filtering works
      var updatedRestaurantState = container.read(restaurantProvider);
      expect(updatedRestaurantState.filteredRestaurants, isNotEmpty);
      expect(updatedRestaurantState.filteredMenuItems, isNotEmpty);
      
      // For restaurants, verify they meet the rating criteria
      for (final restaurant in updatedRestaurantState.filteredRestaurants) {
        expect(restaurant.rating, greaterThanOrEqualTo(4.0));
      }
      
      // For menu items, verify they meet the category and dietary criteria
      for (final menuItem in updatedRestaurantState.filteredMenuItems) {
        expect(menuItem.category, 'Main Course');
        expect(menuItem.dietaryRestrictions, contains('vegetarian'));
      }
    });

    test('restaurant detail view and menu exploration', () async {
      // Get the restaurant provider
      final restaurantNotifier = container.read(restaurantProvider.notifier);
      
      // Load restaurants
      await restaurantNotifier.loadRestaurants();
      
      // Select a restaurant to view details
      final restaurantState = container.read(restaurantProvider);
      final testRestaurant = restaurantState.restaurants.first;
      await restaurantNotifier.selectRestaurant(testRestaurant);
      
      // Verify restaurant details are loaded
      var updatedRestaurantState = container.read(restaurantProvider);
      expect(updatedRestaurantState.selectedRestaurant, isNotNull);
      expect(updatedRestaurantState.selectedRestaurant!.id, testRestaurant.id);
      
      // Load menu items for the selected restaurant
      await restaurantNotifier.loadMenuItems(testRestaurant.id);
      
      // Verify menu items are loaded
      updatedRestaurantState = container.read(restaurantProvider);
      expect(updatedRestaurantState.menuItems, isNotEmpty);
      
      // Group menu items by category
      final menuItemsByCategory = <String, List<MenuItem>>{};
      for (final menuItem in updatedRestaurantState.menuItems) {
        final category = menuItem.category;
        if (!menuItemsByCategory.containsKey(category)) {
          menuItemsByCategory[category] = [];
        }
        menuItemsByCategory[category]!.add(menuItem);
      }
      
      // Verify menu items are grouped correctly
      expect(menuItemsByCategory, isNotEmpty);
      
      // Verify each category has menu items
      for (final entry in menuItemsByCategory.entries) {
        expect(entry.value, isNotEmpty);
        for (final menuItem in entry.value) {
          expect(menuItem.category, entry.key);
        }
      }
    });

    test('restaurant sorting functionality', () async {
      // Get the restaurant provider
      final restaurantNotifier = container.read(restaurantProvider.notifier);
      
      // Load restaurants
      await restaurantNotifier.loadRestaurants();
      
      // Verify initial state
      var restaurantState = container.read(restaurantProvider);
      expect(restaurantState.restaurants, isNotEmpty);
      
      // Sort by rating (descending)
      await restaurantNotifier.sortRestaurants(SortCriteria.rating);
      
      // Verify restaurants are sorted by rating
      restaurantState = container.read(restaurantProvider);
      for (var i = 1; i < restaurantState.filteredRestaurants.length; i++) {
        expect(restaurantState.filteredRestaurants[i-1].rating, 
               greaterThanOrEqualTo(restaurantState.filteredRestaurants[i].rating));
      }
      
      // Sort by delivery time (ascending)
      await restaurantNotifier.sortRestaurants(SortCriteria.deliveryTime);
      
      // Verify restaurants are sorted by delivery time
      restaurantState = container.read(restaurantProvider);
      for (var i = 1; i < restaurantState.filteredRestaurants.length; i++) {
        expect(restaurantState.filteredRestaurants[i-1].estimatedDeliveryTime, 
               lessThanOrEqualTo(restaurantState.filteredRestaurants[i].estimatedDeliveryTime));
      }
    });

    test('nearby restaurant discovery', () async {
      // Get the restaurant provider
      final restaurantNotifier = container.read(restaurantProvider.notifier);
      
      // Load restaurants with location-based filtering
      // In a real app, this would use actual user location
      await restaurantNotifier.loadRestaurants(
        userLat: 40.7128, // New York City latitude
        userLng: -74.0060, // New York City longitude
        maxDistanceKm: 10.0, // 10km radius
      );
      
      // Verify restaurants are loaded
      var restaurantState = container.read(restaurantProvider);
      expect(restaurantState.restaurants, isNotEmpty);
      
      // Verify restaurants are filtered by distance
      // In a real implementation, we would verify the distance calculation
      expect(restaurantState.filteredRestaurants, isNotEmpty);
    });
  });
}