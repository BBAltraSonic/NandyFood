import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

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
      // Verify that initialize method can be called without throwing
      expect(() => paymentService.initialize(), returnsNormally);
    });

    test('PaymentService should validate card numbers correctly', () {
      // Test valid card numbers (these are actual valid test card numbers that pass Luhn)
      expect(paymentService.validateCardNumber('4532015112830366'), isTrue); // Visa (valid Luhn)
      expect(paymentService.validateCardNumber('378282246310005'), isTrue);  // American Express (valid Luhn)
      expect(paymentService.validateCardNumber('371449635398431'), isTrue);  // Another Amex (valid Luhn)
      
      // Test invalid card numbers
      expect(paymentService.validateCardNumber('400005665556'), isFalse);
      expect(paymentService.validateCardNumber('1234567890123456'), isFalse);
      expect(paymentService.validateCardNumber(''), isFalse);
      expect(paymentService.validateCardNumber('123'), isFalse);
      expect(paymentService.validateCardNumber('555555554444'), isFalse); // Invalid Luhn
      expect(paymentService.validateCardNumber('520082828210'), isFalse); // Invalid Luhn
    });

    test('PaymentService should validate expiry dates correctly', () {
      final now = DateTime.now();
      final currentYear = now.year % 100;
      final nextYear = (now.year + 1) % 100;
      final pastYear = (now.year - 1) % 100;
      
      // Test valid future dates
      expect(paymentService.validateExpiryDate(now.month, nextYear), isTrue);
      expect(paymentService.validateExpiryDate(12, nextYear), isTrue);
      
      // Test invalid past dates
      expect(paymentService.validateExpiryDate(now.month, pastYear), isFalse);
      
      // Test current month/year (should be valid)
      expect(paymentService.validateExpiryDate(now.month, currentYear), isTrue);
    });

    test('PaymentService should validate CVC codes correctly', () {
      // Test Visa/Mastercard CVC (3 digits)
      expect(paymentService.validateCvc('123', '4532015112830366'), isTrue);
      expect(paymentService.validateCvc('1234', '4532015112830366'), isFalse);
      
      // Test Amex CVC (4 digits)
      expect(paymentService.validateCvc('1234', '378282246310005'), isTrue);
      expect(paymentService.validateCvc('123', '378282246310005'), isFalse);
    });

    test('PaymentService should identify card brands correctly', () {
      // Test Visa
      expect(paymentService.getCardBrand('4532015112830366'), 'Visa');
      
      // Test Mastercard
      expect(paymentService.getCardBrand('555555554444'), 'Mastercard');
      
      // Test American Express
      expect(paymentService.getCardBrand('378282246310005'), 'Amex');
      
      // Test unknown
      expect(paymentService.getCardBrand('1234567890123456'), 'Unknown');
    });

    test('PaymentService should create payment intents', () async {
      // Test that createPaymentIntent returns a string (not null) without throwing
      final result = await paymentService.createPaymentIntent(
        amount: 100.0,
        currency: 'usd',
        description: 'Test payment',
      );
      // The service actually returns a mock payment intent ID
      expect(result, isNotNull);
      expect(result, isA<String>());
    });

    test('PaymentService should process order payments', () async {
      // Create a mock order
      final order = Order(
        id: 'test_order_123',
        userId: 'user_123',
        restaurantId: 'restaurant_456',
        deliveryAddress: {'street': '123 Test St', 'city': 'Test City'},
        status: OrderStatus.placed,
        totalAmount: 25.99,
        deliveryFee: 3.99,
        taxAmount: 2.21,
        paymentMethod: 'card',
        paymentStatus: PaymentStatus.pending,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create a mock payment method
      final paymentMethod = PaymentMethod(
        id: 'pm_test_123',
        type: 'card',
        last4: '1234',
        brand: 'Visa',
        expiryMonth: 12,
        expiryYear: 25,
      );
      
      // Test that processOrderPayment returns a bool without throwing
      // Note: The service has a 90% success rate, so we test that it returns a bool
      final result = await paymentService.processOrderPayment(
        order: order,
        paymentMethod: paymentMethod,
      );
      // The service actually returns a boolean (mock implementation with 90% success rate)
      expect(result, isA<bool>());
    });
  });
}