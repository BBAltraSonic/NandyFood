import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

// Restaurant state class to represent the restaurant state
class RestaurantState {
  final List<Restaurant> restaurants;
  final List<Restaurant> filteredRestaurants; // Added for filtering
  final Restaurant? selectedRestaurant;
  final List<MenuItem> menuItems;
  final List<MenuItem> filteredMenuItems; // Added for filtering
  final bool isLoading;
  final String? errorMessage;
  final List<String> selectedDietaryRestrictions; // Added for tracking selected filters

  RestaurantState({
    this.restaurants = const [],
    this.filteredRestaurants = const [],
    this.selectedRestaurant,
    this.menuItems = const [],
    this.filteredMenuItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedDietaryRestrictions = const [],
  });

  RestaurantState copyWith({
    List<Restaurant>? restaurants,
    List<Restaurant>? filteredRestaurants,
    Restaurant? selectedRestaurant,
    List<MenuItem>? menuItems,
    List<MenuItem>? filteredMenuItems,
    bool? isLoading,
    String? errorMessage,
    List<String>? selectedDietaryRestrictions,
  }) {
    return RestaurantState(
      restaurants: restaurants ?? this.restaurants,
      filteredRestaurants: filteredRestaurants ?? this.filteredRestaurants,
      selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
      menuItems: menuItems ?? this.menuItems,
      filteredMenuItems: filteredMenuItems ?? this.filteredMenuItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDietaryRestrictions: selectedDietaryRestrictions ?? this.selectedDietaryRestrictions,
    );
  }
}

// Restaurant provider to manage restaurant state
final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>(
  (ref) => RestaurantNotifier(),
);

class RestaurantNotifier extends StateNotifier<RestaurantState> {
  RestaurantNotifier() : super(RestaurantState());

  // Load restaurants from the database
 Future<void> loadRestaurants() async {
   state = state.copyWith(isLoading: true);
   
   try {
     final dbService = DatabaseService();
     final restaurantData = await dbService.getRestaurants();
     
     final restaurants = restaurantData.map((data) => Restaurant.fromJson(data)).toList();
     
     state = state.copyWith(
       restaurants: restaurants,
       filteredRestaurants: restaurants, // Initially show all restaurants
       isLoading: false,
     );
   } catch (e) {
     state = state.copyWith(
       isLoading: false,
       errorMessage: e.toString(),
     );
   }
 }

  // Select a restaurant
  void selectRestaurant(Restaurant restaurant) {
    state = state.copyWith(selectedRestaurant: restaurant);
  }

  // Load menu items for the selected restaurant
 Future<void> loadMenuItems(String restaurantId) async {
   state = state.copyWith(isLoading: true);
   
   try {
     final dbService = DatabaseService();
     final menuItemData = await dbService.getMenuItems(restaurantId);
     
     final menuItems = menuItemData.map((data) => MenuItem.fromJson(data)).toList();
     
     state = state.copyWith(
       menuItems: menuItems,
       filteredMenuItems: menuItems, // Initially show all menu items
       isLoading: false,
     );
   } catch (e) {
     state = state.copyWith(
       isLoading: false,
       errorMessage: e.toString(),
     );
   }
 }
 
 // Load all menu items for all restaurants to enable dietary filtering across restaurants
 Future<void> loadAllMenuItemsForDietaryFiltering() async {
   if (state.restaurants.isEmpty) {
     // If restaurants haven't been loaded yet, load them first
     await loadRestaurants();
   }
   
   // Load menu items for all restaurants
   List<MenuItem> allMenuItems = [];
   for (final restaurant in state.restaurants) {
     try {
       final dbService = DatabaseService();
       final menuItemData = await dbService.getMenuItems(restaurant.id);
       final menuItems = menuItemData.map((data) => MenuItem.fromJson(data)).toList();
       allMenuItems.addAll(menuItems);
     } catch (e) {
       // Continue with other restaurants even if one fails
       continue;
     }
   }
   
   state = state.copyWith(
     menuItems: allMenuItems,
   );
   
   // Apply the filters after loading all menu items
   _applyRestaurantFilters();
 }

  // Clear error message
 void clearError() {
   state = state.copyWith(errorMessage: null);
 }

 // Toggle dietary restriction filter
void toggleDietaryRestriction(String restriction) async {
   List<String> newRestrictions = List.from(state.selectedDietaryRestrictions);
   
   if (newRestrictions.contains(restriction)) {
     newRestrictions.remove(restriction);
   } else {
     newRestrictions.add(restriction);
   }
   
   state = state.copyWith(selectedDietaryRestrictions: newRestrictions);
   
   // Load all menu items to enable proper filtering across restaurants
   await loadAllMenuItemsForDietaryFiltering();
 }

// Apply dietary restriction filters to restaurants
void _applyRestaurantFilters() {
   List<Restaurant> filtered = state.restaurants;
   
   if (state.selectedDietaryRestrictions.isNotEmpty) {
     // For restaurants, we'll consider the restaurant as matching if any of its menu items match the dietary restrictions
     filtered = state.restaurants.where((restaurant) {
       // Check if the restaurant has any menu items that satisfy the dietary restrictions
       // For now, we'll consider a restaurant as matching if it has at least one menu item
       // that matches the selected dietary restrictions
       bool hasMatchingMenuItems = state.menuItems.any((menuItem) {
         // Check if the menu item belongs to this restaurant and satisfies all selected dietary restrictions
         return menuItem.restaurantId == restaurant.id &&
                state.selectedDietaryRestrictions.every((restriction) =>
                  menuItem.dietaryRestrictions.map((s) => s.toLowerCase()).contains(restriction.toLowerCase())
                );
       });
       
       return hasMatchingMenuItems;
     }).toList();
   }
   
   state = state.copyWith(filteredRestaurants: filtered);
 }

 // Apply dietary restriction filters to menu items
 void applyMenuItemFilters() {
   // Only filter the menu items that belong to the currently selected restaurant
   List<MenuItem> itemsToFilter = state.menuItems.where(
     (item) => item.restaurantId == state.selectedRestaurant?.id
   ).toList();
   
   List<MenuItem> filtered = itemsToFilter;
   
   if (state.selectedDietaryRestrictions.isNotEmpty) {
     filtered = itemsToFilter.where((item) {
       // Check if the menu item satisfies all selected dietary restrictions
       return state.selectedDietaryRestrictions.every((restriction) =>
         item.dietaryRestrictions.map((s) => s.toLowerCase()).contains(restriction.toLowerCase())
       );
     }).toList();
   }
   
   state = state.copyWith(filteredMenuItems: filtered);
 }

 // Clear all dietary restriction filters
 void clearDietaryRestrictionsFilter() {
   // Only reset filtered menu items to the ones for the selected restaurant
   final selectedRestaurantMenuItems = state.menuItems.where(
     (item) => item.restaurantId == state.selectedRestaurant?.id
   ).toList();
   
   state = state.copyWith(
     selectedDietaryRestrictions: const [],
     filteredRestaurants: state.restaurants,
     filteredMenuItems: selectedRestaurantMenuItems,
   );
 }
}