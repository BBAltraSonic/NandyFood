import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/order.dart';

class RealtimeOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _ordersChannel;

  final _newOrderController = StreamController<Order>.broadcast();
  final _orderStatusController = StreamController<Order>.broadcast();
  final _preparationUpdateController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Order> get newOrdersStream => _newOrderController.stream;
  Stream<Order> get orderStatusStream => _orderStatusController.stream;
  Stream<Map<String, dynamic>> get preparationUpdateStream => _preparationUpdateController.stream;

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

  /// Start preparation for an order
  Future<bool> startOrderPreparation(String orderId, {int? estimatedMinutes}) async {
    try {
      final response = await _supabase.rpc('start_order_preparation', params: {
        'order_id_param': orderId,
        'estimated_minutes': estimatedMinutes,
      });

      if (response['success'] == true) {
        AppLogger.success('Order preparation started: $orderId');
        _broadcastPreparationUpdate(orderId, 'preparation_started', {
          'estimated_minutes': estimatedMinutes,
          'message': response['message'] ?? 'Preparation started',
        });
        return true;
      } else {
        AppLogger.error('Failed to start preparation: ${response['message']}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error starting order preparation: $e');
      return false;
    }
  }

  /// Mark order as ready for pickup
  Future<bool> markOrderReadyForPickup(String orderId) async {
    try {
      final response = await _supabase.rpc('mark_order_ready_for_pickup', params: {
        'order_id_param': orderId,
      });

      if (response['success'] == true) {
        AppLogger.success('Order marked as ready: $orderId');
        _broadcastPreparationUpdate(orderId, 'ready_for_pickup', {
          'message': response['message'] ?? 'Order ready for pickup',
        });
        return true;
      } else {
        AppLogger.error('Failed to mark order ready: ${response['message']}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Error marking order ready: $e');
      return false;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final now = DateTime.now().toIso8601String();

      await _supabase
          .from('orders')
          .update({
            'status': newStatus.name,
            'updated_at': now,
          })
          .eq('id', orderId);

      AppLogger.success('Order status updated: $orderId -> ${newStatus.name}');

      _broadcastPreparationUpdate(orderId, 'status_updated', {
        'new_status': newStatus.name,
        'updated_at': now,
      });

      return true;
    } catch (e) {
      AppLogger.error('Error updating order status: $e');
      return false;
    }
  }

  /// Get preparation analytics for a restaurant
  Future<Map<String, dynamic>> getPreparationAnalytics(String restaurantId, {int days = 7}) async {
    try {
      final response = await _supabase.rpc('get_restaurant_preparation_analytics', params: {
        'restaurant_id_param': restaurantId,
        'days_param': days,
      });

      if (response is List && response.isNotEmpty) {
        final latest = response.first;
        return {
          'avg_estimated_time': latest['avg_estimated_time']?.toDouble() ?? 0.0,
          'avg_actual_time': latest['avg_actual_time']?.toDouble() ?? 0.0,
          'efficiency': latest['preparation_efficiency']?.toDouble() ?? 0.0,
          'total_orders': latest['total_orders'] ?? 0,
        };
      }

      return {
        'avg_estimated_time': 0.0,
        'avg_actual_time': 0.0,
        'efficiency': 0.0,
        'total_orders': 0,
      };
    } catch (e) {
      AppLogger.error('Error getting preparation analytics: $e');
      return {
        'avg_estimated_time': 0.0,
        'avg_actual_time': 0.0,
        'efficiency': 0.0,
        'total_orders': 0,
      };
    }
  }

  /// Get orders currently in preparation
  Future<List<Order>> getOrdersInPreparation(String restaurantId) async {
    try {
      final response = await _supabase
          .from('preparation_tracking_view')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .eq('status', 'preparing')
          .order('placed_at', ascending: false);

      return response.map((data) => Order.fromJson(data)).toList();
    } catch (e) {
      AppLogger.error('Error getting orders in preparation: $e');
      return [];
    }
  }

  /// Get orders ready for pickup
  Future<List<Order>> getOrdersReadyForPickup(String restaurantId) async {
    try {
      final response = await _supabase
          .from('preparation_tracking_view')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .eq('status', 'ready_for_pickup')
          .order('ready_at', ascending: false);

      return response.map((data) => Order.fromJson(data)).toList();
    } catch (e) {
      AppLogger.error('Error getting orders ready for pickup: $e');
      return [];
    }
  }

  void _broadcastPreparationUpdate(String orderId, String type, Map<String, dynamic> data) {
    final update = {
      'order_id': orderId,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      ...data,
    };

    _preparationUpdateController.add(update);
  }

  void dispose() {
    _newOrderController.close();
    _orderStatusController.close();
    _preparationUpdateController.close();
    unsubscribe();
  }
}
