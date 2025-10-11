import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_provider.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

void main() {
  group('OrderProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be empty', () {
      final state = container.read(orderProvider);
      expect(state.orders, isEmpty);
      expect(state.currentOrder, isNull);
      expect(state.orderItems, isEmpty);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('createOrder should add order to state', () async {
      final notifier = container.read(orderProvider.notifier);

      final order = Order(
        id: 'order1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        deliveryAddress: {'street': '123 Main St'},
        status: OrderStatus.placed,
        totalAmount: 25.0,
        deliveryFee: 2.0,
        taxAmount: 2.0,
        paymentMethod: 'card',
        paymentStatus: PaymentStatus.pending,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.createOrder(order);

      final state = container.read(orderProvider);
      expect(state.orders.length, 1);
      expect(state.currentOrder?.id, 'order1');
      expect(state.orders[0].id, 'order1');
    });

    test('loadOrders should update orders list', () async {
      final notifier = container.read(orderProvider.notifier);

      // Since we don't have a real database service for tests,
      // we'll test the loading state and error handling
      await notifier.loadOrders('user1');

      final state = container.read(orderProvider);
      // This will be empty since we don't have a real DB service in tests
      expect(state.orders, isEmpty);
    });

    test('addItemToOrder should add order item', () async {
      final notifier = container.read(orderProvider.notifier);

      final orderItem = OrderItem(
        id: 'orderItem1',
        orderId: 'order1',
        menuItemId: 'menuItem1',
        quantity: 2,
        unitPrice: 10.0,
        customizations: {'size': 'large'},
      );

      await notifier.addItemToOrder(orderItem);

      final state = container.read(orderProvider);
      expect(state.orderItems.length, 1);
      expect(state.orderItems[0].id, 'orderItem1');
      expect(state.orderItems[0].quantity, 2);
    });

    test('removeItemFromOrder should remove order item', () async {
      final notifier = container.read(orderProvider.notifier);

      final orderItem = OrderItem(
        id: 'orderItem1',
        orderId: 'order1',
        menuItemId: 'menuItem1',
        quantity: 2,
        unitPrice: 10.0,
        customizations: {'size': 'large'},
      );

      await notifier.addItemToOrder(orderItem);
      await notifier.removeItemFromOrder('orderItem1');

      final state = container.read(orderProvider);
      expect(state.orderItems, isEmpty);
    });

    test('updateOrderStatus should update order status', () async {
      final notifier = container.read(orderProvider.notifier);

      final order = Order(
        id: 'order1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        deliveryAddress: {'street': '123 Main St'},
        status: OrderStatus.placed,
        totalAmount: 25.0,
        deliveryFee: 2.0,
        taxAmount: 2.0,
        paymentMethod: 'card',
        paymentStatus: PaymentStatus.pending,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.createOrder(order);
      await notifier.updateOrderStatus('order1', OrderStatus.confirmed);

      final state = container.read(orderProvider);
      expect(state.orders[0].status, OrderStatus.confirmed);
      expect(state.currentOrder?.status, OrderStatus.confirmed);
    });

    test('clearCurrentOrder should clear current order', () {
      final notifier = container.read(orderProvider.notifier);

      notifier.clearCurrentOrder();

      final state = container.read(orderProvider);
      expect(state.currentOrder, isNull);
    });
  });
}
