import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

void main() {
  group('Dish Customization Price Calculation Tests', () {
    late ProviderContainer container;
    late MenuItem testMenuItem;

    setUp(() {
      container = ProviderContainer();
      testMenuItem = MenuItem(
        id: 'test-item-1',
        restaurantId: 'test-restaurant-1',
        name: 'Test Burger',
        description: 'A delicious test burger',
        price: 10.00,
        category: 'Burgers',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        imageUrl: null,
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Cart calculates price with size customization correctly', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      // Add item with Large size (1.3x multiplier)
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Large',
          'sizeMultiplier': 1.3,
          'toppings': [],
          'toppingsPrice': 0.0,
          'spiceLevel': 1,
        },
      );

      // Verify price calculation
      final cartState = container.read(cartProvider);
      final cartItem = cartState.items.first;

      // Expected price: 10.00 * 1.3 = 13.00
      expect(cartItem.unitPrice, 13.00);
    });

    test('Cart calculates price with toppings correctly', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      // Add item with Extra Cheese topping (\$1.50)
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Medium',
          'sizeMultiplier': 1.0,
          'toppings': ['Extra Cheese'],
          'toppingsPrice': 1.50,
          'spiceLevel': 2,
        },
      );

      // Verify price calculation
      final cartState = container.read(cartProvider);
      final cartItem = cartState.items.first;

      // Expected price: (10.00 * 1.0) + 1.50 = 11.50
      expect(cartItem.unitPrice, 11.50);
    });

    test('Cart calculates price with size and toppings correctly', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      // Add item with Large size (1.3x) and multiple toppings
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Large',
          'sizeMultiplier': 1.3,
          'toppings': ['Extra Cheese', 'Bacon'],
          'toppingsPrice': 3.50, // 1.50 + 2.00
          'spiceLevel': 3,
        },
      );

      // Verify price calculation
      final cartState = container.read(cartProvider);
      final cartItem = cartState.items.first;

      // Expected price: (10.00 * 1.3) + 3.50 = 16.50
      expect(cartItem.unitPrice, 16.50);
    });

    test('Cart distinguishes items with different customizations', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      // Add item with Small size
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Small',
          'sizeMultiplier': 0.8,
          'toppings': [],
          'toppingsPrice': 0.0,
          'spiceLevel': 1,
        },
      );

      // Add same item with Large size
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Large',
          'sizeMultiplier': 1.3,
          'toppings': [],
          'toppingsPrice': 0.0,
          'spiceLevel': 1,
        },
      );

      // Should have 2 separate items in cart
      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 2);

      // Verify each item has correct price
      final smallItem = cartState.items.firstWhere(
        (item) => (item.customizations?['size'] as String) == 'Small',
      );
      final largeItem = cartState.items.firstWhere(
        (item) => (item.customizations?['size'] as String) == 'Large',
      );

      expect(smallItem.unitPrice, 8.0); // 10.00 * 0.8
      expect(largeItem.unitPrice, 13.0); // 10.00 * 1.3
    });

    test('Cart combines items with identical customizations', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      // Add item with Medium size and Extra Cheese
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Medium',
          'sizeMultiplier': 1.0,
          'toppings': ['Extra Cheese'],
          'toppingsPrice': 1.50,
          'spiceLevel': 2,
        },
      );

      // Add same item with identical customizations
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Medium',
          'sizeMultiplier': 1.0,
          'toppings': ['Extra Cheese'],
          'toppingsPrice': 1.50,
          'spiceLevel': 2,
        },
      );

      // Should have 1 item with quantity 2
      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.quantity, 2);
      expect(cartState.items.first.unitPrice, 11.50);
    });

    test('Cart respects special instructions', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Medium',
          'sizeMultiplier': 1.0,
          'toppings': [],
          'toppingsPrice': 0.0,
          'spiceLevel': 1,
        },
        specialInstructions: 'Please make it extra crispy',
      );

      final cartState = container.read(cartProvider);
      final cartItem = cartState.items.first;

      expect(cartItem.specialInstructions, 'Please make it extra crispy');
    });

    test('Cart stores spice level customization', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Medium',
          'sizeMultiplier': 1.0,
          'toppings': [],
          'toppingsPrice': 0.0,
          'spiceLevel': 5,
        },
      );

      final cartState = container.read(cartProvider);
      final cartItem = cartState.items.first;

      expect(cartItem.customizations?['spiceLevel'], 5);
    });

    test('Cart calculates subtotal with multiple customized items', () async {
      final cartNotifier = container.read(cartProvider.notifier);

      // Add first item
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 2,
        customizations: {
          'size': 'Small',
          'sizeMultiplier': 0.8,
          'toppings': [],
          'toppingsPrice': 0.0,
          'spiceLevel': 1,
        },
      );

      // Add second item
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Large',
          'sizeMultiplier': 1.3,
          'toppings': ['Extra Cheese', 'Bacon'],
          'toppingsPrice': 3.50,
          'spiceLevel': 3,
        },
      );

      final cartState = container.read(cartProvider);

      // Small: 10.00 * 0.8 * 2 = 16.00
      // Large with toppings: (10.00 * 1.3 + 3.50) * 1 = 16.50
      // Total: 32.50
      expect(cartState.subtotal, 32.50);
    });
  });
}
