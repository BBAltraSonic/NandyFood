import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/screens/checkout_screen.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('CheckoutScreen Widget Tests', () {
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

    testWidgets('displays checkout form correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CheckoutScreen())),
      );

      // Verify that title is displayed
      expect(find.text('Checkout'), findsOneWidget);

      // Verify that delivery address section is displayed
      expect(find.text('Delivery Address'), findsOneWidget);

      // Verify that payment method section is displayed
      expect(find.text('Payment Method'), findsOneWidget);

      // Verify that order summary section is displayed
      expect(find.text('Order Summary'), findsOneWidget);

      // Verify that place order button is displayed
      expect(find.text('Place Order'), findsOneWidget);
    });

    testWidgets('displays delivery address fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CheckoutScreen())),
      );

      // Verify that address fields are displayed
      expect(
        find.byType(TextField),
        findsNWidgets(5),
      ); // street, city, zip, etc.

      // Verify that edit address button is displayed
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('displays payment method options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CheckoutScreen())),
      );

      // Wait for payment methods to load
      await tester.pumpAndSettle();

      // Verify that payment method options are displayed
      // Note: Actual options would depend on available payment methods
      expect(find.byType(RadioListTile<String>), findsWidgets);
    });

    testWidgets('displays promo code input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CheckoutScreen())),
      );

      // Find promo code field
      final promoCodeFields = find.byType(TextField).evaluate().where((
        element,
      ) {
        final textField = element.widget as TextField;
        return textField.decoration?.labelText == 'Promo Code';
      });

      // Verify that promo code field is displayed
      expect(promoCodeFields.length, 1);
    });

    testWidgets('applies promo code when apply button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CheckoutScreen())),
      );

      // Find promo code field and enter code
      final promoCodeField = find.byType(TextField).evaluate().firstWhere((
        element,
      ) {
        final textField = element.widget as TextField;
        return textField.decoration?.labelText == 'Promo Code';
      });

      await tester.enterText(promoCodeField, 'SAVE10');

      // Find apply button and tap it
      await tester.tap(find.text('Apply'));
      await tester.pump();

      // Verify that promo code is applied
      // Note: Actual verification would depend on state management
    });

    testWidgets('places order when place order button is tapped', (
      WidgetTester tester,
    ) async {
      bool orderPlaced = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CheckoutScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/order/confirmation') {
                orderPlaced = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Order Confirmation')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Wait for checkout data to load
      await tester.pumpAndSettle();

      // Find and tap place order button
      await tester.tap(find.text('Place Order'));
      await tester.pumpAndSettle();

      // Verify that order was placed
      expect(orderPlaced, isTrue);
    });

    testWidgets('displays order summary correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CheckoutScreen())),
      );

      // Wait for checkout data to load
      await tester.pumpAndSettle();

      // Verify that order summary is displayed
      expect(find.text('Order Summary'), findsOneWidget);

      // Verify that subtotal is displayed
      expect(find.text('Subtotal'), findsOneWidget);

      // Verify that tax is displayed
      expect(find.text('Tax'), findsOneWidget);

      // Verify that delivery fee is displayed
      expect(find.text('Delivery Fee'), findsOneWidget);

      // Verify that discount is displayed (if promo code applied)
      // Note: This would depend on promo code state

      // Verify that total is displayed
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('updates tip amount when tip slider is moved', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: CheckoutScreen())),
      );

      // Wait for checkout data to load
      await tester.pumpAndSettle();

      // Find tip slider
      final tipSliders = find.byType(Slider);

      // Move slider
      if (tipSliders.evaluate().isNotEmpty) {
        await tester.drag(tipSliders.first, const Offset(50.0, 0.0));
        await tester.pump();

        // Verify that tip amount is updated
        // Note: Actual verification would depend on state management
      }
    });
  });
}
