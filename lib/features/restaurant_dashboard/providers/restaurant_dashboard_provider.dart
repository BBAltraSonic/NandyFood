import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/realtime_service.dart';
import 'package:food_delivery_app/core/services/notification_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/restaurant_analytics.dart';

/// Dashboard state class
class RestaurantDashboardState {
  final Restaurant? restaurant;
  final List<Order> recentOrders;
  final List<Order> pendingOrders;
  final RestaurantAnalytics? analytics;
  final DashboardMetrics? metrics;
  final bool isLoading;
  final String? error;

  RestaurantDashboardState({
    this.restaurant,
    this.recentOrders = const [],
    this.pendingOrders = const [],
    this.analytics,
    this.metrics,
    this.isLoading = false,
    this.error,
  });

  RestaurantDashboardState copyWith({
    Restaurant? restaurant,
    List<Order>? recentOrders,
    List<Order>? pendingOrders,
    RestaurantAnalytics? analytics,
    DashboardMetrics? metrics,
    bool? isLoading,
    String? error,
  }) {
    return RestaurantDashboardState(
      restaurant: restaurant ?? this.restaurant,
      recentOrders: recentOrders ?? this.recentOrders,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      analytics: analytics ?? this.analytics,
      metrics: metrics ?? this.metrics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Dashboard notifier
class RestaurantDashboardNotifier
    extends StateNotifier<RestaurantDashboardState> {
  RestaurantDashboardNotifier(
    this._restaurantId,
    this._realtimeService,
    this._notificationService,
  ) : super(RestaurantDashboardState()) {
    _service = RestaurantManagementService();
    loadDashboardData();
    _subscribeToRealtimeUpdates();
  }

  final String _restaurantId;
  final RealtimeService _realtimeService;
  final NotificationService _notificationService;
  late final RestaurantManagementService _service;
  
  StreamSubscription<Map<String, dynamic>>? _orderSubscription;
  StreamSubscription<Map<String, dynamic>>? _restaurantSubscription;

  /// Load all dashboard data
  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load data in parallel
      final results = await Future.wait([
        _service.getRestaurant(_restaurantId),
        _service.getDashboardMetrics(_restaurantId),
        _service.getRestaurantOrders(
          _restaurantId,
          status: 'pending',
        ),
        _service.getRestaurantOrders(
          _restaurantId,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);

      state = RestaurantDashboardState(
        restaurant: results[0] as Restaurant?,
        metrics: results[1] as DashboardMetrics?,
        pendingOrders: results[2] as List<Order>,
        recentOrders: results[3] as List<Order>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data: ${e.toString()}',
      );
    }
  }

  /// Refresh orders only
  Future<void> refreshOrders() async {
    try {
      final results = await Future.wait([
        _service.getRestaurantOrders(
          _restaurantId,
          status: 'pending',
        ),
        _service.getRestaurantOrders(
          _restaurantId,
          startDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ]);

      state = state.copyWith(
        pendingOrders: results[0] as List<Order>,
        recentOrders: results[1] as List<Order>,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to refresh orders: ${e.toString()}',
      );
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _service.updateOrderStatus(orderId, status);
      await refreshOrders();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update order status: ${e.toString()}',
      );
      return false;
    }
  }

  /// Accept order with prep time
  Future<bool> acceptOrder(String orderId, int prepTimeMinutes) async {
    try {
      await _service.acceptOrder(orderId, prepTimeMinutes);
      await refreshOrders();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to accept order: ${e.toString()}',
      );
      return false;
    }
  }

  /// Reject order with reason
  Future<bool> rejectOrder(String orderId, String reason) async {
    try {
      await _service.rejectOrder(orderId, reason);
      await refreshOrders();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to reject order: ${e.toString()}',
      );
      return false;
    }
  }

  /// Toggle accepting orders
  Future<void> toggleAcceptingOrders() async {
    if (state.restaurant == null) return;

    try {
      final newStatus = !state.restaurant!.isActive;
      await _service.toggleAcceptingOrders(_restaurantId, newStatus);

      // Update local state
      state = state.copyWith(
        restaurant: state.restaurant!.copyWith(
          isActive: newStatus,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to toggle order acceptance: ${e.toString()}',
      );
    }
  }

  /// Refresh dashboard metrics
  Future<void> refreshMetrics() async {
    try {
      final metrics = await _service.getDashboardMetrics(_restaurantId);
      state = state.copyWith(metrics: metrics);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to refresh metrics: ${e.toString()}',
      );
    }
  }

  /// Load analytics for a date range
  Future<void> loadAnalytics(DateTime startDate, DateTime endDate) async {
    try {
      final analyticsData = await _service.getAnalytics(
        _restaurantId,
        startDate,
        endDate,
      );

      if (analyticsData.isNotEmpty) {
        // Get the most recent analytics
        state = state.copyWith(analytics: analyticsData.first);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load analytics: ${e.toString()}',
      );
    }
  }

  /// Subscribe to real-time updates
  void _subscribeToRealtimeUpdates() {
    // Subscribe to restaurant orders
    _orderSubscription = _realtimeService
        .subscribeToRestaurantOrders(_restaurantId)
        .listen(_handleOrderUpdate);

    // Subscribe to restaurant changes
    _restaurantSubscription = _realtimeService
        .subscribeToRestaurant(_restaurantId)
        .listen(_handleRestaurantUpdate);
  }

  /// Handle real-time order updates
  void _handleOrderUpdate(Map<String, dynamic> data) {
    try {
      final order = Order.fromJson(data);
      
      // Update pending orders if new order
      if (order.status == 'pending' || order.status == 'placed') {
        final updatedPending = [...state.pendingOrders];
        final existingIndex = updatedPending.indexWhere((o) => o.id == order.id);
        
        if (existingIndex >= 0) {
          updatedPending[existingIndex] = order;
        } else {
          updatedPending.insert(0, order);
          // Show notification for new order
          final customerAddress = order.deliveryAddress['name'] as String? ?? 'Customer';
          _notificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
            title: 'New Order Received!',
            body: 'Order from $customerAddress for ${order.total.toStringAsFixed(2)}',
            payload: 'order:${order.id}',
          );
        }
        
        state = state.copyWith(pendingOrders: updatedPending);
      }
      
      // Update recent orders
      final updatedRecent = [...state.recentOrders];
      final recentIndex = updatedRecent.indexWhere((o) => o.id == order.id);
      
      if (recentIndex >= 0) {
        updatedRecent[recentIndex] = order;
      } else if (updatedRecent.length < 10) {
        updatedRecent.insert(0, order);
      }
      
      state = state.copyWith(recentOrders: updatedRecent);
      
      // Refresh metrics on order changes
      refreshMetrics();
    } catch (e) {
      // Silently fail - don't disrupt the UI
      print('Error handling order update: $e');
    }
  }

  /// Handle real-time restaurant updates
  void _handleRestaurantUpdate(Map<String, dynamic> data) {
    try {
      final restaurant = Restaurant.fromJson(data);
      state = state.copyWith(restaurant: restaurant);
    } catch (e) {
      print('Error handling restaurant update: $e');
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
  
  @override
  void dispose() {
    _orderSubscription?.cancel();
    _restaurantSubscription?.cancel();
    super.dispose();
  }
}

/// Dashboard provider factory
final restaurantDashboardProvider = StateNotifierProvider.family<
    RestaurantDashboardNotifier,
    RestaurantDashboardState,
    String>(
  (ref, restaurantId) {
    final realtimeService = ref.watch(realtimeServiceProvider);
    final notificationService = NotificationService();
    
    return RestaurantDashboardNotifier(
      restaurantId,
      realtimeService,
      notificationService,
    );
  },
);

/// Helper provider to get pending orders count
final pendingOrdersCountProvider = Provider.family<int, String>((ref, restaurantId) {
  final dashboardState = ref.watch(restaurantDashboardProvider(restaurantId));
  return dashboardState.pendingOrders.length;
});

/// Helper provider to check if restaurant is accepting orders
final isAcceptingOrdersProvider = Provider.family<bool, String>((ref, restaurantId) {
  final dashboardState = ref.watch(restaurantDashboardProvider(restaurantId));
  return dashboardState.restaurant?.isActive ?? false;
});
