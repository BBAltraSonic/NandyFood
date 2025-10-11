import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

/// Database optimization utilities for better performance
class DatabaseOptimizer {
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const Duration defaultCacheExpiry = Duration(minutes: 5);

  /// Cache for database queries
  static final Map<String, _CachedQuery> _queryCache = {};

  /// Paginated query helper
  static Future<List<Map<String, dynamic>>> paginatedQuery({
    required Future<List<Map<String, dynamic>>> Function(int offset, int limit)
    queryFunction,
    int pageSize = defaultPageSize,
    int maxPages = 5,
  }) async {
    final results = <Map<String, dynamic>>[];
    int currentPage = 0;

    while (currentPage < maxPages) {
      final pageResults = await queryFunction(currentPage * pageSize, pageSize);

      if (pageResults.isEmpty) break;

      results.addAll(pageResults);
      currentPage++;

      // If we got fewer results than the page size, we've reached the end
      if (pageResults.length < pageSize) break;
    }

    return results;
  }

  /// Cached query helper
  static Future<List<Map<String, dynamic>>> cachedQuery({
    required String cacheKey,
    required Future<List<Map<String, dynamic>>> Function() queryFunction,
    Duration cacheExpiry = defaultCacheExpiry,
  }) async {
    // Check if we have a cached result that hasn't expired
    final cachedResult = _queryCache[cacheKey];
    if (cachedResult != null &&
        DateTime.now().isBefore(cachedResult.expiryTime)) {
      return cachedResult.data;
    }

    // Execute the query and cache the result
    final result = await queryFunction();
    _queryCache[cacheKey] = _CachedQuery(
      data: result,
      expiryTime: DateTime.now().add(cacheExpiry),
    );

    return result;
  }

  /// Clear query cache
  static void clearCache() {
    _queryCache.clear();
  }

  /// Clear specific cache entry
  static void clearCacheEntry(String cacheKey) {
    _queryCache.remove(cacheKey);
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _queryCache.length,
      'cacheKeys': _queryCache.keys.toList(),
    };
  }

  /// Batch database operations for better performance
  static Future<List<T>> batchOperations<T>({
    required List<Future<T> Function()> operations,
    int batchSize = 10,
  }) async {
    final results = <T>[];

    // Process operations in batches
    for (int i = 0; i < operations.length; i += batchSize) {
      final endIndex = (i + batchSize).clamp(0, operations.length);
      final batch = operations.sublist(i, endIndex);

      // Execute batch operations concurrently
      final batchResults = await Future.wait(batch.map((op) => op()));
      results.addAll(batchResults);
    }

    return results;
  }

  /// Optimized restaurant query with filtering and sorting
  static Future<List<Map<String, dynamic>>> optimizedRestaurantQuery({
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
  }) async {
    // Create cache key for this query
    final cacheKey = 'restaurants_${cuisineType}_${minRating}_$maxDeliveryTime';

    return cachedQuery(
      cacheKey: cacheKey,
      queryFunction: () async {
        final dbService = DatabaseService();
        return await dbService.getRestaurants(
          cuisineType: cuisineType,
          minRating: minRating,
          maxDeliveryTime: maxDeliveryTime,
        );
      },
    );
  }

  /// Optimized menu items query with filtering
  static Future<List<Map<String, dynamic>>> optimizedMenuItemsQuery({
    required String restaurantId,
  }) async {
    // Create cache key for this query
    final cacheKey = 'menu_items_$restaurantId';

    return cachedQuery(
      cacheKey: cacheKey,
      queryFunction: () async {
        final dbService = DatabaseService();
        return await dbService.getMenuItems(restaurantId);
      },
    );
  }

  /// Optimized order history query
  static Future<List<Map<String, dynamic>>> optimizedOrderHistoryQuery({
    required String userId,
  }) async {
    // Create cache key for this query
    final cacheKey = 'order_history_$userId';

    return cachedQuery(
      cacheKey: cacheKey,
      queryFunction: () async {
        final dbService = DatabaseService();
        return await dbService.getUserOrders(userId);
      },
    );
  }

  /// Prefetch commonly used data
  static Future<void> prefetchUserData(String userId) async {
    // Prefetch user profile
    try {
      final dbService = DatabaseService();
      final profile = await dbService.getUserProfile(userId);
      if (profile != null) {
        _queryCache['user_profile_$userId'] = _CachedQuery(
          data: [profile],
          expiryTime: DateTime.now().add(defaultCacheExpiry),
        );
      }
    } catch (e) {
      debugPrint('Failed to prefetch user profile: $e');
    }

    // Additional prefetch operations can be added here as needed
  }

  /// Warm up database connections
  static Future<void> warmUp() async {
    try {
      final dbService = DatabaseService();
      await dbService.initialize();

      // Perform a lightweight query to establish connection
      await dbService.getRestaurants();
    } catch (e) {
      debugPrint('Database warm-up failed: $e');
    }
  }
}

/// Cached query result
class _CachedQuery {
  final List<Map<String, dynamic>> data;
  final DateTime expiryTime;

  _CachedQuery({required this.data, required this.expiryTime});
}
