import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:food_delivery_app/core/config/environment_config.dart';
import 'package:food_delivery_app/core/config/feature_flags.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Analytics service for tracking user behavior and app events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;

  /// Initialize analytics
  Future<void> initialize() async {
    if (!FeatureFlags().enableAnalytics) {
      AppLogger.info('Analytics disabled by feature flag');
      return;
    }

    if (EnvironmentConfig.isDevelopment) {
      AppLogger.info('Analytics disabled in development environment');
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      
      // Set default properties
      await _analytics?.setAnalyticsCollectionEnabled(true);
      
      AppLogger.success('Analytics service initialized');
    } catch (e, stack) {
      AppLogger.error('Failed to initialize analytics', error: e, stack: stack);
    }
  }

  /// Get analytics observer for navigation tracking
  FirebaseAnalyticsObserver? get observer => _observer;

  // ==================== USER TRACKING ====================

  /// Set user ID for tracking
  Future<void> setUserId(String userId) async {
    await _analytics?.setUserId(id: userId);
    AppLogger.debug('Analytics user ID set: $userId');
  }

  /// Set user properties
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics?.setUserProperty(name: name, value: value);
    AppLogger.debug('Analytics user property set: $name = $value');
  }

  /// Clear user data (on logout)
  Future<void> clearUserData() async {
    await _analytics?.setUserId(id: null);
    AppLogger.debug('Analytics user data cleared');
  }

  // ==================== EVENT TRACKING ====================

  /// Log custom event
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    if (!FeatureFlags().enableAnalytics) return;

    try {
      await _analytics?.logEvent(
        name: name,
        parameters: parameters,
      );
      AppLogger.debug('Analytics event logged: $name', details: parameters?.toString());
    } catch (e) {
      AppLogger.warning('Failed to log analytics event', error: e);
    }
  }

  // ==================== E-COMMERCE EVENTS ====================

  /// Track restaurant view
  Future<void> trackRestaurantView({
    required String restaurantId,
    required String restaurantName,
  }) async {
    await logEvent(
      name: 'view_restaurant',
      parameters: {
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
      },
    );
  }

  /// Track menu item view
  Future<void> trackMenuItemView({
    required String itemId,
    required String itemName,
    required double price,
  }) async {
    await logEvent(
      name: 'view_item',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
      },
    );
  }

  /// Track add to cart
  Future<void> trackAddToCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    await logEvent(
      name: 'add_to_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
        'price': price,
        'quantity': quantity,
        'value': price * quantity,
      },
    );
  }

  /// Track remove from cart
  Future<void> trackRemoveFromCart({
    required String itemId,
    required String itemName,
  }) async {
    await logEvent(
      name: 'remove_from_cart',
      parameters: {
        'item_id': itemId,
        'item_name': itemName,
      },
    );
  }

  /// Track begin checkout
  Future<void> trackBeginCheckout({
    required double value,
    required int itemCount,
  }) async {
    await logEvent(
      name: 'begin_checkout',
      parameters: {
        'value': value,
        'item_count': itemCount,
      },
    );
  }

  /// Track purchase
  Future<void> trackPurchase({
    required String orderId,
    required double value,
    required double tax,
    required double deliveryFee,
    required String paymentMethod,
  }) async {
    await _analytics?.logPurchase(
      value: value,
      currency: 'ZAR',
      transactionId: orderId,
      tax: tax,
      shipping: deliveryFee,
      parameters: {
        'payment_method': paymentMethod,
      },
    );
  }

  /// Track refund
  Future<void> trackRefund({
    required String orderId,
    required double value,
  }) async {
    await logEvent(
      name: 'refund',
      parameters: {
        'transaction_id': orderId,
        'value': value,
        'currency': 'ZAR',
      },
    );
  }

  // ==================== USER ENGAGEMENT ====================

  /// Track search
  Future<void> trackSearch(String searchTerm) async {
    await _analytics?.logSearch(searchTerm: searchTerm);
  }

  /// Track review submission
  Future<void> trackReviewSubmission({
    required String restaurantId,
    required int rating,
  }) async {
    await logEvent(
      name: 'submit_review',
      parameters: {
        'restaurant_id': restaurantId,
        'rating': rating,
      },
    );
  }

  /// Track share
  Future<void> trackShare({
    required String contentType,
    required String contentId,
  }) async {
    await _analytics?.logShare(
      contentType: contentType,
      itemId: contentId,
      method: 'app_share',
    );
  }

  // ==================== APP LIFECYCLE ====================

  /// Track app open
  Future<void> trackAppOpen() async {
    await _analytics?.logAppOpen();
  }

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics?.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  // ==================== ERROR TRACKING ====================

  /// Track error
  Future<void> trackError({
    required String error,
    String? fatal,
  }) async {
    await logEvent(
      name: 'app_error',
      parameters: {
        'error_message': error,
        'fatal': fatal ?? 'false',
      },
    );
  }

  // ==================== CUSTOM BUSINESS EVENTS ====================

  /// Track order cancellation
  Future<void> trackOrderCancellation({
    required String orderId,
    required String reason,
  }) async {
    await logEvent(
      name: 'cancel_order',
      parameters: {
        'order_id': orderId,
        'reason': reason,
      },
    );
  }

  /// Track delivery tracking
  Future<void> trackDeliveryTracking(String orderId) async {
    await logEvent(
      name: 'track_delivery',
      parameters: {
        'order_id': orderId,
      },
    );
  }

  /// Track promo code usage
  Future<void> trackPromoCodeUsage({
    required String promoCode,
    required double discountAmount,
  }) async {
    await logEvent(
      name: 'use_promo_code',
      parameters: {
        'promo_code': promoCode,
        'discount_amount': discountAmount,
      },
    );
  }
}
