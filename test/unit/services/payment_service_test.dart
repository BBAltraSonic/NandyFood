import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

void main() {
  group('PaymentService Tests', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('PaymentService should be a singleton', () {
      final instance1 = PaymentService();
      final instance2 = PaymentService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('PaymentService should initialize without errors', () async {
      // PaymentService initializes automatically on first use
      expect(paymentService, isNotNull);
      expect(paymentService, isA<PaymentService>());
    });

    test('PaymentService should validate card numbers correctly', () {
      // Test valid card numbers (these are actual valid test card numbers that pass Luhn)
      expect(
        paymentService.validateCardNumber('4532015112830366'),
        isTrue,
      ); // Visa (valid Luhn)
      expect(
        paymentService.validateCardNumber('378282246310005'),
        isTrue,
      ); // American Express (valid Luhn)
      expect(
        paymentService.validateCardNumber('371449635398431'),
        isTrue,
      ); // Another Amex (valid Luhn)

      // Test invalid card numbers
      expect(paymentService.validateCardNumber('400005665556'), isFalse);
      expect(paymentService.validateCardNumber('1234567890123456'), isFalse);
      expect(paymentService.validateCardNumber(''), isFalse);
      expect(paymentService.validateCardNumber('123'), isFalse);
      expect(
        paymentService.validateCardNumber('555555554444'),
        isFalse,
      ); // Invalid Luhn
      expect(paymentService.validateCardNumber('abcd1234'), isFalse); // Non-numeric
    });

    test('PaymentService should identify card brands correctly', () {
      // Test Visa
      expect(paymentService.getCardBrand('4532015112830366'), 'visa');
      expect(paymentService.getCardBrand('4111111111111111'), 'visa');

      // Test Mastercard
      expect(paymentService.getCardBrand('5555555555554444'), 'mastercard');
      expect(paymentService.getCardBrand('2223000048400011'), 'mastercard');

      // Test American Express
      expect(paymentService.getCardBrand('378282246310005'), 'amex');
      expect(paymentService.getCardBrand('371449635398431'), 'amex');

      // Test unknown
      expect(paymentService.getCardBrand('1234567890123456'), 'unknown');
      expect(paymentService.getCardBrand(''), 'unknown');
    });

    test('PaymentService should validate card expiry dates', () {
      // Test valid expiry dates
      expect(paymentService.validateExpiryDate(12, 2025), isTrue);
      expect(paymentService.validateExpiryDate(6, 2030), isTrue);

      // Test invalid expiry dates
      expect(paymentService.validateExpiryDate(1, 2020), isFalse); // Past year
      expect(paymentService.validateExpiryDate(13, 2025), isFalse); // Invalid month
      expect(paymentService.validateExpiryDate(0, 2025), isFalse); // Invalid month
    });

    test('PaymentService should validate CVC/CVV', () {
      // Test valid CVC for regular cards
      expect(paymentService.validateCvc('123', '4532015112830366'), isTrue);
      expect(paymentService.validateCvc('456', '378282246310005'), isFalse); // Amex needs 4 digits

      // Test valid CVC for American Express
      expect(paymentService.validateCvc('1234', '378282246310005'), isTrue);

      // Test invalid CVC
      expect(paymentService.validateCvc('12', '4532015112830366'), isFalse);
      expect(paymentService.validateCvc('abcd', '4532015112830366'), isFalse);
    });

    test('PaymentService should provide available payment methods', () {
      final methods = paymentService.getAvailablePaymentMethods();
      expect(methods, isA<List<Map<String, dynamic>>>());
      expect(methods.isNotEmpty, isTrue);

      // Check that cash on delivery is enabled
      final cashMethod = methods.firstWhere(
        (method) => method['type'] == PaymentMethodType.cash,
        orElse: () => <String, dynamic>{},
      );
      expect(cashMethod['enabled'], isTrue);
    });

    test('PaymentService should get payment method names', () {
      expect(paymentService.getPaymentMethodName(PaymentMethodType.cash), 'Cash on Delivery');
      expect(paymentService.getPaymentMethodName(PaymentMethodType.card), 'Credit/Debit Card');
    });
  });
}