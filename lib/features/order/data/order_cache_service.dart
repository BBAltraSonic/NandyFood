import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/order.dart';

/// Order cache service for offline persistence
class OrderCacheService {
  static const String _boxName = 'orders_cache';
  static const String _activeOrdersKey = 'active_orders';
  static const String _historyOrdersKey = 'history_orders';
  static const String _lastSyncKey = 'last_sync';
  static const int _maxHistoryOrders = 100;

  Box<dynamic>? _box;
  bool _isInitialized = false;

  /// Singleton instance
  static final OrderCacheService _instance = OrderCacheService._internal();
  factory OrderCacheService() => _instance;
  OrderCacheService._internal();

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('OrderCacheService already initialized');
      return;
    }

    try {
      AppLogger.init('Initializing OrderCacheService...');

      // Initialize Hive if not already initialized
      if (!Hive.isBoxOpen(_boxName)) {
        await Hive.initFlutter();
      }

      // Open the box
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;

      AppLogger.success('OrderCacheService initialized successfully');

      final lastSync = await getLastSyncTime();
      if (lastSync != null) {
        AppLogger.info('Last sync: ${lastSync.toIso8601String()}');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to initialize OrderCacheService', error: e, stack: stack);
      rethrow;
    }
  }

  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized || _box == null) {
      throw Exception('OrderCacheService not initialized. Call initialize() first.');
    }
  }

  // ==================== ACTIVE ORDERS ====================

  /// Cache active orders
  Future<void> cacheActiveOrders(List<Order> orders) async {
    try {
      _ensureInitialized();

      final ordersJson = orders.map((order) => order.toJson()).toList();
      await _box!.put(_activeOrdersKey, jsonEncode(ordersJson));

      AppLogger.info('Cached ${orders.length} active orders');
    } catch (e, stack) {
      AppLogger.error('Failed to cache active orders', error: e, stack: stack);
    }
  }

  /// Get cached active orders
  Future<List<Order>> getCachedActiveOrders() async {
    try {
      _ensureInitialized();

      final cachedData = _box!.get(_activeOrdersKey);
      if (cachedData == null) {
        AppLogger.debug('No cached active orders found');
        return [];
      }

      final List<dynamic> ordersJson = jsonDecode(cachedData as String);
      final orders = ordersJson
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('Retrieved ${orders.length} cached active orders');
      return orders;
    } catch (e, stack) {
      AppLogger.error('Failed to get cached active orders', error: e, stack: stack);
      return [];
    }
  }

  /// Clear cached active orders
  Future<void> clearActiveOrders() async {
    try {
      _ensureInitialized();
      await _box!.delete(_activeOrdersKey);
      AppLogger.info('Cleared cached active orders');
    } catch (e, stack) {
      AppLogger.error('Failed to clear active orders', error: e, stack: stack);
    }
  }

  // ==================== ORDER HISTORY ====================

  /// Cache order history
  Future<void> cacheOrderHistory(List<Order> orders) async {
    try {
      _ensureInitialized();

      // Limit to max history orders to prevent cache bloat
      final ordersToCache = orders.take(_maxHistoryOrders).toList();
      final ordersJson = ordersToCache.map((order) => order.toJson()).toList();
      await _box!.put(_historyOrdersKey, jsonEncode(ordersJson));

      AppLogger.info('Cached ${ordersToCache.length} history orders');
    } catch (e, stack) {
      AppLogger.error('Failed to cache order history', error: e, stack: stack);
    }
  }

  /// Get cached order history
  Future<List<Order>> getCachedOrderHistory() async {
    try {
      _ensureInitialized();

      final cachedData = _box!.get(_historyOrdersKey);
      if (cachedData == null) {
        AppLogger.debug('No cached order history found');
        return [];
      }

      final List<dynamic> ordersJson = jsonDecode(cachedData as String);
      final orders = ordersJson
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.info('Retrieved ${orders.length} cached history orders');
      return orders;
    } catch (e, stack) {
      AppLogger.error('Failed to get cached order history', error: e, stack: stack);
      return [];
    }
  }

  /// Clear cached order history
  Future<void> clearOrderHistory() async {
    try {
      _ensureInitialized();
      await _box!.delete(_historyOrdersKey);
      AppLogger.info('Cleared cached order history');
    } catch (e, stack) {
      AppLogger.error('Failed to clear order history', error: e, stack: stack);
    }
  }

  // ==================== SPECIFIC ORDERS ====================

  /// Cache a single order
  Future<void> cacheOrder(Order order) async {
    try {
      _ensureInitialized();

      final orderKey = 'order_${order.id}';
      await _box!.put(orderKey, jsonEncode(order.toJson()));

      AppLogger.debug('Cached order: ${order.id}');
    } catch (e, stack) {
      AppLogger.error('Failed to cache order', error: e, stack: stack);
    }
  }

  /// Get a specific cached order
  Future<Order?> getCachedOrder(String orderId) async {
    try {
      _ensureInitialized();

      final orderKey = 'order_$orderId';
      final cachedData = _box!.get(orderKey);

      if (cachedData == null) {
        AppLogger.debug('No cached order found for ID: $orderId');
        return null;
      }

      final orderJson = jsonDecode(cachedData as String);
      final order = Order.fromJson(orderJson as Map<String, dynamic>);

      AppLogger.debug('Retrieved cached order: $orderId');
      return order;
    } catch (e, stack) {
      AppLogger.error('Failed to get cached order', error: e, stack: stack);
      return null;
    }
  }

  /// Delete a specific cached order
  Future<void> deleteCachedOrder(String orderId) async {
    try {
      _ensureInitialized();

      final orderKey = 'order_$orderId';
      await _box!.delete(orderKey);

      AppLogger.debug('Deleted cached order: $orderId');
    } catch (e, stack) {
      AppLogger.error('Failed to delete cached order', error: e, stack: stack);
    }
  }

  // ==================== SYNC MANAGEMENT ====================

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    try {
      _ensureInitialized();

      final now = DateTime.now();
      await _box!.put(_lastSyncKey, now.toIso8601String());

      AppLogger.debug('Updated last sync time: ${now.toIso8601String()}');
    } catch (e, stack) {
      AppLogger.error('Failed to update last sync time', error: e, stack: stack);
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      _ensureInitialized();

      final lastSyncStr = _box!.get(_lastSyncKey);
      if (lastSyncStr == null) return null;

      return DateTime.parse(lastSyncStr as String);
    } catch (e, stack) {
      AppLogger.error('Failed to get last sync time', error: e, stack: stack);
      return null;
    }
  }

  /// Check if cache is stale (older than specified duration)
  Future<bool> isCacheStale({Duration maxAge = const Duration(hours: 1)}) async {
    try {
      final lastSync = await getLastSyncTime();
      if (lastSync == null) return true;

      final age = DateTime.now().difference(lastSync);
      final isStale = age > maxAge;

      if (isStale) {
        AppLogger.debug('Cache is stale (age: ${age.inMinutes} minutes)');
      }

      return isStale;
    } catch (e) {
      AppLogger.error('Failed to check cache staleness', error: e);
      return true; // Assume stale on error
    }
  }

  // ==================== MERGE STRATEGIES ====================

  /// Merge remote orders with cached orders
  /// Prioritizes remote data but preserves local optimistic updates
  Future<List<Order>> mergeOrders({
    required List<Order> remoteOrders,
    required List<Order> cachedOrders,
  }) async {
    try {
      final mergedMap = <String, Order>{};

      // Add all remote orders (they are source of truth)
      for (final order in remoteOrders) {
        mergedMap[order.id] = order;
      }

      // Add cached orders that don't exist in remote
      // This handles offline-created orders that haven't synced yet
      for (final order in cachedOrders) {
        if (!mergedMap.containsKey(order.id)) {
          mergedMap[order.id] = order;
          AppLogger.debug('Preserved offline order: ${order.id}');
        }
      }

      final merged = mergedMap.values.toList();
      AppLogger.info('Merged ${merged.length} orders (${remoteOrders.length} remote, ${cachedOrders.length} cached)');

      return merged;
    } catch (e, stack) {
      AppLogger.error('Failed to merge orders', error: e, stack: stack);
      return remoteOrders; // Fallback to remote on error
    }
  }

  // ==================== CACHE STATISTICS ====================

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      _ensureInitialized();

      final activeOrders = await getCachedActiveOrders();
      final historyOrders = await getCachedOrderHistory();
      final lastSync = await getLastSyncTime();
      final isStale = await isCacheStale();

      return {
        'active_orders_count': activeOrders.length,
        'history_orders_count': historyOrders.length,
        'last_sync': lastSync?.toIso8601String(),
        'is_stale': isStale,
        'cache_size_bytes': _box!.length,
        'is_initialized': _isInitialized,
      };
    } catch (e, stack) {
      AppLogger.error('Failed to get cache stats', error: e, stack: stack);
      return {};
    }
  }

  // ==================== MAINTENANCE ====================

  /// Clear all cached data
  Future<void> clearAll() async {
    try {
      _ensureInitialized();

      await _box!.clear();
      AppLogger.warning('Cleared all cached order data');
    } catch (e, stack) {
      AppLogger.error('Failed to clear all cache', error: e, stack: stack);
    }
  }

  /// Compact the cache (remove old entries)
  Future<void> compactCache() async {
    try {
      _ensureInitialized();

      await _box!.compact();
      AppLogger.info('Compacted order cache');
    } catch (e, stack) {
      AppLogger.error('Failed to compact cache', error: e, stack: stack);
    }
  }

  /// Close the cache service
  Future<void> close() async {
    try {
      if (_box != null && _box!.isOpen) {
        await _box!.close();
        _isInitialized = false;
        AppLogger.info('OrderCacheService closed');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to close OrderCacheService', error: e, stack: stack);
    }
  }

  // ==================== DEBUG ====================

  /// Print cache contents (debug only)
  Future<void> debugPrintCache() async {
    if (!kDebugMode) return;

    try {
      _ensureInitialized();

      final stats = await getCacheStats();
      AppLogger.debug('=== Order Cache Debug ===');
      AppLogger.debug('Stats: $stats');

      final activeOrders = await getCachedActiveOrders();
      AppLogger.debug('Active Orders:');
      for (final order in activeOrders) {
        AppLogger.debug('  - ${order.id}: ${order.status}');
      }

      final historyOrders = await getCachedOrderHistory();
      AppLogger.debug('History Orders (first 10):');
      for (final order in historyOrders.take(10)) {
        AppLogger.debug('  - ${order.id}: ${order.status}');
      }

      AppLogger.debug('========================');
    } catch (e) {
      AppLogger.error('Failed to debug print cache', error: e);
    }
  }
}
