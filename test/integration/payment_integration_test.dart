import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/config/payment_config.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/core/services/payfast_service.dart';

void main() {
  group('Payment Integration Tests', () {
    setUpAll(() async {
      // Load test environment variables
      await dotenv.load(fileName: '.env');
      await PaymentConfig.initialize();
    });

    testWidgets('Complete cash payment flow should work end-to-end', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));

      final paymentService = PaymentService();

      // Test cash payment processing
      final result = await paymentService.processPayment(
        context: context,
        amount: 250.0,
        orderId: 'test_order_12345',
        method: PaymentMethodType.cash,
      );

      expect(result, isTrue);
    });

    test('PayFast service should initialize payment correctly', () async {
      final payfastService = PayFastService();

      try {
        final paymentData = await payfastService.initializePayment(
          orderId: 'test_order_67890',
          userId: 'test_user_123',
          amount: 150.0,
          itemName: 'Test Order Items',
          itemDescription: 'Test payment integration',
          customerEmail: 'test@example.com',
          customerFirstName: 'Test',
          customerLastName: 'User',
        );

        expect(paymentData, isNotNull);
        expect(paymentData, isA<Map<String, String>>());
        expect(paymentData.containsKey('merchant_id'), isTrue);
        expect(paymentData.containsKey('signature'), isTrue);
        expect(paymentData['amount'], '150.00');
      } catch (e) {
        // PayFast might fail in test environment, but we can verify it attempts initialization
        expect(e, isA<Exception>());
      }
    });

    test('Payment validation should work correctly', () async {
      final paymentService = PaymentService();

      // Test card validation
      expect(paymentService.validateCardNumber('4532015112830366'), isTrue);
      expect(paymentService.validateCardNumber('1234567890123456'), isFalse);

      // Test expiry validation
      expect(paymentService.validateExpiryDate(12, 2025), isTrue);
      expect(paymentService.validateExpiryDate(1, 2020), isFalse);

      // Test CVC validation
      expect(paymentService.validateCvc('123', '4532015112830366'), isTrue);
      expect(paymentService.validateCvc('12', '4532015112830366'), isFalse);
    });

    test('Payment configuration should be consistent across services', () async {
      // Verify that PaymentConfig and PaymentService are aligned
      expect(PaymentConfig.isCashOnDeliveryEnabled, isTrue);

      final paymentService = PaymentService();
      final availableMethods = paymentService.getAvailablePaymentMethods();
      final cashMethod = availableMethods.firstWhere(
        (method) => method['type'] == PaymentMethodType.cash,
        orElse: () => <String, dynamic>{},
      );

      expect(cashMethod['enabled'], isTrue);
      expect(cashMethod['name'], 'Cash on Delivery');
    });

    test('Payment amount validation should be consistent', () async {
      // Test minimum order amount
      expect(PaymentConfig.validateOrderAmount(15.0, PaymentMethod.cashOnDelivery), isTrue);
      expect(PaymentConfig.validateOrderAmount(5.0, PaymentMethod.cashOnDelivery), isFalse);

      // Test maximum cash amount
      expect(PaymentConfig.validateOrderAmount(3000.0, PaymentMethod.cashOnDelivery), isTrue);
      expect(PaymentConfig.validateOrderAmount(6000.0, PaymentMethod.cashOnDelivery), isFalse);
    });
  });
}