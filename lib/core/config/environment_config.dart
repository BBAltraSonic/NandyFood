import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Environment configuration for different deployment stages
enum Environment {
  development,
  staging,
  production,
}

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  /// Initialize environment configuration
  static Future<void> initialize() async {
    final envString = dotenv.maybeGet('ENVIRONMENT') ?? 'development';
    
    switch (envString.toLowerCase()) {
      case 'production':
        _currentEnvironment = Environment.production;
        break;
      case 'staging':
        _currentEnvironment = Environment.staging;
        break;
      case 'development':
      default:
        _currentEnvironment = Environment.development;
        break;
    }

    AppLogger.info('Environment initialized: ${_currentEnvironment.name}');
  }

  /// Get current environment
  static Environment get current => _currentEnvironment;

  /// Check if running in production
  static bool get isProduction => _currentEnvironment == Environment.production;

  /// Check if running in staging
  static bool get isStaging => _currentEnvironment == Environment.staging;

  /// Check if running in development
  static bool get isDevelopment => _currentEnvironment == Environment.development;

  // ==================== ENVIRONMENT-SPECIFIC CONFIGURATIONS ====================

  /// API base URL
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.production:
        return dotenv.get('PRODUCTION_API_URL', fallback: 'https://api.nandyfood.com');
      case Environment.staging:
        return dotenv.get('STAGING_API_URL', fallback: 'https://staging-api.nandyfood.com');
      case Environment.development:
        return dotenv.get('DEV_API_URL', fallback: 'http://localhost:3000');
    }
  }

  /// Supabase URL
  static String get supabaseUrl {
    switch (_currentEnvironment) {
      case Environment.production:
        return dotenv.get('SUPABASE_URL_PROD', fallback: dotenv.get('SUPABASE_URL'));
      case Environment.staging:
        return dotenv.get('SUPABASE_URL_STAGING', fallback: dotenv.get('SUPABASE_URL'));
      case Environment.development:
        return dotenv.get('SUPABASE_URL');
    }
  }

  /// Supabase Anon Key
  static String get supabaseAnonKey {
    switch (_currentEnvironment) {
      case Environment.production:
        return dotenv.get('SUPABASE_ANON_KEY_PROD', fallback: dotenv.get('SUPABASE_ANON_KEY'));
      case Environment.staging:
        return dotenv.get('SUPABASE_ANON_KEY_STAGING', fallback: dotenv.get('SUPABASE_ANON_KEY'));
      case Environment.development:
        return dotenv.get('SUPABASE_ANON_KEY');
    }
  }

  /// PayFast configuration
  static bool get usePayFastSandbox {
    if (_currentEnvironment == Environment.production) {
      return false;
    }
    return dotenv.get('PAYFAST_MODE', fallback: 'sandbox').toLowerCase() == 'sandbox';
  }

  /// Debug mode
  static bool get debugMode {
    if (_currentEnvironment == Environment.production) {
      return false;
    }
    return dotenv.get('DEBUG_MODE', fallback: 'true').toLowerCase() == 'true';
  }

  /// Enable detailed logging
  static bool get enableDetailedLogging {
    return debugMode || _currentEnvironment == Environment.development;
  }

  /// Sentry DSN (crash reporting)
  static String? get sentryDsn {
    if (_currentEnvironment == Environment.development) {
      return null; // Don't send crash reports in development
    }
    return dotenv.maybeGet('SENTRY_DSN');
  }

  /// Google Analytics tracking ID
  static String? get analyticsTrackingId {
    if (_currentEnvironment == Environment.development) {
      return null; // Don't track in development
    }
    return dotenv.maybeGet('GOOGLE_ANALYTICS_ID');
  }

  /// Enable mock services (for testing)
  static bool get useMockServices {
    return dotenv.get('USE_MOCK_SERVICES', fallback: 'false').toLowerCase() == 'true';
  }

  /// API timeout
  static Duration get apiTimeout {
    switch (_currentEnvironment) {
      case Environment.production:
        return const Duration(seconds: 30);
      case Environment.staging:
        return const Duration(seconds: 45);
      case Environment.development:
        return const Duration(seconds: 60);
    }
  }

  /// Maximum retry attempts for failed requests
  static int get maxRetryAttempts {
    return _currentEnvironment == Environment.production ? 2 : 1;
  }

  /// Cache duration
  static Duration get cacheDuration {
    switch (_currentEnvironment) {
      case Environment.production:
        return const Duration(minutes: 30);
      case Environment.staging:
        return const Duration(minutes: 15);
      case Environment.development:
        return const Duration(minutes: 5);
    }
  }

  // ==================== CONFIGURATION REPORT ====================

  /// Generate configuration report (for debugging, never log sensitive data)
  static Map<String, dynamic> generateReport() {
    return {
      'environment': _currentEnvironment.name,
      'is_production': isProduction,
      'is_staging': isStaging,
      'is_development': isDevelopment,
      'debug_mode': debugMode,
      'api_base_url': apiBaseUrl,
      'use_payfast_sandbox': usePayFastSandbox,
      'api_timeout': apiTimeout.inSeconds,
      'max_retry_attempts': maxRetryAttempts,
      'cache_duration': cacheDuration.inMinutes,
      'analytics_enabled': analyticsTrackingId != null,
      'crash_reporting_enabled': sentryDsn != null,
      'use_mock_services': useMockServices,
    };
  }
}
