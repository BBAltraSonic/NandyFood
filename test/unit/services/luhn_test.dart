import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

void main() {
  group('Luhn Algorithm Tests', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('Find valid card numbers that pass Luhn algorithm', () {
      // Test some known valid test card numbers
      final validCards = [
        '4532015112830366', // Visa
        '555555554444', // Mastercard
        '378282246310005', // American Express
        '4000056655665556', // Another Visa test card
        '520082828210', // Another Mastercard test card
        '371449635398431', // Another Amex test card
      ];

      print('Testing valid card numbers:');
      for (final card in validCards) {
        final isValid = paymentService.validateCardNumber(card);
        print('$card: ${isValid ? "VALID" : "INVALID"}');
      }

      // Test some invalid card numbers
      final invalidCards = [
        '1234567890123456',
        '1111',
        '4532015112830367', // One digit different from valid Visa
      ];

      print('\nTesting invalid card numbers:');
      for (final card in invalidCards) {
        final isValid = paymentService.validateCardNumber(card);
        print('$card: ${isValid ? "VALID" : "INVALID"}');
      }
    });
  });
}
