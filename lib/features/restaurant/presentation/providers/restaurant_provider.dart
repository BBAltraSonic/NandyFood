import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_delivery_app/features/restaurant/data/repositories/restaurant_repository_result.dart';


// Restaurant state class to represent the restaurant state
class RestaurantState {
  final List<Restaurant> restaurants;
  final List<Restaurant> filteredRestaurants; // Filtering
  final Restaurant? selectedRestaurant;
  final List<MenuItem> menuItems;
  final List<MenuItem> filteredMenuItems; // Filtering
  final List<MenuItem> popularItems; // Popular items
  final List<Review> reviews; // Reviews
  final Map<int, int> ratingBreakdown; // Rating distribution
  final int totalReviews; // Total reviews count
  final bool isLoading;
  final String? errorMessage;
  final List<String> selectedDietaryRestrictions; // Selected dietary filters
  final String? selectedCategory; // Category filtering

  // Pagination
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingMore;

  RestaurantState({
    this.restaurants = const [],
    this.filteredRestaurants = const [],
    this.selectedRestaurant,
    this.menuItems = const [],
    this.filteredMenuItems = const [],
    this.popularItems = const [],
    this.reviews = const [],
    this.ratingBreakdown = const {},
    this.totalReviews = 0,
    this.isLoading = false,
    this.errorMessage,
    this.selectedDietaryRestrictions = const [],
    this.selectedCategory,
    this.currentPage = 0,
    this.pageSize = 20,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  RestaurantState copyWith({
    List<Restaurant>? restaurants,
    List<Restaurant>? filteredRestaurants,
    Restaurant? selectedRestaurant,
    List<MenuItem>? menuItems,
    List<MenuItem>? filteredMenuItems,
    List<MenuItem>? popularItems,
    List<Review>? reviews,
    Map<int, int>? ratingBreakdown,
    int? totalReviews,
    bool? isLoading,
    String? errorMessage,
    List<String>? selectedDietaryRestrictions,
    String? selectedCategory,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return RestaurantState(
      restaurants: restaurants ?? this.restaurants,
      filteredRestaurants: filteredRestaurants ?? this.filteredRestaurants,
      selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
      menuItems: menuItems ?? this.menuItems,
      filteredMenuItems: filteredMenuItems ?? this.filteredMenuItems,
      popularItems: popularItems ?? this.popularItems,
      reviews: reviews ?? this.reviews,
      ratingBreakdown: ratingBreakdown ?? this.ratingBreakdown,
      totalReviews: totalReviews ?? this.totalReviews,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedDietaryRestrictions:
          selectedDietaryRestrictions ?? this.selectedDietaryRestrictions,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// Restaurant provider to manage restaurant state
final restaurantProvider =
    StateNotifierProvider<RestaurantNotifier, RestaurantState>(
      (ref) => RestaurantNotifier(),
    );

class RestaurantNotifier extends StateNotifier<RestaurantState> {
  RestaurantNotifier() : super(RestaurantState()) {
    // Load any persisted dietary filters on startup
    Future.microtask(_loadPersistedDietaryFilters);
  }

  Future<void> _loadPersistedDietaryFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('selected_dietary_filters') ?? [];
      if (saved.isNotEmpty) {
        state = state.copyWith(selectedDietaryRestrictions: saved);
      }
    } catch (_) {
      // ignore
    }
  }

  // Load restaurants from the database (first page)
  Future<void> loadRestaurants() async {
    state = state.copyWith(isLoading: true, currentPage: 0, hasMore: true);

    try {
      final repo = RestaurantRepositoryR();
      final res = await repo.fetchList(
        limit: state.pageSize,
        page: 0,
      );

      await res.when(
        success: (restaurants) async {
          state = state.copyWith(
            restaurants: restaurants,
            filteredRestaurants: restaurants, // Initially show all restaurants
            isLoading: false,
            currentPage: 0,
            hasMore: restaurants.length == state.pageSize,
          );

          // Apply any persisted dietary filters
          if (state.selectedDietaryRestrictions.isNotEmpty) {
            await loadAllMenuItemsForDietaryFiltering();
          }
        },
        failure: (f) {
          state = state.copyWith(isLoading: false, errorMessage: f.message);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }


  // Load additional restaurants (pagination)
  Future<void> loadMoreRestaurants() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = RestaurantRepositoryR();
      final nextPage = state.currentPage + 1;
      final res = await repo.fetchList(
        limit: state.pageSize,
        page: nextPage,
      );

      await res.when(
        success: (moreRestaurants) async {
          final allRestaurants = [...state.restaurants, ...moreRestaurants];

          state = state.copyWith(
            restaurants: allRestaurants,
            filteredRestaurants: allRestaurants,
            currentPage: nextPage,
            hasMore: moreRestaurants.length == state.pageSize,
            isLoadingMore: false,
          );

          if (state.selectedDietaryRestrictions.isNotEmpty) {
            // Re-apply dietary filters after loading more
            await loadAllMenuItemsForDietaryFiltering();
          }
        },
        failure: (f) {
          state = state.copyWith(isLoadingMore: false, errorMessage: f.message);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
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

      final menuItems = menuItemData
          .map((data) => MenuItem.fromJson(data))
          .toList();

      // Also load popular items
      final popularItemData = await dbService.getPopularMenuItems(
        restaurantId,
        limit: 5,
      );
      final popularItems = popularItemData
          .map((data) => MenuItem.fromJson(data))
          .toList();

      // Load reviews and rating breakdown
      await loadReviews(restaurantId);

      state = state.copyWith(
        menuItems: menuItems,
        filteredMenuItems: menuItems, // Initially show all menu items
        popularItems: popularItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Load reviews for a restaurant
  Future<void> loadReviews(String restaurantId, {int limit = 10}) async {
    try {
      final dbService = DatabaseService();

      // Load initial reviews
      final reviewData = await dbService.getRestaurantReviews(
        restaurantId,
        limit: limit,
        offset: 0,
      );
      final reviews = reviewData
          .map((data) => Review.fromJson(data))
          .toList();

      // Load rating breakdown
      final breakdown = await dbService.getRestaurantRatingBreakdown(
        restaurantId,
      );

      // Get total count
      final totalCount = await dbService.getRestaurantReviewsCount(
        restaurantId,
      );

      state = state.copyWith(
        reviews: reviews,
        ratingBreakdown: breakdown,
        totalReviews: totalCount,
      );
    } catch (e) {
      print('Error loading reviews: $e');
      // Don't set error state, reviews are optional
    }
  }

  // Load more reviews with pagination
  Future<List<Review>> loadMoreReviews(
    String restaurantId,
    int offset,
  ) async {
    try {
      final dbService = DatabaseService();
      final reviewData = await dbService.getRestaurantReviews(
        restaurantId,
        limit: 10,
        offset: offset,
      );
      return reviewData.map((data) => Review.fromJson(data)).toList();
    } catch (e) {
      print('Error loading more reviews: $e');
      return [];
    }
  }

  // Load all menu items for all restaurants to enable dietary filtering across restaurants
  // Optimized to use a single query with JOIN instead of N+1 queries
  Future<void> loadAllMenuItemsForDietaryFiltering() async {
    if (state.restaurants.isEmpty) {
      // If restaurants haven't been loaded yet, load them first
      await loadRestaurants();
    }

    if (state.restaurants.isEmpty) return;

    try {
      final dbService = DatabaseService();
      // Use a single query to get all menu items for all restaurants
      final restaurantIds = state.restaurants.map((r) => r.id).toList();
      final allMenuItemData = await dbService.client
          .from('menu_items')
          .select('*, restaurants(*)')
          .inFilter('restaurant_id', restaurantIds)
          .order('restaurant_id');

      final allMenuItems = allMenuItemData
          .map((data) => MenuItem.fromJson(data))
          .toList();

      state = state.copyWith(menuItems: allMenuItems);

      // Apply the filters after loading all menu items
      _applyRestaurantFilters();
    } catch (e) {
      print('Error loading menu items for dietary filtering: $e');
      // Fallback to empty menu items if query fails
      state = state.copyWith(menuItems: []);
    }
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

    // Persist selection for the session/app restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_dietary_filters', newRestrictions);
    } catch (_) {}

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
              state.selectedDietaryRestrictions.every(
                (restriction) => menuItem.dietaryRestrictions
                    ?.map((s) => s.toLowerCase())
                    .contains(restriction.toLowerCase()) ?? false,
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
    List<MenuItem> itemsToFilter = state.menuItems
        .where((item) => item.restaurantId == state.selectedRestaurant?.id)
        .toList();

    List<MenuItem> filtered = itemsToFilter;

    if (state.selectedDietaryRestrictions.isNotEmpty) {
      filtered = itemsToFilter.where((item) {
        // Check if the menu item satisfies all selected dietary restrictions
        return state.selectedDietaryRestrictions.every(
          (restriction) => item.dietaryRestrictions
              ?.map((s) => s.toLowerCase())
              .contains(restriction.toLowerCase()) ?? false,
        );
      }).toList();
    }

    state = state.copyWith(filteredMenuItems: filtered);
  }

  // Clear all dietary restriction filters
  void clearDietaryRestrictionsFilter() {
    // Only reset filtered menu items to the ones for the selected restaurant
    final selectedRestaurantMenuItems = state.menuItems
        .where((item) => item.restaurantId == state.selectedRestaurant?.id)
        .toList();

    state = state.copyWith(
      selectedDietaryRestrictions: const [],
      filteredRestaurants: state.restaurants,
      filteredMenuItems: selectedRestaurantMenuItems,
    );
  }

  /// Filter restaurants by category
  Future<void> filterByCategory(String category) async {
    state = state.copyWith(isLoading: true, selectedCategory: category);

    try {
      final repo = RestaurantRepositoryR();
      final res = await repo.fetchByCategory(category);

      res.when(
        success: (filteredRestaurants) {
          state = state.copyWith(
            filteredRestaurants: filteredRestaurants,
            isLoading: false,
          );
        },
        failure: (f) {
          state = state.copyWith(isLoading: false, errorMessage: f.message);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Clear category filter
  void clearCategoryFilter() {
    state = state.copyWith(
      selectedCategory: null,
      filteredRestaurants: state.restaurants,
    );
  }
}
