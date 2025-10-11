import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/place_order_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/order.dart';

void main() {
  group('Day 15 - Checkout Flow with Tip and Confirmation Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Should set tip amount to 10% of subtotal', () {
      final cartNotifier = container.read(cartProvider.notifier);
      
      // Set a subtotal by adding items
      const subtotal = 100.0;
      cartNotifier.setTipAmount(subtotal * 0.10);

      final cartState = container.read(cartProvider);
      expect(cartState.tipAmount, equals(10.0));
    });

    test('Should set tip amount to 15% of subtotal', () {
      final cartNotifier = container.read(cartProvider.notifier);
      
      const subtotal = 100.0;
      cartNotifier.setTipAmount(subtotal * 0.15);

      final cartState = container.read(cartProvider);
      expect(cartState.tipAmount, equals(15.0));
    });

    test('Should set tip amount to 20% of subtotal', () {
      final cartNotifier = container.read(cartProvider.notifier);
      
      const subtotal = 100.0;
      cartNotifier.setTipAmount(subtotal * 0.20);

      final cartState = container.read(cartProvider);
      expect(cartState.tipAmount, equals(20.0));
    });

    test('Should set custom tip amount', () {
      final cartNotifier = container.read(cartProvider.notifier);
      
      cartNotifier.setTipAmount(25.50);

      final cartState = container.read(cartProvider);
      expect(cartState.tipAmount, equals(25.50));
    });

    test('Should update total amount when tip is added', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      
      // Add a mock menu item
      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Item',
        description: 'Test Description',
        price: 50.0,
        category: 'Main',
        imageUrl: 'https://example.com/image.jpg',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(menuItem, quantity: 2);

      var cartState = container.read(cartProvider);
      final subtotalWithoutTip = cartState.totalAmount;

      // Add 15% tip
      cartNotifier.setTipAmount(cartState.subtotal * 0.15);

      cartState = container.read(cartProvider);
      
      expect(cartState.totalAmount, greaterThan(subtotalWithoutTip));
      expect(cartState.tipAmount, equals(cartState.subtotal * 0.15));
    });

    test('Should include tip in order total when placing order', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      
      // Add a mock menu item
      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Item',
        description: 'Test Description',
        price: 50.0,
        category: 'Main',
        imageUrl: 'https://example.com/image.jpg',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(menuItem, quantity: 1);
      
      var cartState = container.read(cartProvider);
      cartNotifier.setTipAmount(cartState.subtotal * 0.15);

      cartState = container.read(cartProvider);
      final expectedTotal = cartState.totalAmount;

      // Place order
      await placeOrderNotifier.placeOrder(
        userId: 'user_123',
        restaurantId: 'restaurant_456',
        deliveryAddress: {
          'street': '123 Main Street',
          'city': 'New York',
          'zipCode': '10001',
        },
        tipAmount: cartState.tipAmount,
      );

      final placeOrderState = container.read(placeOrderProvider);
      expect(placeOrderState.placedOrder, isNotNull);
      expect(placeOrderState.placedOrder!.tipAmount, equals(cartState.tipAmount));
      expect(placeOrderState.placedOrder!.totalAmount, equals(expectedTotal));
    });

    test('Should generate order ID when placing order', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      
      // Add a mock menu item
      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Item',
        description: 'Test Description',
        price: 50.0,
        category: 'Main',
        imageUrl: 'https://example.com/image.jpg',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(menuItem, quantity: 1);

      // Place order
      await placeOrderNotifier.placeOrder(
        userId: 'user_123',
        restaurantId: 'restaurant_456',
        deliveryAddress: {
          'street': '123 Main Street',
          'city': 'New York',
          'zipCode': '10001',
        },
      );

      final placeOrderState = container.read(placeOrderProvider);
      expect(placeOrderState.placedOrder, isNotNull);
      expect(placeOrderState.placedOrder!.id, isNotEmpty);
      expect(placeOrderState.placedOrder!.id.length, equals(36)); // UUID v4 length
    });

    test('Should set estimated delivery time when placing order', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      
      // Add a mock menu item
      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Item',
        description: 'Test Description',
        price: 50.0,
        category: 'Main',
        imageUrl: 'https://example.com/image.jpg',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(menuItem, quantity: 1);

      final beforeOrderTime = DateTime.now();

      // Place order
      await placeOrderNotifier.placeOrder(
        userId: 'user_123',
        restaurantId: 'restaurant_456',
        deliveryAddress: {
          'street': '123 Main Street',
          'city': 'New York',
          'zipCode': '10001',
        },
      );

      final placeOrderState = container.read(placeOrderProvider);
      expect(placeOrderState.placedOrder, isNotNull);
      expect(placeOrderState.placedOrder!.estimatedDeliveryAt, isNotNull);
      
      // Should be approximately 30 minutes from now
      final estimatedTime = placeOrderState.placedOrder!.estimatedDeliveryAt!;
      final difference = estimatedTime.difference(beforeOrderTime);
      expect(difference.inMinutes, greaterThanOrEqualTo(29));
      expect(difference.inMinutes, lessThanOrEqualTo(31));
    });

    test('Should clear cart after successful order placement', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      
      // Add a mock menu item
      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Item',
        description: 'Test Description',
        price: 50.0,
        category: 'Main',
        imageUrl: 'https://example.com/image.jpg',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(menuItem, quantity: 1);
      
      var cartState = container.read(cartProvider);
      expect(cartState.items, isNotEmpty);

      // Place order
      await placeOrderNotifier.placeOrder(
        userId: 'user_123',
        restaurantId: 'restaurant_456',
        deliveryAddress: {
          'street': '123 Main Street',
          'city': 'New York',
          'zipCode': '10001',
        },
      );

      // Cart should be empty after order
      cartState = container.read(cartProvider);
      expect(cartState.items, isEmpty);
      expect(cartState.tipAmount, equals(0.0));
    });

    test('Should set payment status to completed for cash orders', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      
      // Add a mock menu item
      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Item',
        description: 'Test Description',
        price: 50.0,
        category: 'Main',
        imageUrl: 'https://example.com/image.jpg',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(menuItem, quantity: 1);

      // Place order with cash payment
      await placeOrderNotifier.placeOrder(
        userId: 'user_123',
        restaurantId: 'restaurant_456',
        deliveryAddress: {
          'street': '123 Main Street',
          'city': 'New York',
          'zipCode': '10001',
        },
        paymentMethod: 'cash',
      );

      final placeOrderState = container.read(placeOrderProvider);
      expect(placeOrderState.placedOrder, isNotNull);
      expect(placeOrderState.placedOrder!.paymentMethod, equals('cash'));
      expect(
        placeOrderState.placedOrder!.paymentStatus,
        equals(PaymentStatus.completed),
      );
    });
  });
}
