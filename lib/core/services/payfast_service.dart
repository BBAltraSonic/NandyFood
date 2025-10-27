
import 'package:dio/dio.dart';
import 'package:food_delivery_app/core/constants/config.dart';
import 'package:food_delivery_app/core/security/payment_security.dart';
import 'package:food_delivery_app/core/services/connectivity_service.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/core/utils/error_handler.dart';
import 'package:uuid/uuid.dart';

/// Service for PayFast payment gateway integration
class PayFastService {
  static final PayFastService _instance = PayFastService._internal();
  factory PayFastService() => _instance;
  PayFastService._internal();

  final DatabaseService _dbService = DatabaseService();
  final ConnectivityService _connectivityService = ConnectivityService();
  final Dio _dio = Dio();
  final Uuid _uuid = const Uuid();

  /// Initialize PayFast payment session
  /// Returns payment data including signature for webview redirect
  Future<Map<String, String>> initializePayment({
    required String orderId,
    required String userId,
    required double amount,
    required String itemName,
    String? itemDescription,
    String? customerEmail,
    String? customerFirstName,
    String? customerLastName,
    String? customerPhone,
  }) async {
    AppLogger.function('PayFastService.initializePayment', 'ENTER', params: {
      'orderId': orderId,
      'amount': amount,
      'itemName': itemName,
    });

    try {
      // Check network connectivity
      if (!_connectivityService.isConnected) {
        throw NetworkException('No internet connection');
      }

      // Validate configuration
      if (!PaymentSecurity.validateMerchantConfig()) {
        throw PaymentInitializationException('Invalid PayFast configuration');
      }

      // Validate amount
      if (!PaymentSecurity.validateAmount(amount)) {
        throw PaymentInitializationException('Invalid payment amount');
      }

      // Generate unique payment reference
      final paymentRef =
          PaymentSecurity.generatePaymentReference(userId, orderId);

      // Build payment data
      final paymentData = {
        'merchant_id': Config.payfastMerchantId,
        'merchant_key': Config.payfastMerchantKey,
        'return_url': Config.payfastReturnUrl,
        'cancel_url': Config.payfastCancelUrl,
        'notify_url': Config.payfastNotifyUrl,
        'm_payment_id': paymentRef,
        'amount': amount.toStringAsFixed(2),
        'item_name': PaymentSecurity.sanitizeInput(itemName),
        'item_description':
            itemDescription ?? 'Payment for order $orderId',
        'email_address': customerEmail ?? 'customer@nandyfood.com',
        'name_first': customerFirstName ?? 'Customer',
        'name_last': customerLastName ?? 'User',
        'cell_number': customerPhone ?? '',
      };

      // Generate signature
      final signature = PaymentSecurity.generatePaymentSignature(paymentData);
      paymentData['signature'] = signature;

      // Record payment intent in database
      await _recordPaymentIntent(
        orderId: orderId,
        userId: userId,
        amount: amount,
        paymentRef: paymentRef,
        paymentData: paymentData,
      );

      AppLogger.success('Payment initialized', details: paymentRef);
      AppLogger.function('PayFastService.initializePayment', 'EXIT',
          result: paymentData);

      return paymentData;
    } on PaymentException {
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Failed to initialize payment', error: e, stack: stack);
      throw PaymentInitializationException('Failed to initialize payment: $e');
    }
  }

  /// Record payment intent in database
  Future<void> _recordPaymentIntent({
    required String orderId,
    required String userId,
    required double amount,
    required String paymentRef,
    required Map<String, String> paymentData,
  }) async {
    try {
      await _dbService.client.from('payment_transactions').insert({
        'id': _uuid.v4(),
        'order_id': orderId,
        'user_id': userId,
        'amount': amount,
        'payment_method': 'payfast',
        'payment_reference': paymentRef,
        'status': 'pending',
        'payment_gateway': 'payfast',
        'metadata': paymentData,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.database('INSERT', 'payment_transactions');
    } catch (e) {
      AppLogger.warning('Failed to record payment intent: $e');
      // Don't throw - this shouldn't block payment flow
    }
  }

  /// Verify PayFast ITN (Instant Transaction Notification)
  /// This should be called from webhook endpoint
  Future<bool> verifyPaymentWebhook(
    Map<String, String> postData,
    String sourceIP,
  ) async {
    AppLogger.function('PayFastService.verifyPaymentWebhook', 'ENTER');

    try {
      // Step 1: Verify source IP
      if (!PaymentSecurity.validateWebhookIP(sourceIP)) {
        AppLogger.warning('Invalid webhook IP: $sourceIP');
        return false;
      }

      // Step 2: Verify signature
      final receivedSignature = postData['signature'];
      if (receivedSignature == null || receivedSignature.isEmpty) {
        AppLogger.warning('Missing signature in webhook');
        return false;
      }

      final dataWithoutSignature = Map<String, String>.from(postData);
      dataWithoutSignature.remove('signature');

      if (!PaymentSecurity.verifyPaymentSignature(
          dataWithoutSignature, receivedSignature)) {
        AppLogger.warning('Invalid signature in webhook');
        return false;
      }

      // Step 3: Verify payment data with PayFast servers
      final isValid = await _validateWithPayFast(postData);

      if (isValid) {
        AppLogger.success('Payment webhook verified');
      } else {
        AppLogger.warning('Payment webhook validation failed');
      }

      return isValid;
    } catch (e, stack) {
      AppLogger.error('Failed to verify payment webhook',
          error: e, stack: stack);
      return false;
    }
  }

  /// Validate payment data with PayFast servers
  Future<bool> _validateWithPayFast(Map<String, String> postData) async {
    try {
      final response = await _dio.post(
        Config.payfastValidateUrl,
        data: postData,
        options: Options(
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          validateStatus: (status) => status! < 500,
        ),
      );

      final responseText = response.data.toString().trim();
      final isValid = responseText == 'VALID';

      AppLogger.http('POST', Config.payfastValidateUrl,
          statusCode: response.statusCode, body: responseText);

      return isValid;
    } catch (e, stack) {
      AppLogger.error('Failed to validate with PayFast', error: e, stack: stack);
      return false;
    }
  }

  /// Verify payment response with backend
  Future<bool> _verifyWithBackend(Map<String, String> responseData) async {
    try {
      final response = await _dio.post(
        Config.paymentVerifyUrl,
        data: responseData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      AppLogger.http('POST', Config.paymentVerifyUrl,
          statusCode: response.statusCode, body: response.data);

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final success = data['success'] == true || data['valid'] == true;
          return success;
        }
      }
      return false;
    } catch (e, stack) {
      AppLogger.error('Failed to verify with backend', error: e, stack: stack);
      return false;
    }
  }


  /// Process payment response from return URL
  Future<Map<String, dynamic>> processPaymentResponse({
    required Map<String, String> responseData,
  }) async {
    AppLogger.function('PayFastService.processPaymentResponse', 'ENTER');

    try {
      final paymentRef = responseData['m_payment_id'];
      final paymentStatus = responseData['payment_status'];

      if (paymentRef == null) {
        throw PaymentProcessingException('Missing payment reference');
      }

      // Verify via backend; fallback to PayFast validation if backend is unavailable
      bool isValid = await _verifyWithBackend(responseData);
      if (!isValid) {
        AppLogger.info('Backend verification failed or invalid. Falling back to PayFast validation');
        isValid = await _validateWithPayFast(responseData);
      }

      // Update payment transaction status in DB
      await _updatePaymentStatus(
        paymentRef: paymentRef,
        status: paymentStatus ?? 'unknown',
        responseData: responseData,
      );

      final success = (paymentStatus == 'COMPLETE') && isValid;

      final result = {
        'success': success,
        'payment_reference': paymentRef,
        'status': paymentStatus,
        'message': success
            ? _getStatusMessage(paymentStatus ?? 'unknown')
            : 'Payment validation failed',
      };

      AppLogger.function('PayFastService.processPaymentResponse', 'EXIT',
          result: result);

      return result;
    } catch (e, stack) {
      AppLogger.error('Failed to process payment response',
          error: e, stack: stack);
      throw PaymentProcessingException('Failed to process payment: $e');
    }
  }

  /// Update payment transaction status
  Future<void> _updatePaymentStatus({
    required String paymentRef,
    required String status,
    required Map<String, String> responseData,
  }) async {
    try {
      final updateData = {
        'status': _mapPayFastStatus(status),
        'payment_response': responseData,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'COMPLETE') {
        updateData['completed_at'] = DateTime.now().toIso8601String();
      }

      await _dbService.client
          .from('payment_transactions')
          .update(updateData)
          .eq('payment_reference', paymentRef);

      AppLogger.database('UPDATE', 'payment_transactions');
    } catch (e, stack) {
      AppLogger.error('Failed to update payment status',
          error: e, stack: stack);
      // Don't throw - this shouldn't block user flow
    }
  }

  /// Map PayFast status to application status
  String _mapPayFastStatus(String payfastStatus) {
    switch (payfastStatus.toUpperCase()) {
      case 'COMPLETE':
        return 'completed';
      case 'CANCELLED':
        return 'cancelled';
      case 'FAILED':
        return 'failed';
      default:
        return 'pending';
    }
  }

  /// Get user-friendly status message
  String _getStatusMessage(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETE':
        return 'Payment successful';
      case 'CANCELLED':
        return 'Payment was cancelled';
      case 'FAILED':
        return 'Payment failed';
      default:
        return 'Payment status unknown';
    }
  }

  /// Get transaction status by payment reference
  Future<Map<String, dynamic>?> getTransactionStatus(
      String paymentRef) async {
    AppLogger.function('PayFastService.getTransactionStatus', 'ENTER',
        params: {'paymentRef': paymentRef});

    try {
      final response = await _dbService.client
          .from('payment_transactions')
          .select()
          .eq('payment_reference', paymentRef)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('Transaction not found: $paymentRef');
        return null;
      }

      AppLogger.success('Transaction status retrieved');
      return response;
    } catch (e, stack) {
      AppLogger.error('Failed to get transaction status',
          error: e, stack: stack);
      return null;
    }
  }

  /// Initiate refund (manual process for PayFast)
  /// PayFast doesn't support automatic refunds via API
  Future<String> initiateRefund({
    required String paymentRef,
    required double amount,
    required String reason,
  }) async {
    AppLogger.function('PayFastService.initiateRefund', 'ENTER', params: {
      'paymentRef': paymentRef,
      'amount': amount,
      'reason': reason,
    });

    try {
      // PayFast requires manual refund process
      // Record refund request in database for admin processing
      final refundId = _uuid.v4();

      await _dbService.client.from('payment_refund_requests').insert({
        'id': refundId,
        'payment_reference': paymentRef,
        'amount': amount,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.success('Refund request created', details: refundId);
      return refundId;
    } catch (e, stack) {
      AppLogger.error('Failed to initiate refund', error: e, stack: stack);
      throw PaymentRefundException('Failed to initiate refund: $e');
    }
  }

  /// Log webhook for debugging
  Future<void> logWebhook({
    required Map<String, String> data,
    required String sourceIP,
    required bool verified,
  }) async {
    try {
      await _dbService.client.from('payment_webhook_logs').insert({
        'id': _uuid.v4(),
        'transaction_id': data['pf_payment_id'] ?? 'unknown',
        'payload': data,
        'source_ip': sourceIP,
        'signature': data['signature'],
        'status': verified ? 'verified' : 'rejected',
        'processed_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.database('INSERT', 'payment_webhook_logs');
    } catch (e) {
      AppLogger.warning('Failed to log webhook: $e');
    }
  }
}
