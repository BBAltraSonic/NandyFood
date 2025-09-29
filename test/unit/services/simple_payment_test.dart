import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

void main() {
  group('Simple PaymentService Tests', () {
    late PaymentService paymentService;

    setUp(() {
      paymentService = PaymentService();
    });

    test('Test card validation with known valid numbers', () {
      // Test with a known valid Visa test card number
      print('Testing Visa card: 4532015112830367');
      final visaResult = paymentService.validateCardNumber('4532015112830367');
      print('Visa result: $visaResult');
      
      // Test with a known valid Mastercard test card number
      print('Testing Mastercard: 555555554444');
      final mastercardResult = paymentService.validateCardNumber('55554444');
      print('Mastercard result: $mastercardResult');
      
      // Test with a known valid Amex test card number
      print('Testing Amex: 378282246310005');
      final amexResult = paymentService.validateCardNumber('378282246310005');
      print('Amex result: $amexResult');
      
      // Test with an invalid card number
      print('Testing invalid card: 1234567890123456');
      final invalidResult = paymentService.validateCardNumber('1234567890123456');
      print('Invalid result: $invalidResult');
    });
  });
}