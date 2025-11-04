import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';

// Simplified provider for dish recommendations using existing restaurant data
class DishRecommendationNotifier extends StateNotifier<AsyncValue<List<MenuItem>>> {
  final RestaurantState _restaurantState;

  DishRecommendationNotifier(
    this._restaurantState,
    AuthState authState,
  ) : super(const AsyncValue.loading());

  Future<void> loadRecommendations() async {
    state = const AsyncValue.loading();

    try {
      if (_restaurantState.restaurants.isEmpty) {
        state = const AsyncValue.data([]);
        return;
      }

      // Get popular items from the restaurant state
      final popularItems = _restaurantState.popularItems;

      // Filter and rank recommendations
      final recommendations = _filterAndRankRecommendations(
        popularItems.isNotEmpty ? popularItems : _getAllAvailableMenuItems(),
        _restaurantState.restaurants,
      );

      state = AsyncValue.data(recommendations.take(8).toList()); // Limit to 8 recommendations
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
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
  ) {
    // Create a restaurant map for quick lookup
    final restaurantMap = {for (var r in restaurants) r.id: r};

    // Filter available items (from active restaurants)
    final availableItems = allItems.where((item) =>
      item.isAvailable &&
      restaurantMap[item.restaurantId]?.isActive == true
    ).toList();

    // Sort by multiple criteria
    availableItems.sort((a, b) {
      // Priority 1: Restaurant rating
      final aRestaurantRating = restaurantMap[a.restaurantId]?.rating ?? 0.0;
      final bRestaurantRating = restaurantMap[b.restaurantId]?.rating ?? 0.0;

      if (aRestaurantRating != bRestaurantRating) {
        return bRestaurantRating.compareTo(aRestaurantRating);
      }

      // Priority 2: Price (favor mid-range options)
      final aPrice = a.price;
      final bPrice = b.price;
      final aScore = _calculatePriceScore(aPrice);
      final bScore = _calculatePriceScore(bPrice);

      return bScore.compareTo(aScore);
    });

    return availableItems;
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

  Future<void> refresh() async {
    await loadRecommendations();
  }
}

// Provider instance
final dishRecommendationProvider = StateNotifierProvider<DishRecommendationNotifier, AsyncValue<List<MenuItem>>>(
  (ref) {
    final restaurantState = ref.watch(restaurantProvider);
    final authState = ref.watch(authStateProvider);

    return DishRecommendationNotifier(
      restaurantState,
      authState,
    );
  },
);