import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/core/services/order_service.dart';
import 'package:food_delivery_app/shared/models/order.dart';

/// Restaurant orders state
class RestaurantOrdersState {
  final List<Order> orders;
  final bool isLoading;
  final String? error;
  final String? selectedStatusFilter;
  final String? selectedDateFilter;

  RestaurantOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
    this.selectedStatusFilter,
    this.selectedDateFilter,
  });

  RestaurantOrdersState copyWith({
    List<Order>? orders,
    bool? isLoading,
    String? error,
    String? selectedStatusFilter,
    String? selectedDateFilter,
  }) {
    return RestaurantOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedStatusFilter: selectedStatusFilter ?? this.selectedStatusFilter,
      selectedDateFilter: selectedDateFilter ?? this.selectedDateFilter,
    );
  }
}

/// Restaurant orders notifier
class RestaurantOrdersNotifier extends StateNotifier<RestaurantOrdersState> {
  final OrderService _orderService;

  RestaurantOrdersNotifier(this._orderService) : super(RestaurantOrdersState());

  /// Load restaurant orders
  Future<void> loadOrders({
    OrderStatus? statusFilter,
    String? dateFilter,
    String? restaurantId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Get restaurant ID from user context or pass as parameter
      // For now, we need to implement getting the restaurant ID
      final targetRestaurantId = restaurantId ?? 'default-restaurant-id'; // Replace with actual logic

      final orders = await _orderService.getRestaurantOrders(
        targetRestaurantId,
        status: statusFilter,
        dateFilter: dateFilter,
        limit: 50,
      );

      state = state.copyWith(
        orders: orders,
        isLoading: false,
        selectedStatusFilter: statusFilter?.toString().split('.').last,
        selectedDateFilter: dateFilter,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load orders: ${e.toString()}',
      );
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final success = await _orderService.updateOrderStatus(orderId, status);

      if (success) {
        // Update local state to reflect the change immediately
        final updatedOrders = state.orders.map((order) {
          if (order.id == orderId) {
            return order.copyWith(status: status);
          }
          return order;
        }).toList();

        state = state.copyWith(orders: updatedOrders);
      } else {
        state = state.copyWith(error: 'Failed to update order status');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update order status: ${e.toString()}');
    }
  }

  /// Get order by ID
  Order? getOrderById(String orderId) {
    try {
      return state.orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Get orders by status
  List<Order> getOrdersByStatus(OrderStatus status) {
    return state.orders.where((order) => order.status == status).toList();
  }

  /// Refresh orders
  Future<void> refreshOrders() async {
    await loadOrders(
      statusFilter: state.selectedStatusFilter != null
          ? OrderStatus.values.firstWhere(
              (s) => s.toString().split('.').last == state.selectedStatusFilter,
            )
          : null,
      dateFilter: state.selectedDateFilter,
    );
  }

  /// Update payment status
  Future<void> updatePaymentStatus(String orderId, PaymentStatus status) async {
    try {
      final success = await _orderService.updatePaymentStatus(orderId, status);

      if (success) {
        // Update local state to reflect the change immediately
        final updatedOrders = state.orders.map((order) {
          if (order.id == orderId) {
            return order.copyWith(paymentStatus: status);
          }
          return order;
        }).toList();

        state = state.copyWith(orders: updatedOrders);
      } else {
        state = state.copyWith(error: 'Failed to update payment status');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update payment status: ${e.toString()}');
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      final success = await _orderService.cancelOrder(orderId, reason: reason);

      if (success) {
        await refreshOrders(); // Refresh to get the updated status
      } else {
        state = state.copyWith(error: 'Failed to cancel order');
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel order: ${e.toString()}');
    }
  }

  /// Clear orders
  void clearOrders() {
    state = RestaurantOrdersState();
  }
}

/// Restaurant orders provider
final restaurantOrdersProvider =
    StateNotifierProvider<RestaurantOrdersNotifier, RestaurantOrdersState>(
  (ref) {
    final orderService = ref.watch(orderServiceProvider);
    return RestaurantOrdersNotifier(orderService);
  },
);

/// Provider for orders filtered by role
final filteredOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(restaurantOrdersProvider).orders;
  final userRole = ref.watch(primaryRoleProvider);

  // Implement role-based filtering logic
  switch (userRole) {
    case 'restaurant_owner':
      // Restaurant owners see all their orders
      return orders;
    case 'driver':
      // Drivers see orders ready for pickup or in delivery
      return orders.where((order) =>
        order.status == OrderStatus.ready_for_pickup ||
        order.status == OrderStatus.confirmed
      ).toList();
    case 'admin':
      // Admins see all orders
      return orders;
    case 'consumer':
    default:
      // Consumers shouldn't see restaurant orders
      return [];
  }
});

/// Provider for orders count by status
final ordersCountByStatusProvider = Provider<Map<String, int>>((ref) {
  final orders = ref.watch(restaurantOrdersProvider).orders;

  final Map<String, int> countByStatus = {};

  for (final status in OrderStatus.values) {
    countByStatus[status.toString().split('.').last] =
        orders.where((order) => order.status == status).length;
  }

  return countByStatus;
});