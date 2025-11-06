import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/dish_favorites_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

/// Dish Favorites State
class DishFavoritesState {
  final List<MenuItem> favoriteItems;
  final Map<String, bool> favoriteStatus; // menu_item_id -> is_favorite
  final bool isLoading;
  final String? errorMessage;

  DishFavoritesState({
    this.favoriteItems = const [],
    this.favoriteStatus = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  DishFavoritesState copyWith({
    List<MenuItem>? favoriteItems,
    Map<String, bool>? favoriteStatus,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DishFavoritesState(
      favoriteItems: favoriteItems ?? this.favoriteItems,
      favoriteStatus: favoriteStatus ?? this.favoriteStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage,
    );
  }
}

/// Dish Favorites Notifier
class DishFavoritesNotifier extends StateNotifier<DishFavoritesState> {
  DishFavoritesNotifier() : super(DishFavoritesState());

  final DishFavoritesService _dishFavoritesService = DishFavoritesService();
  final DatabaseService _dbService = DatabaseService();

  String? _currentUserId;

  /// Set the current user and load their favorites
  void setCurrentUser(String userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      loadUserFavorites();
    }
  }

  /// Load user's favorite menu items
  Future<void> loadUserFavorites() async {
    if (_currentUserId == null) {
      AppLogger.warning('Cannot load favorites: No user ID set');
      return;
    }

    AppLogger.function('DishFavoritesNotifier.loadUserFavorites', 'ENTER');

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final favorites = await _dishFavoritesService.getUserFavorites(_currentUserId!);

      // Build favorite status map
      final favoriteStatus = <String, bool>{};
      for (final item in favorites) {
        favoriteStatus[item.id] = true;
      }

      state = state.copyWith(
        favoriteItems: favorites,
        favoriteStatus: favoriteStatus,
        isLoading: false,
      );

      AppLogger.success('Loaded ${favorites.length} favorite menu items');
      AppLogger.function('DishFavoritesNotifier.loadUserFavorites', 'EXIT',
          result: favorites.length);
    } catch (e, stack) {
      AppLogger.error('Failed to load user favorites', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load favorites. Please try again.',
      );
    }
  }

  /// Toggle favorite status for a menu item
  Future<bool> toggleFavorite(String menuItemId) async {
    if (_currentUserId == null) {
      AppLogger.warning('Cannot toggle favorite: No user ID set');
      return false;
    }

    AppLogger.function('DishFavoritesNotifier.toggleFavorite', 'ENTER',
        params: {'menuItemId': menuItemId});

    try {
      final isNowFavorite = await _dishFavoritesService.toggleFavorite(
        _currentUserId!,
        menuItemId,
      );

      // Update favorite status map
      final updatedFavoriteStatus = Map<String, bool>.from(state.favoriteStatus);
      updatedFavoriteStatus[menuItemId] = isNowFavorite;

      // Update favorites list
      List<MenuItem> updatedFavorites = List<MenuItem>.from(state.favoriteItems);

      if (isNowFavorite) {
        // Add to favorites list (need to fetch full menu item details)
        await _addToFavoritesList(menuItemId, updatedFavorites);
      } else {
        // Remove from favorites list
        updatedFavorites.removeWhere((item) => item.id == menuItemId);
      }

      state = state.copyWith(
        favoriteItems: updatedFavorites,
        favoriteStatus: updatedFavoriteStatus,
      );

      AppLogger.success('Toggled favorite status for menu item: $menuItemId');
      AppLogger.function('DishFavoritesNotifier.toggleFavorite', 'EXIT',
          result: isNowFavorite);

      return isNowFavorite;
    } catch (e, stack) {
      AppLogger.error('Failed to toggle favorite', error: e, stack: stack);
      state = state.copyWith(
        errorMessage: 'Failed to update favorites. Please try again.',
      );
      rethrow;
    }
  }

  /// Check if a menu item is favorited
  bool isFavorite(String menuItemId) {
    return state.favoriteStatus[menuItemId] ?? false;
  }

  /// Add menu item to favorites list
  Future<void> _addToFavoritesList(String menuItemId, List<MenuItem> favorites) async {
    try {
      // Fetch the menu item details to add to the list
      final response = await _dbService.client
          .from('menu_items')
          .select('''
            id,
            name,
            description,
            price,
            image_url,
            category,
            restaurant_id,
            restaurants (
              id,
              name,
              image_url
            ),
            is_available,
            preparation_time,
            spicy_level,
            dietary_info
          ''')
          .eq('id', menuItemId)
          .single();

      final menuItem = MenuItem.fromJson(response);
      favorites.insert(0, menuItem); // Add to beginning of list
    } catch (e) {
      AppLogger.warning('Failed to fetch menu item details for favorites list: $e');
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Refresh favorites from server
  Future<void> refresh() async {
    await loadUserFavorites();
  }
}

/// Dish Favorites Provider
final dishFavoritesProvider = StateNotifierProvider<DishFavoritesNotifier, DishFavoritesState>((ref) {
  return DishFavoritesNotifier();
});

/// Provider to get current user ID for favorites
final currentUserIdProvider = Provider<String?>((ref) {
  final databaseService = DatabaseService();
  final session = databaseService.client.auth.currentSession;
  if (session != null) {
    return session.user.id;
  }
  return null;
});

/// Provider to automatically sync favorites with current user
final syncedDishFavoritesProvider = Provider<DishFavoritesState>((ref) {
  final dishFavorites = ref.watch(dishFavoritesProvider);
  final currentUserId = ref.watch(currentUserIdProvider);

  // Set current user when it changes
  ref.listen(currentUserIdProvider, (previous, next) {
    if (next != null && next != previous) {
      ref.read(dishFavoritesProvider.notifier).setCurrentUser(next);
    }
  });

  return dishFavorites;
});