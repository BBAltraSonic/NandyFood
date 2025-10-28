import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/data/repositories/owner_repository.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/notifications_screen.dart';
import 'package:food_delivery_app/shared/models/restaurant_analytics.dart';

class AnalyticsInsightsService {
  final OwnerRepository _repository;

  AnalyticsInsightsService({OwnerRepository? repository})
      : _repository = repository ?? OwnerRepository();

  /// Generate insights from analytics data and return notification suggestions
  Future<List<NotificationSuggestion>> generateInsights(
    String restaurantId,
    RestaurantAnalytics analytics,
  ) async {
    final suggestions = <NotificationSuggestion>[];

    try {
      // Sales performance insights
      await _analyzeSalesPerformance(restaurantId, analytics, suggestions);

      // Customer behavior insights
      await _analyzeCustomerBehavior(restaurantId, analytics, suggestions);

      // Menu performance insights
      await _analyzeMenuPerformance(restaurantId, analytics, suggestions);

      // Operating hours insights
      await _analyzeOperatingHours(restaurantId, analytics, suggestions);

      AppLogger.info('Generated ${suggestions.length} analytics insights');
      return suggestions;
    } catch (e) {
      AppLogger.error('Error generating analytics insights', error: e);
      return [];
    }
  }

  Future<void> _analyzeSalesPerformance(
    String restaurantId,
    RestaurantAnalytics analytics,
    List<NotificationSuggestion> suggestions,
  ) async {
    final salesAnalytics = analytics.salesAnalytics;
    final revenueAnalytics = analytics.revenueAnalytics;

    // Check for declining sales
    if (salesAnalytics.salesGrowthRate < -0.1) {
      suggestions.add(NotificationSuggestion(
        type: NotificationType.analytics,
        title: 'Sales Decline Alert',
        message: 'Sales have decreased by ${(salesAnalytics.salesGrowthRate * 100).abs().toStringAsFixed(1)}% compared to last period',
        priority: NotificationPriority.high,
        actionUrl: '/restaurant/analytics',
        data: {
          'metric': 'sales_growth',
          'value': salesAnalytics.salesGrowthRate,
        },
      ));
    }

    // Check for exceptional sales growth
    if (salesAnalytics.salesGrowthRate > 0.2) {
      suggestions.add(NotificationSuggestion(
        type: NotificationType.analytics,
        title: 'Excellent Sales Growth!',
        message: 'Sales have increased by ${(salesAnalytics.salesGrowthRate * 100).toStringAsFixed(1)}% compared to last period',
        priority: NotificationPriority.low,
        actionUrl: '/restaurant/analytics',
        data: {
          'metric': 'sales_growth',
          'value': salesAnalytics.salesGrowthRate,
        },
      ));
    }

    // Check average order value
    if (salesAnalytics.avgOrderValue < 150) {
      suggestions.add(NotificationSuggestion(
        type: NotificationType.analytics,
        title: 'Low Average Order Value',
        message: 'Consider upselling strategies to increase average order value',
        priority: NotificationPriority.medium,
        actionUrl: '/restaurant/analytics',
        data: {
          'metric': 'avg_order_value',
          'value': salesAnalytics.avgOrderValue,
        },
      ));
    }

    // Check revenue trends
    if (revenueAnalytics.netRevenue < revenueAnalytics.targetRevenue * 0.8) {
      suggestions.add(NotificationSuggestion(
        type: NotificationType.analytics,
        title: 'Revenue Below Target',
        message: 'Current revenue is ${(revenueAnalytics.netRevenue / revenueAnalytics.targetRevenue * 100).toStringAsFixed(1)}% of target',
        priority: NotificationPriority.high,
        actionUrl: '/restaurant/analytics',
        data: {
          'metric': 'revenue_target',
          'actual': revenueAnalytics.netRevenue,
          'target': revenueAnalytics.targetRevenue,
        },
      ));
    }
  }

  Future<void> _analyzeCustomerBehavior(
    String restaurantId,
    RestaurantAnalytics analytics,
    List<NotificationSuggestion> suggestions,
  ) async {
    final customerAnalytics = analytics.customerAnalytics;

    // Check repeat customer rate
    if (customerAnalytics.repeatRate < 0.3) {
      suggestions.add(NotificationSuggestion(
        type: NotificationType.analytics,
        title: 'Low Customer Retention',
        message: 'Only ${(customerAnalytics.repeatRate * 100).toStringAsFixed(1)}% of customers are returning',
        priority: NotificationPriority.medium,
        actionUrl: '/restaurant/analytics',
        data: {
          'metric': 'repeat_rate',
          'value': customerAnalytics.repeatRate,
        },
      ));
    }

    // Check for high new customer acquisition
    if (customerAnalytics.newCustomers > customerAnalytics.totalCustomers * 0.7) {
      suggestions.add(NotificationSuggestion(
        type: NotificationType.analytics,
        title: 'Great Customer Acquisition!',
        message: '${customerAnalytics.newCustomers} new customers this period',
        priority: NotificationPriority.low,
        actionUrl: '/restaurant/analytics',
        data: {
          'metric': 'new_customers',
          'value': customerAnalytics.newCustomers,
        },
      ));
    }
  }

  Future<void> _analyzeMenuPerformance(
    String restaurantId,
    RestaurantAnalytics analytics,
    List<NotificationSuggestion> suggestions,
  ) async {
    final topItems = analytics.topItems;

    // Check if top items are generating most revenue
    if (topItems.isNotEmpty) {
      final topRevenue = topItems
          .take(3)
          .map((item) => item.totalRevenue)
          .reduce((a, b) => a + b);

      final totalRevenue = analytics.salesAnalytics.totalSales;

      if (topRevenue / totalRevenue > 0.7) {
        suggestions.add(NotificationSuggestion(
          type: NotificationType.analytics,
          title: 'Menu Performance Insight',
          message: 'Top 3 items generate ${(topRevenue / totalRevenue * 100).toStringAsFixed(1)}% of revenue',
          priority: NotificationPriority.low,
          actionUrl: '/restaurant/analytics',
          data: {
            'metric': 'menu_concentration',
            'value': topRevenue / totalRevenue,
          },
        ));
      }
    }
  }

  Future<void> _analyzeOperatingHours(
    String restaurantId,
    RestaurantAnalytics analytics,
    List<NotificationSuggestion> suggestions,
  ) async {
    final peakHours = analytics.peakHours;

    if (peakHours.isNotEmpty) {
      // Find peak hour
      final peakHourData = peakHours.reduce((a, b) =>
          (a['orders'] as int) > (b['orders'] as int) ? a : b);
      final peakHour = peakHourData['hour'] as int;
      final peakOrders = peakHourData['orders'] as int;

      // Check if peak hour is during typical lunch/dinner times
      if (peakHour >= 11 && peakHour <= 14) {
        suggestions.add(NotificationSuggestion(
          type: NotificationType.analytics,
          title: 'Lunch Rush Peak',
          message: 'Peak hour is ${peakHour.toString().padLeft(2, '0')}:00 with $peakOrders orders',
          priority: NotificationPriority.low,
          actionUrl: '/restaurant/analytics',
          data: {
            'metric': 'peak_hour_lunch',
            'hour': peakHour,
            'orders': peakOrders,
          },
        ));
      } else if (peakHour >= 17 && peakHour <= 20) {
        suggestions.add(NotificationSuggestion(
          type: NotificationType.analytics,
          title: 'Dinner Rush Peak',
          message: 'Peak hour is ${peakHour.toString().padLeft(2, '0')}:00 with $peakOrders orders',
          priority: NotificationPriority.low,
          actionUrl: '/restaurant/analytics',
          data: {
            'metric': 'peak_hour_dinner',
            'hour': peakHour,
            'orders': peakOrders,
          },
        ));
      }
    }
  }

  /// Check for weekly summary and generate insights
  Future<List<NotificationSuggestion>> generateWeeklySummary(
    String restaurantId,
  ) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));

      final analyticsResult = await _repository.getAnalytics(restaurantId, startDate, endDate);

      if (analyticsResult.isSuccess && analyticsResult.data != null) {
        final analytics = analyticsResult.data!;
        final suggestions = <NotificationSuggestion>[];

        // Generate weekly summary notification
        final totalSales = analytics.salesAnalytics.totalSales;
        final totalOrders = analytics.salesAnalytics.totalOrders;
        final avgOrderValue = analytics.salesAnalytics.avgOrderValue;

        suggestions.add(NotificationSuggestion(
          type: NotificationType.analytics,
          title: 'Weekly Performance Summary',
          message: '$totalOrders orders, R${totalSales.toStringAsFixed(2)} revenue, Avg: R${avgOrderValue.toStringAsFixed(2)}',
          priority: NotificationPriority.low,
          actionUrl: '/restaurant/analytics',
          data: {
            'metric': 'weekly_summary',
            'total_sales': totalSales,
            'total_orders': totalOrders,
            'avg_order_value': avgOrderValue,
          },
        ));

        // Add other insights
        final insights = await generateInsights(restaurantId, analytics);
        suggestions.addAll(insights.where((insight) => insight.priority == NotificationPriority.high));

        return suggestions;
      }
    } catch (e) {
      AppLogger.error('Error generating weekly summary', error: e);
    }

    return [];
  }
}

class NotificationSuggestion {
  final NotificationType type;
  final String title;
  final String message;
  final NotificationPriority priority;
  final String? actionUrl;
  final Map<String, dynamic>? data;

  NotificationSuggestion({
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    this.actionUrl,
    this.data,
  });

  RestaurantNotification toNotification() {
    return RestaurantNotification(
      id: 'insight_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      data: data,
      actionUrl: actionUrl,
    );
  }
}

enum NotificationPriority {
  low,
  medium,
  high,
}