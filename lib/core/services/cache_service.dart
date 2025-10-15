import 'package:hive_flutter/hive_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Service for caching data locally for offline access
/// 
/// Uses Hive for fast, lightweight local storage with automatic
/// cache invalidation based on TTL (Time To Live).
class CacheService {
  static const String _restaurantsBox = 'restaurants';
  static const String _menuItemsBox = 'menuItems';
  static const String _ordersBox = 'orders';
  static const String _userProfileBox = 'userProfile';
  static const String _metadataBox = 'metadata';
  
  // Cache TTL (Time To Live) in hours
  static const int restaurantsCacheTTL = 24; // 24 hours
  static const int menuItemsCacheTTL = 12; // 12 hours
  static const int ordersCacheTTL = 1; // 1 hour
  static const int userProfileCacheTTL = 24; // 24 hours

  static CacheService? _instance;
  static CacheService get instance {
    _instance ??= CacheService._();
    return _instance!;
  }

  CacheService._();

  /// Initialize Hive and open all boxes
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      
      // Open all boxes
      await Hive.openBox(_restaurantsBox);
      await Hive.openBox(_menuItemsBox);
      await Hive.openBox(_ordersBox);
      await Hive.openBox(_userProfileBox);
      await Hive.openBox(_metadataBox);
      
      AppLogger.info('CacheService: Initialized successfully');
    } catch (e) {
      AppLogger.error('CacheService: Failed to initialize - $e');
    }
  }

  /// Check if cached data is still valid based on TTL
  bool _isCacheValid(String key, int ttlHours) {
    try {
      final metadataBox = Hive.box<dynamic>(_metadataBox);
      final timestamp = metadataBox.get('${key}_timestamp') as int?;
      
      if (timestamp == null) return false;
      
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final maxAge = Duration(hours: ttlHours).inMilliseconds;
      
      return cacheAge < maxAge;
    } catch (e) {
      AppLogger.error('CacheService: Error checking cache validity', error: e);
      return false;
    }
  }

  /// Update cache timestamp
  void _updateTimestamp(String key) {
    try {
      final metadataBox = Hive.box<dynamic>(_metadataBox);
      metadataBox.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      AppLogger.error('CacheService: Error updating timestamp', error: e);
    }
  }

  // ========== RESTAURANTS ==========

  /// Cache restaurants list
  Future<void> cacheRestaurants(List<Map<String, dynamic>> restaurants) async {
    try {
      final box = Hive.box<dynamic>(_restaurantsBox);
      await box.put('all', restaurants);
      _updateTimestamp('restaurants');
      AppLogger.info('CacheService: Cached ${restaurants.length} restaurants');
    } catch (e) {
      AppLogger.error('CacheService: Failed to cache restaurants - $e');
    }
  }

  /// Get cached restaurants
  List<Map<String, dynamic>>? getCachedRestaurants() {
    try {
      if (!_isCacheValid('restaurants', restaurantsCacheTTL)) {
        AppLogger.info('CacheService: Restaurant cache expired');
        return null;
      }
      
      final box = Hive.box<dynamic>(_restaurantsBox);
      final cached = box.get('all');
      
      if (cached == null) return null;
      
      final restaurants = (cached as List).cast<Map<String, dynamic>>();
      AppLogger.info('CacheService: Retrieved ${restaurants.length} cached restaurants');
      return restaurants;
    } catch (e) {
      AppLogger.error('CacheService: Failed to get cached restaurants - $e');
      return null;
    }
  }

  /// Cache single restaurant details
  Future<void> cacheRestaurant(String restaurantId, Map<String, dynamic> restaurant) async {
    try {
      final box = Hive.box<dynamic>(_restaurantsBox);
      await box.put(restaurantId, restaurant);
      _updateTimestamp('restaurant_$restaurantId');
      AppLogger.info('CacheService: Cached restaurant $restaurantId');
    } catch (e) {
      AppLogger.error('CacheService: Failed to cache restaurant - $e');
    }
  }

  /// Get cached restaurant by ID
  Map<String, dynamic>? getCachedRestaurant(String restaurantId) {
    try {
      if (!_isCacheValid('restaurant_$restaurantId', restaurantsCacheTTL)) {
        return null;
      }
      
      final box = Hive.box<dynamic>(_restaurantsBox);
      final cached = box.get(restaurantId);
      
      if (cached != null) {
        AppLogger.info('CacheService: Retrieved cached restaurant $restaurantId');
      }
      
      return cached as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.error('CacheService: Failed to get cached restaurant', error: e);
      return null;
    }
  }

  // ========== MENU ITEMS ==========

  /// Cache menu items for a restaurant
  Future<void> cacheMenuItems(String restaurantId, List<Map<String, dynamic>> menuItems) async {
    try {
      final box = Hive.box<dynamic>(_menuItemsBox);
      await box.put(restaurantId, menuItems);
      _updateTimestamp('menu_$restaurantId');
      AppLogger.info('CacheService: Cached ${menuItems.length} menu items for restaurant $restaurantId');
    } catch (e) {
      AppLogger.error('CacheService: Failed to cache menu items - $e');
    }
  }

  /// Get cached menu items for a restaurant
  List<Map<String, dynamic>>? getCachedMenuItems(String restaurantId) {
    try {
      if (!_isCacheValid('menu_$restaurantId', menuItemsCacheTTL)) {
        AppLogger.info('CacheService: Menu items cache expired for restaurant $restaurantId');
        return null;
      }
      
      final box = Hive.box<dynamic>(_menuItemsBox);
      final cached = box.get(restaurantId);
      
      if (cached == null) return null;
      
      final menuItems = (cached as List).cast<Map<String, dynamic>>();
      AppLogger.info('CacheService: Retrieved ${menuItems.length} cached menu items');
      return menuItems;
    } catch (e) {
      AppLogger.error('CacheService: Failed to get cached menu items - $e');
      return null;
    }
  }

  // ========== ORDERS ==========

  /// Cache user orders
  Future<void> cacheOrders(String userId, List<Map<String, dynamic>> orders) async {
    try {
      final box = Hive.box<dynamic>(_ordersBox);
      await box.put(userId, orders);
      _updateTimestamp('orders_$userId');
      AppLogger.info('CacheService: Cached ${orders.length} orders for user $userId');
    } catch (e) {
      AppLogger.error('CacheService: Failed to cache orders - $e');
    }
  }

  /// Get cached orders for a user
  List<Map<String, dynamic>>? getCachedOrders(String userId) {
    try {
      if (!_isCacheValid('orders_$userId', ordersCacheTTL)) {
        AppLogger.info('CacheService: Orders cache expired for user $userId');
        return null;
      }
      
      final box = Hive.box<dynamic>(_ordersBox);
      final cached = box.get(userId);
      
      if (cached == null) return null;
      
      final orders = (cached as List).cast<Map<String, dynamic>>();
      AppLogger.info('CacheService: Retrieved ${orders.length} cached orders');
      return orders;
    } catch (e) {
      AppLogger.error('CacheService: Failed to get cached orders - $e');
      return null;
    }
  }

  // ========== USER PROFILE ==========

  /// Cache user profile
  Future<void> cacheUserProfile(String userId, Map<String, dynamic> profile) async {
    try {
      final box = Hive.box<dynamic>(_userProfileBox);
      await box.put(userId, profile);
      _updateTimestamp('profile_$userId');
      AppLogger.info('CacheService: Cached profile for user $userId');
    } catch (e) {
      AppLogger.error('CacheService: Failed to cache user profile - $e');
    }
  }

  /// Get cached user profile
  Map<String, dynamic>? getCachedUserProfile(String userId) {
    try {
      if (!_isCacheValid('profile_$userId', userProfileCacheTTL)) {
        return null;
      }
      
      final box = Hive.box<dynamic>(_userProfileBox);
      final cached = box.get(userId);
      
      if (cached != null) {
        AppLogger.info('CacheService: Retrieved cached profile for user $userId');
      }
      
      return cached as Map<String, dynamic>?;
    } catch (e) {
      AppLogger.error('CacheService: Failed to get cached user profile', error: e);
      return null;
    }
  }

  // ========== CACHE MANAGEMENT ==========

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      await Hive.box<dynamic>(_restaurantsBox).clear();
      await Hive.box<dynamic>(_menuItemsBox).clear();
      await Hive.box<dynamic>(_ordersBox).clear();
      await Hive.box<dynamic>(_userProfileBox).clear();
      await Hive.box<dynamic>(_metadataBox).clear();
      
      AppLogger.info('CacheService: Cleared all cache');
    } catch (e) {
      AppLogger.error('CacheService: Failed to clear cache - $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final metadataBox = Hive.box<dynamic>(_metadataBox);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final keysToDelete = <String>[];
      
      for (final key in metadataBox.keys) {
        final timestamp = metadataBox.get(key) as int?;
        if (timestamp == null) continue;
        
        // Extract TTL based on key prefix
        int ttl = 24; // Default
        if (key.startsWith('orders_')) {
          ttl = ordersCacheTTL;
        } else if (key.startsWith('menu_')) {
          ttl = menuItemsCacheTTL;
        }
        
        final cacheAge = now - timestamp;
        final maxAge = Duration(hours: ttl).inMilliseconds;
        
        if (cacheAge >= maxAge) {
          keysToDelete.add(key);
        }
      }
      
      for (final key in keysToDelete) {
        await metadataBox.delete(key);
      }
      
      AppLogger.info('CacheService: Cleared ${keysToDelete.length} expired cache entries');
    } catch (e) {
      AppLogger.error('CacheService: Failed to clear expired cache - $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    try {
      return {
        'restaurants': Hive.box<dynamic>(_restaurantsBox).length,
        'menuItems': Hive.box<dynamic>(_menuItemsBox).length,
        'orders': Hive.box<dynamic>(_ordersBox).length,
        'userProfiles': Hive.box<dynamic>(_userProfileBox).length,
        'totalSize': _getTotalCacheSize(),
      };
    } catch (e) {
      AppLogger.error('CacheService: Failed to get cache stats', error: e);
      return {};
    }
  }

  int _getTotalCacheSize() {
    try {
      int total = 0;
      total += Hive.box<dynamic>(_restaurantsBox).length;
      total += Hive.box<dynamic>(_menuItemsBox).length;
      total += Hive.box<dynamic>(_ordersBox).length;
      total += Hive.box<dynamic>(_userProfileBox).length;
      return total;
    } catch (e) {
      return 0;
    }
  }

  /// Close all boxes (call on app termination)
  Future<void> close() async {
    try {
      await Hive.close();
      AppLogger.info('CacheService: Closed all boxes');
    } catch (e) {
      AppLogger.error('CacheService: Failed to close boxes - $e');
    }
  }
}
