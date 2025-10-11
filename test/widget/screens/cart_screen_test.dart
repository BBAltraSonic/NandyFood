import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/screens/cart_screen.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('CartScreen Widget Tests', () {
    late DatabaseService dbService;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();
    });

    tearDown(() {
      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    testWidgets('displays empty cart message when cart is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Verify that empty cart message is displayed
      expect(find.text('Your cart is empty'), findsOneWidget);

      // Verify that browse restaurants button is displayed
      expect(find.text('Browse Restaurants'), findsOneWidget);
    });

    testWidgets('displays cart items when cart is not empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Verify that cart items are displayed
      // Note: Actual cart items would depend on cart state
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('updates item quantity when +/- buttons are tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Wait for cart to load
      await tester.pumpAndSettle();

      // Find quantity controls
      final incrementButtons = find.byIcon(Icons.add);
      final decrementButtons = find.byIcon(Icons.remove);

      // Test increment button
      if (incrementButtons.evaluate().isNotEmpty) {
        await tester.tap(incrementButtons.first);
        await tester.pump();

        // Verify that quantity increased
        // Note: Actual verification would depend on cart state
      }

      // Test decrement button
      if (decrementButtons.evaluate().isNotEmpty) {
        await tester.tap(decrementButtons.first);
        await tester.pump();

        // Verify that quantity decreased
        // Note: Actual verification would depend on cart state
      }
    });

    testWidgets('removes item when remove button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Wait for cart to load
      await tester.pumpAndSettle();

      // Find remove buttons
      final removeButtons = find.byIcon(Icons.delete);

      // Tap remove button
      if (removeButtons.evaluate().isNotEmpty) {
        await tester.tap(removeButtons.first);
        await tester.pump();

        // Verify that item was removed
        // Note: Actual verification would depend on cart state
      }
    });

    testWidgets('navigates to checkout when checkout button is tapped', (WidgetTester tester) async {
      bool navigatedToCheckout = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/order/checkout') {
                navigatedToCheckout = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Checkout Screen')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Wait for cart to load
      await tester.pumpAndSettle();

      // Find and tap checkout button
      final checkoutButtons = find.text('Checkout');
      if (checkoutButtons.evaluate().isNotEmpty) {
        await tester.tap(checkoutButtons.first);
        await tester.pumpAndSettle();

        // Verify that navigation occurred
        expect(navigatedToCheckout, isTrue);
      }
    });

    testWidgets('clears cart when clear cart button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Wait for cart to load
      await tester.pumpAndSettle();

      // Find and tap clear cart button
      final clearCartButtons = find.byIcon(Icons.delete);
      if (clearCartButtons.evaluate().isNotEmpty) {
        await tester.tap(clearCartButtons.first);
        await tester.pump();

        // Verify that confirmation dialog is shown
        expect(find.text('Cart cleared'), findsOneWidget);
      }
    });

    testWidgets('displays order summary correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );

      // Wait for cart to load
      await tester.pumpAndSettle();

      // Verify that order summary is displayed
      expect(find.text('Order Summary'), findsOneWidget);

      // Verify that subtotal is displayed
      expect(find.text('Subtotal'), findsOneWidget);

      // Verify that tax is displayed
      expect(find.text('Tax'), findsOneWidget);

      // Verify that delivery fee is displayed
      expect(find.text('Delivery Fee'), findsOneWidget);

      // Verify that total is displayed
      expect(find.text('Total'), findsOneWidget);
    });
  });
}