import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant_analytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing restaurant operations, menus, and orders
class RestaurantManagementService {
  final SupabaseClient _supabase = DatabaseService().client;

  // ==========================================
  // Restaurant Operations
  // ==========================================

  /// Get restaurant details
  Future<Restaurant> getRestaurant(String restaurantId) async {
    try {
      AppLogger.function('RestaurantManagementService.getRestaurant', 'ENTER',
          params: {'restaurantId': restaurantId});

      final response = await _supabase
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();

      final restaurant = Restaurant.fromJson(response as Map<String, dynamic>);
      AppLogger.function('RestaurantManagementService.getRestaurant', 'EXIT');
      return restaurant;
    } catch (e, stack) {
      AppLogger.error('Failed to get restaurant', error: e, stack: stack);
      rethrow;
    }
  }

  /// Update restaurant information
  Future<void> updateRestaurant(
    String restaurantId,
    Map<String, dynamic> updates,
  ) async {
    try {
      AppLogger.function('RestaurantManagementService.updateRestaurant',
          'ENTER',
          params: {'restaurantId': restaurantId});

      await _supabase
          .from('restaurants')
          .update(updates)
          .eq('id', restaurantId);

      AppLogger.success('Restaurant updated successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to update restaurant', error: e, stack: stack);
      rethrow;
    }
  }

  /// Update restaurant operating hours
  Future<void> updateOperatingHours(
    String restaurantId,
    Map<String, dynamic> hours,
  ) async {
    try {
      await _supabase.from('restaurants').update({
        'opening_hours': hours,
      }).eq('id', restaurantId);

      AppLogger.success('Operating hours updated');
    } catch (e, stack) {
      AppLogger.error('Failed to update operating hours',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Toggle accepting orders status
  Future<void> toggleAcceptingOrders(
    String restaurantId,
    bool isAccepting,
  ) async {
    try {
      await _supabase.from('restaurants').update({
        'is_accepting_orders': isAccepting,
      }).eq('id', restaurantId);

      AppLogger.success('Accepting orders status updated: $isAccepting');
    } catch (e, stack) {
      AppLogger.error('Failed to toggle accepting orders',
          error: e, stack: stack);
      rethrow;
    }
  }

  // ==========================================
  // Menu Management
  // ==========================================

  /// Get all menu items for a restaurant
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    try {
      AppLogger.function('RestaurantManagementService.getMenuItems', 'ENTER',
          params: {'restaurantId': restaurantId});

      final response = await _supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('category')
          .order('name');

      final items = (response as List)
          .map((json) => MenuItem.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.function('RestaurantManagementService.getMenuItems', 'EXIT',
          result: '${items.length} items');
      return items;
    } catch (e, stack) {
      AppLogger.error('Failed to get menu items', error: e, stack: stack);
      rethrow;
    }
  }

  /// Create a new menu item
  Future<MenuItem> createMenuItem(MenuItem item) async {
    try {
      AppLogger.function('RestaurantManagementService.createMenuItem', 'ENTER',
          params: {'name': item.name});

      final response = await _supabase
          .from('menu_items')
          .insert(item.toJson())
          .select()
          .single();

      final createdItem = MenuItem.fromJson(response as Map<String, dynamic>);
      AppLogger.success('Menu item created: ${createdItem.name}');
      return createdItem;
    } catch (e, stack) {
      AppLogger.error('Failed to create menu item', error: e, stack: stack);
      rethrow;
    }
  }

  /// Update a menu item
  Future<void> updateMenuItem(
    String itemId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase.from('menu_items').update(updates).eq('id', itemId);

      AppLogger.success('Menu item updated');
    } catch (e, stack) {
      AppLogger.error('Failed to update menu item', error: e, stack: stack);
      rethrow;
    }
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _supabase.from('menu_items').delete().eq('id', itemId);

      AppLogger.success('Menu item deleted');
    } catch (e, stack) {
      AppLogger.error('Failed to delete menu item', error: e, stack: stack);
      rethrow;
    }
  }

  /// Toggle menu item availability
  Future<void> toggleMenuItemAvailability(
    String itemId,
    bool isAvailable,
  ) async {
    try {
      await _supabase.from('menu_items').update({
        'is_available': isAvailable,
      }).eq('id', itemId);

      AppLogger.success('Menu item availability updated: $isAvailable');
    } catch (e, stack) {
      AppLogger.error('Failed to toggle menu item availability',
          error: e, stack: stack);
      rethrow;
    }
  }

  // ==========================================
  // Order Management
  // ==========================================

  /// Get orders for a restaurant
  Future<List<Order>> getRestaurantOrders(
    String restaurantId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.function('RestaurantManagementService.getRestaurantOrders',
          'ENTER',
          params: {
            'restaurantId': restaurantId,
            'status': status,
          });

      var query = _supabase
          .from('orders')
          .select()
          .eq('restaurant_id', restaurantId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      final orders = (response as List)
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.function('RestaurantManagementService.getRestaurantOrders',
          'EXIT',
          result: '${orders.length} orders');
      return orders;
    } catch (e, stack) {
      AppLogger.error('Failed to get restaurant orders',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _supabase.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      AppLogger.success('Order status updated: $newStatus');
    } catch (e, stack) {
      AppLogger.error('Failed to update order status', error: e, stack: stack);
      rethrow;
    }
  }

  /// Accept an order with estimated prep time
  Future<void> acceptOrder(String orderId, int estimatedPrepTimeMinutes) async {
    try {
      final estimatedTime =
          DateTime.now().add(Duration(minutes: estimatedPrepTimeMinutes));

      await _supabase.from('orders').update({
        'status': 'accepted',
        'estimated_delivery_time': estimatedTime.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      AppLogger.success('Order accepted with prep time: $estimatedPrepTimeMinutes min');
    } catch (e, stack) {
      AppLogger.error('Failed to accept order', error: e, stack: stack);
      rethrow;
    }
  }

  /// Reject an order with reason
  Future<void> rejectOrder(String orderId, String reason) async {
    try {
      await _supabase.from('orders').update({
        'status': 'rejected',
        'rejection_reason': reason,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      AppLogger.success('Order rejected');
    } catch (e, stack) {
      AppLogger.error('Failed to reject order', error: e, stack: stack);
      rethrow;
    }
  }

  // ==========================================
  // Analytics
  // ==========================================

  /// Get analytics for a date range
  Future<List<RestaurantAnalytics>> getAnalytics(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      AppLogger.function('RestaurantManagementService.getAnalytics', 'ENTER',
          params: {
            'restaurantId': restaurantId,
            'startDate': startDate.toString(),
            'endDate': endDate.toString(),
          });

      final response = await _supabase
          .from('restaurant_analytics')
          .select()
          .eq('restaurant_id', restaurantId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      final analytics = (response as List)
          .map((json) =>
              RestaurantAnalytics.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.function('RestaurantManagementService.getAnalytics', 'EXIT',
          result: '${analytics.length} records');
      return analytics;
    } catch (e, stack) {
      AppLogger.error('Failed to get analytics', error: e, stack: stack);
      rethrow;
    }
  }

  /// Get dashboard metrics using database function
  Future<DashboardMetrics> getDashboardMetrics(String restaurantId) async {
    try {
      AppLogger.function('RestaurantManagementService.getDashboardMetrics',
          'ENTER',
          params: {'restaurantId': restaurantId});

      final response = await _supabase
          .rpc('get_restaurant_dashboard_metrics', params: {
        'p_restaurant_id': restaurantId,
      });

      final metrics = DashboardMetrics.fromJson(response as Map<String, dynamic>);
      AppLogger.function('RestaurantManagementService.getDashboardMetrics',
          'EXIT');
      return metrics;
    } catch (e, stack) {
      AppLogger.error('Failed to get dashboard metrics',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Calculate analytics for a specific date
  Future<void> calculateDailyAnalytics(
    String restaurantId, [
    DateTime? date,
  ]) async {
    try {
      await _supabase.rpc('calculate_daily_restaurant_analytics', params: {
        'p_restaurant_id': restaurantId,
        'p_date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
      });

      AppLogger.success('Analytics calculated successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to calculate analytics', error: e, stack: stack);
      rethrow;
    }
  }

  // ==========================================
  // Realtime Subscriptions
  // ==========================================

  /// Subscribe to new orders
  RealtimeChannel subscribeToNewOrders(
    String restaurantId,
    void Function(Order order) onNewOrder,
  ) {
    AppLogger.info('Subscribing to new orders for restaurant: $restaurantId');

    return _supabase
        .channel('restaurant_orders_$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) {
            try {
              final order = Order.fromJson(payload.newRecord);
              AppLogger.info('New order received: ${order.id}');
              onNewOrder(order);
            } catch (e) {
              AppLogger.error('Failed to parse new order', error: e);
            }
          },
        )
        .subscribe();
  }

  /// Subscribe to order status changes
  RealtimeChannel subscribeToOrderUpdates(
    String restaurantId,
    void Function(Order order) onOrderUpdate,
  ) {
    AppLogger.info('Subscribing to order updates for restaurant: $restaurantId');

    return _supabase
        .channel('restaurant_order_updates_$restaurantId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) {
            try {
              final order = Order.fromJson(payload.newRecord);
              AppLogger.info('Order updated: ${order.id} - ${order.status}');
              onOrderUpdate(order);
            } catch (e) {
              AppLogger.error('Failed to parse updated order', error: e);
            }
          },
        )
        .subscribe();
  }
}
