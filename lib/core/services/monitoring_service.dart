import 'dart:async';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:food_delivery_app/core/config/environment_config.dart';
import 'package:food_delivery_app/core/config/feature_flags.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Performance monitoring and alerting service
class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  FirebasePerformance? _performance;
  final Map<String, Trace> _activeTraces = {};
  final Map<String, HttpMetric> _activeMetrics = {};
  final List<PerformanceAlert> _alerts = [];

  /// Initialize monitoring service
  Future<void> initialize() async {
    if (!FeatureFlags().enablePerformanceMonitoring) {
      AppLogger.info('Performance monitoring disabled by feature flag');
      return;
    }

    if (EnvironmentConfig.isDevelopment) {
      AppLogger.info('Performance monitoring disabled in development');
      return;
    }

    try {
      _performance = FirebasePerformance.instance;
      await _performance?.setPerformanceCollectionEnabled(true);
      
      // Start app startup monitoring
      startTrace('app_startup');
      
      AppLogger.success('Monitoring service initialized');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize monitoring', error: e, stack: stack);
    }
  }

  // ==================== TRACE MONITORING ====================

  /// Start a custom trace
  Future<void> startTrace(String name) async {
    if (!FeatureFlags().enablePerformanceMonitoring) return;

    try {
      final trace = _performance?.newTrace(name);
      await trace?.start();
      
      if (trace != null) {
        _activeTraces[name] = trace;
        AppLogger.debug('Performance trace started: $name');
      }
    } catch (e) {
      AppLogger.warning('Failed to start trace: $e');
    }
  }

  /// Stop a custom trace
  Future<void> stopTrace(String name) async {
    if (!FeatureFlags().enablePerformanceMonitoring) return;

    try {
      final trace = _activeTraces[name];
      if (trace != null) {
        await trace.stop();
        _activeTraces.remove(name);
        AppLogger.debug('Performance trace stopped: $name');
      }
    } catch (e) {
      AppLogger.warning('Failed to stop trace: $e');
    }
  }

  /// Increment metric in a trace
  Future<void> incrementMetric(String traceName, String metricName, int value) async {
    try {
      final trace = _activeTraces[traceName];
      trace?.incrementMetric(metricName, value);
    } catch (e) {
      AppLogger.warning('Failed to increment metric: $e');
    }
  }

  /// Set attribute in a trace
  Future<void> setTraceAttribute(String traceName, String attribute, String value) async {
    try {
      final trace = _activeTraces[traceName];
      trace?.putAttribute(attribute, value);
    } catch (e) {
      AppLogger.warning('Failed to set trace attribute: $e');
    }
  }

  // ==================== HTTP METRICS ====================

  /// Start HTTP metric
  Future<void> startHttpMetric({
    required String url,
    required String method,
  }) async {
    if (!FeatureFlags().enablePerformanceMonitoring) return;

    try {
      final metric = _performance?.newHttpMetric(url, HttpMethod.values.byName(method.toUpperCase()));
      await metric?.start();
      
      if (metric != null) {
        final key = '$method:$url';
        _activeMetrics[key] = metric;
        AppLogger.debug('HTTP metric started: $key');
      }
    } catch (e) {
      AppLogger.warning('Failed to start HTTP metric: $e');
    }
  }

  /// Stop HTTP metric
  Future<void> stopHttpMetric({
    required String url,
    required String method,
    int? statusCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  }) async {
    if (!FeatureFlags().enablePerformanceMonitoring) return;

    try {
      final key = '$method:$url';
      final metric = _activeMetrics[key];
      
      if (metric != null) {
        if (statusCode != null) {
          metric.httpResponseCode = statusCode;
        }
        if (requestPayloadSize != null) {
          metric.requestPayloadSize = requestPayloadSize;
        }
        if (responsePayloadSize != null) {
          metric.responsePayloadSize = responsePayloadSize;
        }
        
        await metric.stop();
        _activeMetrics.remove(key);
        AppLogger.debug('HTTP metric stopped: $key');
      }
    } catch (e) {
      AppLogger.warning('Failed to stop HTTP metric: $e');
    }
  }

  // ==================== APP PERFORMANCE TRACKING ====================

  /// Track screen load time
  Future<void> trackScreenLoad(String screenName) async {
    final traceName = 'screen_$screenName';
    await startTrace(traceName);
    
    // Auto-stop after reasonable time (prevents memory leaks)
    Timer(const Duration(seconds: 30), () async {
      await stopTrace(traceName);
    });
  }

  /// Track database query performance
  Future<T> trackDatabaseQuery<T>(
    String queryName,
    Future<T> Function() query,
  ) async {
    final traceName = 'db_query_$queryName';
    await startTrace(traceName);
    
    try {
      final result = await query();
      await setTraceAttribute(traceName, 'status', 'success');
      return result;
    } catch (e) {
      await setTraceAttribute(traceName, 'status', 'error');
      rethrow;
    } finally {
      await stopTrace(traceName);
    }
  }

  /// Track API call performance
  Future<T> trackApiCall<T>(
    String endpoint,
    String method,
    Future<T> Function() apiCall,
  ) async {
    final url = '${EnvironmentConfig.apiBaseUrl}$endpoint';
    await startHttpMetric(url: url, method: method);
    
    try {
      final result = await apiCall();
      await stopHttpMetric(
        url: url,
        method: method,
        statusCode: 200,
      );
      return result;
    } catch (e) {
      await stopHttpMetric(
        url: url,
        method: method,
        statusCode: 500,
      );
      rethrow;
    }
  }

  // ==================== PERFORMANCE ALERTS ====================

  /// Add performance alert
  void addAlert({
    required AlertSeverity severity,
    required String message,
    String? metric,
    double? value,
    double? threshold,
  }) {
    final alert = PerformanceAlert(
      severity: severity,
      message: message,
      metric: metric,
      value: value,
      threshold: threshold,
      timestamp: DateTime.now(),
    );

    _alerts.add(alert);

    AppLogger.warning(
      'Performance alert - ${severity.name}: $message',
    );

    // Keep only recent alerts (last 100)
    if (_alerts.length > 100) {
      _alerts.removeRange(0, _alerts.length - 100);
    }
  }

  /// Check performance thresholds
  void checkThresholds({
    required String metric,
    required double value,
    required double warningThreshold,
    required double criticalThreshold,
  }) {
    if (value >= criticalThreshold) {
      addAlert(
        severity: AlertSeverity.critical,
        message: '$metric exceeded critical threshold',
        metric: metric,
        value: value,
        threshold: criticalThreshold,
      );
    } else if (value >= warningThreshold) {
      addAlert(
        severity: AlertSeverity.warning,
        message: '$metric exceeded warning threshold',
        metric: metric,
        value: value,
        threshold: warningThreshold,
      );
    }
  }

  /// Get recent alerts
  List<PerformanceAlert> getRecentAlerts({int limit = 50}) {
    return _alerts.reversed.take(limit).toList();
  }

  // ==================== REPORTING ====================

  /// Generate performance report
  Map<String, dynamic> generateReport() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentAlerts = _alerts
        .where((a) => a.timestamp.isAfter(last24Hours))
        .toList();

    return {
      'report_date': now.toIso8601String(),
      'active_traces': _activeTraces.length,
      'active_metrics': _activeMetrics.length,
      'total_alerts_24h': recentAlerts.length,
      'critical_alerts': recentAlerts
          .where((a) => a.severity == AlertSeverity.critical)
          .length,
      'warning_alerts': recentAlerts
          .where((a) => a.severity == AlertSeverity.warning)
          .length,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    // Stop all active traces
    for (final name in _activeTraces.keys.toList()) {
      await stopTrace(name);
    }

    // Stop all active metrics
    for (final key in _activeMetrics.keys.toList()) {
      final parts = key.split(':');
      if (parts.length == 2) {
        await stopHttpMetric(url: parts[1], method: parts[0]);
      }
    }

    AppLogger.info('Monitoring service disposed');
  }
}

// ==================== MODELS ====================

enum AlertSeverity {
  info,
  warning,
  critical,
}

class PerformanceAlert {
  final AlertSeverity severity;
  final String message;
  final String? metric;
  final double? value;
  final double? threshold;
  final DateTime timestamp;

  PerformanceAlert({
    required this.severity,
    required this.message,
    this.metric,
    this.value,
    this.threshold,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'severity': severity.name,
    'message': message,
    'metric': metric,
    'value': value,
    'threshold': threshold,
    'timestamp': timestamp.toIso8601String(),
  };
}
