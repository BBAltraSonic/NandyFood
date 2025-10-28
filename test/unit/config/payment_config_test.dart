import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/config/payment_config.dart';

void main() {
  group('PaymentConfig Tests', () {
    setUpAll(() async {
      // Load test environment variables
      await dotenv.load(fileName: '.env');
    });

    test('PaymentConfig should initialize without errors', () async {
      await PaymentConfig.initialize();
      expect(PaymentConfig.isCashOnDeliveryEnabled, isTrue);
    });

    test('PaymentConfig should have cash on delivery enabled', () async {
      await PaymentConfig.initialize();
      expect(PaymentConfig.isCashOnDeliveryEnabled, isTrue);
    });

    test('PaymentConfig should provide enabled payment methods', () async {
      await PaymentConfig.initialize();
      final methods = PaymentConfig.getEnabledPaymentMethods();
      expect(methods, isNotEmpty);
      expect(methods.contains(PaymentMethod.cashOnDelivery), isTrue);
    });

    test('PaymentConfig should validate order amounts', () async {
      await PaymentConfig.initialize();

      // Test valid amounts
      expect(PaymentConfig.validateOrderAmount(50.0, PaymentMethod.cashOnDelivery), isTrue);
      expect(PaymentConfig.validateOrderAmount(5000.0, PaymentMethod.cashOnDelivery), isTrue);

      // Test invalid amounts (below minimum)
      expect(PaymentConfig.validateOrderAmount(5.0, PaymentMethod.cashOnDelivery), isFalse);

      // Test invalid amounts (above cash maximum)
      expect(PaymentConfig.validateOrderAmount(6000.0, PaymentMethod.cashOnDelivery), isFalse);
    });

    test('PaymentConfig should provide method names and descriptions', () async {
      await PaymentConfig.initialize();

      expect(PaymentConfig.getPaymentMethodName(PaymentMethod.cashOnDelivery), 'Cash on Delivery');
      expect(PaymentConfig.getPaymentMethodDescription(PaymentMethod.cashOnDelivery), contains('Pay with cash'));
    });

    test('PaymentConfig should generate report', () async {
      await PaymentConfig.initialize();
      final report = PaymentConfig.generateReport();
      expect(report, isA<Map<String, dynamic>>());
      expect(report['enabled_methods'], isA<List>());
      expect(report['cash_on_delivery']['enabled'], isTrue);
    });
  });
}