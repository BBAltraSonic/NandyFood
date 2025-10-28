import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/restaurant_detail_screen.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/restaurant_list_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/cart_screen.dart';
import 'package:food_delivery_app/features/order/presentation/screens/checkout_screen.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/place_order_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

void main() {
  group('Order Flow Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete order flow from restaurant to checkout', (WidgetTester tester) async {
      // Mock restaurant and menu items
      final mockRestaurant = Restaurant(
        id: 'restaurant_1',
        name: 'Test Restaurant',
        cuisine: 'Test Cuisine',
        rating: 4.5,
        deliveryTime: '30-40 min',
        deliveryFee: 2.99,
        imageUrl: 'test_image_url',
      );

      final mockMenuItems = [
        MenuItem(
          id: 'item_1',
          name: 'Test Burger',
          description: 'Delicious test burger',
          price: 12.99,
          category: 'Main',
          imageUrl: 'burger_image_url',
          restaurantId: 'restaurant_1',
          isAvailable: true,
        ),
        MenuItem(
          id: 'item_2',
          name: 'Test Fries',
          description: 'Crispy test fries',
          price: 4.99,
          category: 'Side',
          imageUrl: 'fries_image_url',
          restaurantId: 'restaurant_1',
          isAvailable: true,
        ),
      ];

      // Build restaurant detail screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: RestaurantDetailScreen(
              restaurant: mockRestaurant,
              menuItems: mockMenuItems,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify restaurant details are displayed
      expect(find.text('Test Restaurant'), findsOneWidget);
      expect(find.text('Test Cuisine'), findsOneWidget);
      expect(find.text('4.5'), findsOneWidget);

      // Add first item to cart
      expect(find.text('Test Burger'), findsOneWidget);
      await tester.tap(find.text('Add to Cart').first);
      await tester.pumpAndSettle();

      // Verify cart shows item count
      expect(find.text('1'), findsOneWidget);

      // Add second item to cart
      expect(find.text('Test Fries'), findsOneWidget);
      await tester.tap(find.text('Add to Cart').at(1));
      await tester.pumpAndSettle();

      // Verify cart shows updated count
      expect(find.text('2'), findsOneWidget);

      // Navigate to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // Should be on cart screen
      expect(find.byType(CartScreen), findsOneWidget);
      expect(find.text('Test Burger'), findsOneWidget);
      expect(find.text('Test Fries'), findsOneWidget);

      // Verify cart total
      expect(find.text('R17.98'), findsOneWidget); // 12.99 + 4.99

      // Proceed to checkout
      await tester.tap(find.text('Proceed to Checkout'));
      await tester.pumpAndSettle();

      // Should be on checkout screen
      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);

      // Verify order summary
      expect(find.text('Test Burger'), findsOneWidget);
      expect(find.text('Test Fries'), findsOneWidget);
      expect(find.text('R17.98'), findsOneWidget);

      // Test quantity adjustments
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      // Verify updated total (2 burgers + 1 fries = 30.97)
      expect(find.text('R30.97'), findsOneWidget);

      // Remove an item
      await tester.tap(find.byIcon(Icons.remove).first);
      await tester.pumpAndSettle();

      // Verify total is back to original
      expect(find.text('R17.98'), findsOneWidget);
    });

    testWidgets('Cart state management should work correctly', (WidgetTester tester) async {
      // Get cart provider
      final cartNotifier = container.read(cartProvider.notifier);

      // Add items to cart programmatically
      final menuItem = MenuItem(
        id: 'test_item',
        name: 'Test Item',
        price: 10.0,
        restaurantId: 'restaurant_1',
        isAvailable: true,
      );

      cartNotifier.addItem(menuItem);
      await tester.pump();

      // Verify item was added
      final cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items.first.name, 'Test Item');
      expect(cartState.totalAmount, 10.0);

      // Add another item
      cartNotifier.addItem(menuItem);
      await tester.pump();

      // Verify quantity increased
      expect(cartState.items.length, 1); // Still 1 unique item
      expect(cartState.items.first.quantity, 2);
      expect(cartState.totalAmount, 20.0);

      // Remove item
      cartNotifier.removeItem(menuItem);
      await tester.pump();

      // Verify quantity decreased
      expect(cartState.items.first.quantity, 1);
      expect(cartState.totalAmount, 10.0);

      // Clear cart
      cartNotifier.clearCart();
      await tester.pump();

      // Verify cart is empty
      expect(cartState.items.isEmpty, true);
      expect(cartState.totalAmount, 0.0);
    });

    testWidgets('Order placement validation should work', (WidgetTester tester) async {
      // Create checkout screen with empty cart
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const CheckoutScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty cart state
      expect(find.text('Your cart is empty'), findsOneWidget);
      expect(find.text('Add items to your cart to proceed'), findsOneWidget);

      // Place order button should be disabled
      expect(find.text('Place Order'), findsNothing);
    });

    testWidgets('Customization options should work correctly', (WidgetTester tester) async {
      // Create menu item with customization options
      final customizableItem = MenuItem(
        id: 'custom_item',
        name: 'Custom Burger',
        price: 10.0,
        restaurantId: 'restaurant_1',
        isAvailable: true,
        customizationOptions: [
          {
            'name': 'Extra Cheese',
            'price': 1.5,
            'type': 'checkbox',
          },
          {
            'name': 'Bacon',
            'price': 2.0,
            'type': 'checkbox',
          },
        ],
      );

      // Build cart screen with customizable item
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Add customizable item to cart
      final cartNotifier = container.read(cartProvider.notifier);
      cartNotifier.addItem(customizableItem, selectedOptions: ['Extra Cheese']);
      await tester.pump();

      // Verify customization is reflected in price
      final cartState = container.read(cartProvider);
      expect(cartState.totalAmount, 11.5); // 10.0 + 1.5
    });

    testWidgets('Error handling should work gracefully', (WidgetTester tester) async {
      // Test with invalid menu item
      final invalidItem = MenuItem(
        id: '',
        name: '',
        price: -1.0,
        restaurantId: '',
        isAvailable: false,
      );

      final cartNotifier = container.read(cartProvider.notifier);

      // Try to add invalid item
      cartNotifier.addItem(invalidItem);
      await tester.pump();

      // Cart should remain empty
      final cartState = container.read(cartProvider);
      expect(cartState.items.isEmpty, true);
      expect(cartState.totalAmount, 0.0);
    });
  });
}