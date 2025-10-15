import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/analytics_data.dart';

/// Service for restaurant analytics
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// Get sales analytics for a restaurant
  Future<SalesAnalytics> getSalesAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsService.getSalesAnalytics', 'ENTER',
        params: {'restaurantId': restaurantId});

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Query orders within date range
      final ordersResponse = await _dbService.client
          .from('orders')
          .select('total_amount, created_at')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .filter('status', 'in', '(completed,delivered)');

      final orders = ordersResponse as List;

      if (orders.isEmpty) {
        return SalesAnalytics(
          totalSales: 0,
          totalOrders: 0,
          averageOrderValue: 0,
          salesByDay: {},
          ordersByDay: {},
        );
      }

      // Calculate totals
      double totalSales = 0;
      final salesByDay = <String, double>{};
      final ordersByDay = <String, int>{};

      for (final order in orders) {
        final amount = (order['total_amount'] as num).toDouble();
        final date = DateTime.parse(order['created_at']);
        final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        totalSales += amount;
        salesByDay[dayKey] = (salesByDay[dayKey] ?? 0) + amount;
        ordersByDay[dayKey] = (ordersByDay[dayKey] ?? 0) + 1;
      }

      final analytics = SalesAnalytics(
        totalSales: totalSales,
        totalOrders: orders.length,
        averageOrderValue: totalSales / orders.length,
        salesByDay: salesByDay,
        ordersByDay: ordersByDay,
      );

      AppLogger.success('Sales analytics calculated');
      AppLogger.function('AnalyticsService.getSalesAnalytics', 'EXIT');

      return analytics;
    } catch (e, stack) {
      AppLogger.error('Failed to get sales analytics', error: e, stack: stack);
      rethrow;
    }
  }

  /// Get revenue analytics
  Future<RevenueAnalytics> getRevenueAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsService.getRevenueAnalytics', 'ENTER');

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 90));
      endDate ??= DateTime.now();

      final ordersResponse = await _dbService.client
          .from('orders')
          .select('total_amount, delivery_fee, created_at, status')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final orders = ordersResponse as List;

      double grossRevenue = 0;
      double deliveryFees = 0;
      double refunds = 0;
      final revenueByMonth = <String, double>{};

      for (final order in orders) {
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;
        final deliveryFee = (order['delivery_fee'] as num?)?.toDouble() ?? 0;
        final date = DateTime.parse(order['created_at']);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

        if (order['status'] == 'refunded' || order['status'] == 'cancelled') {
          refunds += amount;
        } else {
          grossRevenue += amount;
          deliveryFees += deliveryFee;
          revenueByMonth[monthKey] = (revenueByMonth[monthKey] ?? 0) + amount;
        }
      }

      // Platform fees (example: 15% of gross revenue)
      final platformFees = grossRevenue * 0.15;
      final netRevenue = grossRevenue - platformFees;

      final analytics = RevenueAnalytics(
        grossRevenue: grossRevenue,
        netRevenue: netRevenue,
        deliveryFees: deliveryFees,
        platformFees: platformFees,
        refunds: refunds,
        revenueByMonth: revenueByMonth,
      );

      AppLogger.success('Revenue analytics calculated');
      return analytics;
    } catch (e, stack) {
      AppLogger.error('Failed to get revenue analytics',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get customer analytics
  Future<CustomerAnalytics> getCustomerAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsService.getCustomerAnalytics', 'ENTER');

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final ordersResponse = await _dbService.client
          .from('orders')
          .select('user_id, created_at')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .filter('status', 'in', '(completed,delivered)');

      final orders = ordersResponse as List;

      // Count unique customers and their order counts
      final customerOrderCounts = <String, int>{};
      for (final order in orders) {
        final userId = order['user_id'] as String;
        customerOrderCounts[userId] = (customerOrderCounts[userId] ?? 0) + 1;
      }

      final totalCustomers = customerOrderCounts.length;
      final newCustomers = customerOrderCounts.values.where((count) => count == 1).length;
      final returningCustomers = totalCustomers - newCustomers;
      final repeatRate = totalCustomers > 0 ? returningCustomers / totalCustomers : 0.0;
      final avgOrdersPerCustomer = totalCustomers > 0 ? orders.length / totalCustomers : 0.0;

      final analytics = CustomerAnalytics(
        totalCustomers: totalCustomers,
        newCustomers: newCustomers,
        returningCustomers: returningCustomers,
        repeatRate: repeatRate,
        averageOrdersPerCustomer: avgOrdersPerCustomer,
      );

      AppLogger.success('Customer analytics calculated');
      return analytics;
    } catch (e, stack) {
      AppLogger.error('Failed to get customer analytics',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get top performing menu items
  Future<List<MenuItemPerformance>> getTopMenuItems(
    String restaurantId, {
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsService.getTopMenuItems', 'ENTER');

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final response = await _dbService.client.rpc('get_top_menu_items', params: {
        'p_restaurant_id': restaurantId,
        'p_start_date': startDate.toIso8601String(),
        'p_end_date': endDate.toIso8601String(),
        'p_limit': limit,
      });

      final items = (response as List)
          .map((json) =>
              MenuItemPerformance.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.success('Fetched ${items.length} top menu items');
      return items;
    } catch (e, stack) {
      AppLogger.warning('Failed to get top menu items (RPC may not exist): $e');
      // Return empty list if RPC doesn't exist
      return [];
    }
  }

  /// Get order status breakdown
  Future<OrderStatusBreakdown> getOrderStatusBreakdown(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsService.getOrderStatusBreakdown', 'ENTER');

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 7));
      endDate ??= DateTime.now();

      final ordersResponse = await _dbService.client
          .from('orders')
          .select('status')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String());

      final orders = ordersResponse as List;

      final statusCounts = <String, int>{};
      for (final order in orders) {
        final status = order['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      final breakdown = OrderStatusBreakdown(
        pending: statusCounts['pending'] ?? 0,
        confirmed: statusCounts['confirmed'] ?? 0,
        preparing: statusCounts['preparing'] ?? 0,
        readyForPickup: statusCounts['ready_for_pickup'] ?? 0,
        outForDelivery: statusCounts['out_for_delivery'] ?? 0,
        delivered: statusCounts['delivered'] ?? 0,
        cancelled: statusCounts['cancelled'] ?? 0,
      );

      AppLogger.success('Order status breakdown calculated');
      return breakdown;
    } catch (e, stack) {
      AppLogger.error('Failed to get order status breakdown',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get peak hours data
  Future<List<PeakHoursData>> getPeakHours(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsService.getPeakHours', 'ENTER');

    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      final ordersResponse = await _dbService.client
          .from('orders')
          .select('created_at, total_amount')
          .eq('restaurant_id', restaurantId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .filter('status', 'in', '(completed,delivered)');

      final orders = ordersResponse as List;

      // Group by hour of day
      final hourlyData = <int, Map<String, dynamic>>{};

      for (final order in orders) {
        final date = DateTime.parse(order['created_at']);
        final hour = date.hour;
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0;

        if (!hourlyData.containsKey(hour)) {
          hourlyData[hour] = {'count': 0, 'sales': 0.0};
        }

        hourlyData[hour]!['count'] = (hourlyData[hour]!['count'] as int) + 1;
        hourlyData[hour]!['sales'] =
            (hourlyData[hour]!['sales'] as double) + amount;
      }

      final peakHours = hourlyData.entries
          .map((entry) => PeakHoursData(
                hourOfDay: entry.key,
                orderCount: entry.value['count'] as int,
                totalSales: entry.value['sales'] as double,
              ))
          .toList()
        ..sort((a, b) => a.hourOfDay.compareTo(b.hourOfDay));

      AppLogger.success('Peak hours calculated');
      return peakHours;
    } catch (e, stack) {
      AppLogger.error('Failed to get peak hours', error: e, stack: stack);
      rethrow;
    }
  }

  /// Get comprehensive dashboard analytics
  Future<DashboardAnalytics> getDashboardAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    AppLogger.function('AnalyticsService.getDashboardAnalytics', 'ENTER');

    try {
      // Fetch all analytics in parallel
      final results = await Future.wait([
        getSalesAnalytics(restaurantId, startDate: startDate, endDate: endDate),
        getRevenueAnalytics(restaurantId, startDate: startDate, endDate: endDate),
        getCustomerAnalytics(restaurantId, startDate: startDate, endDate: endDate),
        getTopMenuItems(restaurantId, startDate: startDate, endDate: endDate),
        getOrderStatusBreakdown(restaurantId, startDate: startDate, endDate: endDate),
        getPeakHours(restaurantId, startDate: startDate, endDate: endDate),
      ]);

      final dashboard = DashboardAnalytics(
        salesAnalytics: results[0] as SalesAnalytics,
        revenueAnalytics: results[1] as RevenueAnalytics,
        customerAnalytics: results[2] as CustomerAnalytics,
        topItems: results[3] as List<MenuItemPerformance>,
        orderStatusBreakdown: results[4] as OrderStatusBreakdown,
        peakHours: results[5] as List<PeakHoursData>,
      );

      AppLogger.success('Dashboard analytics loaded');
      AppLogger.function('AnalyticsService.getDashboardAnalytics', 'EXIT');

      return dashboard;
    } catch (e, stack) {
      AppLogger.error('Failed to get dashboard analytics',
          error: e, stack: stack);
      rethrow;
    }
  }
}
