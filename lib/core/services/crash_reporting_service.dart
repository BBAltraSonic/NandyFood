import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/core/config/environment_config.dart';
import 'package:food_delivery_app/core/config/feature_flags.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Crash reporting and error tracking service
class CrashReportingService {
  static final CrashReportingService _instance = CrashReportingService._internal();
  factory CrashReportingService() => _instance;
  CrashReportingService._internal();

  FirebaseCrashlytics? _crashlytics;

  /// Initialize crash reporting
  Future<void> initialize() async {
    if (!FeatureFlags().enableCrashReporting) {
      AppLogger.info('Crash reporting disabled by feature flag');
      return;
    }

    if (EnvironmentConfig.isDevelopment) {
      AppLogger.info('Crash reporting disabled in development environment');
      return;
    }

    try {
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable automatic crash collection
      await _crashlytics?.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught errors to Crashlytics
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics?.recordFlutterFatalError(details);
        AppLogger.error(
          'Flutter error',
          error: details.exception,
          stack: details.stack,
        );
      };

      // Catch errors not handled by Flutter
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics?.recordError(error, stack, fatal: true);
        AppLogger.error('Platform error', error: error, stack: stack);
        return true;
      };

      AppLogger.success('Crash reporting service initialized');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize crash reporting', error: e, stack: stack);
    }
  }

  // ==================== USER TRACKING ====================

  /// Set user identifier for crash reports
  Future<void> setUserId(String userId) async {
    await _crashlytics?.setUserIdentifier(userId);
    AppLogger.debug('Crash reporting user ID set: $userId');
  }

  /// Set custom key for crash context
  Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics?.setCustomKey(key, value);
    AppLogger.debug('Crash reporting custom key set: $key = $value');
  }

  /// Clear user data (on logout)
  Future<void> clearUserData() async {
    await _crashlytics?.setUserIdentifier('');
    AppLogger.debug('Crash reporting user data cleared');
  }

  // ==================== ERROR REPORTING ====================

  /// Record non-fatal error
  Future<void> recordError({
    required dynamic error,
    required StackTrace stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    if (!FeatureFlags().enableCrashReporting) return;

    try {
      await _crashlytics?.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );

      AppLogger.error(
        'Error recorded to crash reporting',
        error: error,
        stack: stackTrace,
        details: reason,
      );
    } catch (e) {
      AppLogger.warning('Failed to record error to crash reporting', error: e);
    }
  }

  /// Record Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!FeatureFlags().enableCrashReporting) return;

    try {
      await _crashlytics?.recordFlutterError(details);
      AppLogger.error(
        'Flutter error recorded',
        error: details.exception,
        stack: details.stack,
      );
    } catch (e) {
      AppLogger.warning('Failed to record Flutter error', error: e);
    }
  }

  /// Log message to crash report
  Future<void> log(String message) async {
    await _crashlytics?.log(message);
  }

  // ==================== CRASH CONTEXT ====================

  /// Set breadcrumb for debugging
  Future<void> setBreadcrumb({
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final breadcrumb = '$timestamp: $message';
    
    await _crashlytics?.log(breadcrumb);
    
    if (data != null) {
      for (final entry in data.entries) {
        await setCustomKey('breadcrumb_${entry.key}', entry.value);
      }
    }
  }

  /// Set app context information
  Future<void> setAppContext({
    required String appVersion,
    required String buildNumber,
    String? userId,
    String? userEmail,
  }) async {
    await setCustomKey('app_version', appVersion);
    await setCustomKey('build_number', buildNumber);
    
    if (userId != null) {
      await setUserId(userId);
    }
    
    if (userEmail != null) {
      await setCustomKey('user_email', userEmail);
    }
  }

  // ==================== PERFORMANCE ====================

  /// Test crash reporting (for testing only)
  Future<void> testCrash() async {
    if (EnvironmentConfig.isProduction) {
      AppLogger.warning('Cannot test crash in production environment');
      return;
    }

    AppLogger.warning('Triggering test crash...');
    await _crashlytics?.crash();
  }

  /// Force send pending crash reports
  Future<void> sendUnsentReports() async {
    await _crashlytics?.sendUnsentReports();
    AppLogger.info('Unsent crash reports sent');
  }

  /// Delete unsent reports
  Future<void> deleteUnsentReports() async {
    await _crashlytics?.deleteUnsentReports();
    AppLogger.info('Unsent crash reports deleted');
  }

  /// Check for unsent reports
  Future<bool> checkForUnsentReports() async {
    final hasUnsent = await _crashlytics?.checkForUnsentReports() ?? false;
    return hasUnsent;
  }
}

/// Extension for easy error reporting
extension ErrorReportingExtension on Object {
  /// Report this error to crash reporting
  Future<void> report({
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    await CrashReportingService().recordError(
      error: this,
      stackTrace: stackTrace ?? StackTrace.current,
      reason: reason,
      fatal: fatal,
    );
  }
}
