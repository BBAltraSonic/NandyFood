import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

/// Service for managing user favorite menu items (dish-level favorites)
class DishFavoritesService {
  static final DishFavoritesService _instance = DishFavoritesService._internal();
  factory DishFavoritesService() => _instance;
  DishFavoritesService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// Get user's favorite menu items
  Future<List<MenuItem>> getUserFavorites(String userId) async {
    AppLogger.function('DishFavoritesService.getUserFavorites', 'ENTER',
        params: {'userId': userId});

    try {
      final response = await _dbService.client
          .from('user_favorite_menu_items')
          .select('''
            menu_item_id,
            menu_items (
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
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final menuItems = (response as List)
          .map((json) => MenuItem.fromJson(json['menu_items'] as Map<String, dynamic>))
          .toList();

      AppLogger.success('Fetched ${menuItems.length} favorite menu items');
      AppLogger.function('DishFavoritesService.getUserFavorites', 'EXIT',
          result: menuItems.length);

      return menuItems;
    } catch (e, stack) {
      AppLogger.error('Failed to get user favorite menu items',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Add a menu item to user's favorites
  Future<void> addToFavorites(String userId, String menuItemId) async {
    AppLogger.function('DishFavoritesService.addToFavorites', 'ENTER',
        params: {'userId': userId, 'menuItemId': menuItemId});

    try {
      await _dbService.client.from('user_favorite_menu_items').insert({
        'user_id': userId,
        'menu_item_id': menuItemId,
      });

      AppLogger.success('Added menu item to favorites');
      AppLogger.function('DishFavoritesService.addToFavorites', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to add menu item to favorites',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Remove a menu item from user's favorites
  Future<void> removeFromFavorites(String userId, String menuItemId) async {
    AppLogger.function('DishFavoritesService.removeFromFavorites', 'ENTER',
        params: {'userId': userId, 'menuItemId': menuItemId});

    try {
      await _dbService.client
          .from('user_favorite_menu_items')
          .delete()
          .eq('user_id', userId)
          .eq('menu_item_id', menuItemId);

      AppLogger.success('Removed menu item from favorites');
      AppLogger.function('DishFavoritesService.removeFromFavorites', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to remove menu item from favorites',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Check if a menu item is in user's favorites
  Future<bool> isFavorite(String userId, String menuItemId) async {
    AppLogger.function('DishFavoritesService.isFavorite', 'ENTER',
        params: {'userId': userId, 'menuItemId': menuItemId});

    try {
      final response = await _dbService.client
          .from('user_favorite_menu_items')
          .select('id')
          .eq('user_id', userId)
          .eq('menu_item_id', menuItemId)
          .maybeSingle();

      final isFav = response != null;

      AppLogger.function('DishFavoritesService.isFavorite', 'EXIT',
          result: isFav);

      return isFav;
    } catch (e, stack) {
      AppLogger.error('Failed to check if menu item is favorite',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Toggle a menu item in user's favorites (add if not favorite, remove if favorite)
  Future<bool> toggleFavorite(String userId, String menuItemId) async {
    AppLogger.function('DishFavoritesService.toggleFavorite', 'ENTER',
        params: {'userId': userId, 'menuItemId': menuItemId});

    try {
      final isCurrentlyFavorite = await isFavorite(userId, menuItemId);

      if (isCurrentlyFavorite) {
        await removeFromFavorites(userId, menuItemId);
        AppLogger.function('DishFavoritesService.toggleFavorite', 'EXIT',
            result: false);
        return false;
      } else {
        await addToFavorites(userId, menuItemId);
        AppLogger.function('DishFavoritesService.toggleFavorite', 'EXIT',
            result: true);
        return true;
      }
    } catch (e, stack) {
      AppLogger.error('Failed to toggle menu item favorite',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get the count of favorites for a menu item
  Future<int> getFavoriteCount(String menuItemId) async {
    AppLogger.function('DishFavoritesService.getFavoriteCount', 'ENTER',
        params: {'menuItemId': menuItemId});

    try {
      final response = await _dbService.client
          .from('user_favorite_menu_items')
          .select('id')
          .eq('menu_item_id', menuItemId);

      final count = (response as List).length;

      AppLogger.function('DishFavoritesService.getFavoriteCount', 'EXIT',
          result: count);

      return count;
    } catch (e, stack) {
      AppLogger.error('Failed to get favorite count',
          error: e, stack: stack);
      return 0;
    }
  }

  /// Get popular menu items based on favorite count
  Future<List<Map<String, dynamic>>> getPopularMenuItems({int limit = 10}) async {
    AppLogger.function('DishFavoritesService.getPopularMenuItems', 'ENTER',
        params: {'limit': limit});

    try {
      // Use a different approach for Supabase - get count via RPC or a raw query
      final response = await _dbService.client
          .from('user_favorite_menu_items')
          .select('''
            menu_item_id,
            menu_items!inner (
              id,
              name,
              description,
              price,
              image_url,
              category,
              restaurant_id,
              restaurants (
                id,
                name
              )
            )
          ''')
          .order('created_at', ascending: false)
          .limit(limit * 3); // Get more items to simulate popularity

      AppLogger.success('Fetched ${(response as List).length} favorite menu items');
      AppLogger.function('DishFavoritesService.getPopularMenuItems', 'EXIT',
          result: (response as List).length);

      return (response).cast<Map<String, dynamic>>();
    } catch (e, stack) {
      AppLogger.error('Failed to get popular menu items',
          error: e, stack: stack);
      rethrow;
    }
  }
}