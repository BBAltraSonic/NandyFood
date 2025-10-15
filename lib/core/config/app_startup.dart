import 'package:flutter/foundation.dart';
import 'package:food_delivery_app/core/services/cache_service.dart';
import 'package:food_delivery_app/core/services/offline_sync_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

/// Handles app initialization and startup optimization
/// 
/// Initializes services in the correct order with proper error handling
/// and lazy loading for non-critical services.
class AppStartup {
  static bool _initialized = false;

  /// Initialize critical services required for app startup
  /// 
  /// This should be called before runApp() in main.dart
  static Future<void> initializeCriticalServices() async {
    if (_initialized) {
      AppLogger.warning('AppStartup: Already initialized');
      return;
    }

    final stopwatch = Stopwatch()..start();
    AppLogger.init('AppStartup: Starting critical services initialization...');

    try {
      // 1. Load environment variables (critical)
      await _loadEnvironment();

      // 2. Initialize Supabase (critical for auth)
      await _initializeSupabase();

      // 3. Initialize Firebase (critical for notifications)
      await _initializeFirebase();

      // 4. Initialize cache service (critical for offline mode)
      await _initializeCache();

      _initialized = true;
      stopwatch.stop();
      AppLogger.success(
        'AppStartup: Critical services initialized',
        details: 'Time: ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      AppLogger.error('AppStartup: Failed to initialize critical services - $e');
      rethrow;
    }
  }

  /// Initialize non-critical services after app is running
  /// 
  /// These can be loaded in background to improve startup time
  static Future<void> initializeNonCriticalServices() async {
    AppLogger.info('AppStartup: Starting non-critical services initialization...');

    try {
      // Initialize offline sync service
      await _initializeOfflineSync();

      // Initialize analytics (if needed)
      // await _initializeAnalytics();

      // Pre-cache critical data (if needed)
      // await _precacheData();

      AppLogger.success('AppStartup: Non-critical services initialized');
    } catch (e) {
      // Don't throw - these failures shouldn't prevent app from running
      AppLogger.warning('AppStartup: Some non-critical services failed to initialize - $e');
    }
  }

  /// Load environment variables
  static Future<void> _loadEnvironment() async {
    try {
      await dotenv.load(fileName: '.env');
      AppLogger.success('Environment variables loaded');
    } catch (e) {
      AppLogger.error('Failed to load environment variables - $e');
      // Don't rethrow - app can work with hardcoded fallbacks
    }
  }

  /// Initialize Supabase
  static Future<void> _initializeSupabase() async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw Exception('Supabase credentials not found in .env');
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );

      AppLogger.success('Supabase initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize Supabase - $e');
      rethrow; // Critical - app can't work without Supabase
    }
  }

  /// Initialize Firebase
  static Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      AppLogger.success('Firebase initialized');
    } catch (e) {
      AppLogger.warning('Firebase initialization failed (notifications may not work) - $e');
      // Don't rethrow - app can work without Firebase
    }
  }

  /// Initialize cache service
  static Future<void> _initializeCache() async {
    try {
      await CacheService.instance.initialize();
      AppLogger.success('Cache service initialized');
    } catch (e) {
      AppLogger.warning('Cache service initialization failed (offline mode may not work) - $e');
      // Don't rethrow - app can work without cache
    }
  }

  /// Initialize offline sync service
  static Future<void> _initializeOfflineSync() async {
    try {
      await OfflineSyncService.instance.initialize();
      AppLogger.success('Offline sync service initialized');
    } catch (e) {
      AppLogger.warning('Offline sync service initialization failed - $e');
      // Don't throw - this is non-critical
    }
  }

  /// Check if app is initialized
  static bool get isInitialized => _initialized;

  /// Get initialization status for debugging
  static Map<String, dynamic> getInitializationStatus() {
    return {
      'initialized': _initialized,
      'supabase': Supabase.instance.client.auth.currentUser != null,
      'cache': CacheService.instance.getCacheStats(),
      'offline_sync_queue': OfflineSyncService.instance.queuedActionsCount,
    };
  }
}
