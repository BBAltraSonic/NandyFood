import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:food_delivery_app/core/config/environment_config.dart';
import 'package:food_delivery_app/core/config/feature_flags.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/analytics_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Analytics service for tracking user behavior and app events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  /// Initialize analytics
  Future<void> initialize() async {
    if (!FeatureFlags().enableAnalytics) {
      AppLogger.info('Analytics disabled by feature flag');
      return;
    }

    if (EnvironmentConfig.isDevelopment) {
      AppLogger.info('Analytics disabled in development environment');
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      
      // Set default properties
      await _analytics?.setAnalyticsCollectionEnabled(true);
      
      AppLogger.success('Analytics service initialized');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize analytics', error: e, stack: stack);
    }
  }

  /// Get analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  // ==================== USER TRACKING ====================

  /// Set user ID for tracking
  Future<void> setUserId(String userId) async {
    await _analytics?.setUserId(id: userId);
    AppLogger.debug('Analytics user ID set: $userId');
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics?.setUserProperty(name: name, value: value);
    AppLogger.debug('Analytics user property set: $name = $value');
  }

  /// Clear user data (on logout)
  Future<void> clearUserData() async {
    await _analytics?.setUserId(id: null);
    AppLogger.debug('Analytics user data cleared');
  }

  // ==================== EVENT TRACKING ====================

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!FeatureFlags().enableAnalytics) return;

    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );
      AppLogger.debug('Analytics event logged: $name', details: parameters?.toString());
    } catch (e) {
      AppLogger.warning('Failed to log analytics event: $e');
    }
  }

  // ==================== E-COMMERCE EVENTS ====================

  /// Track restaurant view
  Future<void> trackRestaurantView({
    required String restaurantId,
    required String restaurantName,
  }) async {
    await logEvent(
      name: 'view_restaurant',
      parameters: {
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
      },
    );
  }

  /// Track menu item view
  Future<void> trackMenuItemView({
    required String itemId,
    required String itemName,
    required double price,
  }) async {
    await logEvent(
      name: 'view_item',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
      },
    );
  }

  /// Track add to cart
  Future<void> trackAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    await logEvent(
      name: 'add_to_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
        'value': price * quantity,
      },
    );
  }

  /// Track remove from cart
  Future<void> trackRemoveFromCart({
    required String itemId,
    required String itemName,
  }) async {
    await logEvent(
      name: 'remove_from_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
      },
    );
  }

  /// Track begin checkout
  Future<void> trackBeginCheckout({
    required double value,
    required int itemCount,
  }) async {
    await logEvent(
      name: 'begin_checkout',
      parameters: {
        'value': value,
        'item_count': itemCount,
      },
    );
  }

  /// Track purchase
  Future<void> trackPurchase({
    required String orderId,
    required double value,
    required double tax,
    required double deliveryFee,
    required String paymentMethod,
  }) async {
    await _analytics?.logPurchase(
      value: value,
      currency: 'ZAR',
      transactionId: orderId,
      tax: tax,
      shipping: deliveryFee,
      parameters: {
        'payment_method': paymentMethod,
      },
    );
  }

  /// Track refund
  Future<void> trackRefund({
    required String orderId,
    required double value,
  }) async {
    await logEvent(
      name: 'refund',
      parameters: {
        'transaction_id': orderId,
        'value': value,
        'currency': 'ZAR',
      },
    );
  }

  // ==================== USER ENGAGEMENT ====================

  /// Track search
  Future<void> trackSearch(String searchTerm) async {
    await _analytics?.logSearch(searchTerm: searchTerm);
  }

  /// Track review submission
  Future<void> trackReviewSubmission({
    required String restaurantId,
    required int rating,
  }) async {
    await logEvent(
      name: 'submit_review',
      parameters: {
        'restaurant_id': restaurantId,
        'rating': rating,
      },
    );
  }

  /// Track share
  Future<void> trackShare({
    required String contentType,
    required String contentId,
  }) async {
    await _analytics?.logShare(
      contentType: contentType,
      itemId: contentId,
      method: 'app_share',
    );
  }

  // ==================== APP LIFECYCLE ====================

  /// Track app open
  Future<void> trackAppOpen() async {
    await _analytics?.logAppOpen();
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // ==================== ERROR TRACKING ====================

  /// Track error
  Future<void> trackError({
    required String error,
    String? fatal,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_message': error,
        'fatal': fatal ?? 'false',
      },
    );
  }

  // ==================== CUSTOM BUSINESS EVENTS ====================

  /// Track order cancellation
  Future<void> trackOrderCancellation({
    required String orderId,
    required String reason,
  }) async {
    await logEvent(
      name: 'cancel_order',
      parameters: {
        'order_id': orderId,
        'reason': reason,
      },
    );
  }

  /// Track delivery tracking
  Future<void> trackDeliveryTracking(String orderId) async {
    await logEvent(
      name: 'track_delivery',
      parameters: {
        'order_id': orderId,
      },
    );
  }

  /// Track promo code usage
  Future<void> trackPromoCodeUsage({
    required String promoCode,
    required double discountAmount,
  }) async {
    await logEvent(
      name: 'use_promo_code',
      parameters: {
        'promo_code': promoCode,
        'discount_amount': discountAmount,
      },
    );
  }

  // ==================== RESTAURANT DASHBOARD ANALYTICS ====================

  /// Get comprehensive dashboard analytics for a restaurant
  Future<DashboardAnalytics> getDashboardAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug('Getting dashboard analytics for restaurant: $restaurantId');
      
      // Run all analytics queries in parallel for better performance
      final results = await Future.wait([
        getSalesAnalytics(restaurantId, startDate: startDate, endDate: endDate),
        getRevenueAnalytics(restaurantId, startDate: startDate, endDate: endDate),
        getCustomerAnalytics(restaurantId, startDate: startDate, endDate: endDate),
        _getTopMenuItems(restaurantId, startDate: startDate, endDate: endDate),
        _getOrderStatusBreakdown(restaurantId, startDate: startDate, endDate: endDate),
        _getPeakHours(restaurantId, startDate: startDate, endDate: endDate),
      ]);
      
      return DashboardAnalytics(
        salesAnalytics: results[0] as SalesAnalytics,
        revenueAnalytics: results[1] as RevenueAnalytics,
        customerAnalytics: results[2] as CustomerAnalytics,
        topItems: results[3] as List<MenuItemPerformance>,
        orderStatusBreakdown: results[4] as OrderStatusBreakdown,
        peakHours: results[5] as List<PeakHoursData>,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get dashboard analytics', error: e, stack: stack);
      
      // Return default analytics on error to prevent UI crash
      return DashboardAnalytics(
        salesAnalytics: SalesAnalytics(
          totalSales: 0,
          totalOrders: 0,
          averageOrderValue: 0,
          salesByDay: {},
          ordersByDay: {},
        ),
        revenueAnalytics: RevenueAnalytics(
          grossRevenue: 0,
          netRevenue: 0,
          deliveryFees: 0,
          platformFees: 0,
          refunds: 0,
          revenueByMonth: {},
        ),
        customerAnalytics: CustomerAnalytics(
          totalCustomers: 0,
          newCustomers: 0,
          returningCustomers: 0,
          repeatRate: 0,
          averageOrdersPerCustomer: 0,
        ),
        topItems: [],
        orderStatusBreakdown: OrderStatusBreakdown(
          pending: 0,
          confirmed: 0,
          preparing: 0,
          readyForPickup: 0,
          outForDelivery: 0,
          delivered: 0,
          cancelled: 0,
        ),
        peakHours: [],
      );
    }
  }

  /// Get sales analytics for a restaurant
  Future<SalesAnalytics> getSalesAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug('Getting sales analytics for restaurant: $restaurantId');
      
      // Set default date range if not provided
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      // Query orders within date range
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('total_amount, placed_at, status')
          .eq('restaurant_id', restaurantId)
          .gte('placed_at', start.toIso8601String())
          .lte('placed_at', end.toIso8601String())
          .neq('status', 'cancelled'); // Exclude cancelled orders from sales
      
      final orders = ordersResponse as List<dynamic>;
      
      // Calculate totals
      double totalSales = 0;
      final salesByDay = <String, double>{};
      final ordersByDay = <String, int>{};
      
      for (final order in orders) {
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        totalSales += amount;
        
        // Parse date and get day name
        final placedAt = DateTime.parse(order['placed_at'] as String);
        final dayName = _getDayName(placedAt.weekday);
        
        salesByDay[dayName] = (salesByDay[dayName] ?? 0) + amount;
        ordersByDay[dayName] = (ordersByDay[dayName] ?? 0) + 1;
      }
      
      final totalOrders = orders.length;
      final averageOrderValue = (totalOrders > 0 ? totalSales / totalOrders : 0).toDouble();
      
      return SalesAnalytics(
        totalSales: totalSales,
        totalOrders: totalOrders,
        averageOrderValue: averageOrderValue,
        salesByDay: salesByDay,
        ordersByDay: ordersByDay,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get sales analytics', error: e, stack: stack);
      
      // Return empty analytics on error
      return SalesAnalytics(
        totalSales: 0,
        totalOrders: 0,
        averageOrderValue: 0,
        salesByDay: {},
        ordersByDay: {},
      );
    }
  }
  
  /// Helper to get day name from weekday number
  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  /// Get revenue analytics for a restaurant
  Future<RevenueAnalytics> getRevenueAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug('Getting revenue analytics for restaurant: $restaurantId');
      
      // Set default date range if not provided
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      // Query orders within date range
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('total_amount, subtotal, delivery_fee, tax_amount, discount_amount, placed_at, payment_status')
          .eq('restaurant_id', restaurantId)
          .gte('placed_at', start.toIso8601String())
          .lte('placed_at', end.toIso8601String())
          .neq('status', 'cancelled');
      
      final orders = ordersResponse as List<dynamic>;
      
      // Calculate revenue breakdown
      double grossRevenue = 0;
      double deliveryFees = 0;
      double refunds = 0;
      final revenueByMonth = <String, double>{};
      
      for (final order in orders) {
        final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0;
        final paymentStatus = order['payment_status'] as String?;
        
        // Calculate gross revenue
        if (paymentStatus == 'completed') {
          grossRevenue += totalAmount;
          deliveryFees += deliveryFee;
        } else if (paymentStatus == 'refunded') {
          refunds += totalAmount;
        }
        
        // Group by month
        final placedAt = DateTime.parse(order['placed_at'] as String);
        final monthKey = _getMonthName(placedAt.month);
        revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0) + totalAmount;
      }
      
      // Platform fee is typically 15-20% of order value (without delivery fee)
      final platformFees = grossRevenue * 0.15;
      final netRevenue = grossRevenue - deliveryFees - platformFees;
      
      return RevenueAnalytics(
        grossRevenue: grossRevenue,
        netRevenue: netRevenue,
        deliveryFees: deliveryFees,
        platformFees: platformFees,
        refunds: refunds,
        revenueByMonth: revenueByMonth,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get revenue analytics', error: e, stack: stack);
      
      // Return empty analytics on error
      return RevenueAnalytics(
        grossRevenue: 0,
        netRevenue: 0,
        deliveryFees: 0,
        platformFees: 0,
        refunds: 0,
        revenueByMonth: {},
      );
    }
  }
  
  /// Helper to get month name from month number
  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  /// Get customer analytics for a restaurant
  Future<CustomerAnalytics> getCustomerAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug('Getting customer analytics for restaurant: $restaurantId');
      
      // Set default date range if not provided
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      // Query orders within date range
      final ordersResponse = await Supabase.instance.client
          .from('orders')
          .select('user_id, placed_at')
          .eq('restaurant_id', restaurantId)
          .gte('placed_at', start.toIso8601String())
          .lte('placed_at', end.toIso8601String())
          .neq('status', 'cancelled');
      
      final orders = ordersResponse as List<dynamic>;
      
      // Count unique customers and their order frequency
      final customerOrderCounts = <String, int>{};
      final customerFirstOrder = <String, DateTime>{};
      
      for (final order in orders) {
        final userId = order['user_id'] as String?;
        if (userId == null) continue;
        
        customerOrderCounts[userId] = (customerOrderCounts[userId] ?? 0) + 1;
        
        final placedAt = DateTime.parse(order['placed_at'] as String);
        if (!customerFirstOrder.containsKey(userId) || placedAt.isBefore(customerFirstOrder[userId]!)) {
          customerFirstOrder[userId] = placedAt;
        }
      }
      
      final totalCustomers = customerOrderCounts.length;
      
      // Count new vs returning customers
      int newCustomers = 0;
      int returningCustomers = 0;
      int totalOrders = 0;
      
      for (final entry in customerOrderCounts.entries) {
        totalOrders += entry.value;
        if (entry.value == 1) {
          newCustomers++;
        } else {
          returningCustomers++;
        }
      }
      
      final repeatRate = (totalCustomers > 0 ? returningCustomers / totalCustomers : 0).toDouble();
      final averageOrdersPerCustomer = (totalCustomers > 0 ? totalOrders / totalCustomers : 0).toDouble();
      
      return CustomerAnalytics(
        totalCustomers: totalCustomers,
        newCustomers: newCustomers,
        returningCustomers: returningCustomers,
        repeatRate: repeatRate,
        averageOrdersPerCustomer: averageOrdersPerCustomer,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get customer analytics', error: e, stack: stack);
      
      // Return empty analytics on error
      return CustomerAnalytics(
        totalCustomers: 0,
        newCustomers: 0,
        returningCustomers: 0,
        repeatRate: 0,
        averageOrdersPerCustomer: 0,
      );
    }
  }
  
  // ==================== HELPER METHODS FOR ANALYTICS ====================
  
  /// Get top performing menu items
  Future<List<MenuItemPerformance>> _getTopMenuItems(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      // Set default date range
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      // Query order items with menu item details
      final response = await Supabase.instance.client
          .from('order_items')
          .select('menu_item_id, item_name, unit_price, quantity, subtotal, orders!inner(placed_at, restaurant_id)')
          .eq('orders.restaurant_id', restaurantId)
          .gte('orders.placed_at', start.toIso8601String())
          .lte('orders.placed_at', end.toIso8601String());
      
      final orderItems = response as List<dynamic>;
      
      // Group by menu item and calculate totals
      final itemStats = <String, Map<String, dynamic>>{};
      
      for (final item in orderItems) {
        final menuItemId = item['menu_item_id'] as String?;
        if (menuItemId == null) continue;
        
        final itemName = item['item_name'] as String? ?? 'Unknown';
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
        
        if (!itemStats.containsKey(menuItemId)) {
          itemStats[menuItemId] = {
            'id': menuItemId,
            'name': itemName,
            'totalOrders': 0,
            'totalRevenue': 0.0,
          };
        }
        
        itemStats[menuItemId]!['totalOrders'] = (itemStats[menuItemId]!['totalOrders'] as int) + quantity;
        itemStats[menuItemId]!['totalRevenue'] = (itemStats[menuItemId]!['totalRevenue'] as double) + subtotal;
      }
      
      // Convert to MenuItemPerformance objects and sort by revenue
      final performances = itemStats.values
          .map((stats) => MenuItemPerformance(
                itemId: stats['id'] as String,
                itemName: stats['name'] as String,
                totalOrders: stats['totalOrders'] as int,
                totalRevenue: stats['totalRevenue'] as double,
                averageRating: null, // Could be fetched from menu_items table if needed
              ))
          .toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
      
      return performances.take(limit).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to get top menu items', error: e, stack: stack);
      return [];
    }
  }
  
  /// Get order status breakdown
  Future<OrderStatusBreakdown> _getOrderStatusBreakdown(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Set default date range
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      // Query orders by status
      final response = await Supabase.instance.client
          .from('orders')
          .select('status')
          .eq('restaurant_id', restaurantId)
          .gte('placed_at', start.toIso8601String())
          .lte('placed_at', end.toIso8601String());
      
      final orders = response as List<dynamic>;
      
      // Count by status
      int pending = 0;
      int confirmed = 0;
      int preparing = 0;
      int readyForPickup = 0;
      int outForDelivery = 0;
      int delivered = 0;
      int cancelled = 0;
      
      for (final order in orders) {
        final status = order['status'] as String?;
        switch (status) {
          case 'placed':
            pending++;
            break;
          case 'confirmed':
            confirmed++;
            break;
          case 'preparing':
            preparing++;
            break;
          case 'ready_for_pickup':
            readyForPickup++;
            break;
          case 'out_for_delivery':
            outForDelivery++;
            break;
          case 'delivered':
            delivered++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }
      
      return OrderStatusBreakdown(
        pending: pending,
        confirmed: confirmed,
        preparing: preparing,
        readyForPickup: readyForPickup,
        outForDelivery: outForDelivery,
        delivered: delivered,
        cancelled: cancelled,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get order status breakdown', error: e, stack: stack);
      return OrderStatusBreakdown(
        pending: 0,
        confirmed: 0,
        preparing: 0,
        readyForPickup: 0,
        outForDelivery: 0,
        delivered: 0,
        cancelled: 0,
      );
    }
  }
  
  /// Get peak hours data
  Future<List<PeakHoursData>> _getPeakHours(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Set default date range
      final end = endDate ?? DateTime.now();
      final start = startDate ?? end.subtract(const Duration(days: 30));
      
      // Query orders with timestamps
      final response = await Supabase.instance.client
          .from('orders')
          .select('placed_at, total_amount')
          .eq('restaurant_id', restaurantId)
          .gte('placed_at', start.toIso8601String())
          .lte('placed_at', end.toIso8601String())
          .neq('status', 'cancelled');
      
      final orders = response as List<dynamic>;
      
      // Group by hour of day
      final hourStats = <int, Map<String, dynamic>>{};
      
      for (int hour = 0; hour < 24; hour++) {
        hourStats[hour] = {
          'hour': hour,
          'orderCount': 0,
          'totalSales': 0.0,
        };
      }
      
      for (final order in orders) {
        final placedAt = DateTime.parse(order['placed_at'] as String);
        final hour = placedAt.hour;
        final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        
        hourStats[hour]!['orderCount'] = (hourStats[hour]!['orderCount'] as int) + 1;
        hourStats[hour]!['totalSales'] = (hourStats[hour]!['totalSales'] as double) + totalAmount;
      }
      
      // Convert to PeakHoursData objects
      return hourStats.values
          .map((stats) => PeakHoursData(
                hourOfDay: stats['hour'] as int,
                orderCount: stats['orderCount'] as int,
                totalSales: stats['totalSales'] as double,
              ))
          .toList()
        ..sort((a, b) => b.orderCount.compareTo(a.orderCount));
    } catch (e, stack) {
      AppLogger.error('Failed to get peak hours', error: e, stack: stack);
      return [];
    }
  }
}
