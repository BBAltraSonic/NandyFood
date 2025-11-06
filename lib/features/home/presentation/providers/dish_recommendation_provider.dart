import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/dish_favorites_service.dart';

// Data class for pagination state
class DishRecommendationState {
  final List<MenuItem> recommendations;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int currentPage;
  final int pageSize;

  const DishRecommendationState({
    this.recommendations = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 0,
    this.pageSize = 8,
  });

  DishRecommendationState copyWith({
    List<MenuItem>? recommendations,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return DishRecommendationState(
      recommendations: recommendations ?? this.recommendations,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Simplified provider for dish recommendations using existing restaurant data
class DishRecommendationNotifier extends StateNotifier<AsyncValue<DishRecommendationState>> {
  final RestaurantState _restaurantState;
  final AuthState _authState;
  final DishFavoritesService _favoritesService;
  List<MenuItem> _allRecommendations = [];

  DishRecommendationNotifier(
    this._restaurantState,
    this._authState,
  ) : _favoritesService = DishFavoritesService(), super(const AsyncValue.loading());

  Future<void> loadRecommendations() async {
    state = const AsyncValue.loading();

    try {
      if (_restaurantState.restaurants.isEmpty) {
        state = AsyncValue.data(const DishRecommendationState());
        return;
      }

      // Get popular items from the restaurant state
      final popularItems = _restaurantState.popularItems;

      // Get user's favorite dishes for personalization
      List<MenuItem> userFavorites = [];
      if (_authState.user != null) {
        try {
          userFavorites = await _favoritesService.getUserFavorites(_authState.user!.id);
        } catch (e) {
          // Continue without favorites if there's an error
        }
      }

      // Filter and rank recommendations with personalization
      _allRecommendations = _filterAndRankRecommendations(
        popularItems.isNotEmpty ? popularItems : _getAllAvailableMenuItems(),
        _restaurantState.restaurants,
        userFavorites,
      );

      // Load first page
      final firstPage = _allRecommendations.take(8).toList();
      final hasMore = _allRecommendations.length > 8;

      state = AsyncValue.data(DishRecommendationState(
        recommendations: firstPage,
        hasMore: hasMore,
        currentPage: 0,
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> loadMoreRecommendations() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      final startIndex = (nextPage) * currentState.pageSize;
      final endIndex = startIndex + currentState.pageSize;

      final moreRecommendations = _allRecommendations.skip(startIndex).take(currentState.pageSize).toList();
      final hasMore = endIndex < _allRecommendations.length;

      state = AsyncValue.data(currentState.copyWith(
        recommendations: [...currentState.recommendations, ...moreRecommendations],
        isLoadingMore: false,
        hasMore: hasMore,
        currentPage: nextPage,
      ));
    } catch (e) {
      state = AsyncValue.data(currentState.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  List<MenuItem> _getAllAvailableMenuItems() {
    // Get menu items from all restaurants
    final allMenuItems = <MenuItem>[];

    for (final restaurant in _restaurantState.restaurants) {
      // Get menu items for this restaurant
      final restaurantMenuItems = _restaurantState.menuItems
          .where((item) => item.restaurantId == restaurant.id)
          .toList();

      allMenuItems.addAll(restaurantMenuItems);
    }

    return allMenuItems;
  }

  List<MenuItem> _filterAndRankRecommendations(
    List<MenuItem> allItems,
    List<Restaurant> restaurants,
    List<MenuItem> userFavorites,
  ) {
    // Create a restaurant map for quick lookup
    final restaurantMap = {for (var r in restaurants) r.id: r};

    // Filter available items (from active restaurants)
    final availableItems = allItems.where((item) =>
      item.isAvailable &&
      (restaurantMap[item.restaurantId]?.isActive ?? false)
    ).toList();

    // Sort by multiple criteria including personalization and time-based preferences
    availableItems.sort((a, b) {
      // Priority 1: User preference bonus (favorite restaurants/categories)
      final aPreferenceScore = _calculatePreferenceScore(a, userFavorites);
      final bPreferenceScore = _calculatePreferenceScore(b, userFavorites);

      if (aPreferenceScore != bPreferenceScore) {
        return bPreferenceScore.compareTo(aPreferenceScore);
      }

      // Priority 2: Restaurant rating
      final aRestaurantRating = restaurantMap[a.restaurantId]?.rating ?? 0.0;
      final bRestaurantRating = restaurantMap[b.restaurantId]?.rating ?? 0.0;

      if (aRestaurantRating != bRestaurantRating) {
        return bRestaurantRating.compareTo(aRestaurantRating);
      }

      // Priority 3: Time-based relevance score
      final aTimeScore = _calculateTimeBasedScore(a);
      final bTimeScore = _calculateTimeBasedScore(b);

      if (aTimeScore != bTimeScore) {
        return bTimeScore.compareTo(aTimeScore);
      }

      // Priority 4: Price (favor mid-range options)
      final aPrice = a.price;
      final bPrice = b.price;
      final aScore = _calculatePriceScore(aPrice);
      final bScore = _calculatePriceScore(bPrice);

      return bScore.compareTo(aScore);
    });

    return availableItems;
  }

  double _calculateTimeBasedScore(MenuItem item) {
    final hour = DateTime.now().hour;
    double score = 0.0;

    // Get dish category from description or name
    final dishName = item.name.toLowerCase();
    final dishDescription = item.description?.toLowerCase() ?? '';

    // Time-based scoring
    if (hour >= 6 && hour < 11) {
      // Breakfast (6 AM - 11 AM)
      if (_containsBreakfastKeywords(dishName, dishDescription)) {
        score += 10.0;
      }
    } else if (hour >= 11 && hour < 14) {
      // Lunch (11 AM - 2 PM)
      if (_containsLunchKeywords(dishName, dishDescription)) {
        score += 10.0;
      }
    } else if (hour >= 14 && hour < 17) {
      // Afternoon snack (2 PM - 5 PM)
      if (_containsSnackKeywords(dishName, dishDescription)) {
        score += 10.0;
      }
    } else if (hour >= 17 && hour < 21) {
      // Dinner (5 PM - 9 PM)
      if (_containsDinnerKeywords(dishName, dishDescription)) {
        score += 10.0;
      }
    } else {
      // Late night (9 PM - 6 AM)
      if (_containsLateNightKeywords(dishName, dishDescription)) {
        score += 10.0;
      }
    }

    // Add variety bonus for different meal times
    if (hour >= 11 && hour < 14) {
      // Lunch - favor quick items
      if (dishName.contains('quick') || dishName.contains('fast') || dishDescription.contains('ready')) {
        score += 5.0;
      }
    } else if (hour >= 17 && hour < 21) {
      // Dinner - favor hearty meals
      if (dishName.contains('combo') || dishName.contains('platter') || dishName.contains('family')) {
        score += 5.0;
      }
    }

    return score;
  }

  bool _containsBreakfastKeywords(String name, String description) {
    final keywords = [
      'breakfast', 'pancake', 'waffle', 'egg', 'omelet', 'toast', 'cereal',
      'coffee', 'bagel', 'muffin', 'croissant', 'yogurt', 'oatmeal', 'burrito'
    ];
    return keywords.any((keyword) =>
      name.contains(keyword) || description.contains(keyword));
  }

  bool _containsLunchKeywords(String name, String description) {
    final keywords = [
      'sandwich', 'burger', 'wrap', 'salad', 'soup', 'taco', 'pizza',
      'quick', 'lunch', 'meal', 'combo', 'bowl'
    ];
    return keywords.any((keyword) =>
      name.contains(keyword) || description.contains(keyword));
  }

  bool _containsSnackKeywords(String name, String description) {
    final keywords = [
      'snack', 'fries', 'nuggets', 'wings', 'roll', 'pretzel', 'cookie',
      'cake', 'pastry', 'smoothie', 'shake', 'coffee'
    ];
    return keywords.any((keyword) =>
      name.contains(keyword) || description.contains(keyword));
  }

  bool _containsDinnerKeywords(String name, String description) {
    final keywords = [
      'dinner', 'steak', 'chicken', 'pasta', 'seafood', 'ribs', 'grill',
      'platter', 'combo', 'family', 'dinner', 'meal', 'feast'
    ];
    return keywords.any((keyword) =>
      name.contains(keyword) || description.contains(keyword));
  }

  bool _containsLateNightKeywords(String name, String description) {
    final keywords = [
      'late', 'night', 'pizza', 'burger', 'taco', 'wings', 'snack',
      'quick', 'easy', 'fast'
    ];
    return keywords.any((keyword) =>
      name.contains(keyword) || description.contains(keyword));
  }

  double _calculatePriceScore(double price) {
    // Favor mid-range prices ($8-$20) for recommendations
    if (price >= 8 && price <= 20) {
      return 20 - (price - 8).abs(); // Maximum score at $14
    } else if (price < 8) {
      return 10 + price; // Lower score for very cheap items
    } else {
      return 30 - price; // Lower score for expensive items
    }
  }

  double _calculatePreferenceScore(MenuItem item, List<MenuItem> userFavorites) {
    if (userFavorites.isEmpty) return 0.0;

    double score = 0.0;

    // Check if this exact dish is a favorite
    if (userFavorites.any((fav) => fav.id == item.id)) {
      score += 15.0; // High bonus for exact favorites
    }

    // Check if user favors dishes from the same restaurant
    final favoriteRestaurantIds = userFavorites
        .map((fav) => fav.restaurantId)
        .toSet();

    if (favoriteRestaurantIds.contains(item.restaurantId)) {
      score += 8.0; // Bonus for favorite restaurants
    }

    // Check if user favors dishes in the same category
    final favoriteCategories = userFavorites
        .map((fav) => fav.category.toLowerCase())
        .toSet();

    if (favoriteCategories.contains(item.category.toLowerCase())) {
      score += 5.0; // Bonus for favorite categories
    }

    // Price preference analysis
    final userFavoritePrices = userFavorites.map((fav) => fav.price).toList();
    if (userFavoritePrices.isNotEmpty) {
      final avgFavoritePrice = userFavoritePrices.reduce((a, b) => a + b) / userFavoritePrices.length;
      final priceDifference = (item.price - avgFavoritePrice).abs();

      // Bonus for prices close to user's average favorite price
      if (priceDifference <= 3.0) {
        score += 3.0;
      } else if (priceDifference <= 6.0) {
        score += 1.0;
      }
    }

    return score;
  }

  Future<void> refresh() async {
    await loadRecommendations();
  }
}

// Provider instance
final dishRecommendationProvider = StateNotifierProvider<DishRecommendationNotifier, AsyncValue<DishRecommendationState>>(
  (ref) {
    final restaurantState = ref.watch(restaurantProvider);
    final authState = ref.watch(authStateProvider);

    return DishRecommendationNotifier(
      restaurantState,
      authState,
    );
  },
);