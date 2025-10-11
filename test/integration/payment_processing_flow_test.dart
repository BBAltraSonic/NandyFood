import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/order.dart';

void main() {
  group('Payment Processing Flow Integration Tests', () {
    late DatabaseService dbService;
    late PaymentService paymentService;
    late ProviderContainer container;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();
      
      // Initialize payment service
      paymentService = PaymentService();
      
      // Create a provider container for testing
      container = ProviderContainer();
    });

    tearDown(() {
      // Dispose of the provider container
      container.dispose();
      
      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    test('successful credit card payment processing', () async {
      // Create a test order
      final testOrder = Order(
        id: 'payment_order_1',
        userId: 'payment_user_1',
        restaurantId: 'payment_restaurant_1',
        deliveryAddress: {
          'street': '123 Payment St',
          'city': 'Payment City',
          'zipCode': '12345',
        },
        status: OrderStatus.placed,
        totalAmount: 25.99,
        deliveryFee: 2.99,
        taxAmount: 2.10,
        tipAmount: 3.00,
        discountAmount: 0.00,
        paymentMethod: 'card',
        paymentStatus: PaymentStatus.pending,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create a payment method
      final paymentMethod = PaymentMethod(
        id: 'pm_card_1',
        type: 'card',
        last4: '4242',
        brand: 'Visa',
        expiryMonth: 12,
        expiryYear: 25,
      );

      // Process the payment
      final paymentResult = await paymentService.processOrderPayment(
        order: testOrder,
        paymentMethod: paymentMethod,
      );

      // Verify payment was successful
      expect(paymentResult, isTrue);

      // Verify payment method was created
      expect(paymentMethod.id, isNotEmpty);
      expect(paymentMethod.type, 'card');
      expect(paymentMethod.last4, '4242');
      expect(paymentMethod.brand, 'Visa');
    });

    test('failed payment with invalid card', () async {
      // Create a test order
      final testOrder = Order(
        id: 'payment_order_2',
        userId: 'payment_user_2',
        restaurantId: 'payment_restaurant_2',
        deliveryAddress: {
          'street': '456 Invalid St',
          'city': 'Invalid City',
          'zipCode': '67890',
        },
        status: OrderStatus.placed,
        totalAmount: 32.50,
        deliveryFee: 3.99,
        taxAmount: 2.75,
        tipAmount: 4.00,
        discountAmount: 2.00,
        paymentMethod: 'card',
        paymentStatus: PaymentStatus.pending,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create an invalid payment method
      final invalidPaymentMethod = PaymentMethod(
        id: 'pm_invalid_1',
        type: 'card',
        last4: '0000', // Invalid card number
        brand: 'Unknown',
        expiryMonth: 1,
        expiryYear: 20, // Expired card
      );

      // Process the payment
      final paymentResult = await paymentService.processOrderPayment(
        order: testOrder,
        paymentMethod: invalidPaymentMethod,
      );

      // Verify payment failed
      expect(paymentResult, isFalse);
    });

    test('payment intent creation and confirmation', () async {
      // Create payment intent
      final paymentIntentId = await paymentService.createPaymentIntent(
        amount: 2999, // $29.99 in cents
        currency: 'usd',
        description: 'Test order payment',
      );

      // Verify payment intent was created
      expect(paymentIntentId, isNotNull);
      expect(paymentIntentId, startsWith('pi_mock_'));

      // Create a payment method
      final paymentMethod = PaymentMethod(
        id: 'pm_card_2',
        type: 'card',
        last4: '1234',
        brand: 'Mastercard',
        expiryMonth: 6,
        expiryYear: 26,
      );

      // Confirm the payment
      final confirmationResult = await paymentService.confirmPayment(
        paymentIntentId: paymentIntentId!,
        paymentMethod: paymentMethod,
      );

      // Verify payment confirmation result
      expect(confirmationResult, isA<bool>());
    });

    test('card validation', () async {
      // Test valid card numbers
      final validCards = [
        '4242424242424242', // Visa
        '5555555555554444', // Mastercard
        '378282246310005',  // American Express
      ];

      for (final cardNumber in validCards) {
        final isValid = paymentService.validateCardNumber(cardNumber);
        expect(isValid, isTrue, reason: 'Card $cardNumber should be valid');
      }

      // Test invalid card numbers
      final invalidCards = [
        '1234567890123456', // Invalid Luhn checksum
        '1234',             // Too short
        '12345678901234567890', // Too long
        'abcdabcdabcdabcd', // Contains letters
      ];

      for (final cardNumber in invalidCards) {
        final isValid = paymentService.validateCardNumber(cardNumber);
        expect(isValid, isFalse, reason: 'Card $cardNumber should be invalid');
      }
    });

    test('expiry date validation', () async {
      final now = DateTime.now();
      final currentYear = now.year % 100; // Get last 2 digits of year
      final currentMonth = now.month;

      // Test valid expiry dates
      final validExpiryDates = [
        [currentMonth, currentYear],           // Current month/year
        [12, currentYear + 1],                 // Next year
        [currentMonth, currentYear + 2],       // Two years from now
      ];

      for (final date in validExpiryDates) {
        final isValid = paymentService.validateExpiryDate(date[0], date[1]);
        expect(isValid, isTrue, reason: 'Expiry date ${date[0]}/${date[1]} should be valid');
      }

      // Test invalid expiry dates
      final invalidExpiryDates = [
        [currentMonth, currentYear - 1],       // Previous year (expired)
        [currentMonth - 1, currentYear - 1],   // Previous month and year (expired)
      ];

      for (final date in invalidExpiryDates) {
        final isValid = paymentService.validateExpiryDate(date[0], date[1]);
        expect(isValid, isFalse, reason: 'Expiry date ${date[0]}/${date[1]} should be invalid');
      }
    });

    test('cvv validation', () async {
      // Test valid CVVs for regular cards
      final validCVVs = ['123', '456', '789'];
      for (final cvv in validCVVs) {
        final isValid = paymentService.validateCvc(cvv, '4242424242424242');
        expect(isValid, isTrue, reason: 'CVV $cvv should be valid for regular card');
      }

      // Test valid CVVs for American Express cards
      final validAmexCVVs = ['1234', '5678'];
      for (final cvv in validAmexCVVs) {
        final isValid = paymentService.validateCvc(cvv, '378282246310005');
        expect(isValid, isTrue, reason: 'CVV $cvv should be valid for Amex card');
      }

      // Test invalid CVVs
      final invalidCVVs = ['12', '12345', 'abc', ''];
      for (final cvv in invalidCVVs) {
        final isValid = paymentService.validateCvc(cvv, '4242424242424242');
        expect(isValid, isFalse, reason: 'CVV $cvv should be invalid for regular card');
      }
    });

    test('card brand detection', () async {
      // Test Visa card detection
      final visaCards = ['4242424242424242', '4000056655665556'];
      for (final cardNumber in visaCards) {
        final brand = paymentService.getCardBrand(cardNumber);
        expect(brand, 'Visa', reason: 'Card $cardNumber should be detected as Visa');
      }

      // Test Mastercard detection
      final mastercardCards = ['5555555555554444', '5200828282828282'];
      for (final cardNumber in mastercardCards) {
        final brand = paymentService.getCardBrand(cardNumber);
        expect(brand, 'Mastercard', reason: 'Card $cardNumber should be detected as Mastercard');
      }

      // Test American Express detection
      final amexCards = ['378282246310005', '371449635398431'];
      for (final cardNumber in amexCards) {
        final brand = paymentService.getCardBrand(cardNumber);
        expect(brand, 'Amex', reason: 'Card $cardNumber should be detected as Amex');
      }

      // Test unknown brand detection
      final unknownCards = ['1234567890123456', '9999999999999999'];
      for (final cardNumber in unknownCards) {
        final brand = paymentService.getCardBrand(cardNumber);
        expect(brand, 'Unknown', reason: 'Card $cardNumber should be detected as Unknown');
      }
    });

    test('payment method creation from card details', () async {
      // Create a payment method from card details
      final paymentMethod = await paymentService.createPaymentMethod(
        type: 'card',
        number: '4242424242424242',
        expiryMonth: 12,
        expiryYear: 25,
        cvc: '123',
        holderName: 'Test User',
      );

      // Verify payment method was created correctly
      expect(paymentMethod, isNotNull);
      expect(paymentMethod.id, startsWith('pm_mock_'));
      expect(paymentMethod.type, 'card');
      expect(paymentMethod.last4, '4242');
      expect(paymentMethod.brand, 'Visa');
      expect(paymentMethod.expiryMonth, 12);
      expect(paymentMethod.expiryYear, 25);
    });
  });
}