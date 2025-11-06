import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';

/// Restaurant orders state
class RestaurantOrdersState {
  final List<Map<String, dynamic>> orders;
  final bool isLoading;
  final String? error;

  RestaurantOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.error,
  });

  RestaurantOrdersState copyWith({
    List<Map<String, dynamic>>? orders,
    bool? isLoading,
    String? error,
  }) {
    return RestaurantOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Restaurant orders notifier
class RestaurantOrdersNotifier extends StateNotifier<RestaurantOrdersState> {
  RestaurantOrdersNotifier() : super(RestaurantOrdersState());

  /// Load restaurant orders
  Future<void> loadOrders() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implement actual orders loading logic
      // For now, return mock data
      final mockOrders = [
        {
          'id': '1',
          'customerName': 'John Doe',
          'items': [{'name': 'Burger', 'quantity': 2}],
          'total': 25.99,
          'status': 'pending',
          'createdAt': DateTime.now().toIso8601String(),
        },
        {
          'id': '2',
          'customerName': 'Jane Smith',
          'items': [{'name': 'Pizza', 'quantity': 1}],
          'total': 18.50,
          'status': 'preparing',
          'createdAt': DateTime.now().toIso8601String(),
        },
      ];

      state = state.copyWith(
        orders: mockOrders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load orders: ${e.toString()}',
      );
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      // TODO: Implement actual order status update logic
      final updatedOrders = state.orders.map((order) {
        if (order['id'] == orderId) {
          return {...order, 'status': status};
        }
        return order;
      }).toList();

      state = state.copyWith(orders: updatedOrders);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update order status: ${e.toString()}');
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
  (ref) => RestaurantOrdersNotifier(),
);

/// Provider for orders filtered by role
final filteredOrdersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final orders = ref.watch(restaurantOrdersProvider).orders;
  final userRole = ref.watch(primaryRoleProvider);

  // TODO: Implement role-based filtering logic
  return orders;
});