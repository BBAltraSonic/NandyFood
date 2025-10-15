import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

void main() {
  group('CartProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be empty', () {
      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
      expect(state.subtotal, 0.0);
      expect(state.taxAmount, 0.0);
      expect(state.deliveryFee, 0.0);
      expect(state.tipAmount, 0.0);
      expect(state.discountAmount, 0.0);
      expect(state.promoCode, isNull);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
    });

    test('addItem should add item to cart', () async {
      final notifier = container.read(cartProvider.notifier);

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 10.0,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.addItem(menuItem);

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items[0].menuItemId, 'item1');
      expect(state.items[0].quantity, 1);
      expect(state.items[0].unitPrice, 10.0);
    });

    test('addItem should increment quantity for existing item', () async {
      final notifier = container.read(cartProvider.notifier);

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 10.0,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add item twice
      await notifier.addItem(menuItem);
      await notifier.addItem(menuItem);

      final state = container.read(cartProvider);
      expect(state.items.length, 1);
      expect(state.items[0].quantity, 2);
    });

    test('removeItem should remove item from cart', () async {
      final notifier = container.read(cartProvider.notifier);

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 10.0,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.addItem(menuItem);
      final itemId = container.read(cartProvider).items[0].id;
      await notifier.removeItem(itemId);

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
    });

    test('updateItemQuantity should update quantity', () async {
      final notifier = container.read(cartProvider.notifier);

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 10.0,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.addItem(menuItem);
      final itemId = container.read(cartProvider).items[0].id;

      await notifier.updateItemQuantity(itemId, 3);

      final state = container.read(cartProvider);
      expect(state.items[0].quantity, 3);
    });

    test('updateItemQuantity should remove item when quantity is 0', () async {
      final notifier = container.read(cartProvider.notifier);

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 10.0,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.addItem(menuItem);
      final itemId = container.read(cartProvider).items[0].id;

      await notifier.updateItemQuantity(itemId, 0);

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
    });

    test('clearCart should clear all items', () async {
      final notifier = container.read(cartProvider.notifier);

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 10.0,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.addItem(menuItem);
      notifier.clearCart();

      final state = container.read(cartProvider);
      expect(state.items, isEmpty);
      expect(state.subtotal, 0.0);
      expect(state.taxAmount, 0.0);
      expect(state.deliveryFee, 0.0);
      expect(state.tipAmount, 0.0);
      expect(state.discountAmount, 0.0);
    });

    test('subtotal should be calculated correctly', () async {
      final notifier = container.read(cartProvider.notifier);

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 10.0,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await notifier.addItem(menuItem);
      await notifier.addItem(
        menuItem,
      ); // Add same item again to make quantity 2

      final state = container.read(cartProvider);
      expect(state.subtotal, 20.0); // 10.0 * 2
    });

    test(
      'totalAmount should be calculated correctly with tax, fees, and discount',
      () async {
        final notifier = container.read(cartProvider.notifier);

        final menuItem = MenuItem(
          id: 'item1',
          restaurantId: 'restaurant1',
          name: 'Burger',
          description: 'Delicious burger',
          price: 10.0,
          category: 'Main Course',
          isAvailable: true,
          dietaryRestrictions: ['gluten-free'],
          preparationTime: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await notifier.addItem(menuItem);
        await notifier.addItem(
          menuItem,
        ); // Add same item again to make quantity 2

        // Set delivery fee
        notifier.setDeliveryFee(2.0);
        // Set tip amount
        notifier.setTipAmount(1.0);
        // Apply discount
        await notifier.applyPromoCode(
          'TEST10',
        ); // Assuming this gives a $2 discount

        final state = container.read(cartProvider);
        // Subtotal: 20.0 (10.0 * 2)
        // Tax: 20.0 * 0.085 = 1.7
        // Delivery fee: 2.0
        // Tip: 1.0
        // Discount: 2.0 (from mock)
        // Total: 20.0 + 1.7 + 2.0 + 1.0 - 2.0 = 22.7
        expect(state.totalAmount, closeTo(22.7, 0.01));
      },
    );
  });
}
