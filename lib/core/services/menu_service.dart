import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../../shared/models/menu_item.dart';

class MenuService {
  final DatabaseService _dbService;
  final SupabaseClient _client;

  MenuService(this._dbService) : _client = _dbService.client;

  /// Get all menu items for a restaurant
  Future<List<MenuItem>> getMenuItems(String restaurantId, {
    bool includeUnavailable = false,
  }) async {
    try {
      var query = _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId);

      if (!includeUnavailable) {
        query = query.eq('is_available', true);
      }

      final response = await query.order('category', ascending: true)
          .order('name', ascending: true);

      return response.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error getting menu items: $e');
      return [];
    }
  }

  /// Get menu items for a restaurant by category
  Future<List<MenuItem>> getMenuItemsByCategory(
    String restaurantId,
    String category, {
    bool includeUnavailable = false,
  }) async {
    try {
      var query = _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('category', category);

      if (!includeUnavailable) {
        query = query.eq('is_available', true);
      }

      final response = await query.order('name', ascending: true);
      return response.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error getting menu items by category: $e');
      return [];
    }
  }

  /// Get popular menu items for a restaurant
  Future<List<MenuItem>> getPopularMenuItems(
    String restaurantId, {
    int limit = 10,
  }) async {
    try {
      final response = await _dbService.getPopularMenuItems(restaurantId, limit: limit);
      return response.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error getting popular menu items: $e');
      return [];
    }
  }

  /// Get a single menu item by ID
  Future<MenuItem?> getMenuItemById(String menuItemId) async {
    try {
      final response = await _dbService.getMenuItemById(menuItemId);
      return response != null ? MenuItem.fromJson(response) : null;
    } catch (e) {
      print('Error getting menu item: $e');
      return null;
    }
  }

  /// Search menu items for a restaurant
  Future<List<MenuItem>> searchMenuItems(
    String restaurantId,
    String searchQuery, {
    bool includeUnavailable = false,
    int limit = 50,
  }) async {
    try {
      final query = searchQuery.trim().toLowerCase();
      var dbQuery = _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .or('name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%');

      if (!includeUnavailable) {
        dbQuery = dbQuery.eq('is_available', true);
      }

      final response = await dbQuery
          .order('name', ascending: true)
          .limit(limit);

      return response.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error searching menu items: $e');
      return [];
    }
  }

  /// Get menu categories for a restaurant
  Future<List<String>> getMenuCategories(String restaurantId) async {
    try {
      final response = await _client
          .from('menu_items')
          .select('category')
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .order('category', ascending: true);

      final categories = response
          .map((item) => item['category'] as String)
          .toSet()
          .toList();

      return categories;
    } catch (e) {
      print('Error getting menu categories: $e');
      return [];
    }
  }

  /// Create a new menu item (for restaurant owners)
  Future<MenuItem?> createMenuItem(Map<String, dynamic> menuItemData) async {
    try {
      final response = await _client
          .from('menu_items')
          .insert({
            ...menuItemData,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      print('Error creating menu item: $e');
      rethrow;
    }
  }

  /// Update a menu item (for restaurant owners)
  Future<MenuItem?> updateMenuItem(
    String menuItemId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await _client
          .from('menu_items')
          .update({
            ...updateData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', menuItemId)
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  /// Toggle menu item availability (for restaurant owners)
  Future<MenuItem?> toggleMenuItemAvailability(
    String menuItemId,
  ) async {
    try {
      // First get current status
      final current = await getMenuItemById(menuItemId);
      if (current == null) return null;

      final newStatus = !current.isAvailable;

      final response = await _client
          .from('menu_items')
          .update({
            'is_available': newStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', menuItemId)
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      print('Error toggling menu item availability: $e');
      rethrow;
    }
  }

  /// Delete a menu item (for restaurant owners)
  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      await _client.from('menu_items').delete().eq('id', menuItemId);
    } catch (e) {
      print('Error deleting menu item: $e');
      rethrow;
    }
  }

  /// Bulk update menu item availability (for restaurant owners)
  Future<void> bulkUpdateAvailability(
    List<String> menuItemIds,
    bool isAvailable,
  ) async {
    try {
      // Since 'in' method doesn't exist and 'in' is a keyword, we need to update items one by one
      for (final itemId in menuItemIds) {
        await _client
            .from('menu_items')
            .update({
              'is_available': isAvailable,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', itemId);
      }
    } catch (e) {
      print('Error bulk updating menu item availability: $e');
      rethrow;
    }
  }

  /// Get menu item statistics for a restaurant
  Future<Map<String, dynamic>> getMenuStatistics(String restaurantId) async {
    try {
      final response = await _client
          .from('menu_items')
          .select('is_available, category, price');

      final totalItems = response.length;
      int availableItems = 0;
      final Map<String, int> categoryCounts = {};
      double totalPrice = 0.0;

      for (final item in response) {
        if (item['is_available'] == true) {
          availableItems++;
        }

        final category = item['category'] as String;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

        if (item['price'] != null) {
          totalPrice += (item['price'] as num).toDouble();
        }
      }

      final averagePrice = totalItems > 0 ? totalPrice / totalItems : 0.0;

      return {
        'total_items': totalItems,
        'available_items': availableItems,
        'unavailable_items': totalItems - availableItems,
        'categories': categoryCounts,
        'average_price': averagePrice.toStringAsFixed(2),
      };
    } catch (e) {
      print('Error getting menu statistics: $e');
      return {
        'total_items': 0,
        'available_items': 0,
        'unavailable_items': 0,
        'categories': <String, int>{},
        'average_price': '0.00',
      };
    }
  }

  /// Watch menu item changes in real-time for a restaurant
  Stream<List<MenuItem>> watchMenuItems(String restaurantId, {
    bool includeUnavailable = false,
  }) {
    var query = _client
        .from('menu_items')
        .select('*')
        .eq('restaurant_id', restaurantId);

    if (!includeUnavailable) {
      query = query.eq('is_available', true);
    }

    return query
        .order('category', ascending: true)
        .order('name', ascending: true)
        .asStream()
        .map((event) => (event as List)
            .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Watch menu items by category in real-time
  Stream<List<MenuItem>> watchMenuItemsByCategory(
    String restaurantId,
    String category, {
    bool includeUnavailable = false,
  }) {
    var query = _client
        .from('menu_items')
        .select('*')
        .eq('restaurant_id', restaurantId)
        .eq('category', category);

    if (!includeUnavailable) {
      query = query.eq('is_available', true);
    }

    return query
        .order('name', ascending: true)
        .asStream()
        .map((event) => (event as List)
            .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Get dietary options available at a restaurant
  Future<List<String>> getDietaryOptions(String restaurantId) async {
    try {
      final response = await _client
          .from('menu_items')
          .select('dietary_tags')
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .not('dietary_tags', 'is', null);

      final Set<String> dietaryOptions = {};

      for (final item in response) {
        final tags = item['dietary_tags'] as List?;
        if (tags != null) {
          dietaryOptions.addAll(tags.cast<String>());
        }
      }

      return dietaryOptions.toList()..sort();
    } catch (e) {
      print('Error getting dietary options: $e');
      return [];
    }
  }

  /// Filter menu items by dietary restrictions
  Future<List<MenuItem>> getMenuItemsByDietaryRestrictions(
    String restaurantId,
    List<String> dietaryRestrictions, {
    bool includeUnavailable = false,
  }) async {
    try {
      var query = _client
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId);

      if (!includeUnavailable) {
        query = query.eq('is_available', true);
      }

      // Filter for items that contain at least one of the requested dietary tags
      if (dietaryRestrictions.isNotEmpty) {
        query = query.contains('dietary_tags', dietaryRestrictions);
      }

      final response = await query.order('category', ascending: true)
          .order('name', ascending: true);

      return response.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      print('Error filtering menu items by dietary restrictions: $e');
      return [];
    }
  }
}

/// Provider for MenuService
final menuServiceProvider = Provider<MenuService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return MenuService(dbService);
});