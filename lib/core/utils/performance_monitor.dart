import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

/// Performance monitoring utility for tracking app performance
class PerformanceMonitor {
  static bool _isEnabled = kDebugMode;

  /// Enable or disable performance monitoring
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Start timing an operation
  static Stopwatch startTiming(String operationName) {
    if (!_isEnabled) return Stopwatch();

    final stopwatch = Stopwatch()..start();
    developer.log('Starting operation: $operationName', name: 'PerformanceMonitor');
    return stopwatch;
  }

  /// End timing an operation and log the result
  static void endTiming(Stopwatch stopwatch, String operationName) {
    if (!_isEnabled) return;

    stopwatch.stop();
    final milliseconds = stopwatch.elapsedMilliseconds;
    developer.log(
      'Operation completed: $operationName took ${milliseconds}ms',
      name: 'PerformanceMonitor',
      level: milliseconds > 100 ? 900 : 800, // Warning level for slow operations
    );

    // Send warning for operations that take too long
    if (milliseconds > 100) {
      developer.log(
        'WARNING: Slow operation detected: $operationName took ${milliseconds}ms (>100ms)',
        name: 'PerformanceMonitor',
        level: 1000,
      );
    }
  }

  /// Measure the execution time of a function
  static Future<T> measureAsync<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    if (!_isEnabled) return await operation();

    final stopwatch = startTiming(operationName);
    try {
      final result = await operation();
      endTiming(stopwatch, operationName);
      return result;
    } catch (e) {
      endTiming(stopwatch, operationName);
      rethrow;
    }
  }

  /// Measure the execution time of a synchronous function
  static T measureSync<T>(
    T Function() operation,
    String operationName,
  ) {
    if (!_isEnabled) return operation();

    final stopwatch = startTiming(operationName);
    try {
      final result = operation();
      endTiming(stopwatch, operationName);
      return result;
    } catch (e) {
      endTiming(stopwatch, operationName);
      rethrow;
    }
  }

  /// Log a performance event
  static void logEvent(String eventName, [Map<String, dynamic>? properties]) {
    if (!_isEnabled) return;

    developer.log(
      'Event: $eventName${properties != null ? ' with properties: $properties' : ''}',
      name: 'PerformanceMonitor',
    );
  }

  /// Log memory usage information
  static void logMemoryUsage() {
    if (!_isEnabled) return;

    // In a real implementation, we might use platform channels to get actual memory usage
    // For now, we'll just log that we're checking memory
    developer.log('Checking memory usage', name: 'PerformanceMonitor');
  }
}