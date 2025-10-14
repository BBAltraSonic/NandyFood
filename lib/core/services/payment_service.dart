import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Payment method types
enum PaymentMethodType {
  cash,
  card,
  // Future payment methods can be added here
  // digitalWallet,
  // bankTransfer,
}

/// Payment status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

/// Card brand types
enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  diners,
  jcb,
  unknown,
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// Initialize Stripe with publishable key
  /// In a real app, this would be called during app initialization
  Future<void> initializeStripe(String publishableKey) async {
    AppLogger.function(
      'PaymentService.initializeStripe',
      'ENTER',
      params: {'keyLength': publishableKey.length},
    );

    try {
      Stripe.publishableKey = publishableKey;
      // For testing purposes, disable URL scheme validation
      await Stripe.instance.applySettings();
      
      AppLogger.success('Stripe initialized successfully');
      AppLogger.function('PaymentService.initializeStripe', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize Stripe', error: e, stack: stack);
      rethrow;
    }
  }

  /// Process cash payment
  /// For cash payments, we simply confirm the order and mark payment as "pending"
  /// Payment will be collected on delivery
  Future<bool> processCashPayment({
    required BuildContext context,
    required double amount,
    required String orderId,
  }) async {
    AppLogger.function(
      'PaymentService.processCashPayment',
      'ENTER',
      params: {
        'amount': amount,
        'orderId': orderId,
      },
    );

    try {
      // Cash on delivery - no actual payment processing needed
      AppLogger.info('Processing cash on delivery payment');

      // Simulate a small delay for UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Record the payment intent in database
      await _recordPaymentIntent(
        orderId: orderId,
        amount: amount,
        method: 'cash',
        status: 'pending',
      );

      AppLogger.success(
        'Cash payment confirmed',
        details: 'Payment will be collected on delivery',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed! Pay cash on delivery.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      AppLogger.function(
        'PaymentService.processCashPayment',
        'EXIT',
        result: true,
      );
      return true;
    } catch (e, stack) {
      AppLogger.error('Cash payment processing failed', error: e, stack: stack);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      AppLogger.function(
        'PaymentService.processCashPayment',
        'EXIT',
        result: false,
      );
      return false;
    }
  }

  /// Process card payment using Stripe
  Future<bool> processCardPayment({
    required BuildContext context,
    required double amount,
    required String orderId,
    required String currency,
    String? customerId,
  }) async {
    AppLogger.function(
      'PaymentService.processCardPayment',
      'ENTER',
      params: {
        'amount': amount,
        'orderId': orderId,
        'currency': currency,
        'customerId': customerId,
      },
    );

    try {
      // Convert amount to cents (smallest currency unit)
      final amountInCents = (amount * 100).round();

      // Present payment sheet to user
      final paymentSheetResult = await _presentPaymentSheet(
        context: context,
        amount: amountInCents,
        currency: currency,
        orderId: orderId,
        customerId: customerId,
      );

      if (paymentSheetResult == null) {
        // User cancelled payment
        AppLogger.info('User cancelled payment');
        return false;
      }

      // Process the payment result
      final paymentResult = await _processPaymentResult(
        context: context,
        paymentResult: paymentSheetResult,
        orderId: orderId,
        amount: amount,
      );

      AppLogger.function(
        'PaymentService.processCardPayment',
        'EXIT',
        result: paymentResult,
      );
      return paymentResult;
    } catch (e, stack) {
      AppLogger.error('Card payment processing failed', error: e, stack: stack);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Record failed payment
      await _recordPaymentIntent(
        orderId: orderId,
        amount: amount,
        method: 'card',
        status: 'failed',
        errorMessage: e.toString(),
      );

      AppLogger.function(
        'PaymentService.processCardPayment',
        'EXIT',
        result: false,
      );
      return false;
    }
  }

  /// Present payment sheet for user to complete payment
  Future<PaymentSheetPaymentOption?> _presentPaymentSheet({
    required BuildContext context,
    required int amount,
    required String currency,
    required String orderId,
    String? customerId,
  }) async {
    try {
      // Create payment intent on backend (this would be an API call in a real app)
      final paymentIntent = await _createPaymentIntent(
        amount: amount,
        currency: currency,
        orderId: orderId,
        customerId: customerId,
      );

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'NandyFood',
          paymentIntentClientSecret: paymentIntent['client_secret'],
          customerId: customerId,
          customerEphemeralKeySecret: paymentIntent['ephemeral_key'],
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFFEF6C3F), // NandyFood orange
            ),
          ),
        ),
      );

      // Present payment sheet to user
      final result = await Stripe.instance.presentPaymentSheet();

      return result;
    } catch (e) {
      AppLogger.error('Failed to present payment sheet', error: e);
      rethrow;
    }
  }

  /// Create payment intent (simulated - in a real app this would call your backend)
  Future<Map<String, dynamic>> _createPaymentIntent({
    required int amount,
    required String currency,
    required String orderId,
    String? customerId,
  }) async {
    // In a real implementation, this would make an HTTP request to your backend
    // which would then call Stripe's API to create a payment intent
    
    // For simulation, we'll return a mock response
    await Future.delayed(const Duration(milliseconds: 800));
    
    return {
      'client_secret': 'pi_mock_secret_1234567890',
      'ephemeral_key': 'ek_mock_1234567890',
      'customer': customerId ?? 'cus_mock_1234567890',
    };
  }

  /// Process payment result from Stripe
  Future<bool> _processPaymentResult({
    required BuildContext context,
    required PaymentSheetPaymentOption paymentResult,
    required String orderId,
    required double amount,
  }) async {
    try {
      // Record successful payment
      await _recordPaymentIntent(
        orderId: orderId,
        amount: amount,
        method: 'card',
        status: 'completed',
        transactionId: paymentResult.label,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Order confirmed.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      return true;
    } catch (e) {
      AppLogger.error('Failed to process payment result', error: e);
      rethrow;
    }
  }

  /// Record payment intent in database
  Future<void> _recordPaymentIntent({
    required String orderId,
    required double amount,
    required String method,
    required String status,
    String? transactionId,
    String? errorMessage,
  }) async {
    try {
      AppLogger.database(
        'INSERT',
        'payment_transactions',
        data: {
          'order_id': orderId,
          'amount': amount,
          'method': method,
          'status': status,
        },
      );

      await _dbService.client.from('payment_transactions').insert({
        'order_id': orderId,
        'amount': amount,
        'payment_method': method,
        'status': status,
        'transaction_id': transactionId,
        'error_message': errorMessage,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.success('Payment intent recorded');
    } catch (e) {
      AppLogger.warning('Failed to record payment intent: $e');
      // Don't throw - this shouldn't block the order
    }
  }

  /// Confirm cash payment (called when driver confirms payment received)
  Future<bool> confirmCashPayment(String orderId) async {
    AppLogger.function(
      'PaymentService.confirmCashPayment',
      'ENTER',
      params: {'orderId': orderId},
    );

    try {
      await _dbService.client
          .from('payment_transactions')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId)
          .eq('payment_method', 'cash');

      AppLogger.success('Cash payment confirmed');
      AppLogger.function(
        'PaymentService.confirmCashPayment',
        'EXIT',
        result: true,
      );
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to confirm cash payment', error: e, stack: stack);
      AppLogger.function(
        'PaymentService.confirmCashPayment',
        'EXIT',
        result: false,
      );
      return false;
    }
  }

  /// Get payment methods available for orders
  List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return [
      {
        'type': PaymentMethodType.cash,
        'name': 'Cash on Delivery',
        'description': 'Pay with cash when your order arrives',
        'icon': Icons.money,
        'enabled': true,
      },
      {
        'type': PaymentMethodType.card,
        'name': 'Credit/Debit Card',
        'description': 'Pay securely with your card',
        'icon': Icons.credit_card,
        'enabled': true,
      },
    ];
  }

  /// Helper: Get payment method display name
  String getPaymentMethodName(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return 'Cash on Delivery';
      case PaymentMethodType.card:
        return 'Credit/Debit Card';
    }
  }

  /// Validate card number using Luhn algorithm (for future card payments)
  bool validateCardNumber(String cardNumber) {
    // Remove spaces and dashes
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }

    // Check length (13-19 digits for most cards)
    if (cleaned.length < 13 || cleaned.length > 19) {
      return false;
    }

    // Luhn algorithm
    int sum = 0;
    bool alternate = false;

    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return (sum % 10) == 0;
  }

  /// Validate expiry date
  bool validateExpiryDate(int month, int year) {
    if (month < 1 || month > 12) {
      return false;
    }

    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // Handle 2-digit year
    final fullYear = year < 100 ? 2000 + year : year;

    // Check if card is expired
    if (fullYear < currentYear) {
      return false;
    }

    if (fullYear == currentYear && month < currentMonth) {
      return false;
    }

    return true;
  }

  /// Validate CVC/CVV
  bool validateCvc(String cvc, String cardNumber) {
    // Remove spaces
    final cleaned = cvc.replaceAll(RegExp(r'\s'), '');

    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }

    // American Express uses 4 digits, others use 3
    final brand = getCardBrand(cardNumber);
    final expectedLength = (brand == 'amex') ? 4 : 3;

    return cleaned.length == expectedLength;
  }

  /// Get card brand from card number
  String getCardBrand(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');

    if (cleaned.isEmpty) {
      return 'unknown';
    }

    // Visa: starts with 4
    if (RegExp(r'^4').hasMatch(cleaned)) {
      return 'visa';
    }

    // Mastercard: starts with 51-55 or 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(cleaned) ||
        RegExp(
          r'^2(2[2-9][0-9]|[3-6][0-9]{2}|7[0-1][0-9]|720)',
        ).hasMatch(cleaned)) {
      return 'mastercard';
    }

    // American Express: starts with 34 or 37
    if (RegExp(r'^3[47]').hasMatch(cleaned)) {
      return 'amex';
    }

    // Discover: starts with 6011, 622126-622925, 644-649, or 65
    if (RegExp(
      r'^6(?:011|5[0-9]{2}|4[4-9][0-9]|22(1(2[6-9]|[3-9][0-9])|[2-8][0-9]{2}|9([01][0-9]|2[0-5])))',
    ).hasMatch(cleaned)) {
      return 'discover';
    }

    // Diners Club: starts with 36 or 38 or 300-305
    if (RegExp(r'^3(?:0[0-5]|[68])').hasMatch(cleaned)) {
      return 'diners';
    }

    // JCB: starts with 2131, 1800, or 35
    if (RegExp(r'^(?:2131|1800|35)').hasMatch(cleaned)) {
      return 'jcb';
    }

    return 'unknown';
  }

  /// Process a complete order payment based on payment method
  Future<bool> processOrderPayment({
    required BuildContext context,
    required double amount,
    required String orderId,
    required PaymentMethodType paymentMethod,
    String currency = 'usd',
    String? customerId,
  }) async {
    AppLogger.function(
      'PaymentService.processOrderPayment',
      'ENTER',
      params: {
        'amount': amount,
        'orderId': orderId,
        'paymentMethod': paymentMethod.toString(),
        'currency': currency,
      },
    );

    try {
      bool result;
      
      switch (paymentMethod) {
        case PaymentMethodType.cash:
          result = await processCashPayment(
            context: context,
            amount: amount,
            orderId: orderId,
          );
          break;
          
        case PaymentMethodType.card:
          result = await processCardPayment(
            context: context,
            amount: amount,
            orderId: orderId,
            currency: currency,
            customerId: customerId,
          );
          break;
      }

      AppLogger.function(
        'PaymentService.processOrderPayment',
        'EXIT',
        result: result,
      );
      return result;
    } catch (e, stack) {
      AppLogger.error('Order payment processing failed', error: e, stack: stack);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment processing failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      AppLogger.function(
        'PaymentService.processOrderPayment',
        'EXIT',
        result: false,
      );
      return false;
    }
  }

  /// Retry a failed payment
  Future<bool> retryPayment({
    required BuildContext context,
    required String orderId,
    required double amount,
    required PaymentMethodType paymentMethod,
    String currency = 'usd',
    String? customerId,
  }) async {
    AppLogger.function(
      'PaymentService.retryPayment',
      'ENTER',
      params: {
        'orderId': orderId,
        'amount': amount,
        'paymentMethod': paymentMethod.toString(),
      },
    );

    try {
      // Update payment status to processing
      await _dbService.client
          .from('payment_transactions')
          .update({
            'status': 'processing',
            'retry_count': 
                '((SELECT retry_count FROM payment_transactions WHERE order_id = \'$orderId\') + 1)',
          })
          .eq('order_id', orderId);

      // Process the payment again
      final result = await processOrderPayment(
        context: context,
        amount: amount,
        orderId: orderId,
        paymentMethod: paymentMethod,
        currency: currency,
        customerId: customerId,
      );

      AppLogger.function(
        'PaymentService.retryPayment',
        'EXIT',
        result: result,
      );
      return result;
    } catch (e, stack) {
      AppLogger.error('Payment retry failed', error: e, stack: stack);
      
      // Update status to failed
      await _dbService.client
          .from('payment_transactions')
          .update({
            'status': 'failed',
            'error_message': 'Retry failed: ${e.toString()}',
          })
          .eq('order_id', orderId);
      
      AppLogger.function(
        'PaymentService.retryPayment',
        'EXIT',
        result: false,
      );
      return false;
    }
  }
}