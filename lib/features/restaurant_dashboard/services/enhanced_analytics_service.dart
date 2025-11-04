import 'dart:async';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/enhanced_analytics.dart';
import 'package:food_delivery_app/shared/models/restaurant_analytics.dart';

/// Enhanced Analytics Service for advanced restaurant analytics
class EnhancedAnalyticsService {
  final SupabaseClient _supabase;
  static const String _cacheTimeout = '30 minutes';

  EnhancedAnalyticsService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get comprehensive dashboard analytics with caching
  Future<AdvancedRevenueAnalytics> getAdvancedRevenueAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    AppLogger.function('EnhancedAnalyticsService.getAdvancedRevenueAnalytics', 'ENTER',
        params: {
          'restaurantId': restaurantId,
          'startDate': startDate,
          'endDate': endDate,
          'useCache': useCache,
        });

    try {
      // Check cache first
      if (useCache) {
        final cachedData = await _getCachedData(
          restaurantId,
          'revenue_analytics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}',
        );
        if (cachedData != null) {
          AppLogger.info('Revenue analytics loaded from cache');
          return AdvancedRevenueAnalytics.fromJson(cachedData);
        }
      }

      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Get revenue data with complex queries
      final revenueData = await _executeRevenueAnalyticsQuery(
        restaurantId,
        startDate,
        endDate,
      );

      // Get daily revenue trends
      final dailyRevenueData = await _getDailyRevenueData(
        restaurantId,
        startDate,
        endDate,
      );

      // Get weekly revenue trends
      final weeklyRevenueData = await _getWeeklyRevenueData(
        restaurantId,
        startDate,
        endDate,
      );

      // Get monthly revenue trends
      final monthlyRevenueData = await _getMonthlyRevenueData(
        restaurantId,
        startDate,
        endDate,
      );

      // Get revenue breakdowns
      final revenueByCategory = await _getRevenueByCategory(
        restaurantId,
        startDate,
        endDate,
      );

      final revenueByPaymentMethod = await _getRevenueByPaymentMethod(
        restaurantId,
        startDate,
        endDate,
      );

      final revenueByTimeOfDay = await _getRevenueByTimeOfDay(
        restaurantId,
        startDate,
        endDate,
      );

      final revenueByDayOfWeek = await _getRevenueByDayOfWeek(
        restaurantId,
        startDate,
        endDate,
      );

      // Get revenue forecast
      final revenueForecast = await _getRevenueForecast(
        restaurantId,
        startDate,
        endDate,
      );

      final analytics = AdvancedRevenueAnalytics(
        id: 'revenue_analytics_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        startDate: startDate,
        endDate: endDate,
        totalRevenue: revenueData['total_revenue'] ?? 0.0,
        grossRevenue: revenueData['gross_revenue'] ?? 0.0,
        netRevenue: revenueData['net_revenue'] ?? 0.0,
        targetRevenue: revenueData['target_revenue'] ?? 0.0,
        revenueGrowthRate: (revenueData['revenue_growth_rate'] ?? 0.0).toDouble(),
        averageOrderValue: (revenueData['average_order_value'] ?? 0.0).toDouble(),
        revenuePerCustomer: (revenueData['revenue_per_customer'] ?? 0.0).toDouble(),
        revenueByCategory: revenueByCategory,
        revenueByPaymentMethod: revenueByPaymentMethod,
        revenueByTimeOfDay: revenueByTimeOfDay,
        revenueByDayOfWeek: revenueByDayOfWeek,
        dailyRevenueData: dailyRevenueData,
        weeklyRevenueData: weeklyRevenueData,
        monthlyRevenueData: monthlyRevenueData,
        revenueForecast: revenueForecast,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Cache the results
      if (useCache) {
        await _cacheData(
          restaurantId,
          'revenue_analytics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}',
          analytics.toJson(),
        );
      }

      AppLogger.success('Advanced revenue analytics loaded successfully');
      AppLogger.function('EnhancedAnalyticsService.getAdvancedRevenueAnalytics', 'EXIT');
      return analytics;
    } catch (e, stack) {
      AppLogger.error('Failed to get advanced revenue analytics',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get advanced customer analytics
  Future<AdvancedCustomerAnalytics> getAdvancedCustomerAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    AppLogger.function('EnhancedAnalyticsService.getAdvancedCustomerAnalytics', 'ENTER',
        params: {
          'restaurantId': restaurantId,
          'startDate': startDate,
          'endDate': endDate,
        });

    try {
      // Check cache first
      if (useCache) {
        final cachedData = await _getCachedData(
          restaurantId,
          'customer_analytics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}',
        );
        if (cachedData != null) {
          AppLogger.info('Customer analytics loaded from cache');
          return AdvancedCustomerAnalytics.fromJson(cachedData);
        }
      }

      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Get customer metrics
      final customerMetrics = await _executeCustomerAnalyticsQuery(
        restaurantId,
        startDate,
        endDate,
      );

      // Get customer segments
      final customerSegments = await _getCustomerSegments(restaurantId);

      // Get conversion funnel data
      final conversionFunnel = await _getConversionFunnel(
        restaurantId,
        startDate,
        endDate,
      );

      // Get demographic data
      final ageDistribution = await _getAgeDistribution(restaurantId);
      final locationDistribution = await _getLocationDistribution(restaurantId);

      final analytics = AdvancedCustomerAnalytics(
        id: 'customer_analytics_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        startDate: startDate,
        endDate: endDate,
        totalCustomers: customerMetrics['total_customers'] ?? 0,
        newCustomers: customerMetrics['new_customers'] ?? 0,
        returningCustomers: customerMetrics['returning_customers'] ?? 0,
        activeCustomers: customerMetrics['active_customers'] ?? 0,
        customerRetentionRate: (customerMetrics['customer_retention_rate'] ?? 0.0).toDouble(),
        customerAcquisitionRate: (customerMetrics['customer_acquisition_rate'] ?? 0.0).toDouble(),
        churnRate: (customerMetrics['churn_rate'] ?? 0.0).toDouble(),
        customerSegments: customerSegments,
        customerLifetimeValue: (customerMetrics['customer_lifetime_value'] ?? 0.0).toDouble(),
        avgOrdersPerCustomer: (customerMetrics['avg_orders_per_customer'] ?? 0.0).toDouble(),
        avgDaysBetweenOrders: (customerMetrics['avg_days_between_orders'] ?? 0.0).toDouble(),
        customerSatisfactionScore: (customerMetrics['customer_satisfaction_score'] ?? 0.0).toDouble(),
        ageDistribution: ageDistribution,
        locationDistribution: locationDistribution,
        conversionFunnel: conversionFunnel,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Cache the results
      if (useCache) {
        await _cacheData(
          restaurantId,
          'customer_analytics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}',
          analytics.toJson(),
        );
      }

      AppLogger.success('Advanced customer analytics loaded successfully');
      return analytics;
    } catch (e, stack) {
      AppLogger.error('Failed to get advanced customer analytics',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get advanced menu analytics
  Future<AdvancedMenuAnalytics> getAdvancedMenuAnalytics(
    String restaurantId, {
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    AppLogger.function('EnhancedAnalyticsService.getAdvancedMenuAnalytics', 'ENTER',
        params: {
          'restaurantId': restaurantId,
          'startDate': startDate,
          'endDate': endDate,
        });

    try {
      // Check cache first
      if (useCache) {
        final cachedData = await _getCachedData(
          restaurantId,
          'menu_analytics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}',
        );
        if (cachedData != null) {
          AppLogger.info('Menu analytics loaded from cache');
          return AdvancedMenuAnalytics.fromJson(cachedData);
        }
      }

      startDate ??= DateTime.now().subtract(const Duration(days: 30));
      endDate ??= DateTime.now();

      // Get menu performance metrics
      final menuMetrics = await _executeMenuAnalyticsQuery(
        restaurantId,
        startDate,
        endDate,
      );

      // Get item performance data
      final topPerformingItems = await _getTopPerformingItems(
        restaurantId,
        startDate,
        endDate,
      );

      final underperformingItems = await _getUnderperformingItems(
        restaurantId,
        startDate,
        endDate,
      );

      final trendingItems = await _getTrendingItems(
        restaurantId,
        startDate,
        endDate,
      );

      // Get category performance
      final categoryPerformance = await _getCategoryPerformance(
        restaurantId,
        startDate,
        endDate,
      );

      // Get optimization recommendations
      final optimizationRecommendations = await _getMenuOptimizationRecommendations(
        restaurantId,
        startDate,
        endDate,
      );

      final analytics = AdvancedMenuAnalytics(
        id: 'menu_analytics_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        startDate: startDate,
        endDate: endDate,
        totalMenuItems: menuMetrics['total_menu_items'] ?? 0,
        activeMenuItems: menuMetrics['active_menu_items'] ?? 0,
        avgItemPrice: (menuMetrics['avg_item_price'] ?? 0.0).toDouble(),
        menuRevenue: (menuMetrics['menu_revenue'] ?? 0.0).toDouble(),
        topPerformingItems: topPerformingItems,
        underperformingItems: underperformingItems,
        trendingItems: trendingItems,
        categoryPerformance: categoryPerformance,
        optimizationRecommendations: optimizationRecommendations,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Cache the results
      if (useCache) {
        await _cacheData(
          restaurantId,
          'menu_analytics_${startDate?.toIso8601String()}_${endDate?.toIso8601String()}',
          analytics.toJson(),
        );
      }

      AppLogger.success('Advanced menu analytics loaded successfully');
      return analytics;
    } catch (e, stack) {
      AppLogger.error('Failed to get advanced menu analytics',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get real-time metrics
  Future<RealTimeMetrics> getRealTimeMetrics(String restaurantId) async {
    AppLogger.function('EnhancedAnalyticsService.getRealTimeMetrics', 'ENTER',
        params: {'restaurantId': restaurantId});

    try {
      // Get current timestamp for the hour
      final now = DateTime.now();
      final hourStart = DateTime(now.year, now.month, now.day, now.hour);
      final dayStart = DateTime(now.year, now.month, now.day);

      // Execute real-time queries
      final data = await _supabase.rpc('get_real_time_metrics', params: {
        'p_restaurant_id': restaurantId,
        'p_hour_start': hourStart.toIso8601String(),
        'p_day_start': dayStart.toIso8601String(),
      });

      final metrics = RealTimeMetrics(
        id: 'real_time_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        metricTimestamp: DateTime.now(),
        activeOrders: data['active_orders'] ?? 0,
        pendingOrders: data['pending_orders'] ?? 0,
        preparingOrders: data['preparing_orders'] ?? 0,
        readyOrders: data['ready_orders'] ?? 0,
        currentDayRevenue: (data['current_day_revenue'] ?? 0.0).toDouble(),
        currentHourRevenue: (data['current_hour_revenue'] ?? 0.0).toDouble(),
        currentDayOrders: data['current_day_orders'] ?? 0,
        currentHourOrders: data['current_hour_orders'] ?? 0,
        currentAvgPrepTime: data['current_avg_prep_time'] ?? 0,
        currentAvgResponseTime: data['current_avg_response_time'] ?? 0,
        staffAvailable: data['staff_available'] ?? 0,
        queueLength: data['queue_length'] ?? 0,
        isAcceptingOrders: data['is_accepting_orders'] ?? true,
        kitchenCapacityUtilization: (data['kitchen_capacity_utilization'] ?? 0.0).toDouble(),
        createdAt: DateTime.now(),
      );

      AppLogger.success('Real-time metrics loaded successfully');
      return metrics;
    } catch (e, stack) {
      AppLogger.error('Failed to get real-time metrics', error: e, stack: stack);
      rethrow;
    }
  }

  /// Generate analytics report
  Future<AnalyticsReport> generateAnalyticsReport(
    String restaurantId, {
    required String reportName,
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
    Map<String, dynamic>? additionalParameters,
  }) async {
    AppLogger.function('EnhancedAnalyticsService.generateAnalyticsReport', 'ENTER',
        params: {
          'restaurantId': restaurantId,
          'reportName': reportName,
          'reportType': reportType,
        });

    try {
      // Generate report data based on type
      Map<String, dynamic> reportData = {};

      switch (reportType) {
        case 'comprehensive':
          reportData = await _generateComprehensiveReport(restaurantId, startDate, endDate);
          break;
        case 'revenue':
          final revenueAnalytics = await getAdvancedRevenueAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: false);
          reportData = revenueAnalytics.toJson();
          break;
        case 'customer':
          final customerAnalytics = await getAdvancedCustomerAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: false);
          reportData = customerAnalytics.toJson();
          break;
        case 'menu':
          final menuAnalytics = await getAdvancedMenuAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: false);
          reportData = menuAnalytics.toJson();
          break;
        case 'performance':
          reportData = await _generatePerformanceReport(restaurantId, startDate, endDate);
          break;
        default:
          throw ArgumentError('Unknown report type: $reportType');
      }

      final report = AnalyticsReport(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: restaurantId,
        reportName: reportName,
        reportType: reportType,
        dateRangeStart: startDate,
        dateRangeEnd: endDate,
        reportData: reportData,
        generatedAt: DateTime.now(),
        isScheduled: false,
        createdBy: _supabase.auth.currentUser?.id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save report to database
      await _supabase.from('analytics_reports').insert(report.toJson());

      AppLogger.success('Analytics report generated successfully');
      return report;
    } catch (e, stack) {
      AppLogger.error('Failed to generate analytics report', error: e, stack: stack);
      rethrow;
    }
  }

  /// Get predictive analytics
  Future<List<PredictiveAnalytics>> getPredictiveAnalytics(
    String restaurantId, {
    String? predictionType,
    int? horizon,
  }) async {
    AppLogger.function('EnhancedAnalyticsService.getPredictiveAnalytics', 'ENTER',
        params: {
          'restaurantId': restaurantId,
          'predictionType': predictionType,
          'horizon': horizon,
        });

    try {
      final query = _supabase
          .from('predictive_analytics')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .gte('prediction_date', DateTime.now().toIso8601String())
          .order('prediction_date', ascending: true);

      if (predictionType != null) {
        query.eq('prediction_type', predictionType);
      }
      if (horizon != null) {
        query.eq('prediction_horizon', horizon);
      }

      final data = await query;
      final predictions = data
          .map((json) => PredictiveAnalytics.fromJson(json))
          .toList();

      AppLogger.success('Predictive analytics loaded successfully');
      return predictions;
    } catch (e, stack) {
      AppLogger.error('Failed to get predictive analytics', error: e, stack: stack);
      rethrow;
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _executeRevenueAnalyticsQuery(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_revenue_analytics', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, dynamic>.from(data);
  }

  Future<List<DailyRevenueData>> _getDailyRevenueData(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_daily_revenue_data', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return (data as List)
        .map((json) => DailyRevenueData.fromJson(json))
        .toList();
  }

  Future<List<WeeklyRevenueData>> _getWeeklyRevenueData(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_weekly_revenue_data', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return (data as List)
        .map((json) => WeeklyRevenueData.fromJson(json))
        .toList();
  }

  Future<List<MonthlyRevenueData>> _getMonthlyRevenueData(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_monthly_revenue_data', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return (data as List)
        .map((json) => MonthlyRevenueData.fromJson(json))
        .toList();
  }

  Future<Map<String, double>> _getRevenueByCategory(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_revenue_by_category', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, double>.from(data);
  }

  Future<Map<String, double>> _getRevenueByPaymentMethod(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_revenue_by_payment_method', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, double>.from(data);
  }

  Future<Map<String, double>> _getRevenueByTimeOfDay(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_revenue_by_time_of_day', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, double>.from(data);
  }

  Future<Map<String, double>> _getRevenueByDayOfWeek(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_revenue_by_day_of_week', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, double>.from(data);
  }

  Future<RevenueForecast> _getRevenueForecast(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_revenue_forecast', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return RevenueForecast.fromJson(data);
  }

  Future<Map<String, dynamic>> _executeCustomerAnalyticsQuery(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_customer_analytics', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, dynamic>.from(data);
  }

  Future<List<CustomerSegment>> _getCustomerSegments(String restaurantId) async {
    final data = await _supabase
        .from('customer_segments')
        .select('*')
        .eq('restaurant_id', restaurantId)
        .order('score', ascending: false);

    return (data as List)
        .map((json) => CustomerSegment.fromJson(json))
        .toList();
  }

  Future<ConversionFunnel> _getConversionFunnel(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_conversion_funnel', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return ConversionFunnel.fromJson(data);
  }

  Future<Map<String, int>> _getAgeDistribution(String restaurantId) async {
    final data = await _supabase.rpc('get_customer_age_distribution', params: {
      'p_restaurant_id': restaurantId,
    });

    return Map<String, int>.from(data);
  }

  Future<Map<String, int>> _getLocationDistribution(String restaurantId) async {
    final data = await _supabase.rpc('get_customer_location_distribution', params: {
      'p_restaurant_id': restaurantId,
    });

    return Map<String, int>.from(data);
  }

  Future<Map<String, dynamic>> _executeMenuAnalyticsQuery(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_menu_analytics', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, dynamic>.from(data);
  }

  Future<List<MenuItemPerformance>> _getTopPerformingItems(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_top_performing_menu_items', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
      'p_limit': 10,
    });

    return (data as List)
        .map((json) => MenuItemPerformance.fromJson(json))
        .toList();
  }

  Future<List<MenuItemPerformance>> _getUnderperformingItems(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_underperforming_menu_items', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
      'p_limit': 10,
    });

    return (data as List)
        .map((json) => MenuItemPerformance.fromJson(json))
        .toList();
  }

  Future<List<MenuItemPerformance>> _getTrendingItems(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_trending_menu_items', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
      'p_limit': 10,
    });

    return (data as List)
        .map((json) => MenuItemPerformance.fromJson(json))
        .toList();
  }

  Future<Map<String, CategoryPerformance>> _getCategoryPerformance(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_category_performance', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    final Map<String, CategoryPerformance> result = {};
    for (final item in data) {
      final category = CategoryPerformance.fromJson(item);
      result[category.name] = category;
    }
    return result;
  }

  Future<List<MenuOptimizationRecommendation>> _getMenuOptimizationRecommendations(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_menu_optimization_recommendations', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return (data as List)
        .map((json) => MenuOptimizationRecommendation.fromJson(json))
        .toList();
  }

  Future<Map<String, dynamic>> _generateComprehensiveReport(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Get all analytics data
    final revenueAnalytics = await getAdvancedRevenueAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: false);
    final customerAnalytics = await getAdvancedCustomerAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: false);
    final menuAnalytics = await getAdvancedMenuAnalytics(restaurantId, startDate: startDate, endDate: endDate, useCache: false);

    return {
      'revenue_analytics': revenueAnalytics.toJson(),
      'customer_analytics': customerAnalytics.toJson(),
      'menu_analytics': menuAnalytics.toJson(),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _generatePerformanceReport(
    String restaurantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final data = await _supabase.rpc('get_performance_report', params: {
      'p_restaurant_id': restaurantId,
      'p_start_date': startDate.toIso8601String(),
      'p_end_date': endDate.toIso8601String(),
    });

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>?> _getCachedData(
    String restaurantId,
    String cacheKey,
  ) async {
    try {
      final data = await _supabase
          .from('analytics_cache')
          .select('cache_data')
          .eq('restaurant_id', restaurantId)
          .eq('cache_key', cacheKey)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      return data?['cache_data'] != null ? jsonDecode(data!['cache_data']) : null;
    } catch (e) {
      AppLogger.warning('Failed to get cached data', error: e);
      return null;
    }
  }

  Future<void> _cacheData(
    String restaurantId,
    String cacheKey,
    Map<String, dynamic> data,
  ) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(minutes: 30));

      await _supabase.from('analytics_cache').upsert({
        'restaurant_id': restaurantId,
        'cache_key': cacheKey,
        'cache_data': jsonEncode(data),
        'expires_at': expiresAt.toIso8601String(),
      });
    } catch (e) {
      AppLogger.warning('Failed to cache data', error: e);
    }
  }

  /// Clear cache for a restaurant
  Future<void> clearCache(String restaurantId) async {
    try {
      await _supabase
          .from('analytics_cache')
          .delete()
          .eq('restaurant_id', restaurantId);

      AppLogger.info('Analytics cache cleared for restaurant: $restaurantId');
    } catch (e) {
      AppLogger.error('Failed to clear analytics cache', error: e);
    }
  }

  /// Get performance benchmarks for comparison
  Future<Map<String, dynamic>> getPerformanceBenchmarks({
    String? industry,
    String? cuisineType,
    String? region,
  }) async {
    AppLogger.function('EnhancedAnalyticsService.getPerformanceBenchmarks', 'ENTER');

    try {
      final query = _supabase
          .from('performance_benchmarks')
          .select('*')
          .order('benchmark_date', ascending: false)
          .limit(1);

      if (industry != null) query.eq('industry', industry);
      if (cuisineType != null) query.eq('cuisine_type', cuisineType);
      if (region != null) query.eq('region', region);

      final data = await query.maybeSingle();
      return data ?? {};
    } catch (e, stack) {
      AppLogger.error('Failed to get performance benchmarks', error: e, stack: stack);
      return {};
    }
  }

  /// Update real-time metrics
  Future<void> updateRealTimeMetrics(String restaurantId) async {
    AppLogger.function('EnhancedAnalyticsService.updateRealTimeMetrics', 'ENTER',
        params: {'restaurantId': restaurantId});

    try {
      await _supabase.rpc('update_real_time_metrics', params: {
        'p_restaurant_id': restaurantId,
      });

      AppLogger.success('Real-time metrics updated');
    } catch (e, stack) {
      AppLogger.error('Failed to update real-time metrics', error: e, stack: stack);
    }
  }

  /// Stream real-time metrics updates
  Stream<RealTimeMetrics> streamRealTimeMetrics(String restaurantId) {
    return _supabase
        .from('real_time_metrics')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', restaurantId)
        .order('metric_timestamp', ascending: false)
        .limit(1)
        .map((event) {
          final data = event.first;
          return RealTimeMetrics.fromJson(data);
        });
  }
}