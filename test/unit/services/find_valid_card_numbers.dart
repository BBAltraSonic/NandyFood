import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

void main() {
  group('Find Valid Card Numbers', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('Find valid card numbers that pass Luhn algorithm', () {
      // Try different combinations to find valid card numbers
      final testPrefixes = [
        '4', // Visa
        '5', // Mastercard
        '37', // American Express
        '34', // American Express
      ];

      print('Finding valid card numbers...');

      for (final prefix in testPrefixes) {
        // Try different lengths
        for (int length = 13; length <= 19; length++) {
          if (prefix.startsWith('3') && (length != 15))
            continue; // Amex must be 15 digits
          if (!prefix.startsWith('3') && (length == 15))
            continue; // Others aren't 15 digits

          // Generate a test number with the prefix
          String testNumber = prefix;
          while (testNumber.length < length - 1) {
            testNumber += '0';
          }

          // Try different check digits (0-9) to find one that passes Luhn
          for (int checkDigit = 0; checkDigit <= 9; checkDigit++) {
            final fullNumber = testNumber + checkDigit.toString();
            if (paymentService.validateCardNumber(fullNumber)) {
              print(
                'Found valid $prefix card: $fullNumber (length: ${fullNumber.length})',
              );
            }
          }
        }
      }

      // Test some known valid test card numbers
      final knownValidCards = [
        '4242', // Stripe test Visa
        '4000056655665556', // Stripe test Visa
        '55554444', // Stripe test Mastercard
        '378282246310005', // Stripe test Amex
        '371449635398431', // Another Stripe test Amex
      ];

      print('\nTesting known valid test card numbers:');
      for (final card in knownValidCards) {
        final isValid = paymentService.validateCardNumber(card);
        print('$card: ${isValid ? "VALID" : "INVALID"}');
      }
    });
  });
}
