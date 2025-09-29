import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

// Order state class to represent the order state
class OrderState {
  final List<Order> orders;
  final Order? currentOrder;
  final List<OrderItem> orderItems;
  final bool isLoading;
  final String? errorMessage;

  OrderState({
    this.orders = const [],
    this.currentOrder,
    this.orderItems = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  OrderState copyWith({
    List<Order>? orders,
    Order? currentOrder,
    List<OrderItem>? orderItems,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      currentOrder: currentOrder ?? this.currentOrder,
      orderItems: orderItems ?? this.orderItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Order provider to manage order state
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(),
);

class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier() : super(OrderState());

  // Load user orders from the database
  Future<void> loadOrders(String userId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final dbService = DatabaseService();
      final orderData = await dbService.getUserOrders(userId);
      
      final orders = orderData.map((data) => Order.fromJson(data)).toList();
      
      state = state.copyWith(
        orders: orders,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Create a new order
  Future<void> createOrder(Order order) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final dbService = DatabaseService();
      final orderData = order.toJson();
      final orderId = await dbService.createOrder(orderData);
      
      final newOrder = order.copyWith(id: orderId);
      
      state = state.copyWith(
        currentOrder: newOrder,
        orders: [...state.orders, newOrder],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Add an item to the current order
  Future<void> addItemToOrder(OrderItem item) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      final updatedItems = [...state.orderItems, item];
      state = state.copyWith(
        orderItems: updatedItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Remove an item from the current order
  Future<void> removeItemFromOrder(String itemId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      final updatedItems = state.orderItems.where((item) => item.id != itemId).toList();
      state = state.copyWith(
        orderItems: updatedItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 200));
      
      final updatedOrders = state.orders.map((order) {
        if (order.id == orderId) {
          return order.copyWith(status: status);
        }
        return order;
      }).toList();
      
      final updatedCurrentOrder = state.currentOrder?.id == orderId 
          ? state.currentOrder!.copyWith(status: status)
          : state.currentOrder;
      
      state = state.copyWith(
        orders: updatedOrders,
        currentOrder: updatedCurrentOrder,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Clear current order
  void clearCurrentOrder() {
    state = state.copyWith(currentOrder: null, orderItems: const []);
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}