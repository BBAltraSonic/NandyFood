import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/order.dart';

class RealtimeOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _ordersChannel;
  
  final _newOrderController = StreamController<Order>.broadcast();
  final _orderStatusController = StreamController<Order>.broadcast();
  
  Stream<Order> get newOrdersStream => _newOrderController.stream;
  Stream<Order> get orderStatusStream => _orderStatusController.stream;
  
  bool _isSubscribed = false;

  /// Subscribe to real-time order updates for a specific restaurant
  Future<void> subscribeToRestaurantOrders(String restaurantId) async {
    if (_isSubscribed) {
      AppLogger.warning('Already subscribed to restaurant orders');
      return;
    }

    try {
      AppLogger.info('Subscribing to real-time orders for restaurant: $restaurantId');

      // Remove old channel if exists
      if (_ordersChannel != null) {
        await _supabase.removeChannel(_ordersChannel!);
      }

      // Create new channel for this restaurant's orders
      _ordersChannel = _supabase.channel('restaurant_orders_$restaurantId');

      // Subscribe to INSERT events (new orders)
      _ordersChannel!
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
              AppLogger.success('NEW ORDER RECEIVED via Realtime!');
              _handleNewOrder(payload.newRecord);
            },
          )
          // Subscribe to UPDATE events (status changes)
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
              AppLogger.info('Order status updated via Realtime');
              _handleOrderStatusChange(payload.newRecord);
            },
          )
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              AppLogger.success('✅ Subscribed to restaurant orders successfully!');
              _isSubscribed = true;
            } else if (status == RealtimeSubscribeStatus.timedOut) {
              AppLogger.error('⏱️ Subscription timed out');
              _isSubscribed = false;
            } else if (status == RealtimeSubscribeStatus.closed) {
              AppLogger.warning('Subscription closed');
              _isSubscribed = false;
            }

            if (error != null) {
              AppLogger.error('Realtime subscription error: $error');
            }
          });

      AppLogger.info('Realtime channel configured successfully');
    } catch (e) {
      AppLogger.error('Failed to subscribe to orders: $e');
      _isSubscribed = false;
    }
  }

  /// Unsubscribe from real-time updates
  Future<void> unsubscribe() async {
    if (_ordersChannel != null) {
      try {
        await _supabase.removeChannel(_ordersChannel!);
        AppLogger.info('Unsubscribed from restaurant orders');
      } catch (e) {
        AppLogger.error('Error unsubscribing: $e');
      }
      _ordersChannel = null;
    }
    _isSubscribed = false;
  }

  void _handleNewOrder(Map<String, dynamic> orderData) {
    try {
      AppLogger.section('🔔 NEW ORDER NOTIFICATION');
      AppLogger.info('Order ID: ${orderData['id']}');
      AppLogger.info('Total: R ${orderData['total_amount']}');
      AppLogger.info('Status: ${orderData['status']}');

      // Fetch complete order details including items
      _fetchCompleteOrder(orderData['id']).then((order) {
        if (order != null) {
          _newOrderController.add(order);
        }
      });
    } catch (e) {
      AppLogger.error('Error handling new order: $e');
    }
  }

  void _handleOrderStatusChange(Map<String, dynamic> orderData) {
    try {
      AppLogger.info('Order ${orderData['id']} status changed to: ${orderData['status']}');

      _fetchCompleteOrder(orderData['id']).then((order) {
        if (order != null) {
          _orderStatusController.add(order);
        }
      });
    } catch (e) {
      AppLogger.error('Error handling order status change: $e');
    }
  }

  /// Fetch complete order details with items and customer info
  Future<Order?> _fetchCompleteOrder(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (*),
            user_profiles:user_id (full_name, phone_number)
          ''')
          .eq('id', orderId)
          .single();

      return Order.fromJson(response);
    } catch (e) {
      AppLogger.error('Error fetching complete order: $e');
      return null;
    }
  }

  /// Get pending/active orders count for a restaurant
  Future<int> getPendingOrdersCount(String restaurantId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('id')
          .eq('restaurant_id', restaurantId)
          .inFilter('status', ['placed', 'confirmed', 'preparing'])
          .count();

      return response.count;
    } catch (e) {
      AppLogger.error('Error getting pending orders count: $e');
      return 0;
    }
  }

  void dispose() {
    _newOrderController.close();
    _orderStatusController.close();
    unsubscribe();
  }
}
