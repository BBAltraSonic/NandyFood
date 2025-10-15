import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/payfast_service.dart';
import 'package:food_delivery_app/core/services/connectivity_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/core/utils/error_handler.dart';
import 'package:food_delivery_app/shared/models/payment_transaction.dart';

/// Payment status enum
enum PaymentStatus {
  idle,
  initializing,
  processing,
  verifying,
  completed,
  failed,
  cancelled,
}

/// Payment state class
class PaymentState {
  final PaymentStatus status;
  final String? paymentReference;
  final String? errorMessage;
  final Map<String, String>? paymentData;
  final double? amount;
  final DateTime? startedAt;
  final PaymentTransactionStatus? transactionStatus;

  PaymentState({
    this.status = PaymentStatus.idle,
    this.paymentReference,
    this.errorMessage,
    this.paymentData,
    this.amount,
    this.startedAt,
    this.transactionStatus,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    String? paymentReference,
    String? errorMessage,
    Map<String, String>? paymentData,
    double? amount,
    DateTime? startedAt,
    PaymentTransactionStatus? transactionStatus,
  }) {
    return PaymentState(
      status: status ?? this.status,
      paymentReference: paymentReference ?? this.paymentReference,
      errorMessage: errorMessage ?? this.errorMessage,
      paymentData: paymentData ?? this.paymentData,
      amount: amount ?? this.amount,
      startedAt: startedAt ?? this.startedAt,
      transactionStatus: transactionStatus ?? this.transactionStatus,
    );
  }

  // Helper getters
  bool get isIdle => status == PaymentStatus.idle;
  bool get isInitializing => status == PaymentStatus.initializing;
  bool get isProcessing => status == PaymentStatus.processing;
  bool get isVerifying => status == PaymentStatus.verifying;
  bool get isCompleted => status == PaymentStatus.completed;
  bool get isFailed => status == PaymentStatus.failed;
  bool get isCancelled => status == PaymentStatus.cancelled;
  bool get isInProgress =>
      status == PaymentStatus.initializing ||
      status == PaymentStatus.processing ||
      status == PaymentStatus.verifying;
}

/// Payment notifier
class PaymentNotifier extends StateNotifier<PaymentState> {
  PaymentNotifier() : super(PaymentState());

  final PayFastService _payfastService = PayFastService();
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Initialize payment and get payment data for WebView
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
    AppLogger.function('PaymentNotifier.initializePayment', 'ENTER', params: {
      'orderId': orderId,
      'amount': amount,
      'itemName': itemName,
    });

    try {
      // Update state to initializing
      state = state.copyWith(
        status: PaymentStatus.initializing,
        amount: amount,
        startedAt: DateTime.now(),
        errorMessage: null,
      );

      // Check connectivity
      if (!_connectivityService.isConnected) {
        throw NetworkException('No internet connection');
      }

      // Initialize payment with PayFast
      final paymentData = await _payfastService.initializePayment(
        orderId: orderId,
        userId: userId,
        amount: amount,
        itemName: itemName,
        itemDescription: itemDescription,
        customerEmail: customerEmail,
        customerFirstName: customerFirstName,
        customerLastName: customerLastName,
        customerPhone: customerPhone,
      );

      // Update state with payment data
      state = state.copyWith(
        status: PaymentStatus.processing,
        paymentReference: paymentData['m_payment_id'],
        paymentData: paymentData,
      );

      AppLogger.success('Payment initialized successfully');
      AppLogger.function('PaymentNotifier.initializePayment', 'EXIT',
          result: paymentData);

      return paymentData;
    } on PaymentException catch (e) {
      AppLogger.error('Payment initialization failed', error: e);
      state = state.copyWith(
        status: PaymentStatus.failed,
        errorMessage: ErrorHandler.getErrorMessage(e),
      );
      rethrow;
    } catch (e, stack) {
      AppLogger.error('Unexpected error during payment initialization',
          error: e, stack: stack);
      state = state.copyWith(
        status: PaymentStatus.failed,
        errorMessage: 'Failed to initialize payment. Please try again.',
      );
      throw PaymentInitializationException(
        'Failed to initialize payment: $e',
      );
    }
  }

  /// Process payment response from PayFast return URL
  Future<bool> processPaymentResponse(
    Map<String, String> responseData,
  ) async {
    AppLogger.function('PaymentNotifier.processPaymentResponse', 'ENTER');

    try {
      // Update state to verifying
      state = state.copyWith(
        status: PaymentStatus.verifying,
        errorMessage: null,
      );

      // Process response with PayFast service
      final result = await _payfastService.processPaymentResponse(
        responseData: responseData,
      );

      final success = result['success'] as bool;
      final paymentRef = result['payment_reference'] as String;
      final statusStr = result['status'] as String;

      if (success) {
        // Update state to completed
        state = state.copyWith(
          status: PaymentStatus.completed,
          paymentReference: paymentRef,
          transactionStatus: PaymentTransactionStatus.completed,
        );

        AppLogger.success('Payment processed successfully');
        AppLogger.function('PaymentNotifier.processPaymentResponse', 'EXIT',
            result: true);

        return true;
      } else {
        // Update state to failed
        state = state.copyWith(
          status: PaymentStatus.failed,
          errorMessage: result['message'] as String?,
          transactionStatus: _mapStatus(statusStr),
        );

        AppLogger.warning('Payment processing failed: ${result['message']}');
        AppLogger.function('PaymentNotifier.processPaymentResponse', 'EXIT',
            result: false);

        return false;
      }
    } catch (e, stack) {
      AppLogger.error('Failed to process payment response',
          error: e, stack: stack);
      state = state.copyWith(
        status: PaymentStatus.failed,
        errorMessage: ErrorHandler.getErrorMessage(e),
      );

      AppLogger.function('PaymentNotifier.processPaymentResponse', 'EXIT',
          result: false);

      return false;
    }
  }

  /// Verify payment status
  Future<PaymentTransactionStatus?> verifyPaymentStatus(
    String paymentRef,
  ) async {
    AppLogger.function('PaymentNotifier.verifyPaymentStatus', 'ENTER',
        params: {'paymentRef': paymentRef});

    try {
      state = state.copyWith(status: PaymentStatus.verifying);

      final transaction = await _payfastService.getTransactionStatus(paymentRef);

      if (transaction == null) {
        AppLogger.warning('Transaction not found for reference: $paymentRef');
        return null;
      }

      final statusStr = transaction['status'] as String;
      final transactionStatus = _mapStatus(statusStr);

      // Update state based on transaction status
      if (transactionStatus == PaymentTransactionStatus.completed) {
        state = state.copyWith(
          status: PaymentStatus.completed,
          transactionStatus: transactionStatus,
        );
      } else if (transactionStatus == PaymentTransactionStatus.failed) {
        state = state.copyWith(
          status: PaymentStatus.failed,
          transactionStatus: transactionStatus,
          errorMessage: transaction['error_message'] as String?,
        );
      } else if (transactionStatus == PaymentTransactionStatus.cancelled) {
        state = state.copyWith(
          status: PaymentStatus.cancelled,
          transactionStatus: transactionStatus,
        );
      }

      AppLogger.success('Payment status verified: $statusStr');
      AppLogger.function('PaymentNotifier.verifyPaymentStatus', 'EXIT',
          result: transactionStatus);

      return transactionStatus;
    } catch (e, stack) {
      AppLogger.error('Failed to verify payment status', error: e, stack: stack);
      return null;
    }
  }

  /// Cancel payment
  Future<void> cancelPayment(String? paymentRef) async {
    AppLogger.function('PaymentNotifier.cancelPayment', 'ENTER',
        params: {'paymentRef': paymentRef});

    try {
      state = state.copyWith(
        status: PaymentStatus.cancelled,
        errorMessage: 'Payment cancelled by user',
      );

      AppLogger.info('Payment cancelled');
      AppLogger.function('PaymentNotifier.cancelPayment', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to cancel payment', error: e, stack: stack);
    }
  }

  /// Reset payment state
  void reset() {
    AppLogger.info('Resetting payment state');
    state = PaymentState();
  }

  /// Map status string to enum
  PaymentTransactionStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return PaymentTransactionStatus.completed;
      case 'failed':
        return PaymentTransactionStatus.failed;
      case 'cancelled':
        return PaymentTransactionStatus.cancelled;
      case 'refunded':
        return PaymentTransactionStatus.refunded;
      default:
        return PaymentTransactionStatus.pending;
    }
  }
}

/// Payment provider
final paymentProvider =
    StateNotifierProvider<PaymentNotifier, PaymentState>((ref) {
  return PaymentNotifier();
});
