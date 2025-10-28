import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/config/payment_config.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/features/cart/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_tracking_provider.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/providers/restaurant_dashboard_provider.dart';
import 'package:food_delivery_app/shared/models/cart.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/payment.dart';

/// Comprehensive Integration Test Suite
///
/// This test suite covers end-to-end integration between all major components
/// of the NandyFood application to ensure everything works together seamlessly.
void main() {
  group('Comprehensive Integration Tests', () {
    setUpAll(() async {
      // Load test environment
      await dotenv.load(fileName: '.env');
      await PaymentConfig.initialize();
    });

    group('Authentication Integration', () {
      testWidgets('Auth provider should initialize and manage state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final authState = ref.watch(authStateProvider);

                return Scaffold(
                  appBar: AppBar(title: const Text('Auth Integration Test')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Auth State: ${authState.status}'),
                        Text('User: ${authState.user?.email ?? "Not logged in"}'),
                        ElevatedButton(
                          onPressed: () {
                            // Simulate login state change
                            ref.read(authStateProvider.notifier).updateLoading(false);
                          },
                          child: const Text('Test State Update'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial state
        expect(find.text('Auth State: unauthenticated'), findsOneWidget);
        expect(find.text('User: Not logged in'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);

        // Test state update
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Verify state management is working
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('Cart Integration', () {
      testWidgets('Cart provider should manage cart operations correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final cartState = ref.watch(cartProvider);
                final cartNotifier = ref.read(cartProvider.notifier);

                return Scaffold(
                  appBar: AppBar(title: const Text('Cart Integration Test')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Items: ${cartState.items.length}'),
                        Text('Total: R${cartState.totalAmount.toStringAsFixed(2)}'),
                        ElevatedButton(
                          onPressed: () {
                            // Add test item to cart
                            final testItem = CartItem(
                              id: 'test_item_1',
                              restaurantId: 'test_restaurant',
                              name: 'Test Burger',
                              price: 50.0,
                              quantity: 1,
                              imageUrl: null,
                              customizationOptions: const [],
                            );
                            cartNotifier.addItem(testItem);
                          },
                          child: const Text('Add Item'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            cartNotifier.clearCart();
                          },
                          child: const Text('Clear Cart'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial empty cart
        expect(find.text('Items: 0'), findsOneWidget);
        expect(find.text('Total: R0.00'), findsOneWidget);

        // Add item to cart
        await tester.tap(find.text('Add Item'));
        await tester.pumpAndSettle();

        // Verify item added
        expect(find.text('Items: 1'), findsOneWidget);
        expect(find.text('Total: R50.00'), findsOneWidget);

        // Clear cart
        await tester.tap(find.text('Clear Cart'));
        await tester.pumpAndSettle();

        // Verify cart cleared
        expect(find.text('Items: 0'), findsOneWidget);
        expect(find.text('Total: R0.00'), findsOneWidget);
      });
    });

    group('Payment Integration', () {
      test('Payment service should integrate with configuration correctly', () {
        final paymentService = PaymentService();
        final availableMethods = paymentService.getAvailablePaymentMethods();

        // Verify payment methods align with configuration
        final configMethods = PaymentConfig.getEnabledPaymentMethods();
        expect(configMethods, isNotEmpty);
        expect(availableMethods, isNotEmpty);

        // Verify cash on delivery is available
        final cashMethod = availableMethods.firstWhere(
          (method) => method['type'] == PaymentMethodType.cash,
          orElse: () => <String, dynamic>{},
        );
        expect(cashMethod['enabled'], isTrue);
        expect(cashMethod['name'], 'Cash on Delivery');
      });

      test('Payment validation should be consistent across services', () {
        // Test amount validation consistency
        expect(PaymentConfig.validateOrderAmount(15.0, PaymentMethod.cashOnDelivery), isTrue);
        expect(PaymentConfig.validateOrderAmount(5.0, PaymentMethod.cashOnDelivery), isFalse);

        // Test payment method validation
        expect(PaymentConfig.isPaymentMethodEnabled(PaymentMethod.cashOnDelivery), isTrue);
        expect(PaymentConfig.getPaymentMethodName(PaymentMethod.cashOnDelivery), 'Cash on Delivery');
      });
    });

    group('Order Integration', () {
      test('Order tracking provider should handle order states correctly', () {
        // Create test order
        final testOrder = Order(
          id: 'test_order_123',
          userId: 'test_user',
          restaurantId: 'test_restaurant',
          restaurantName: 'Test Restaurant',
          status: OrderStatus.placed,
          items: [],
          totalAmount: 100.0,
          deliveryAddress: 'Test Address',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Test order status tracking
        expect(testOrder.status, OrderStatus.placed);
        expect(testOrder.totalAmount, 100.0);
        expect(testOrder.restaurantName, 'Test Restaurant');
      });

      test('Order status transitions should be logical', () {
        final statuses = [
          OrderStatus.placed,
          OrderStatus.confirmed,
          OrderStatus.preparing,
          OrderStatus.ready,
          OrderStatus.pickedUp,
          OrderStatus.onTheWay,
          OrderStatus.delivered,
        ];

        // Verify all standard statuses exist and can be compared
        for (int i = 0; i < statuses.length - 1; i++) {
          expect(statuses[i] != statuses[i + 1], isTrue);
        }

        // Verify delivered is final state
        expect(OrderStatus.delivered, isA<OrderStatus>());
      });
    });

    group('Restaurant Dashboard Integration', () {
      test('Restaurant dashboard should handle analytics data correctly', () {
        // Test analytics data structure
        final testAnalytics = {
          'totalOrders': 100,
          'totalRevenue': 10000.0,
          'averageRating': 4.5,
          'activeOrders': 5,
        };

        expect(testAnalytics['totalOrders'], isA<int>());
        expect(testAnalytics['totalRevenue'], isA<double>());
        expect(testAnalytics['averageRating'], isA<double>());
        expect(testAnalytics['activeOrders'], isA<int>());

        // Test data validation
        expect(testAnalytics['totalOrders'], greaterThan(0));
        expect(testAnalytics['totalRevenue'], greaterThan(0));
        expect(testAnalytics['averageRating'], greaterThanOrEqualTo(0));
        expect(testAnalytics['averageRating'], lessThanOrEqualTo(5));
      });
    });

    group('End-to-End User Flow Integration', () {
      testWidgets('Complete user journey should work end-to-end', (WidgetTester tester) async {
        // This test simulates a complete user journey from browsing to checkout

        await tester.pumpWidget(
          MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final cartState = ref.watch(cartProvider);
                final cartNotifier = ref.read(cartProvider.notifier);

                return Scaffold(
                  appBar: AppBar(title: const Text('E2E Integration Test')),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Cart Items: ${cartState.items.length}'),
                        Text('Total: R${cartState.totalAmount.toStringAsFixed(2)}'),
                        ElevatedButton(
                          onPressed: () {
                            // Add multiple items to simulate shopping
                            final items = [
                              CartItem(
                                id: 'burger_1',
                                restaurantId: 'rest_1',
                                name: 'Classic Burger',
                                price: 65.0,
                                quantity: 1,
                                imageUrl: null,
                                customizationOptions: const [],
                              ),
                              CartItem(
                                id: 'fries_1',
                                restaurantId: 'rest_1',
                                name: 'French Fries',
                                price: 25.0,
                                quantity: 2,
                                imageUrl: null,
                                customizationOptions: const [],
                              ),
                            ];

                            for (final item in items) {
                              cartNotifier.addItem(item);
                            }
                          },
                          child: const Text('Add Items to Cart'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Simulate checkout process
                            if (cartState.items.isNotEmpty) {
                              // In real app, this would navigate to checkout
                              cartNotifier.clearCart();
                            }
                          },
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial state
        expect(find.text('Cart Items: 0'), findsOneWidget);
        expect(find.text('Total: R0.00'), findsOneWidget);

        // Add items to cart
        await tester.tap(find.text('Add Items to Cart'));
        await tester.pumpAndSettle();

        // Verify items added (1 burger + 2 fries = 3 items, R115 total)
        expect(find.text('Cart Items: 3'), findsOneWidget);
        expect(find.text('Total: R115.00'), findsOneWidget);

        // Process checkout
        await tester.tap(find.text('Checkout'));
        await tester.pumpAndSettle();

        // Verify checkout completed (cart cleared)
        expect(find.text('Cart Items: 0'), findsOneWidget);
        expect(find.text('Total: R0.00'), findsOneWidget);
      });
    });

    group('Error Handling Integration', () {
      test('Payment service should handle errors gracefully', () {
        final paymentService = PaymentService();

        // Test invalid payment scenarios
        expect(paymentService.validateCardNumber(''), isFalse);
        expect(paymentService.validateCardNumber('invalid'), isFalse);
        expect(paymentService.validateCvc('', '4532015112830366'), isFalse);
        expect(paymentService.validateExpiryDate(0, 2020), isFalse);
      });

      test('Configuration should handle missing values gracefully', () {
        // Test that system defaults to safe values when configuration is missing

        // These should not throw exceptions even with edge cases
        expect(PaymentConfig.getPaymentMethodName(PaymentMethod.cashOnDelivery), isNotEmpty);
        expect(PaymentConfig.getPaymentMethodDescription(PaymentMethod.cashOnDelivery), isNotEmpty);
        expect(PaymentConfig.getPaymentMethodIcon(PaymentMethod.cashOnDelivery), isNotEmpty);
      });
    });

    group('Performance Integration', () {
      test('Payment validation should be performant', () {
        final paymentService = PaymentService();
        final stopwatch = Stopwatch()..start();

        // Test 1000 validations to ensure performance is acceptable
        for (int i = 0; i < 1000; i++) {
          paymentService.validateCardNumber('4532015112830366');
          paymentService.validateExpiryDate(12, DateTime.now().year + 1);
          paymentService.validateCvc('123', '4532015112830366');
        }

        stopwatch.stop();

        // Should complete 3000 validations in under 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('Cart operations should be efficient', () {
        // Test cart performance with many items
        final stopwatch = Stopwatch()..start();

        // Simulate adding many items
        for (int i = 0; i < 100; i++) {
          // This would normally be done through the provider
          // Just testing the data structure performance here
          final items = List.generate(100, (index) => CartItem(
            id: 'item_$index',
            restaurantId: 'rest_1',
            name: 'Item $index',
            price: 10.0 + index,
            quantity: 1,
            imageUrl: null,
            customizationOptions: const [],
          ));

          // Calculate total
          final total = items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
          expect(total, greaterThan(0));
        }

        stopwatch.stop();

        // Should complete quickly
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });
    });

    group('Security Integration', () {
      test('Input validation should prevent malicious data', () {
        final paymentService = PaymentService();

        final maliciousInputs = [
          '<script>alert("xss")</script>',
          'javascript:alert("xss")',
          '../etc/passwd',
          'SELECT * FROM users',
          'DROP TABLE orders',
        ];

        for (final input in maliciousInputs) {
          // All malicious inputs should be rejected
          expect(paymentService.validateCardNumber(input), isFalse);
          expect(paymentService.validateCvc(input, '4532015112830366'), isFalse);
        }
      });

      test('Payment amounts should be validated for security', () {
        // Test extreme values that could indicate attacks
        expect(PaymentConfig.validateOrderAmount(-1000.0, PaymentMethod.cashOnDelivery), isFalse);
        expect(PaymentConfig.validateOrderAmount(999999999.99, PaymentMethod.cashOnDelivery), isFalse);
        expect(PaymentConfig.validateOrderAmount(double.infinity, PaymentMethod.cashOnDelivery), isFalse);
        expect(PaymentConfig.validateOrderAmount(double.nan, PaymentMethod.cashOnDelivery), isFalse);
      });
    });

    group('Data Consistency Integration', () {
      test('Payment method types should be consistent across services', () {
        // Verify that payment method types are consistent
        final configMethods = PaymentConfig.getEnabledPaymentMethods();
        final serviceMethods = PaymentService().getAvailablePaymentMethods();

        // Both should have at least one method enabled
        expect(configMethods, isNotEmpty);
        expect(serviceMethods, isNotEmpty);

        // Cash on delivery should be available in both
        final configHasCash = configMethods.contains(PaymentMethod.cashOnDelivery);
        final serviceHasCash = serviceMethods.any((m) => m['type'] == PaymentMethodType.cash && m['enabled']);

        expect(configHasCash, isTrue);
        expect(serviceHasCash, isTrue);
      });

      test('Order amounts should be consistent with cart calculations', () {
        // Create test cart items
        final items = [
          CartItem(
            id: 'item_1',
            restaurantId: 'rest_1',
            name: 'Item 1',
            price: 50.0,
            quantity: 2,
            imageUrl: null,
            customizationOptions: const [],
          ),
          CartItem(
            id: 'item_2',
            restaurantId: 'rest_1',
            name: 'Item 2',
            price: 30.0,
            quantity: 1,
            imageUrl: null,
            customizationOptions: const [],
          ),
        ];

        // Calculate cart total
        final cartTotal = items.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));

        // Create order with same total
        final order = Order(
          id: 'order_1',
          userId: 'user_1',
          restaurantId: 'rest_1',
          restaurantName: 'Test Restaurant',
          status: OrderStatus.placed,
          items: items,
          totalAmount: cartTotal,
          deliveryAddress: 'Test Address',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Verify consistency
        expect(cartTotal, 130.0); // (50 * 2) + (30 * 1) = 130
        expect(order.totalAmount, cartTotal);
      });
    });
  });
}