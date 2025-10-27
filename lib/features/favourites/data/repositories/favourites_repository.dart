import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for user favourites (restaurants and menu items)
/// Encapsulates all Supabase access and returns plain JSON maps
/// so callers can map to their own models as needed.
class FavouritesRepository {
  FavouritesRepository({required DatabaseService databaseService})
      : _supabase = databaseService.client;

  final SupabaseClient _supabase;

  /// Fetch all favourites for a user with joined restaurant/menu_item objects
  Future<List<Map<String, dynamic>>> fetchFavourites(String userId) async {
    try {
      AppLogger.database('SELECT', 'favourites', data: {'user_id': userId});
      final response = await _supabase
          .from('favourites')
          .select('''
            *,
            restaurant:restaurants(*),
            menu_item:menu_items(*)
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(
        (response as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
      return list;
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.fetchFavourites failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Add a restaurant favourite and return the created row with join
  Future<Map<String, dynamic>> addRestaurantFavourite(
    String userId,
    String restaurantId,
  ) async {
    try {
      AppLogger.database('INSERT', 'favourites', data: {
        'user_id': userId,
        'type': 'restaurant',
        'restaurant_id': restaurantId,
      });
      final response = await _supabase
          .from('favourites')
          .insert({
            'user_id': userId,
            'type': 'restaurant',
            'restaurant_id': restaurantId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            restaurant:restaurants(*)
          ''')
          .single();

      return Map<String, dynamic>.from(response as Map);
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.addRestaurantFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Add a menu item favourite and return the created row with join
  Future<Map<String, dynamic>> addMenuItemFavourite(
    String userId,
    String menuItemId,
  ) async {
    try {
      AppLogger.database('INSERT', 'favourites', data: {
        'user_id': userId,
        'type': 'menu_item',
        'menu_item_id': menuItemId,
      });
      final response = await _supabase
          .from('favourites')
          .insert({
            'user_id': userId,
            'type': 'menu_item',
            'menu_item_id': menuItemId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('''
            *,
            menu_item:menu_items(*)
          ''')
          .single();

      return Map<String, dynamic>.from(response as Map);
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.addMenuItemFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Remove a restaurant favourite
  Future<void> removeRestaurantFavourite(String userId, String restaurantId) async {
    try {
      AppLogger.database('DELETE', 'favourites', data: {
        'user_id': userId,
        'restaurant_id': restaurantId,
        'type': 'restaurant',
      });
      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('type', 'restaurant');
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.removeRestaurantFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Remove a menu item favourite
  Future<void> removeMenuItemFavourite(String userId, String menuItemId) async {
    try {
      AppLogger.database('DELETE', 'favourites', data: {
        'user_id': userId,
        'menu_item_id': menuItemId,
        'type': 'menu_item',
      });
      await _supabase
          .from('favourites')
          .delete()
          .eq('user_id', userId)
          .eq('menu_item_id', menuItemId)
          .eq('type', 'menu_item');
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.removeMenuItemFavourite failed', error: e, stack: stack);
      rethrow;
    }
  }

  /// Clear all favourites for a user
  Future<void> clearUserFavourites(String userId) async {
    try {
      AppLogger.database('DELETE', 'favourites', data: {'user_id': userId});
      await _supabase.from('favourites').delete().eq('user_id', userId);
    } catch (e, stack) {
      AppLogger.error('FavouritesRepository.clearUserFavourites failed', error: e, stack: stack);
      rethrow;
    }
  }
}

