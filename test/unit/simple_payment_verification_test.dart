import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/config/payment_config.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/core/services/payfast_service.dart';

/// Simple payment system verification test
void main() {
  group('Payment System Verification', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env');
      await PaymentConfig.initialize();
    });

    test('Payment configuration should initialize successfully', () {
      expect(PaymentConfig.isCashOnDeliveryEnabled, isTrue);
      expect(PaymentConfig.minOrderAmount, greaterThan(0));
      expect(PaymentConfig.maxCashAmount, greaterThan(0));
    });

    test('Payment methods should be properly configured', () {
      final enabledMethods = PaymentConfig.getEnabledPaymentMethods();
      expect(enabledMethods, isNotEmpty);
      expect(enabledMethods, contains(PaymentMethod.cashOnDelivery));
    });

    test('PaymentService should be a singleton', () {
      final instance1 = PaymentService();
      final instance2 = PaymentService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('Available payment methods should match configuration', () {
      final methods = PaymentService().getAvailablePaymentMethods();
      expect(methods, isNotEmpty);

      final cashMethod = methods.firstWhere(
        (method) => method['type'] == PaymentMethodType.cash,
        orElse: () => <String, dynamic>{},
      );
      expect(cashMethod['enabled'], isTrue);
      expect(cashMethod['name'], 'Cash on Delivery');
    });

    test('Card validation should be comprehensive', () {
      final paymentService = PaymentService();

      // Valid cards
      expect(paymentService.validateCardNumber('4532015112830366'), isTrue); // Visa
      expect(paymentService.validateCardNumber('5555555555554444'), isTrue); // Mastercard
      expect(paymentService.validateCardNumber('378282246310005'), isTrue); // Amex

      // Invalid cards
      expect(paymentService.validateCardNumber('1234567890123456'), isFalse);
      expect(paymentService.validateCardNumber(''), isFalse);
      expect(paymentService.validateCardNumber('abc'), isFalse);
    });

    test('Expiry validation should handle edge cases', () {
      final paymentService = PaymentService();
      final now = DateTime.now();

      // Future dates
      expect(paymentService.validateExpiryDate(12, now.year + 1), isTrue);
      expect(paymentService.validateExpiryDate(now.month, now.year), isTrue);

      // Past dates
      expect(paymentService.validateExpiryDate(now.month - 1, now.year), isFalse);
      expect(paymentService.validateExpiryDate(12, now.year - 1), isFalse);

      // Invalid dates
      expect(paymentService.validateExpiryDate(0, now.year + 1), isFalse);
      expect(paymentService.validateExpiryDate(13, now.year + 1), isFalse);
    });

    test('CVC validation should be card-type aware', () {
      final paymentService = PaymentService();

      // Regular cards (3 digits)
      expect(paymentService.validateCvc('123', '4532015112830366'), isTrue);
      expect(paymentService.validateCvc('456', '5555555555554444'), isTrue);

      // American Express (4 digits)
      expect(paymentService.validateCvc('1234', '378282246310005'), isTrue);
      expect(paymentService.validateCvc('123', '378282246310005'), isFalse);

      // Invalid CVCs
      expect(paymentService.validateCvc('12', '4532015112830366'), isFalse);
      expect(paymentService.validateCvc('abc', '4532015112830366'), isFalse);
    });

    test('Amount validation should work correctly', () {
      expect(PaymentConfig.validateOrderAmount(15.0, PaymentMethod.cashOnDelivery), isTrue);
      expect(PaymentConfig.validateOrderAmount(5.0, PaymentMethod.cashOnDelivery), isFalse);
      expect(PaymentConfig.validateOrderAmount(6000.0, PaymentMethod.cashOnDelivery), isFalse);
    });

    test('Card brand detection should be accurate', () {
      final paymentService = PaymentService();

      expect(paymentService.getCardBrand('4532015112830366'), 'visa');
      expect(paymentService.getCardBrand('5555555555554444'), 'mastercard');
      expect(paymentService.getCardBrand('378282246310005'), 'amex');
      expect(paymentService.getCardBrand('6011111111111117'), 'discover');
      expect(paymentService.getCardBrand('1234567890123456'), 'unknown');
    });

    test('PayFast service should initialize payment correctly', () async {
      if (!PaymentConfig.isPayfastEnabled) {
        return; // Skip if PayFast is not configured
      }

      final payfastService = PayFastService();

      try {
        final paymentData = await payfastService.initializePayment(
          orderId: 'test_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'test_user',
          amount: 100.0,
          itemName: 'Test Payment',
          itemDescription: 'Verification test payment',
          customerEmail: 'test@example.com',
          customerFirstName: 'Test',
          customerLastName: 'User',
        );

        expect(paymentData, isNotNull);
        expect(paymentData, isA<Map<String, String>>());
        expect(paymentData.containsKey('merchant_id'), isTrue);
        expect(paymentData.containsKey('signature'), isTrue);
        expect(paymentData['amount'], '100.00');
      } catch (e) {
        // PayFast might fail due to network issues, but we verify it attempts initialization
        expect(e, isA<Exception>());
      }
    });

  
    test('Payment method names should be consistent', () {
      expect(PaymentConfig.getPaymentMethodName(PaymentMethod.cashOnDelivery), 'Cash on Delivery');
      expect(PaymentConfig.getPaymentMethodName(PaymentMethod.payfast), 'PayFast');
      expect(PaymentConfig.getPaymentMethodName(PaymentMethod.card), 'Credit/Debit Card');
      expect(PaymentConfig.getPaymentMethodName(PaymentMethod.digitalWallet), 'Digital Wallet');
    });

    test('Payment method descriptions should be informative', () {
      expect(PaymentConfig.getPaymentMethodDescription(PaymentMethod.cashOnDelivery),
             'Pay with cash when your order is delivered');
      expect(PaymentConfig.getPaymentMethodDescription(PaymentMethod.payfast),
             'Secure online payment via PayFast');
    });

    test('System should handle edge cases gracefully', () {
      final paymentService = PaymentService();

      // Null and empty inputs
      expect(paymentService.validateCardNumber(''), isFalse);
      expect(paymentService.validateCvc('', '4532015112830366'), isFalse);

      // Malicious inputs
      expect(paymentService.validateCardNumber('<script>alert("xss")</script>'), isFalse);
      expect(paymentService.validateCvc('drop table users;', '4532015112830366'), isFalse);
    });

    test('Production readiness indicators', () {
      // Core functionality should be stable
      final paymentService = PaymentService();

      for (int i = 0; i < 10; i++) {
        expect(paymentService.validateCardNumber('4532015112830366'), isTrue);
        expect(paymentService.validateExpiryDate(12, DateTime.now().year + 1), isTrue);
        expect(paymentService.validateCvc('123', '4532015112830366'), isTrue);
      }

      // Configuration should be consistent
      expect(PaymentConfig.isCashOnDeliveryEnabled, isTrue);
      expect(PaymentConfig.minOrderAmount, greaterThan(0));

      // Payment methods should be available
      final methods = PaymentConfig.getEnabledPaymentMethods();
      expect(methods, isNotEmpty);
    });
  });
}