import 'package:flutter/material.dart';
import 'app_error.dart';

class ErrorHandler {
  /// Shows a dialog with error message
  static void showErrorDialog(BuildContext context, AppError error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(error.message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Shows a snackbar with error message
  static void showErrorSnackbar(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Handles an error based on its type
  static void handleError(BuildContext context, AppError error) {
    // Log error (would integrate with a logging service in real app)
    debugPrint('Error [${error.code}]: ${error.message}');

    // Handle specific error types differently
    switch (error.runtimeType) {
      case NetworkError:
        // Show more appropriate message for network errors
        showErrorSnackbar(context, error);
        break;
      case AuthError:
        // Navigate to login page for auth errors
        showErrorDialog(context, error);
        break;
      case PaymentError:
        // Show detailed payment error
        showErrorDialog(context, error);
        break;
      default:
        // Show generic error message for other errors
        showErrorSnackbar(context, error);
    }
  }

  /// Maps common exceptions to AppError types
  static AppError mapExceptionToAppError(dynamic exception, {String? customMessage}) {
    if (exception is AppError) {
      return exception;  // Already an AppError
    }

    // Handle common Dart exceptions
    if (exception is FormatException) {
      return ValidationError(
        message: customMessage ?? 'Invalid data format',
        code: 'FORMAT_ERROR',
      );
    }

    if (exception is RangeError) {
      return ValidationError(
        message: customMessage ?? 'Value out of range',
        code: 'RANGE_ERROR',
      );
    }

    // Handle Dio exceptions for network errors
    if (exception.toString().contains('DioException')) {
      return NetworkError(
        message: customMessage ?? 'Network error occurred',
        code: 'DIO_ERROR',
      );
    }

    // Handle general exceptions
    return GeneralError(
      message: customMessage ?? exception.toString(),
      code: 'UNEXPECTED_ERROR',
    );
  }
}