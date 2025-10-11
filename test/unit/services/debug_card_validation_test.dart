import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

void main() {
  group('Debug Card Validation Tests', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('Debug card validation for known valid numbers', () {
      // Test the valid card numbers we found earlier
      final validCards = [
        '4532015112830366', // Visa
        '378282246310005', // American Express
        '4000056655665556', // Another Visa
        '371449635398431', // Another Amex
      ];

      print('Testing valid card numbers:');
      for (final card in validCards) {
        // Test each step of the validation
        final cleanCardNumber = card.replaceAll(RegExp(r'\s+'), '');
        print('Card: $card');
        print('Clean: $cleanCardNumber');
        print(
          'Length check: ${RegExp(r'^\d{13,19}$').hasMatch(cleanCardNumber)}',
        );

        if (RegExp(r'^\d{13,19}$').hasMatch(cleanCardNumber)) {
          final luhnResult = paymentService.validateCardNumber(card);
          print('Luhn result: $luhnResult');
        } else {
          print('Failed length check');
        }
        print('---');
      }
    });
  });
}
