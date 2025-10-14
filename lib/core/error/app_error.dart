/// Custom error classes for the application
abstract class AppError implements Exception {
  String get message;
  String get code;
  int? get statusCode;
}

/// Error for network-related issues
class NetworkError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final int? statusCode;

  NetworkError({
    required this.message,
    this.code = 'NETWORK_ERROR',
    this.statusCode,
  });
}

/// Error for authentication-related issues
class AuthError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final int? statusCode;

  AuthError({
    required this.message,
    this.code = 'AUTH_ERROR',
    this.statusCode,
  });
}

/// Error for payment-related issues
class PaymentError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final int? statusCode;

  PaymentError({
    required this.message,
    this.code = 'PAYMENT_ERROR',
    this.statusCode,
  });
}

/// Error for data-related issues (database, API, etc.)
class DataError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final int? statusCode;

  DataError({
    required this.message,
    this.code = 'DATA_ERROR',
    this.statusCode,
  });
}

/// Error for validation issues
class ValidationError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final int? statusCode;

  ValidationError({
    required this.message,
    this.code = 'VALIDATION_ERROR',
    this.statusCode,
  });
}

/// Error for general application issues
class GeneralError extends AppError {
  @override
  final String message;
  @override
  final String code;
  @override
  final int? statusCode;

  GeneralError({
    required this.message,
    this.code = 'GENERAL_ERROR',
    this.statusCode,
  });
}