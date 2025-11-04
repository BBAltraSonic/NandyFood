import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/config/payment_config.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Provider for payment configuration
final paymentConfigProvider = FutureProvider<PaymentConfigData>((ref) async {
  try {
    await PaymentConfig.initialize();
    return PaymentConfigData.fromConfig();
  } catch (e, stack) {
    AppLogger.error('Failed to initialize payment config', error: e, stack: stack);
    rethrow;
  }
});

/// Simple wrapper class for PaymentConfig to make it work with Riverpod
class PaymentConfigData {
  final bool isPayfastEnabled;
  final bool isCashOnPickupEnabled;
  final bool isCardPaymentEnabled;
  final bool isDigitalWalletEnabled;

  const PaymentConfigData({
    this.isPayfastEnabled = false,
    this.isCashOnPickupEnabled = true,
    this.isCardPaymentEnabled = false,
    this.isDigitalWalletEnabled = false,
  });

  factory PaymentConfigData.fromConfig() {
    return PaymentConfigData(
      isPayfastEnabled: PaymentConfig.isPayfastEnabled,
      isCashOnPickupEnabled: PaymentConfig.isCashOnPickupEnabled,
      isCardPaymentEnabled: PaymentConfig.isCardPaymentEnabled,
      isDigitalWalletEnabled: PaymentConfig.isDigitalWalletEnabled,
    );
  }
}