import 'dart:developer' as developer;
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';
import '../constants/config.dart';

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  static late Logger _logger;
  
  // Singleton pattern to ensure only one logger instance
  factory AppLogger() {
    return _instance;
  }
  
  AppLogger._internal() {
    _logger = Logger(
      // Only log in debug mode
      filter: Config.isDebugMode ? null : null, // This will disable logging in production
      printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to show in stack trace
        errorMethodCount: 8, // Number of method calls to show if error occurred
        lineLength: 120, // Width of the output
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        printTime: false, // Should each log print contain a timestamp
      ),
    );
  }

  /// Log a verbose message
  static void v(String message, [Object? error, StackTrace? stackTrace]) {
    if (Config.isDebugMode) {
      _logger.v(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
      developer.log(message);
    }
  }

  /// Log a debug message
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    if (Config.isDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
      developer.log(message);
    }
  }

  /// Log an info message
  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    if (Config.isDebugMode) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
      developer.log(message);
    }
  }

  /// Log a warning message
  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    if (Config.isDebugMode) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
      developer.log(message);
    }
  }

  /// Log an error message
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (Config.isDebugMode) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    } else if (kDebugMode) {
      developer.log(message, error: error);
    }
  }

  /// Log a network request
  static void network(String url, String method, [int? statusCode]) {
    final status = statusCode != null ? ' [Status: $statusCode]' : '';
    i('NETWORK: $method $url$status');
  }

  /// Log a database query
  static void database(String query, [Duration? executionTime, int? rowsAffected]) {
    final time = executionTime != null ? ' (${executionTime.inMilliseconds}ms)' : '';
    final rows = rowsAffected != null ? ' ($rowsAffected rows)' : '';
    i('DATABASE: $query$time$rows');
  }

  /// Log a payment transaction
  static void payment(String action, String transactionId, [String? status]) {
    final statusText = status != null ? ' [Status: $status]' : '';
    i('PAYMENT: $action for transaction $transactionId$statusText');
  }

  /// Log an analytics event
  static void analytics(String eventName, [Map<String, dynamic>? parameters]) {
    final params = parameters != null ? ' ${parameters.toString()}' : '';
    i('ANALYTICS: $eventName$params');
  }
}

/// A wrapper for logging payment-related events specifically
class PaymentLogger {
  static void info(String message, String transactionId) {
    AppLogger.i('[PAYMENT-$transactionId] $message');
  }

  static void error(String message, String transactionId, [Object? error]) {
    AppLogger.e('[PAYMENT-$transactionId] $message', error);
  }

  static void debug(String message, String transactionId) {
    AppLogger.d('[PAYMENT-$transactionId] $message');
  }

  static void warn(String message, String transactionId) {
    AppLogger.w('[PAYMENT-$transactionId] $message');
  }
}