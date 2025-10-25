import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/database_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/order.dart';
import '../../../order/data/order_cache_service.dart';

/// Delivery order state
class DeliveryOrdersState {
  const DeliveryOrdersState({
    this.activeOrders = const [],
    this.historyOrders = const [],
    this.isLoadingActive = false,
    this.isLoadingHistory = false,
    this.error,
    this.lastUpdated,
  });

  final List<Order> activeOrders;
  final List<Order> historyOrders;
  final bool isLoadingActive;
  final bool isLoadingHistory;
  final String? error;
  final DateTime? lastUpdated;

  bool get hasActiveOrders => activeOrders.isNotEmpty;
  bool get hasHistoryOrders => historyOrders.isNotEmpty;
  bool get isLoading => isLoadingActive || isLoadingHistory;

  DeliveryOrdersState copyWith({
    List<Order>? activeOrders,
    List<Order>? historyOrders,
    bool? isLoadingActive,
    bool? isLoadingHistory,
    String? error,
    DateTime? lastUpdated,
  }) {
    return DeliveryOrdersState(
      activeOrders: activeOrders ?? this.activeOrders,
      historyOrders: historyOrders ?? this.historyOrders,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Delivery orders notifier
class DeliveryOrdersNotifier extends StateNotifier<DeliveryOrdersState> {
  DeliveryOrdersNotifier({
    required this.databaseService,
    required this.cacheService,
  }) : super(const DeliveryOrdersState()) {
    _initialize();
  }

  final DatabaseService databaseService;
  final OrderCacheService cacheService;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize delivery orders
  Future<void> _initialize() async {
    // Load from cache first for instant display
    await _loadFromCache();

    // Then fetch fresh data from backend
    await Future.wait([
      loadActiveOrders(),
      loadHistoryOrders(),
    ]);
  }

  /// Load orders from cache
  Future<void> _loadFromCache() async {
    try {
      AppLogger.info('Loading orders from cache...');

      final cachedActive = await cacheService.getCachedActiveOrders();
      final cachedHistory = await cacheService.getCachedOrderHistory();

      if (cachedActive.isNotEmpty || cachedHistory.isNotEmpty) {
        state = state.copyWith(
          activeOrders: cachedActive,
          historyOrders: cachedHistory,
          lastUpdated: await cacheService.getLastSyncTime(),
        );

        AppLogger.success(
          'Loaded from cache: ${cachedActive.length} active, ${cachedHistory.length} history',
        );
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load from cache', error: e, stack: stack);
    }
  }

  /// Load active orders (pending, confirmed, preparing, out_for_delivery)
  Future<void> loadActiveOrders() async {
    try {
      state = state.copyWith(isLoadingActive: true, error: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          isLoadingActive: false,
          error: 'User not authenticated',
        );
        return;
      }

      AppLogger.info('Loading active delivery orders for user: $userId');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            restaurant:restaurants(*),
            order_items:order_items(
              *,
              menu_item:menu_items(*)
            ),
            delivery_info:deliveries(
              *,
              driver:profiles(*)
            )
          ''')
          .eq('user_id', userId)
          .inFilter('status', [
            'pending',
            'confirmed',
            'preparing',
            'ready_for_pickup',
            'picked_up',
            'out_for_delivery',
          ])
          .order('created_at', ascending: false);

      final List<Order> orders = [];

      for (final item in response as List<dynamic>) {
        try {
          orders.add(Order.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          AppLogger.error('Error parsing active order', error: e);
        }
      }

      // Merge with cached orders (handles offline changes)
      final cachedOrders = await cacheService.getCachedActiveOrders();
      final mergedOrders = await cacheService.mergeOrders(
        remoteOrders: orders,
        cachedOrders: cachedOrders,
      );

      state = state.copyWith(
        activeOrders: mergedOrders,
        isLoadingActive: false,
        lastUpdated: DateTime.now(),
      );

      // Cache the merged orders
      await cacheService.cacheActiveOrders(mergedOrders);
      await cacheService.updateLastSyncTime();

      AppLogger.success('Loaded ${mergedOrders.length} active orders (${orders.length} remote)');
    } catch (e, stack) {
      AppLogger.error('Failed to load active orders', error: e, stack: stack);
      state = state.copyWith(
        isLoadingActive: false,
        error: 'Failed to load active orders: $e',
      );
    }
  }

  /// Load order history (delivered, cancelled)
  Future<void> loadHistoryOrders({int limit = 50, int offset = 0}) async {
    try {
      state = state.copyWith(isLoadingHistory: true, error: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(
          isLoadingHistory: false,
          error: 'User not authenticated',
        );
        return;
      }

      AppLogger.info('Loading order history for user: $userId (limit: $limit, offset: $offset)');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            restaurant:restaurants(*),
            order_items:order_items(
              *,
              menu_item:menu_items(*)
            ),
            delivery_info:deliveries(
              *,
              driver:profiles(*)
            )
          ''')
          .eq('user_id', userId)
          .inFilter('status', ['delivered', 'cancelled'])
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<Order> orders = [];

      for (final item in response as List<dynamic>) {
        try {
          orders.add(Order.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          AppLogger.error('Error parsing history order', error: e);
        }
      }

      // If offset is 0, replace history; otherwise append
      final updatedHistory = offset == 0
          ? orders
          : [...state.historyOrders, ...orders];

      state = state.copyWith(
        historyOrders: updatedHistory,
        isLoadingHistory: false,
        lastUpdated: DateTime.now(),
      );

      // Cache the history orders (only if offset is 0 - initial load)
      if (offset == 0) {
        await cacheService.cacheOrderHistory(updatedHistory);
        await cacheService.updateLastSyncTime();
      }

      AppLogger.success('Loaded ${orders.length} history orders');
    } catch (e, stack) {
      AppLogger.error('Failed to load order history', error: e, stack: stack);
      state = state.copyWith(
        isLoadingHistory: false,
        error: 'Failed to load order history: $e',
      );
    }
  }

  /// Refresh active orders
  Future<void> refreshActiveOrders() async {
    await loadActiveOrders();
  }

  /// Refresh history orders
  Future<void> refreshHistoryOrders() async {
    await loadHistoryOrders(limit: 50, offset: 0);
  }

  /// Refresh all orders
  Future<void> refreshAll() async {
    await Future.wait([
      loadActiveOrders(),
      loadHistoryOrders(limit: 50, offset: 0),
    ]);
  }

  /// Load more history orders (pagination)
  Future<void> loadMoreHistory() async {
    if (state.isLoadingHistory) return;
    await loadHistoryOrders(
      limit: 20,
      offset: state.historyOrders.length,
    );
  }

  /// Get order by ID
  Order? getOrderById(String orderId) {
    // Check active orders first
    try {
      return state.activeOrders.firstWhere((order) => order.id == orderId);
    } catch (_) {}

    // Check history orders
    try {
      return state.historyOrders.firstWhere((order) => order.id == orderId);
    } catch (_) {}

    return null;
  }

  /// Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('Cancelling order: $orderId');

      await _supabase
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancellation_reason': reason,
            'cancelled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('user_id', userId);

      // Update cache immediately for offline access
      final updatedActiveOrders = state.activeOrders
          .where((o) => o.id != orderId)
          .toList();
      await cacheService.cacheActiveOrders(updatedActiveOrders);

      // Refresh active orders to reflect the change
      await loadActiveOrders();

      AppLogger.success('Order cancelled successfully');
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to cancel order', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to cancel order: $e');
      return false;
    }
  }

  /// Reorder (create new order from existing order)
  Future<String?> reorder(String orderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final order = getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      AppLogger.info('Reordering from order: $orderId');

      // Create new order with same items
      final newOrderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'restaurant_id': order.restaurantId,
            'status': 'pending',
            'subtotal': order.subtotal,
            'delivery_fee': order.deliveryFee,
            'tax': order.tax,
            'total': order.total,
            'payment_method': order.paymentMethod,
            'delivery_address': order.deliveryAddress,
            'delivery_instructions': order.deliveryInstructions,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final newOrderId = newOrderResponse['id'] as String;

      // Copy order items
      final orderItems = order.items.map((item) => {
        'order_id': newOrderId,
        'menu_item_id': item.id,
        'quantity': item.quantity,
        'unit_price': item.price,
        'subtotal': item.price * item.quantity,
        'special_instructions': null,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabase.from('order_items').insert(orderItems);

      // Cache the new order immediately
      final newOrder = Order.fromJson(newOrderResponse as Map<String, dynamic>);
      await cacheService.cacheOrder(newOrder);

      // Refresh active orders
      await loadActiveOrders();

      AppLogger.success('Order reordered successfully: $newOrderId');
      return newOrderId;
    } catch (e, stack) {
      AppLogger.error('Failed to reorder', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to reorder: $e');
      return null;
    }
  }

  /// Mark order as delivered (for testing purposes)
  Future<bool> markAsDelivered(String orderId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('orders')
          .update({
            'status': 'delivered',
            'delivered_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .eq('user_id', userId);

      await refreshAll();
      return true;
    } catch (e) {
      AppLogger.error('Failed to mark order as delivered', error: e);
      return false;
    }
  }

  /// Check if cache is stale and needs refresh
  Future<bool> shouldRefresh() async {
    return await cacheService.isCacheStale(maxAge: const Duration(minutes: 5));
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    return await cacheService.getCacheStats();
  }

  /// Clear all cached orders
  Future<void> clearCache() async {
    await cacheService.clearAll();
    AppLogger.info('Cleared order cache');
  }
}

/// Provider for order cache service
final orderCacheServiceProvider = Provider<OrderCacheService>((ref) {
  return OrderCacheService();
});

/// Provider for delivery orders
final deliveryOrdersProvider = StateNotifierProvider<DeliveryOrdersNotifier, DeliveryOrdersState>(
  (ref) {
    final databaseService = ref.watch(databaseServiceProvider);
    final cacheService = ref.watch(orderCacheServiceProvider);
    return DeliveryOrdersNotifier(
      databaseService: databaseService,
      cacheService: cacheService,
    );
  },
);

/// Provider for active orders count
final activeOrdersCountProvider = Provider<int>((ref) {
  final orders = ref.watch(deliveryOrdersProvider);
  return orders.activeOrders.length;
});

/// Provider for specific order by ID
final orderByIdProvider = Provider.family<Order?, String>((ref, orderId) {
  final orders = ref.watch(deliveryOrdersProvider);
  return orders.activeOrders
      .cast<Order?>()
      .firstWhere((order) => order?.id == orderId, orElse: () => null) ??
      orders.historyOrders
          .cast<Order?>()
          .firstWhere((order) => order?.id == orderId, orElse: () => null);
});
