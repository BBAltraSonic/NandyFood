import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Custom exception class for app-specific errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() {
    return 'AppException: $message (code: $code)';
  }
}

/// Payment-specific exceptions
class PaymentException extends AppException {
  PaymentException(super.message, {super.code, super.details});
}

class PaymentInitializationException extends PaymentException {
  PaymentInitializationException(super.message, {super.code, super.details});
}

class PaymentProcessingException extends PaymentException {
  PaymentProcessingException(super.message, {super.code, super.details});
}

class PaymentVerificationException extends PaymentException {
  PaymentVerificationException(super.message, {super.code, super.details});
}

class PaymentCancelledException extends PaymentException {
  PaymentCancelledException(super.message, {super.code, super.details});
}

class PaymentRefundException extends PaymentException {
  PaymentRefundException(super.message, {super.code, super.details});
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

/// Error handler utility class
class ErrorHandler {
  /// Handle different types of errors and return user-friendly messages
  static String getErrorMessage(Object error) {
    if (error is PaymentCancelledException) {
      return 'Payment was cancelled. You can try again when ready.';
    } else if (error is PaymentInitializationException) {
      return 'Unable to initialize payment. Please try again.';
    } else if (error is PaymentProcessingException) {
      return 'Payment processing failed. Please check your payment details and try again.';
    } else if (error is PaymentVerificationException) {
      return 'Unable to verify payment status. Please contact support if you were charged.';
    } else if (error is PaymentRefundException) {
      return 'Unable to process refund. Please contact support.';
    } else if (error is PaymentException) {
      return error.message.isNotEmpty 
          ? error.message 
          : 'Payment error occurred. Please try again.';
    } else if (error is NetworkException) {
      return 'Network error. Please check your internet connection.';
    } else if (error is AppException) {
      return error.message;
    } else if (error is TimeoutException) {
      return 'Request timed out. Please check your internet connection and try again.';
    } else if (error is SocketException) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (error is FormatException) {
      return 'Data format error. Please try again.';
    } else if (error is HttpException) {
      return 'Server error. Please try again later.';
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Show error dialog to user
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message, {
    VoidCallback? onRetry,
    String retryButtonText = 'Retry',
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: Text(retryButtonText),
              ),
          ],
        );
      },
    );
  }

  /// Show snack bar with error message
  static void showSnackBarError(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    String retryButtonText = 'Retry',
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: onRetry != null
            ? SnackBarAction(
                label: retryButtonText,
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Log error for debugging purposes
  static void logError(
    Object error,
    StackTrace stackTrace, {
    String? logContext,
  }) {
    // In a real app, this would log to a service like Sentry or Firebase Crashlytics
    if (kDebugMode) {
      print('ERROR${logContext != null ? ' ($logContext)' : ''}: $error');
      print('Stack trace: $stackTrace');
    }
  }

  /// Handle error with appropriate UI feedback
  static void handleError(
    BuildContext context,
    Object error,
    StackTrace stackTrace, {
    String? errorContext,
    VoidCallback? onRetry,
    bool useDialog = false,
  }) {
    // Log the error
    logError(error, stackTrace, logContext: errorContext);

    // Get user-friendly error message
    final errorMessage = getErrorMessage(error);

    // Show appropriate UI feedback
    if (useDialog) {
      showErrorDialog(context, 'Error', errorMessage, onRetry: onRetry);
    } else {
      showSnackBarError(context, errorMessage, onRetry: onRetry);
    }
  }
}
