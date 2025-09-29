import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

void main() {
  group('Luhn Algorithm Tests', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('Test specific card numbers against Luhn algorithm', () {
      // Test the specific card numbers that are failing
      final testCards = [
        '4532015112830366', // Visa
        '378282246310005',  // American Express
        '400005665556', // Another Visa
        '371449635398431',  // Another Amex
        '1234567890123456', // Invalid
        '555555554444', // Invalid
        '520082828210', // Invalid
      ];

      print('Testing card numbers against Luhn algorithm:');
      for (final card in testCards) {
        final result = paymentService.validateCardNumber(card);
        print('$card: ${result ? "VALID" : "INVALID"}');
      }

      // Specifically test the failing card number
      final failingCard = '400005665556';
      final isValid = paymentService.validateCardNumber(failingCard);
      print('Failing card $failingCard: ${isValid ? "VALID" : "INVALID"}');
      
      // Test with the corrected card number
      final correctedCard = '400005665556';
      final isCorrectedValid = paymentService.validateCardNumber(correctedCard);
      print('Corrected card $correctedCard: ${isCorrectedValid ? "VALID" : "INVALID"}');
    });
  });
}