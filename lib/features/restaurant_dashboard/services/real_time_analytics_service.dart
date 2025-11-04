import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/enhanced_analytics.dart';

/// Real-time Analytics Service for live restaurant metrics
class RealTimeAnalyticsService {
  final SupabaseClient _supabase;
  Timer? _updateTimer;
  final Map<String, Stream<RealTimeMetrics>> _metricsStreams = {};

  RealTimeAnalyticsService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Start real-time monitoring for a restaurant
  void startRealTimeMonitoring(String restaurantId) {
    AppLogger.info('Starting real-time monitoring for restaurant: $restaurantId');

    // Cancel any existing timer
    stopRealTimeMonitoring(restaurantId);

    // Set up periodic updates every 30 seconds
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateRealTimeMetrics(restaurantId);
    });

    // Initial update
    _updateRealTimeMetrics(restaurantId);
  }

  /// Stop real-time monitoring for a restaurant
  void stopRealTimeMonitoring(String restaurantId) {
    AppLogger.info('Stopping real-time monitoring for restaurant: $restaurantId');

    _updateTimer?.cancel();
    _updateTimer = null;

    // Remove stream
    _metricsStreams.remove(restaurantId);
  }

  /// Get real-time metrics stream for a restaurant
  Stream<RealTimeMetrics> getRealTimeMetricsStream(String restaurantId) {
    if (!_metricsStreams.containsKey(restaurantId)) {
      _metricsStreams[restaurantId] = _createRealTimeStream(restaurantId);
    }
    return _metricsStreams[restaurantId]!;
  }

  /// Create real-time stream using Supabase Realtime
  Stream<RealTimeMetrics> _createRealTimeStream(String restaurantId) {
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

  /// Update real-time metrics for a restaurant
  Future<void> _updateRealTimeMetrics(String restaurantId) async {
    try {
      await _supabase.rpc('update_real_time_metrics', params: {
        'p_restaurant_id': restaurantId,
      });

      AppLogger.debug('Real-time metrics updated for restaurant: $restaurantId');
    } catch (e, stack) {
      AppLogger.error('Failed to update real-time metrics', error: e, stack: stack);
    }
  }

  /// Get current real-time metrics
  Future<RealTimeMetrics?> getCurrentMetrics(String restaurantId) async {
    try {
      final data = await _supabase
          .from('real_time_metrics')
          .select('*')
          .eq('restaurant_id', restaurantId)
          .order('metric_timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      return data != null ? RealTimeMetrics.fromJson(data) : null;
    } catch (e, stack) {
      AppLogger.error('Failed to get current real-time metrics', error: e, stack: stack);
      return null;
    }
  }

  /// Get performance alerts based on real-time metrics
  Future<List<PerformanceAlert>> getPerformanceAlerts(String restaurantId) async {
    final metrics = await getCurrentMetrics(restaurantId);
    if (metrics == null) return [];

    final alerts = <PerformanceAlert>[];

    // Check queue length
    if (metrics.hasLongQueue) {
      alerts.add(PerformanceAlert(
        id: 'long_queue_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertType.warning,
        title: 'Long Queue Detected',
        message: 'Queue length is ${metrics.queueLength} orders. Consider increasing staff capacity.',
        restaurantId: restaurantId,
        timestamp: DateTime.now(),
        metrics: metrics.toJson(),
      ));
    }

    // Check kitchen capacity
    if (metrics.isAtCapacity) {
      alerts.add(PerformanceAlert(
        id: 'kitchen_capacity_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertType.critical,
        title: 'Kitchen at Full Capacity',
        message: 'Kitchen utilization is at ${metrics.kitchenCapacityUtilization.toStringAsFixed(1)}%. Orders may be delayed.',
        restaurantId: restaurantId,
        timestamp: DateTime.now(),
        metrics: metrics.toJson(),
      ));
    }

    // Check preparation time
    if (metrics.currentAvgPrepTime > 25) {
      alerts.add(PerformanceAlert(
        id: 'prep_time_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertType.warning,
        title: 'High Preparation Time',
        message: 'Average preparation time is ${metrics.currentAvgPrepTime} minutes. Check kitchen efficiency.',
        restaurantId: restaurantId,
        timestamp: DateTime.now(),
        metrics: metrics.toJson(),
      ));
    }

    // Check order acceptance status
    if (!metrics.isAcceptingOrders) {
      alerts.add(PerformanceAlert(
        id: 'orders_paused_${DateTime.now().millisecondsSinceEpoch}',
        type: AlertType.info,
        title: 'Order Acceptance Paused',
        message: 'Orders are currently not being accepted. Check if this is intentional.',
        restaurantId: restaurantId,
        timestamp: DateTime.now(),
        metrics: metrics.toJson(),
      ));
    }

    return alerts;
  }

  /// Get hourly performance trends
  Future<List<HourlyPerformance>> getHourlyPerformance(
    String restaurantId,
    DateTime date,
  ) async {
    try {
      final data = await _supabase.rpc('get_hourly_performance', params: {
        'p_restaurant_id': restaurantId,
        'p_date': date.toIso8601String(),
      });

      return (data as List)
          .map((json) => HourlyPerformance.fromJson(json))
          .toList();
    } catch (e, stack) {
      AppLogger.error('Failed to get hourly performance', error: e, stack: stack);
      return [];
    }
  }

  /// Get live order status distribution
  Future<Map<String, int>> getLiveOrderStatusDistribution(String restaurantId) async {
    final metrics = await getCurrentMetrics(restaurantId);
    if (metrics == null) return {};

    return {
      'pending': metrics.pendingOrders,
      'confirmed': metrics.activeOrders - metrics.preparingOrders - metrics.readyOrders,
      'preparing': metrics.preparingOrders,
      'ready': metrics.readyOrders,
    };
  }

  /// Get revenue velocity (revenue per hour)
  Future<double> getRevenueVelocity(String restaurantId) async {
    final metrics = await getCurrentMetrics(restaurantId);
    return metrics?.revenuePerHour ?? 0.0;
  }

  /// Dispose of resources
  void dispose() {
    _updateTimer?.cancel();
    _metricsStreams.clear();
  }
}

/// Performance Alert Model
class PerformanceAlert {
  final String id;
  final AlertType type;
  final String title;
  final String message;
  final String restaurantId;
  final DateTime timestamp;
  final Map<String, dynamic>? metrics;

  PerformanceAlert({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.restaurantId,
    required this.timestamp,
    this.metrics,
  });

  factory PerformanceAlert.fromJson(Map<String, dynamic> json) {
    return PerformanceAlert(
      id: json['id'],
      type: AlertType.values.firstWhere(
        (e) => e.toString() == 'AlertType.${json['type']}',
        orElse: () => AlertType.info,
      ),
      title: json['title'],
      message: json['message'],
      restaurantId: json['restaurant_id'],
      timestamp: DateTime.parse(json['timestamp']),
      metrics: json['metrics'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'restaurant_id': restaurantId,
      'timestamp': timestamp.toIso8601String(),
      'metrics': metrics,
    };
  }

  Color get color {
    switch (type) {
      case AlertType.critical:
        return Colors.red;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return Colors.blue;
      case AlertType.success:
        return Colors.green;
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.critical:
        return Icons.error;
      case AlertType.warning:
        return Icons.warning;
      case AlertType.info:
        return Icons.info;
      case AlertType.success:
        return Icons.check_circle;
    }
  }
}

enum AlertType {
  critical,
  warning,
  info,
  success,
}

/// Hourly Performance Model
class HourlyPerformance {
  final DateTime hour;
  final int orders;
  final double revenue;
  final double avgPrepTime;
  final int staffActive;
  final double customerSatisfaction;

  HourlyPerformance({
    required this.hour,
    required this.orders,
    required this.revenue,
    required this.avgPrepTime,
    required this.staffActive,
    required this.customerSatisfaction,
  });

  factory HourlyPerformance.fromJson(Map<String, dynamic> json) {
    return HourlyPerformance(
      hour: DateTime.parse(json['hour']),
      orders: json['orders'],
      revenue: json['revenue']?.toDouble() ?? 0.0,
      avgPrepTime: json['avg_prep_time'] ?? 0,
      staffActive: json['staff_active'] ?? 0,
      customerSatisfaction: json['customer_satisfaction']?.toDouble() ?? 0.0,
    );
  }

  double get ordersPerHour => orders.toDouble();
  double get revenuePerHour => revenue;
  double get efficiency => staffActive > 0 ? orders / staffActive : 0.0;
}