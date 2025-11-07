import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/database_service.dart';
import '../../shared/models/order.dart';
import '../../shared/models/order_item.dart';

class OrderService {
  final DatabaseService _dbService;
  final SupabaseClient _client;

  OrderService(this._dbService) : _client = _dbService.client;

  /// Get orders for a user with optional status filter
  Future<List<Order>> getUserOrders(
    String userId, {
    OrderStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }

      final response = await query
          .order('placed_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => _parseOrderWithItems(json)).toList();
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }

  /// Get orders for a restaurant (for restaurant owners)
  Future<List<Order>> getRestaurantOrders(
    String restaurantId, {
    OrderStatus? status,
    String? dateFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('restaurant_id', restaurantId);

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }

      if (dateFilter != null) {
        // Filter by date (today, week, month)
        final now = DateTime.now();
        DateTime startDate;

        switch (dateFilter) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            break;
          case 'week':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case 'month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            break;
          default:
            startDate = DateTime(now.year - 1, now.month, now.day);
        }

        query = query.gte('placed_at', startDate.toIso8601String());
      }

      final response = await query
          .order('placed_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => _parseOrderWithItems(json)).toList();
    } catch (e) {
      print('Error getting restaurant orders: $e');
      return [];
    }
  }

  /// Get a single order by ID with its items
  Future<Order?> getOrder(String orderId) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      return _parseOrderWithItems(response);
    } catch (e) {
      print('Error getting order: $e');
      return null;
    }
  }

  /// Create a new order with order items
  Future<String> createOrder({
    required String userId,
    required String restaurantId,
    required List<Map<String, dynamic>> orderItemsData,
    required double totalAmount,
    required double taxAmount,
    String? promoCode,
    String paymentMethod = 'payfast',
    Map<String, dynamic>? pickupAddress,
    String? notes,
    String? pickupInstructions,
    int estimatedPreparationTime = 15,
  }) async {
    try {
      // Start a transaction by creating the order first
      final orderData = {
        'user_id': userId,
        'restaurant_id': restaurantId,
        'total_amount': totalAmount,
        'tax_amount': taxAmount,
        'status': 'placed',
        'payment_status': 'pending',
        'payment_method': paymentMethod,
        'pickup_address': pickupAddress ?? {},
        'notes': notes,
        'pickup_instructions': pickupInstructions,
        'estimated_preparation_time': estimatedPreparationTime,
        'placed_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (promoCode != null) {
        orderData['promo_code'] = promoCode;
      }

      final orderResponse = await _client
          .from('orders')
          .insert(orderData)
          .select('id')
          .single();

      final orderId = orderResponse['id'];

      // Create order items
      final itemsWithOrderId = orderItemsData.map((item) => {
        ...item,
        'order_id': orderId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).toList();

      await _client.from('order_items').insert(itemsWithOrderId);

      return orderId;
    } catch (e) {
      print('Error creating order: $e');
      rethrow;
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final updateData = {
        'status': newStatus.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add status-specific timestamps
      switch (newStatus) {
        case OrderStatus.confirmed:
          updateData['confirmed_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.preparing:
          updateData['preparing_at'] = DateTime.now().toIso8601String();
          updateData['preparation_started_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.ready_for_pickup:
          updateData['ready_at'] = DateTime.now().toIso8601String();
          updateData['preparation_completed_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.cancelled:
          updateData['cancelled_at'] = DateTime.now().toIso8601String();
          break;
        case OrderStatus.placed:
          break; // No specific timestamp for placed status
      }

      final response = await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      return response.error == null;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  /// Update payment status
  Future<bool> updatePaymentStatus(
    String orderId,
    PaymentStatus paymentStatus, {
    String? paymentReference,
    String? transactionId,
  }) async {
    try {
      final updateData = {
        'payment_status': paymentStatus.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (paymentReference != null) {
        updateData['payment_reference'] = paymentReference;
      }

      if (transactionId != null) {
        updateData['payfast_transaction_id'] = transactionId;
      }

      final response = await _client
          .from('orders')
          .update(updateData)
          .eq('id', orderId);

      return response.error == null;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  /// Cancel an order
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    try {
      final response = await _client
          .from('orders')
          .update({
            'status': 'cancelled',
            'cancelled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            if (reason != null) 'notes': reason,
          })
          .eq('id', orderId);

      return response.error == null;
    } catch (e) {
      print('Error cancelling order: $e');
      return false;
    }
  }

  /// Get order statistics for a restaurant
  Future<Map<String, dynamic>> getOrderStatistics(
    String restaurantId, {
    String? dateFilter,
  }) async {
    try {
      var query = _client
          .from('orders')
          .select('status, total_amount, placed_at')
          .eq('restaurant_id', restaurantId);

      if (dateFilter != null) {
        final now = DateTime.now();
        DateTime startDate;

        switch (dateFilter) {
          case 'today':
            startDate = DateTime(now.year, now.month, now.day);
            break;
          case 'week':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case 'month':
            startDate = DateTime(now.year, now.month - 1, now.day);
            break;
          default:
            startDate = DateTime(now.year - 1, now.month, now.day);
        }

        query = query.gte('placed_at', startDate.toIso8601String());
      }

      final response = await query;

      int totalOrders = response.length;
      double totalRevenue = 0.0;
      final Map<String, int> statusCounts = {};

      for (final order in response) {
        final status = order['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        final amount = order['total_amount'] as num?;
        if (amount != null) {
          totalRevenue += amount.toDouble();
        }
      }

      final double averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue.toStringAsFixed(2),
        'average_order_value': averageOrderValue.toStringAsFixed(2),
        'status_breakdown': statusCounts,
        'completed_orders': statusCounts['ready_for_pickup'] ?? 0,
        'pending_orders': (statusCounts['placed'] ?? 0) + (statusCounts['confirmed'] ?? 0) + (statusCounts['preparing'] ?? 0),
        'cancelled_orders': statusCounts['cancelled'] ?? 0,
      };
    } catch (e) {
      print('Error getting order statistics: $e');
      return {
        'total_orders': 0,
        'total_revenue': '0.00',
        'average_order_value': '0.00',
        'status_breakdown': <String, int>{},
        'completed_orders': 0,
        'pending_orders': 0,
        'cancelled_orders': 0,
      };
    }
  }

  /// Get recent orders with pagination
  Future<List<Order>> getRecentOrders({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('orders')
          .select('*, order_items(*)')
          .order('placed_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => _parseOrderWithItems(json)).toList();
    } catch (e) {
      print('Error getting recent orders: $e');
      return [];
    }
  }

  /// Watch order changes in real-time
  Stream<Order> watchOrder(String orderId) {
    return _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('id', orderId)
        .single()
        .asStream()
        .map((event) => _parseOrderWithItems(event as Map<String, dynamic>));
  }

  /// Watch restaurant orders in real-time
  Stream<List<Order>> watchRestaurantOrders(String restaurantId) {
    return _client
        .from('orders')
        .select('*, order_items(*)')
        .eq('restaurant_id', restaurantId)
        .order('placed_at', ascending: false)
        .asStream()
        .map((event) => (event as List)
            .map((json) => _parseOrderWithItems(json as Map<String, dynamic>))
            .toList());
  }

  /// Parse order with items from database response
  Order _parseOrderWithItems(Map<String, dynamic> json) {
    // Parse order items if present
    List<OrderItem>? orderItems;
    if (json['order_items'] != null) {
      final itemsData = json['order_items'] as List;
      orderItems = itemsData
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    // Remove order_items from the order data before parsing
    final orderData = Map<String, dynamic>.from(json);
    orderData.remove('order_items');

    final order = Order.fromJson(orderData);

    // Create a new order with the items
    return Order(
      id: order.id,
      userId: order.userId,
      customerName: order.customerName,
      restaurantId: order.restaurantId,
      restaurantName: order.restaurantName,
      pickupAddress: order.pickupAddress,
      status: order.status,
      orderItems: orderItems,
      totalAmount: order.totalAmount,
      subtotal: order.subtotal,
      taxAmount: order.taxAmount,
      discountAmount: order.discountAmount,
      promoCode: order.promoCode,
      paymentMethod: order.paymentMethod,
      paymentStatus: order.paymentStatus,
      payfastTransactionId: order.payfastTransactionId,
      payfastSignature: order.payfastSignature,
      paymentGateway: order.paymentGateway,
      paymentReference: order.paymentReference,
      placedAt: order.placedAt,
      notes: order.notes,
      pickupInstructions: order.pickupInstructions,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      estimatedPreparationTime: order.estimatedPreparationTime,
      actualPreparationTime: order.actualPreparationTime,
      preparationStartedAt: order.preparationStartedAt,
      preparationCompletedAt: order.preparationCompletedAt,
      customerNotifiedAt: order.customerNotifiedAt,
      pickupReadyConfirmedAt: order.pickupReadyConfirmedAt,
      confirmedAt: order.confirmedAt,
      preparingAt: order.preparingAt,
      readyAt: order.readyAt,
      cancelledAt: order.cancelledAt,
    );
  }
}

/// Provider for OrderService
final orderServiceProvider = Provider<OrderService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return OrderService(dbService);
});