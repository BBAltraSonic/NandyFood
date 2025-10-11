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

/// Error handler utility class
class ErrorHandler {
  /// Handle different types of errors and return user-friendly messages
  static String getErrorMessage(Object error) {
    if (error is AppException) {
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
  static void logError(Object error, StackTrace stackTrace, {String? logContext}) {
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
      showErrorDialog(
        context,
        'Error',
        errorMessage,
        onRetry: onRetry,
      );
    } else {
      showSnackBarError(
        context,
        errorMessage,
        onRetry: onRetry,
      );
    }
  }
}