import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/features/restaurant/data/dtos/menu_item_dto.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

class MenuRepository {
  final DatabaseService _db;

  MenuRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  /// Fetch all menu items for a restaurant
  Future<List<MenuItem>> fetchMenuItems(String restaurantId) async {
    try {
      final menuItemData = await _db.getMenuItems(restaurantId);
      return menuItemData
          .map((data) => MenuItem.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch menu items by category for a restaurant
  Future<List<MenuItem>> fetchMenuItemsByCategory(
    String restaurantId,
    String category,
  ) async {
    try {
      final menuItemData = await _db.getMenuItemsByCategory(restaurantId, category);
      return menuItemData
          .map((data) => MenuItem.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch popular menu items for a restaurant
  Future<List<MenuItem>> fetchPopularMenuItems(
    String restaurantId, {
    int limit = 5,
  }) async {
    try {
      final menuItemData = await _db.getPopularMenuItems(restaurantId, limit: limit);
      return menuItemData
          .map((data) => MenuItem.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch a single menu item with full details
  Future<MenuItem?> fetchMenuItemById(String menuItemId) async {
    try {
      final menuItemData = await _db.getMenuItemById(menuItemId);
      if (menuItemData == null) return null;
      return MenuItem.fromJson(menuItemData);
    } catch (e) {
      return null;
    }
  }

  /// Fetch a single menu item row (including customization_options) and parse DTO
  Future<MenuItemDTO?> fetchMenuItemWithModifiers(String menuItemId) async {
    final row = await _db.getMenuItemById(menuItemId);
    if (row == null) return null;
    try {
      return MenuItemDTO.fromSupabaseRow(row);
    } catch (_) {
      return null;
    }
  }

  /// Filter menu items by dietary restrictions
  List<MenuItem> filterByDietaryRestrictions(
    List<MenuItem> menuItems,
    List<String> restrictions,
  ) {
    if (restrictions.isEmpty) return menuItems;

    return menuItems.where((item) {
      return restrictions.every((restriction) =>
          item.dietaryRestrictions?.any((dietary) =>
                  dietary.toLowerCase().contains(restriction.toLowerCase())) ??
              false);
    }).toList();
  }

  /// Filter menu items by price range
  List<MenuItem> filterByPriceRange(
    List<MenuItem> menuItems,
    double minPrice,
    double maxPrice,
  ) {
    return menuItems.where((item) =>
        item.price >= minPrice && item.price <= maxPrice).toList();
  }

  /// Filter menu items by availability
  List<MenuItem> filterByAvailability(List<MenuItem> menuItems) {
    return menuItems.where((item) => item.isAvailable).toList();
  }

  /// Filter menu items by spicy level
  List<MenuItem> filterBySpicyLevel(
    List<MenuItem> menuItems,
    int maxSpicyLevel,
  ) {
    return menuItems;
  }

  /// Get unique categories from menu items
  List<String> getUniqueCategories(List<MenuItem> menuItems) {
    final categories = menuItems
        .map((item) => item.category)
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList();
    categories.sort(); // Sort alphabetically
    return categories;
  }

  /// Search menu items by name or description
  List<MenuItem> searchMenuItems(
    List<MenuItem> menuItems,
    String query,
  ) {
    if (query.trim().isEmpty) return menuItems;

    final searchQuery = query.toLowerCase();
    return menuItems.where((item) =>
        item.name.toLowerCase().contains(searchQuery) ||
        (item.description?.toLowerCase().contains(searchQuery) ?? false)
    ).toList();
  }

  /// Group menu items by category
  Map<String, List<MenuItem>> groupByCategory(List<MenuItem> menuItems) {
    final Map<String, List<MenuItem>> grouped = {};

    for (final item in menuItems) {
      final category = item.category.isNotEmpty ? item.category : 'Other';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(item);
    }

    // Sort items within each category by name
    for (final category in grouped.keys) {
      grouped[category]!.sort((a, b) => a.name.compareTo(b.name));
    }

    return grouped;
  }

  /// Sort menu items by different criteria
  List<MenuItem> sortMenuItems(
    List<MenuItem> menuItems,
    String sortBy, {
    bool ascending = true,
  }) {
    switch (sortBy.toLowerCase()) {
      case 'price':
        menuItems.sort((a, b) => a.price.compareTo(b.price));
        return ascending ? menuItems : menuItems.reversed.toList();
      case 'name':
        menuItems.sort((a, b) => a.name.compareTo(b.name));
        return ascending ? menuItems : menuItems.reversed.toList();
      case 'rating':
        // MenuItem doesn't have rating field, sort by name instead
        menuItems.sort((a, b) => a.name.compareTo(b.name));
        return ascending ? menuItems : menuItems.reversed.toList();
      case 'popularity':
        // Sort by price descending as a proxy for popularity
        menuItems.sort((a, b) => b.price.compareTo(a.price));
        return ascending ? menuItems.reversed.toList() : menuItems;
      default:
        return menuItems;
    }
  }

  /// Check if menu item is currently available based on restaurant operating hours
  bool isMenuItemAvailable(MenuItem menuItem, Restaurant restaurant) {
    if (!menuItem.isAvailable) return false;

    // Check if restaurant is currently open
    final now = DateTime.now();
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final openingHours = restaurant.openingHours;
    if (openingHours.isEmpty) return false;

    final dayKeys = [
      'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
    ];
    final dayKey = dayKeys[dayOfWeek - 1];

    final todayHours = openingHours[dayKey];
    if (todayHours == null || todayHours['is_closed'] == true) {
      return false;
    }

    final openTime = todayHours['open'] as String?;
    final closeTime = todayHours['close'] as String?;

    if (openTime == null || closeTime == null) return false;

    return _compareTime(currentTime, openTime) >= 0 && _compareTime(currentTime, closeTime) <= 0;
  }

  /// Compare two time strings in "HH:mm" format
  /// Returns: -1 if time1 < time2, 0 if equal, 1 if time1 > time2
  int _compareTime(String time1, String time2) {
    final parts1 = time1.split(':').map(int.parse).toList();
    final parts2 = time2.split(':').map(int.parse).toList();

    final totalMinutes1 = parts1[0] * 60 + parts1[1];
    final totalMinutes2 = parts2[0] * 60 + parts2[1];

    return totalMinutes1.compareTo(totalMinutes2);
  }

  /// Calculate nutritional information for menu item with modifiers
  Map<String, dynamic> calculateNutritionalInfo(
    MenuItem menuItem,
    List<String> selectedModifiers,
  ) {
    // Base nutritional info - this would typically come from the database
    // For now, return empty map as nutritionalInfo is not in the MenuItem model
    final baseNutrition = <String, dynamic>{};

    // This would need to be implemented based on your modifier data structure
    // For now, return the base nutritional info
    return baseNutrition;
  }

  /// Get recommended items based on user preferences
  List<MenuItem> getRecommendedItems(
    List<MenuItem> menuItems,
    List<String> userPreferences,
  ) {
    if (userPreferences.isEmpty) {
      // Return popular items if no preferences
      return sortMenuItems(menuItems, 'popularity', ascending: false).take(5).toList();
    }

    final scoredItems = menuItems.map((item) {
      int score = 0;

      // Score based on dietary preferences
      for (final preference in userPreferences) {
        if (item.dietaryRestrictions?.any((dietary) =>
                dietary.toLowerCase().contains(preference.toLowerCase())) ??
            false) {
          score += 2;
        }
      }

      // MenuItem doesn't have rating field, so we'll skip rating-based recommendations

      return MapEntry(item, score);
    }).toList();

    // Sort by score and return top recommendations
    scoredItems.sort((a, b) => b.value.compareTo(a.value));
    return scoredItems.map((e) => e.key).take(10).toList();
  }
}

