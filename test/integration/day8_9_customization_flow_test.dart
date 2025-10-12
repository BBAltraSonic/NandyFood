import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

void main() {
  group('Dish Customization Flow Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Test 1: Add item to cart with size customization', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_1',
        restaurantId: 'test_restaurant',
        name: 'Test Burger',
        price: 10.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customizations = {
        'size': 'Large',
        'sizeMultiplier': 1.3,
        'toppings': <String>[],
        'toppingsPrice': 0.0,
        'spiceLevel': 1,
      };

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: customizations,
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items[0].customizations?['size'], 'Large');
      expect(cartState.items[0].unitPrice, 13.0); // 10.0 * 1.3
    });

    test('Test 2: Add item with toppings customization', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_2',
        restaurantId: 'test_restaurant',
        name: 'Test Pizza',
        price: 12.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customizations = {
        'size': 'Medium',
        'sizeMultiplier': 1.0,
        'toppings': ['Extra Cheese', 'Bacon'],
        'toppingsPrice': 3.5, // 1.50 + 2.00
        'spiceLevel': 2,
      };

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: customizations,
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items[0].unitPrice, 15.5); // 12.0 + 3.5
      expect(cartState.items[0].customizations?['toppings'], contains('Extra Cheese'));
      expect(cartState.items[0].customizations?['toppings'], contains('Bacon'));
    });

    test('Test 3: Add item with spice level customization', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_3',
        restaurantId: 'test_restaurant',
        name: 'Test Curry',
        price: 15.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 25,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customizations = {
        'size': 'Medium',
        'sizeMultiplier': 1.0,
        'toppings': <String>[],
        'toppingsPrice': 0.0,
        'spiceLevel': 5, // Extra Hot
      };

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: customizations,
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items[0].customizations?['spiceLevel'], 5);
      expect(cartState.items[0].unitPrice, 15.0);
    });

    test('Test 4: Add item with special instructions', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_4',
        restaurantId: 'test_restaurant',
        name: 'Test Salad',
        price: 8.0,
        category: 'Appetizer',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customizations = {
        'size': 'Small',
        'sizeMultiplier': 0.8,
        'toppings': <String>[],
        'toppingsPrice': 0.0,
        'spiceLevel': 1,
      };

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: customizations,
        specialInstructions: 'No onions, please',
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items[0].specialInstructions, 'No onions, please');
      expect(cartState.items[0].unitPrice, 6.4); // 8.0 * 0.8
    });

    test('Test 5: Add multiple items with different customizations', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem1 = MenuItem(
        id: 'test_item_5a',
        restaurantId: 'test_restaurant',
        name: 'Test Burger 1',
        price: 10.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final testMenuItem2 = MenuItem(
        id: 'test_item_5b',
        restaurantId: 'test_restaurant',
        name: 'Test Burger 2',
        price: 12.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(
        testMenuItem1,
        quantity: 1,
        customizations: {
          'size': 'Small',
          'sizeMultiplier': 0.8,
          'toppings': <String>[],
          'toppingsPrice': 0.0,
          'spiceLevel': 1,
        },
      );

      await cartNotifier.addItem(
        testMenuItem2,
        quantity: 2,
        customizations: {
          'size': 'Large',
          'sizeMultiplier': 1.3,
          'toppings': ['Extra Cheese', 'Avocado'],
          'toppingsPrice': 4.0,
          'spiceLevel': 3,
        },
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 2);
      expect(cartState.items[0].quantity, 1);
      expect(cartState.items[1].quantity, 2);
    });

    test('Test 6: Update quantity of item with customizations', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_6',
        restaurantId: 'test_restaurant',
        name: 'Test Pizza',
        price: 15.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customizations = {
        'size': 'Large',
        'sizeMultiplier': 1.3,
        'toppings': ['Extra Cheese'],
        'toppingsPrice': 1.5,
        'spiceLevel': 2,
      };

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: customizations,
      );

      final initialCartState = container.read(cartProvider);
      final itemId = initialCartState.items[0].id;

      await cartNotifier.updateItemQuantity(itemId, 3);

      final updatedCartState = container.read(cartProvider);
      expect(updatedCartState.items.length, 1);
      expect(updatedCartState.items[0].quantity, 3);
      expect(updatedCartState.items[0].customizations, customizations);
    });

    test('Test 7: Remove item with customizations from cart', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_7',
        restaurantId: 'test_restaurant',
        name: 'Test Item',
        price: 10.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Medium',
          'sizeMultiplier': 1.0,
          'toppings': ['Bacon'],
          'toppingsPrice': 2.0,
          'spiceLevel': 2,
        },
      );

      final initialCartState = container.read(cartProvider);
      expect(initialCartState.items.length, 1);

      final itemId = initialCartState.items[0].id;
      await cartNotifier.removeItem(itemId);

      final finalCartState = container.read(cartProvider);
      expect(finalCartState.items.length, 0);
    });

    test('Test 8: Add same item with different customizations creates separate entries', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_8',
        restaurantId: 'test_restaurant',
        name: 'Test Burger',
        price: 10.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add first customization
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Small',
          'sizeMultiplier': 0.8,
          'toppings': <String>[],
          'toppingsPrice': 0.0,
          'spiceLevel': 1,
        },
      );

      // Add second customization (different)
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: {
          'size': 'Large',
          'sizeMultiplier': 1.3,
          'toppings': ['Extra Cheese'],
          'toppingsPrice': 1.5,
          'spiceLevel': 3,
        },
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 2); // Should be 2 separate items
    });

    test('Test 9: Add same item with identical customizations increases quantity', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_9',
        restaurantId: 'test_restaurant',
        name: 'Test Pizza',
        price: 12.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customizations = {
        'size': 'Medium',
        'sizeMultiplier': 1.0,
        'toppings': ['Bacon', 'Extra Cheese'],
        'toppingsPrice': 3.5,
        'spiceLevel': 2,
      };

      // Add first time
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: customizations,
      );

      // Add second time with identical customizations
      await cartNotifier.addItem(
        testMenuItem,
        quantity: 2,
        customizations: customizations,
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 1); // Should be 1 item
      expect(cartState.items[0].quantity, 3); // Quantity should be 1 + 2 = 3
    });

    test('Test 10: Calculate correct subtotal with customizations', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_10',
        restaurantId: 'test_restaurant',
        name: 'Test Item',
        price: 10.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 2,
        customizations: {
          'size': 'Large',
          'sizeMultiplier': 1.3, // 10.0 * 1.3 = 13.0
          'toppings': ['Extra Cheese', 'Bacon'],
          'toppingsPrice': 3.5, // 13.0 + 3.5 = 16.5
          'spiceLevel': 3,
        },
      );

      final cartState = container.read(cartProvider);
      expect(cartState.items[0].unitPrice, 16.5);
      expect(cartState.subtotal, 33.0); // 16.5 * 2
    });

    test('Test 11: Customization data persists in order item', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      final testMenuItem = MenuItem(
        id: 'test_item_11',
        restaurantId: 'test_restaurant',
        name: 'Test Dish',
        price: 20.0,
        category: 'Main',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 30,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final customizations = {
        'size': 'Large',
        'sizeMultiplier': 1.3,
        'toppings': ['Mushrooms', 'Olives', 'Extra Sauce'],
        'toppingsPrice': 2.25,
        'spiceLevel': 4,
      };

      await cartNotifier.addItem(
        testMenuItem,
        quantity: 1,
        customizations: customizations,
        specialInstructions: 'Extra crispy, please',
      );

      final cartState = container.read(cartProvider);
      final orderItem = cartState.items[0];
      
      expect(orderItem.customizations, isNotNull);
      expect(orderItem.customizations?['size'], 'Large');
      expect(orderItem.customizations?['toppings'], hasLength(3));
      expect(orderItem.customizations?['spiceLevel'], 4);
      expect(orderItem.specialInstructions, 'Extra crispy, please');
    });

    test('Test 12: Clear cart removes all items with customizations', () async {
      final cartNotifier = container.read(cartProvider.notifier);
      
      // Add multiple items with customizations
      for (int i = 0; i < 3; i++) {
        final testMenuItem = MenuItem(
          id: 'test_item_12_$i',
          restaurantId: 'test_restaurant',
          name: 'Test Item $i',
          price: 10.0 + i,
          category: 'Main',
          isAvailable: true,
          dietaryRestrictions: [],
          preparationTime: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await cartNotifier.addItem(
          testMenuItem,
          quantity: 1,
          customizations: {
            'size': 'Medium',
            'sizeMultiplier': 1.0,
            'toppings': ['Topping $i'],
            'toppingsPrice': 1.0,
            'spiceLevel': i + 1,
          },
        );
      }

      final initialCartState = container.read(cartProvider);
      expect(initialCartState.items.length, 3);

      cartNotifier.clearCart();

      final finalCartState = container.read(cartProvider);
      expect(finalCartState.items.length, 0);
      expect(finalCartState.subtotal, 0.0);
    });
  });
}
