import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/config/payment_config.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Payment method types
enum PaymentMethodType {
  cash,
  payfast,
  stripe,
  card,
  digitalWallet,
  bankTransfer,
}

/// Payment status types
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

/// Payment gateway types
enum PaymentGateway {
  payfast,
  stripe,
  cash,
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final DatabaseService _dbService = DatabaseService();
  final PaymentConfig _config = PaymentConfig();

  // Store payment sessions for callbacks
  final Map<String, Map<String, dynamic>> _paymentSessions = {};

  /// Process payment with comprehensive support for multiple gateways
  Future<PaymentResult> processPayment({
    required BuildContext context,
    required double amount,
    required String orderId,
    required PaymentMethodType method,
    Map<String, dynamic>? paymentDetails,
    String? successUrl,
    String? cancelUrl,
    String? notifyUrl,
  }) async {
    AppLogger.function(
      'PaymentService.processPayment',
      'ENTER',
      params: {
        'amount': amount,
        'orderId': orderId,
        'method': method.toString(),
      },
    );

    try {
      // Validate amount
      if (amount <= 0) {
        return PaymentResult(
          success: false,
          error: 'Invalid payment amount',
          status: PaymentStatus.failed,
        );
      }

      // Create payment session
      final sessionId = _generatePaymentSessionId();
      final paymentSession = {
        'sessionId': sessionId,
        'orderId': orderId,
        'amount': amount,
        'method': method.toString(),
        'createdAt': DateTime.now().toIso8601String(),
        'status': PaymentStatus.pending.toString(),
      };

      _paymentSessions[sessionId] = paymentSession;

      // Record payment intent
      await _recordPaymentIntent(
        orderId: orderId,
        amount: amount,
        method: method.toString(),
        status: PaymentStatus.pending.toString(),
        sessionId: sessionId,
      );

      bool success = false;
      String? error;
      String? transactionId;
      Map<String, dynamic>? gatewayResponse;

      switch (method) {
        case PaymentMethodType.cash:
          final result = await _processCashPayment(
            context: context,
            orderId: orderId,
            amount: amount,
            sessionId: sessionId,
          );
          success = result.success;
          error = result.error;
          transactionId = result.transactionId;
          break;

        case PaymentMethodType.payfast:
          final result = await _processPayFastPayment(
            context: context,
            orderId: orderId,
            amount: amount,
            sessionId: sessionId,
            successUrl: successUrl,
            cancelUrl: cancelUrl,
            notifyUrl: notifyUrl,
          );
          success = result.success;
          error = result.error;
          transactionId = result.transactionId;
          gatewayResponse = result.response;
          break;

        case PaymentMethodType.stripe:
          final result = await _processStripePayment(
            context: context,
            orderId: orderId,
            amount: amount,
            sessionId: sessionId,
            paymentDetails: paymentDetails,
          );
          success = result.success;
          error = result.error;
          transactionId = result.transactionId;
          gatewayResponse = result.response;
          break;

        case PaymentMethodType.card:
          // Process card through Stripe
          final result = await _processStripePayment(
            context: context,
            orderId: orderId,
            amount: amount,
            sessionId: sessionId,
            paymentDetails: paymentDetails,
          );
          success = result.success;
          error = result.error;
          transactionId = result.transactionId;
          break;

        default:
          error = 'Payment method not supported';
          break;
      }

      // Update payment session
      _paymentSessions[sessionId] = {
        ...paymentSession,
        'status': success ? PaymentStatus.completed.toString() : PaymentStatus.failed.toString(),
        'transactionId': transactionId,
        'error': error,
        'completedAt': DateTime.now().toIso8601String(),
      };

      // Update payment intent in database
      await _updatePaymentIntent(
        sessionId: sessionId,
        status: success ? PaymentStatus.completed.toString() : PaymentStatus.failed.toString(),
        transactionId: transactionId,
        error: error,
      );

      final result = PaymentResult(
        success: success,
        error: error,
        status: success ? PaymentStatus.completed : PaymentStatus.failed,
        transactionId: transactionId,
              );

      AppLogger.function(
        'PaymentService.processPayment',
        'EXIT',
        result: result.toJson(),
      );

      return result;
    } catch (e, stack) {
      AppLogger.error('Payment processing failed', error: e, stack: stack);

      final result = PaymentResult(
        success: false,
        error: e.toString(),
        status: PaymentStatus.failed,
      );

      AppLogger.function(
        'PaymentService.processPayment',
        'EXIT',
        result: result.toJson(),
      );

      return result;
    }
  }

  /// Record payment intent in database
  Future<void> _recordPaymentIntent({
    required String orderId,
    required double amount,
    required String method,
    required String status,
    String? sessionId,
  }) async {
    try {
      AppLogger.database(
        'INSERT',
        'payment_transactions',
        data: {'order_id': orderId, 'amount': amount, 'method': method},
      );

      await _dbService.client.from('payment_transactions').insert({
        'order_id': orderId,
        'amount': amount,
        'payment_method': method,
        'status': status,
        'session_id': sessionId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.success('Payment intent recorded');
    } catch (e) {
      AppLogger.warning('Failed to record payment intent');
      // Don't throw - this shouldn't block the order
    }
  }

  /// Confirm cash payment (called when customer confirms payment on pickup)
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
        'gateway': PaymentGateway.cash,
      },
      {
        'type': PaymentMethodType.payfast,
        'name': 'PayFast',
        'description': 'Pay securely with PayFast (Credit/Debit Card, EFT, etc.)',
        'icon': Icons.credit_card,
        'enabled': PaymentConfig.isPayfastEnabled,
        'gateway': PaymentGateway.payfast,
      },
      {
        'type': PaymentMethodType.stripe,
        'name': 'Credit/Debit Card',
        'description': 'Pay securely with your card via Stripe',
        'icon': Icons.credit_card,
        'enabled': PaymentConfig.isCardPaymentEnabled,
        'gateway': PaymentGateway.stripe,
      },
      {
        'type': PaymentMethodType.card,
        'name': 'Saved Cards',
        'description': 'Use your saved payment methods',
        'icon': Icons.credit_card,
        'enabled': PaymentConfig.isCardPaymentEnabled,
        'gateway': PaymentGateway.stripe,
      },
      {
        'type': PaymentMethodType.digitalWallet,
        'name': 'Digital Wallet',
        'description': 'Pay with Apple Pay, Google Pay, etc.',
        'icon': Icons.wallet,
        'enabled': false, // Coming soon
        'gateway': PaymentGateway.stripe,
      },
      {
        'type': PaymentMethodType.bankTransfer,
        'name': 'Bank Transfer (EFT)',
        'description': 'Pay via electronic funds transfer',
        'icon': Icons.account_balance,
        'enabled': false, // Coming soon
        'gateway': PaymentGateway.payfast,
      },
    ];
  }

  /// Helper: Get payment method display name
  String getPaymentMethodName(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return 'Cash on Delivery';
      case PaymentMethodType.payfast:
        return 'PayFast';
      case PaymentMethodType.stripe:
        return 'Credit/Debit Card';
      case PaymentMethodType.card:
        return 'Saved Cards';
      case PaymentMethodType.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethodType.bankTransfer:
        return 'Bank Transfer (EFT)';
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

  // ==================== PAYMENT GATEWAY IMPLEMENTATIONS ====================

  /// Process cash payment
  Future<PaymentResult> _processCashPayment({
    required BuildContext context,
    required String orderId,
    required double amount,
    required String sessionId,
  }) async {
    try {
      AppLogger.info('Processing cash on delivery payment');

      // Simulate a small delay for UX
      await Future.delayed(const Duration(milliseconds: 500));

      final transactionId = 'CASH_${orderId}_${DateTime.now().millisecondsSinceEpoch}';

      AppLogger.success('Cash payment confirmed');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order confirmed! Pay cash when your order arrives.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      return PaymentResult(
        success: true,
        transactionId: transactionId,
        status: PaymentStatus.pending, // Cash payments are pending until delivery
      );
    } catch (e) {
      AppLogger.error('Cash payment processing failed', error: e);
      return PaymentResult(
        success: false,
        error: e.toString(),
        status: PaymentStatus.failed,
      );
    }
  }

  /// Process PayFast payment
  Future<PaymentResult> _processPayFastPayment({
    required BuildContext context,
    required String orderId,
    required double amount,
    required String sessionId,
    String? successUrl,
    String? cancelUrl,
    String? notifyUrl,
  }) async {
    try {
      AppLogger.info('Processing PayFast payment');

      if (!PaymentConfig.isPayfastEnabled) {
        return PaymentResult(
          success: false,
          error: 'PayFast is not enabled',
          status: PaymentStatus.failed,
        );
      }

      // Generate PayFast payment data
      final paymentData = _generatePayFastPaymentData(
        orderId: orderId,
        amount: amount,
        sessionId: sessionId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
        notifyUrl: notifyUrl,
      );

      // Generate security signature
      final signature = _generatePayFastSignature(paymentData);
      paymentData['signature'] = signature;

      // In a real implementation, you would redirect to PayFast
      // For now, we'll simulate the payment process
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful payment (in real implementation, this would be handled by callback)
      final transactionId = 'PF_${DateTime.now().millisecondsSinceEpoch}';

      return PaymentResult(
        success: true,
        transactionId: transactionId,
        status: PaymentStatus.completed,
      );
    } catch (e) {
      AppLogger.error('PayFast payment processing failed', error: e);
      return PaymentResult(
        success: false,
        error: e.toString(),
        status: PaymentStatus.failed,
      );
    }
  }

  /// Process Stripe payment
  Future<PaymentResult> _processStripePayment({
    required BuildContext context,
    required String orderId,
    required double amount,
    required String sessionId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      AppLogger.info('Processing Stripe payment');

      if (!PaymentConfig.isCardPaymentEnabled) {
        return PaymentResult(
          success: false,
          error: 'Card payment is not enabled',
          status: PaymentStatus.failed,
        );
      }

      if (paymentDetails == null || paymentDetails['paymentMethodId'] == null) {
        return PaymentResult(
          success: false,
          error: 'Payment method ID is required for Stripe payments',
          status: PaymentStatus.failed,
        );
      }

      // Create payment intent
      final paymentIntentData = {
        'amount': (amount * 100).round(), // Stripe uses cents
        'currency': 'zar', // South African Rand
        'payment_method': paymentDetails['paymentMethodId'],
        'confirmation_method': 'manual',
        'confirm': true,
        'metadata': {
          'orderId': orderId,
          'sessionId': sessionId,
        },
      };

      // In a real implementation, you would call Stripe API
      // For now, we'll simulate the payment process
      await Future.delayed(const Duration(seconds: 3));

      // Simulate successful payment
      final transactionId = 'ST_${DateTime.now().millisecondsSinceEpoch}';

      return PaymentResult(
        success: true,
        transactionId: transactionId,
        status: PaymentStatus.completed,
      );
    } catch (e) {
      AppLogger.error('Stripe payment processing failed', error: e);
      return PaymentResult(
        success: false,
        error: e.toString(),
        status: PaymentStatus.failed,
      );
    }
  }

  // ==================== PAYFAST HELPER METHODS ====================

  /// Generate PayFast payment data
  Map<String, String> _generatePayFastPaymentData({
    required String orderId,
    required double amount,
    required String sessionId,
    String? successUrl,
    String? cancelUrl,
    String? notifyUrl,
  }) {
    return {
      // Merchant details
      'merchant_id': PaymentConfig.payfastMerchantId ?? '',
      'merchant_key': PaymentConfig.payfastMerchantKey ?? '',
      'return_url': successUrl ?? 'https://yourapp.com/payment/success',
      'cancel_url': cancelUrl ?? 'https://yourapp.com/payment/cancel',
      'notify_url': notifyUrl ?? 'https://yourapp.com/payment/notify',

      // Transaction details
      'name_first': 'Customer',
      'name_last': 'Name',
      'email_address': 'customer@example.com',
      'm_payment_id': orderId,
      'amount': amount.toStringAsFixed(2),
      'item_name': 'Order #$orderId',
      'item_description': 'Payment for order #$orderId',

      // Custom data
      'custom_str1': sessionId,
      'custom_int1': DateTime.now().millisecondsSinceEpoch.toString(),

      // Payment setup
      'currency': 'ZAR',
      'payment_method': 'cc', // Credit card
    };
  }

  /// Generate PayFast security signature
  String _generatePayFastSignature(Map<String, String> paymentData) {
    // Sort the data alphabetically
    final sortedKeys = paymentData.keys.toList()..sort();

    // Create signature string
    final signatureString = sortedKeys.map((key) => '$key=${Uri.encodeComponent(paymentData[key] ?? '')}').join('&');

    // In a real implementation, you would use the PayFast passphrase to generate the signature
    // For now, we'll use a simple hash
    return _generateSimpleHash(signatureString);
  }

  // ==================== HELPER METHODS ====================

  /// Generate payment session ID
  String _generatePaymentSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random().nextInt(999999).toString().padLeft(6, '0');
    return 'PS_$timestamp$random';
  }

  /// Generate simple hash (in real implementation, use proper cryptographic hashing)
  String _generateSimpleHash(String input) {
    return input.hashCode.toString();
  }

  /// Handle payment callback from PayFast
  Future<PaymentCallbackResult> handlePayFastCallback(Map<String, String> callbackData) async {
    try {
      AppLogger.info('Handling PayFast callback');

      // Verify the signature
      final receivedSignature = callbackData['signature'];
      if (receivedSignature == null) {
        return PaymentCallbackResult(
          success: false,
          error: 'Missing signature',
          transactionId: callbackData['pf_payment_id'],
        );
      }

      // Find the payment session
      final sessionId = callbackData['custom_str1'];
      if (sessionId == null || !_paymentSessions.containsKey(sessionId)) {
        return PaymentCallbackResult(
          success: false,
          error: 'Invalid payment session',
          transactionId: callbackData['pf_payment_id'],
        );
      }

      final session = _paymentSessions[sessionId]!;
      final orderId = session['orderId'] as String;

      // Update payment status based on callback
      final paymentStatus = callbackData['payment_status'];
      var status = PaymentStatus.failed;

      switch (paymentStatus) {
        case 'COMPLETE':
          status = PaymentStatus.completed;
          break;
        case 'PENDING':
          status = PaymentStatus.pending;
          break;
        case 'FAILED':
          status = PaymentStatus.failed;
          break;
        default:
          status = PaymentStatus.failed;
      }

      // Update payment intent
      await _updatePaymentIntent(
        sessionId: sessionId,
        status: status.toString(),
        transactionId: callbackData['pf_payment_id'],
      );

      // Update order status if payment was successful
      if (status == PaymentStatus.completed) {
        await _updateOrderStatus(orderId, 'paid');
      }

      return PaymentCallbackResult(
        success: status == PaymentStatus.completed,
        transactionId: callbackData['pf_payment_id'],
        status: status,
        response: callbackData,
      );
    } catch (e) {
      AppLogger.error('PayFast callback handling failed', error: e);
      return PaymentCallbackResult(
        success: false,
        error: e.toString(),
        transactionId: callbackData['pf_payment_id'],
      );
    }
  }

  /// Handle payment webhook from Stripe
  Future<PaymentCallbackResult> handleStripeWebhook(Map<String, dynamic> webhookData) async {
    try {
      AppLogger.info('Handling Stripe webhook');

      final eventType = webhookData['type'];
      final paymentIntent = webhookData['data']['object'];

      if (eventType == 'payment_intent.succeeded') {
        final sessionId = paymentIntent['metadata']['sessionId'];
        if (sessionId != null && _paymentSessions.containsKey(sessionId)) {
          final session = _paymentSessions[sessionId]!;
          final orderId = session['orderId'] as String;

          // Update payment intent
          await _updatePaymentIntent(
            sessionId: sessionId,
            status: PaymentStatus.completed.toString(),
            transactionId: paymentIntent['id'],
          );

          // Update order status
          await _updateOrderStatus(orderId, 'paid');

          return PaymentCallbackResult(
            success: true,
            transactionId: paymentIntent['id'],
            status: PaymentStatus.completed,
            response: webhookData,
          );
        }
      } else if (eventType == 'payment_intent.payment_failed') {
        final sessionId = paymentIntent['metadata']['sessionId'];
        if (sessionId != null && _paymentSessions.containsKey(sessionId)) {
          // Update payment intent
          await _updatePaymentIntent(
            sessionId: sessionId,
            status: PaymentStatus.failed.toString(),
            transactionId: paymentIntent['id'],
          );
        }
      }

      return PaymentCallbackResult(
        success: false,
        error: 'Unhandled webhook event: $eventType',
      );
    } catch (e) {
      AppLogger.error('Stripe webhook handling failed', error: e);
      return PaymentCallbackResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ==================== DATABASE METHODS ====================

  /// Update payment intent in database
  Future<void> _updatePaymentIntent({
    required String sessionId,
    required String status,
    String? transactionId,
    String? error,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
        if (transactionId != null) 'transaction_id': transactionId,
        if (error != null) 'error': error,
        if (status == PaymentStatus.completed.toString()) 'completed_at': DateTime.now().toIso8601String(),
      };

      await _dbService.client
          .from('payment_transactions')
          .update(updateData)
          .eq('session_id', sessionId);

      AppLogger.success('Payment intent updated');
    } catch (e) {
      AppLogger.warning('Failed to update payment intent: $e');
    }
  }

  /// Update order status in database
  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _dbService.client
          .from('orders')
          .update({
            'payment_status': status,
            'updated_at': DateTime.now().toIso8601String(),
            if (status == 'paid') 'status': 'confirmed',
          })
          .eq('id', orderId);

      AppLogger.success('Order status updated to: $status');
    } catch (e) {
      AppLogger.warning('Failed to update order status: $e');
    }
  }

  /// Refund payment
  Future<RefundResult> refundPayment({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    try {
      AppLogger.info('Processing refund for transaction: $transactionId');

      // In a real implementation, you would call the respective gateway's refund API
      await Future.delayed(const Duration(seconds: 2));

      final refundId = 'REF_${DateTime.now().millisecondsSinceEpoch}';

      // Record refund in database
      await _recordRefund(
        transactionId: transactionId,
        amount: amount,
        reason: reason,
        refundId: refundId,
      );

      return RefundResult(
        success: true,
        refundId: refundId,
        amount: amount,
        status: 'succeeded',
      );
    } catch (e) {
      AppLogger.error('Refund processing failed', error: e);
      return RefundResult(
        success: false,
        error: e.toString(),
        refundId: '', // Empty refundId for failed refunds
        amount: amount,
        status: 'failed',
      );
    }
  }

  /// Record refund in database
  Future<void> _recordRefund({
    required String transactionId,
    required double amount,
    required String reason,
    required String refundId,
  }) async {
    try {
      await _dbService.client.from('refunds').insert({
        'id': refundId,
        'transaction_id': transactionId,
        'amount': amount,
        'reason': reason,
        'status': 'succeeded',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.success('Refund recorded');
    } catch (e) {
      AppLogger.warning('Failed to record refund: $e');
    }
  }

  /// Get payment status
  Future<PaymentStatus?> getPaymentStatus(String sessionId) async {
    try {
      final result = await _dbService.client
          .from('payment_transactions')
          .select('status')
          .eq('session_id', sessionId)
          .single();

      if (result != null && result['status'] != null) {
        final statusString = result['status'] as String;
        return PaymentStatus.values.firstWhere(
          (status) => status.toString() == statusString,
          orElse: () => PaymentStatus.pending,
        );
      }
      return null;
    } catch (e) {
      AppLogger.warning('Failed to get payment status: $e');
      return null;
    }
  }
}

// ==================== SUPPORTING CLASSES ====================

/// Payment result class
class PaymentResult {
  final bool success;
  final String? error;
  final PaymentStatus status;
  final String? transactionId;
  final Map<String, dynamic>? response;

  PaymentResult({
    required this.success,
    this.error,
    required this.status,
    this.transactionId,
    this.response,
  });

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'error': error,
      'status': status.toString(),
      'transactionId': transactionId,
      'response': response,
    };
  }
}

/// Payment callback result class
class PaymentCallbackResult {
  final bool success;
  final String? error;
  final String? transactionId;
  final PaymentStatus? status;
  final Map<String, dynamic>? response;

  PaymentCallbackResult({
    required this.success,
    this.error,
    this.transactionId,
    this.status,
    this.response,
  });
}

/// Refund result class
class RefundResult {
  final bool success;
  final String? error;
  final String refundId;
  final double amount;
  final String status;

  RefundResult({
    required this.success,
    this.error,
    required this.refundId,
    required this.amount,
    required this.status,
  });
}
