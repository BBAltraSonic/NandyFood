import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag management for gradual rollout and A/B testing
class FeatureFlags {
  static final FeatureFlags _instance = FeatureFlags._internal();
  factory FeatureFlags() => _instance;
  FeatureFlags._internal();

  SharedPreferences? _prefs;
  final Map<String, bool> _overrides = {};

  /// Initialize feature flags
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('Feature flags initialized');
  }

  // ==================== FEATURE FLAGS ====================

  /// Payment features
  bool get enablePayFastPayment => _getFlag('enable_payfast_payment', true);
  bool get enableSavedCards => _getFlag('enable_saved_cards', false);
  bool get enableWalletPayment => _getFlag('enable_wallet_payment', false);

  /// Social features
  bool get enableSocialLogin => _getFlag('enable_social_login', true);
  bool get enableReviews => _getFlag('enable_reviews', true);
  bool get enableRatings => _getFlag('enable_ratings', true);
  bool get enableReviewPhotos => _getFlag('enable_review_photos', true);

  /// Order features
  bool get enableRealTimeTracking => _getFlag('enable_realtime_tracking', true);
  bool get enableScheduledOrders => _getFlag('enable_scheduled_orders', false);
  bool get enableGroupOrders => _getFlag('enable_group_orders', false);
  bool get enableOrderModification => _getFlag('enable_order_modification', false);

  /// Promotion features
  bool get enablePromoCodes => _getFlag('enable_promo_codes', true);
  bool get enableLoyaltyProgram => _getFlag('enable_loyalty_program', false);
  bool get enableReferralProgram => _getFlag('enable_referral_program', false);

  /// Communication features
  bool get enablePushNotifications => _getFlag('enable_push_notifications', true);
  bool get enableInAppNotifications => _getFlag('enable_inapp_notifications', true);
  bool get enableEmailNotifications => _getFlag('enable_email_notifications', true);
  bool get enableSMSNotifications => _getFlag('enable_sms_notifications', false);
  bool get enableChatSupport => _getFlag('enable_chat_support', false);

  /// Analytics features
  bool get enableAnalytics => _getFlag('enable_analytics', true);
  bool get enableCrashReporting => _getFlag('enable_crash_reporting', true);
  bool get enablePerformanceMonitoring => _getFlag('enable_performance_monitoring', true);

  /// Advanced features
  bool get enableOfflineMode => _getFlag('enable_offline_mode', true);
  bool get enableAdvancedFilters => _getFlag('enable_advanced_filters', true);
  bool get enableFavorites => _getFlag('enable_favorites', true);
  bool get enableSearchHistory => _getFlag('enable_search_history', true);

  /// Restaurant features
  bool get enableRestaurantDashboard => _getFlag('enable_restaurant_dashboard', true);
  bool get enableRestaurantAnalytics => _getFlag('enable_restaurant_analytics', false);
  bool get enableMenuManagement => _getFlag('enable_menu_management', true);

  /// Experimental features
  bool get enableVoiceOrdering => _getFlag('enable_voice_ordering', false);
  bool get enableARMenuPreview => _getFlag('enable_ar_menu_preview', false);
  bool get enableAIRecommendations => _getFlag('enable_ai_recommendations', false);

  // ==================== FEATURE FLAG METHODS ====================

  /// Get feature flag value with fallback to environment variable
  bool _getFlag(String key, bool defaultValue) {
    // Check for override first (for testing/debugging)
    if (_overrides.containsKey(key)) {
      return _overrides[key]!;
    }

    // Check local storage (user-specific or server-set flags)
    final localValue = _prefs?.getBool(key);
    if (localValue != null) {
      return localValue;
    }

    // Check environment variables
    final envKey = key.toUpperCase();
    final envValue = dotenv.maybeGet(envKey);
    if (envValue != null) {
      return envValue.toLowerCase() == 'true';
    }

    // Return default value
    return defaultValue;
  }

  /// Override a feature flag (for testing/debugging)
  void override(String key, bool value) {
    _overrides[key] = value;
    AppLogger.debug('Feature flag overridden: $key = $value');
  }

  /// Clear override
  void clearOverride(String key) {
    _overrides.remove(key);
    AppLogger.debug('Feature flag override cleared: $key');
  }

  /// Clear all overrides
  void clearAllOverrides() {
    _overrides.clear();
    AppLogger.debug('All feature flag overrides cleared');
  }

  /// Save feature flag to local storage
  Future<void> saveFlag(String key, bool value) async {
    await _prefs?.setBool(key, value);
    AppLogger.info('Feature flag saved: $key = $value');
  }

  /// Get all active feature flags
  Map<String, bool> getAllFlags() {
    return {
      // Payment
      'enable_payfast_payment': enablePayFastPayment,
      'enable_saved_cards': enableSavedCards,
      'enable_wallet_payment': enableWalletPayment,
      // Social
      'enable_social_login': enableSocialLogin,
      'enable_reviews': enableReviews,
      'enable_ratings': enableRatings,
      'enable_review_photos': enableReviewPhotos,
      // Order
      'enable_realtime_tracking': enableRealTimeTracking,
      'enable_scheduled_orders': enableScheduledOrders,
      'enable_group_orders': enableGroupOrders,
      'enable_order_modification': enableOrderModification,
      // Promotion
      'enable_promo_codes': enablePromoCodes,
      'enable_loyalty_program': enableLoyaltyProgram,
      'enable_referral_program': enableReferralProgram,
      // Communication
      'enable_push_notifications': enablePushNotifications,
      'enable_inapp_notifications': enableInAppNotifications,
      'enable_email_notifications': enableEmailNotifications,
      'enable_sms_notifications': enableSMSNotifications,
      'enable_chat_support': enableChatSupport,
      // Analytics
      'enable_analytics': enableAnalytics,
      'enable_crash_reporting': enableCrashReporting,
      'enable_performance_monitoring': enablePerformanceMonitoring,
      // Advanced
      'enable_offline_mode': enableOfflineMode,
      'enable_advanced_filters': enableAdvancedFilters,
      'enable_favorites': enableFavorites,
      'enable_search_history': enableSearchHistory,
      // Restaurant
      'enable_restaurant_dashboard': enableRestaurantDashboard,
      'enable_restaurant_analytics': enableRestaurantAnalytics,
      'enable_menu_management': enableMenuManagement,
      // Experimental
      'enable_voice_ordering': enableVoiceOrdering,
      'enable_ar_menu_preview': enableARMenuPreview,
      'enable_ai_recommendations': enableAIRecommendations,
    };
  }

  /// Feature flag report (for admin/debugging)
  Map<String, dynamic> generateReport() {
    final flags = getAllFlags();
    final activeCount = flags.values.where((v) => v).length;
    final totalCount = flags.length;

    return {
      'report_date': DateTime.now().toIso8601String(),
      'total_flags': totalCount,
      'active_flags': activeCount,
      'inactive_flags': totalCount - activeCount,
      'flags': flags,
      'overrides': _overrides,
    };
  }
}
