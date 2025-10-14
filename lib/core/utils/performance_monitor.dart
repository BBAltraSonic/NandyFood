import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/core/utils/logger.dart';

class PerformanceMonitor {
  static final Map<String, DateTime> _timers = {};

  /// Start timing a specific operation
  static void startTimer(String operationName) {
    _timers[operationName] = DateTime.now();
  }

  /// Stop timing and log the duration of a specific operation
  static Duration? stopTimer(String operationName, {String? description}) {
    if (_timers.containsKey(operationName)) {
      final startTime = _timers.remove(operationName)!;
      final duration = DateTime.now().difference(startTime);
      
      final desc = description != null ? ' ($description)' : '';
      AppLogger.i('PERFORMANCE: $operationName$desc took ${duration.inMilliseconds}ms');
      
      // Log slow operations (those taking more than 100ms)
      if (duration.inMilliseconds > 100) {
        AppLogger.w('PERFORMANCE WARNING: $operationName$desc took ${duration.inMilliseconds}ms (slow operation)');
      }
      
      return duration;
    }
    
    return null;
  }

  /// Measure the execution time of a function
  static T measure<T>(String operationName, T Function() operation, {String? description}) {
    startTimer(operationName);
    try {
      final result = operation();
      stopTimer(operationName, description: description);
      return result;
    } catch (e) {
      stopTimer(operationName, description: description);
      rethrow;
    }
  }

  /// Measure the execution time of an async function
  static Future<T> measureAsync<T>(String operationName, Future<T> Function() operation, {String? description}) async {
    startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(operationName, description: description);
      return result;
    } catch (e) {
      stopTimer(operationName, description: description);
      rethrow;
    }
  }
}

/// Memory usage monitoring
class MemoryMonitor {
  /// Get current memory usage in MB
  static double get currentMemoryUsage {
    if (kDebugMode) {
      // In debug mode, we can access memory usage through the developer library
      // This is a placeholder - actual implementation would require more specific tools
      return 0.0; // Placeholder
    }
    return 0.0; // Not available in release mode
  }

  /// Log memory usage if it exceeds threshold
  static void checkMemoryUsage({double thresholdMB = 50.0}) {
    final memory = currentMemoryUsage;
    if (memory > thresholdMB) {
      AppLogger.w('MEMORY WARNING: Current usage is ${memory.toStringAsFixed(2)}MB, exceeding threshold of ${thresholdMB}MB');
    }
  }
}

/// Widget performance monitoring
class WidgetPerformanceMonitor {
  /// Monitor build times for widgets
  static T measureBuild<T>(String widgetName, T Function() buildMethod) {
    if (kDebugMode) {
      return PerformanceMonitor.measure('WidgetBuild:$widgetName', buildMethod);
    } else {
      return buildMethod();
    }
  }
}

/// Database query performance monitoring
class DatabasePerformanceMonitor {
  /// Monitor the performance of a database query
  static Future<List<Map<String, dynamic>>> measureQuery(
    String query, 
    Future<List<Map<String, dynamic>>> Function() queryFunction,
  ) async {
    return await PerformanceMonitor.measureAsync(
      'DatabaseQuery',
      queryFunction,
      description: query.substring(0, query.length < 50 ? query.length : 50),
    );
  }
  
  /// Monitor the performance of a database insertion
  static Future<void> measureInsert(
    String tableName, 
    Future<void> Function() insertFunction,
  ) async {
    await PerformanceMonitor.measureAsync(
      'DatabaseInsert',
      insertFunction,
      description: 'INSERT INTO $tableName',
    );
  }
  
  /// Monitor the performance of a database update
  static Future<void> measureUpdate(
    String tableName, 
    Future<void> Function() updateFunction,
  ) async {
    await PerformanceMonitor.measureAsync(
      'DatabaseUpdate',
      updateFunction,
      description: 'UPDATE $tableName',
    );
  }
}