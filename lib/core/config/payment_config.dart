import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/config/environment_config.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Payment method types available in the app
enum PaymentMethod {
  cashOnDelivery,
  payfast,
  card,
  digitalWallet,
}

/// Payment strategy configuration
class PaymentConfig {
  static bool _isInitialized = false;

  // Payment method enablement flags
  static bool _cashOnDeliveryEnabled = true;
  static bool _payfastEnabled = false;
  static bool _cardPaymentEnabled = false;
  static bool _digitalWalletEnabled = false;

  // PayFast configuration
  static bool _payfastSandboxMode = true;
  static String? _payfastMerchantId;
  static String? _payfastMerchantKey;
  static String? _payfastPassphrase;

  // Minimum/maximum amounts
  static double _minOrderAmount = 0.0;
  static double _maxCashAmount = 5000.0; // Max amount for cash payment

  /// Initialize payment configuration
  static Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.debug('PaymentConfig already initialized');
      return;
    }

    AppLogger.init('Initializing payment configuration...');

    try {
      // Load payment method flags from environment
      _cashOnDeliveryEnabled = _getBoolEnv('ENABLE_CASH_ON_DELIVERY', defaultValue: true);
      _payfastEnabled = _getBoolEnv('ENABLE_PAYFAST', defaultValue: false);
      _cardPaymentEnabled = _getBoolEnv('ENABLE_CARD_PAYMENT', defaultValue: false);
      _digitalWalletEnabled = _getBoolEnv('ENABLE_DIGITAL_WALLET', defaultValue: false);

      // Load PayFast configuration
      _payfastSandboxMode = _getBoolEnv('PAYFAST_SANDBOX', defaultValue: true);
      _payfastMerchantId = dotenv.maybeGet('PAYFAST_MERCHANT_ID');
      _payfastMerchantKey = dotenv.maybeGet('PAYFAST_MERCHANT_KEY');
      _payfastPassphrase = dotenv.maybeGet('PAYFAST_PASSPHRASE');

      // Load amount limits
      _minOrderAmount = _getDoubleEnv('MIN_ORDER_AMOUNT', defaultValue: 0.0);
      _maxCashAmount = _getDoubleEnv('MAX_CASH_AMOUNT', defaultValue: 5000.0);

      // Validate PayFast configuration if enabled
      if (_payfastEnabled) {
        _validatePayfastConfig();
      }

      _isInitialized = true;

      AppLogger.success('Payment configuration initialized');
      _logPaymentConfig();
    } catch (e, stack) {
      AppLogger.error('Failed to initialize payment configuration', error: e, stack: stack);
      // Fallback to cash-only mode on error
      _cashOnDeliveryEnabled = true;
      _payfastEnabled = false;
      _cardPaymentEnabled = false;
      _digitalWalletEnabled = false;
      _isInitialized = true;
      AppLogger.warning('Falling back to cash-only payment mode');
    }
  }

  /// Validate PayFast configuration
  static void _validatePayfastConfig() {
    final missingFields = <String>[];

    if (_payfastMerchantId == null || _payfastMerchantId!.isEmpty) {
      missingFields.add('PAYFAST_MERCHANT_ID');
    }
    if (_payfastMerchantKey == null || _payfastMerchantKey!.isEmpty) {
      missingFields.add('PAYFAST_MERCHANT_KEY');
    }
    if (_payfastPassphrase == null || _payfastPassphrase!.isEmpty) {
      missingFields.add('PAYFAST_PASSPHRASE');
    }

    if (missingFields.isNotEmpty) {
      AppLogger.warning(
        'PayFast enabled but missing configuration: ${missingFields.join(", ")}',
      );
      _payfastEnabled = false;
      AppLogger.info('PayFast has been disabled due to missing configuration');
    }
  }

  /// Log payment configuration (without sensitive data)
  static void _logPaymentConfig() {
    final config = {
      'cash_on_delivery': _cashOnDeliveryEnabled,
      'payfast': _payfastEnabled,
      'payfast_sandbox': _payfastEnabled ? _payfastSandboxMode : null,
      'card_payment': _cardPaymentEnabled,
      'digital_wallet': _digitalWalletEnabled,
      'min_order_amount': _minOrderAmount,
      'max_cash_amount': _maxCashAmount,
      'environment': EnvironmentConfig.current.name,
    };

    AppLogger.debug('Payment Configuration:', data: config);
  }

  // ==================== GETTERS ====================

  /// Check if cash on delivery is enabled
  static bool get isCashOnDeliveryEnabled => _cashOnDeliveryEnabled;

  /// Check if PayFast is enabled
  static bool get isPayfastEnabled => _payfastEnabled;

  /// Check if card payment is enabled
  static bool get isCardPaymentEnabled => _cardPaymentEnabled;

  /// Check if digital wallet is enabled
  static bool get isDigitalWalletEnabled => _digitalWalletEnabled;

  /// Get PayFast sandbox mode
  static bool get isPayfastSandboxMode => _payfastSandboxMode;

  /// Get PayFast merchant ID
  static String? get payfastMerchantId => _payfastMerchantId;

  /// Get PayFast merchant key
  static String? get payfastMerchantKey => _payfastMerchantKey;

  /// Get PayFast passphrase
  static String? get payfastPassphrase => _payfastPassphrase;

  /// Get minimum order amount
  static double get minOrderAmount => _minOrderAmount;

  /// Get maximum cash amount
  static double get maxCashAmount => _maxCashAmount;

  /// Get list of enabled payment methods
  static List<PaymentMethod> getEnabledPaymentMethods() {
    final methods = <PaymentMethod>[];

    if (_cashOnDeliveryEnabled) methods.add(PaymentMethod.cashOnDelivery);
    if (_payfastEnabled) methods.add(PaymentMethod.payfast);
    if (_cardPaymentEnabled) methods.add(PaymentMethod.card);
    if (_digitalWalletEnabled) methods.add(PaymentMethod.digitalWallet);

    return methods;
  }

  /// Get default payment method
  static PaymentMethod getDefaultPaymentMethod() {
    if (_cashOnDeliveryEnabled) return PaymentMethod.cashOnDelivery;
    if (_payfastEnabled) return PaymentMethod.payfast;
    if (_cardPaymentEnabled) return PaymentMethod.card;
    if (_digitalWalletEnabled) return PaymentMethod.digitalWallet;

    // Fallback to cash on delivery
    return PaymentMethod.cashOnDelivery;
  }

  // ==================== VALIDATION ====================

  /// Check if a payment method is enabled
  static bool isPaymentMethodEnabled(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return _cashOnDeliveryEnabled;
      case PaymentMethod.payfast:
        return _payfastEnabled;
      case PaymentMethod.card:
        return _cardPaymentEnabled;
      case PaymentMethod.digitalWallet:
        return _digitalWalletEnabled;
    }
  }

  /// Validate order amount for payment method
  static bool validateOrderAmount(double amount, PaymentMethod method) {
    // Check minimum order amount
    if (amount < _minOrderAmount) {
      AppLogger.warning('Order amount below minimum: \$$amount < \$$_minOrderAmount');
      return false;
    }

    // Check maximum cash amount for COD
    if (method == PaymentMethod.cashOnDelivery && amount > _maxCashAmount) {
      AppLogger.warning('Cash payment exceeds maximum: \$$amount > \$$_maxCashAmount');
      return false;
    }

    return true;
  }

  /// Get payment method display name
  static String getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.payfast:
        return 'PayFast';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
    }
  }

  /// Get payment method description
  static String getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Pay with cash when your order is delivered';
      case PaymentMethod.payfast:
        return 'Secure online payment via PayFast';
      case PaymentMethod.card:
        return 'Pay with your credit or debit card';
      case PaymentMethod.digitalWallet:
        return 'Pay with your digital wallet';
    }
  }

  /// Get payment method icon name
  static String getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'payments'; // Material Icons name
      case PaymentMethod.payfast:
        return 'account_balance';
      case PaymentMethod.card:
        return 'credit_card';
      case PaymentMethod.digitalWallet:
        return 'account_balance_wallet';
    }
  }

  // ==================== CONFIGURATION REPORT ====================

  /// Generate payment configuration report
  static Map<String, dynamic> generateReport() {
    return {
      'is_initialized': _isInitialized,
      'enabled_methods': getEnabledPaymentMethods().map((m) => m.name).toList(),
      'default_method': getDefaultPaymentMethod().name,
      'cash_on_delivery': {
        'enabled': _cashOnDeliveryEnabled,
        'max_amount': _maxCashAmount,
      },
      'payfast': {
        'enabled': _payfastEnabled,
        'sandbox_mode': _payfastSandboxMode,
        'configured': _payfastMerchantId != null && _payfastMerchantKey != null,
      },
      'card_payment': {
        'enabled': _cardPaymentEnabled,
      },
      'digital_wallet': {
        'enabled': _digitalWalletEnabled,
      },
      'limits': {
        'min_order_amount': _minOrderAmount,
        'max_cash_amount': _maxCashAmount,
      },
      'environment': EnvironmentConfig.current.name,
    };
  }

  // ==================== HELPER METHODS ====================

  /// Get boolean environment variable
  static bool _getBoolEnv(String key, {required bool defaultValue}) {
    try {
      final value = dotenv.maybeGet(key);
      if (value == null) return defaultValue;
      return value.toLowerCase() == 'true' || value == '1';
    } catch (e) {
      return defaultValue;
    }
  }

  /// Get double environment variable
  static double _getDoubleEnv(String key, {required double defaultValue}) {
    try {
      final value = dotenv.maybeGet(key);
      if (value == null) return defaultValue;
      return double.parse(value);
    } catch (e) {
      return defaultValue;
    }
  }

  // ==================== RUNTIME CONFIGURATION ====================

  /// Enable/disable payment method at runtime (for testing)
  static void setPaymentMethodEnabled(PaymentMethod method, bool enabled) {
    if (!EnvironmentConfig.isDevelopment) {
      AppLogger.warning('Cannot modify payment config in production');
      return;
    }

    switch (method) {
      case PaymentMethod.cashOnDelivery:
        _cashOnDeliveryEnabled = enabled;
        break;
      case PaymentMethod.payfast:
        _payfastEnabled = enabled;
        break;
      case PaymentMethod.card:
        _cardPaymentEnabled = enabled;
        break;
      case PaymentMethod.digitalWallet:
        _digitalWalletEnabled = enabled;
        break;
    }

    AppLogger.debug('Payment method ${method.name} ${enabled ? "enabled" : "disabled"}');
  }

  /// Reset to default configuration
  static Future<void> reset() async {
    _isInitialized = false;
    await initialize();
  }
}
