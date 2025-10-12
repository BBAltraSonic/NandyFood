import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Service for managing Firebase Analytics events
class AnalyticsService {
  AnalyticsService() : _analytics = FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// Get Firebase Analytics observer for navigation tracking
  FirebaseAnalyticsObserver getAnalyticsObserver() {
    return FirebaseAnalyticsObserver(analytics: _analytics);
  }

  // ==================== App Events ====================

  /// Log app open event
  Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
      debugPrint('Analytics: App opened');
    } catch (e) {
      debugPrint('Error logging app open: $e');
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('Analytics: Screen view - $screenName');
    } catch (e) {
      debugPrint('Error logging screen view: $e');
    }
  }

  // ==================== User Properties ====================

  /// Set user ID
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      debugPrint('Analytics: User ID set - $userId');
    } catch (e) {
      debugPrint('Error setting user ID: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userType,
    String? membershipTier,
    int? totalOrders,
    double? lifetimeValue,
  }) async {
    try {
      if (userType != null) {
        await _analytics.setUserProperty(
          name: 'user_type',
          value: userType,
        );
      }

      if (membershipTier != null) {
        await _analytics.setUserProperty(
          name: 'membership_tier',
          value: membershipTier,
        );
      }

      if (totalOrders != null) {
        await _analytics.setUserProperty(
          name: 'total_orders',
          value: totalOrders.toString(),
        );
      }

      if (lifetimeValue != null) {
        await _analytics.setUserProperty(
          name: 'lifetime_value',
          value: lifetimeValue.toStringAsFixed(2),
        );
      }

      debugPrint('Analytics: User properties updated');
    } catch (e) {
      debugPrint('Error setting user properties: $e');
    }
  }

  // ==================== Authentication Events ====================

  /// Log sign up event
  Future<void> logSignUp(String method) async {
    try {
      await _analytics.logSignUp(signUpMethod: method);
      debugPrint('Analytics: Sign up - $method');
    } catch (e) {
      debugPrint('Error logging sign up: $e');
    }
  }

  /// Log login event
  Future<void> logLogin(String method) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('Analytics: Login - $method');
    } catch (e) {
      debugPrint('Error logging login: $e');
    }
  }

  // ==================== Restaurant Events ====================

  /// Log restaurant view
  Future<void> logRestaurantView({
    required String restaurantId,
    required String restaurantName,
    String? category,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'restaurant_view',
        parameters: {
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
          if (category != null) 'category': category,
        },
      );
      debugPrint('Analytics: Restaurant view - $restaurantName');
    } catch (e) {
      debugPrint('Error logging restaurant view: $e');
    }
  }

  /// Log menu item view
  Future<void> logMenuItemView({
    required String itemId,
    required String itemName,
    required String restaurantId,
    required double price,
  }) async {
    try {
      await _analytics.logViewItem(
        currency: 'USD',
        value: price,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            affiliation: restaurantId,
            price: price,
          ),
        ],
      );
      debugPrint('Analytics: Menu item view - $itemName');
    } catch (e) {
      debugPrint('Error logging menu item view: $e');
    }
  }

  // ==================== Cart & Checkout Events ====================

  /// Log add to cart
  Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required String restaurantId,
    required double price,
    required int quantity,
  }) async {
    try {
      await _analytics.logAddToCart(
        currency: 'USD',
        value: price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            affiliation: restaurantId,
            price: price,
            quantity: quantity,
          ),
        ],
      );
      debugPrint('Analytics: Add to cart - $itemName x$quantity');
    } catch (e) {
      debugPrint('Error logging add to cart: $e');
    }
  }

  /// Log remove from cart
  Future<void> logRemoveFromCart({
    required String itemId,
    required String itemName,
    required double price,
    required int quantity,
  }) async {
    try {
      await _analytics.logRemoveFromCart(
        currency: 'USD',
        value: price * quantity,
        items: [
          AnalyticsEventItem(
            itemId: itemId,
            itemName: itemName,
            price: price,
            quantity: quantity,
          ),
        ],
      );
      debugPrint('Analytics: Remove from cart - $itemName');
    } catch (e) {
      debugPrint('Error logging remove from cart: $e');
    }
  }

  /// Log begin checkout
  Future<void> logBeginCheckout({
    required double value,
    required String currency,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      await _analytics.logBeginCheckout(
        currency: currency,
        value: value,
        items: items
            .map((item) => AnalyticsEventItem(
                  itemId: item['id'] as String,
                  itemName: item['name'] as String,
                  price: item['price'] as double,
                  quantity: item['quantity'] as int,
                ))
            .toList(),
      );
      debugPrint('Analytics: Begin checkout - \$$value');
    } catch (e) {
      debugPrint('Error logging begin checkout: $e');
    }
  }

  /// Log purchase/order completion
  Future<void> logPurchase({
    required String orderId,
    required double value,
    required String currency,
    required String restaurantId,
    required List<Map<String, dynamic>> items,
    double? tax,
    double? deliveryFee,
    String? paymentMethod,
  }) async {
    try {
      await _analytics.logPurchase(
        transactionId: orderId,
        currency: currency,
        value: value,
        tax: tax,
        shipping: deliveryFee,
        affiliation: restaurantId,
        items: items
            .map((item) => AnalyticsEventItem(
                  itemId: item['id'] as String,
                  itemName: item['name'] as String,
                  price: item['price'] as double,
                  quantity: item['quantity'] as int,
                  affiliation: restaurantId,
                ))
            .toList(),
      );

      if (paymentMethod != null) {
        await _analytics.logEvent(
          name: 'payment_method_used',
          parameters: {
            'method': paymentMethod,
            'order_id': orderId,
            'value': value,
          },
        );
      }

      debugPrint('Analytics: Purchase - Order $orderId, \$$value');
    } catch (e) {
      debugPrint('Error logging purchase: $e');
    }
  }

  // ==================== Order Events ====================

  /// Log order status change
  Future<void> logOrderStatusChange({
    required String orderId,
    required String newStatus,
    required String oldStatus,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'order_status_change',
        parameters: {
          'order_id': orderId,
          'new_status': newStatus,
          'old_status': oldStatus,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Order status - $oldStatus → $newStatus');
    } catch (e) {
      debugPrint('Error logging order status change: $e');
    }
  }

  /// Log order cancellation
  Future<void> logOrderCancellation({
    required String orderId,
    required String reason,
    required double orderValue,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'order_cancelled',
        parameters: {
          'order_id': orderId,
          'reason': reason,
          'order_value': orderValue,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Order cancelled - $orderId');
    } catch (e) {
      debugPrint('Error logging order cancellation: $e');
    }
  }

  // ==================== Search & Filter Events ====================

  /// Log search
  Future<void> logSearch(String searchTerm) async {
    try {
      await _analytics.logSearch(searchTerm: searchTerm);
      debugPrint('Analytics: Search - "$searchTerm"');
    } catch (e) {
      debugPrint('Error logging search: $e');
    }
  }

  /// Log filter usage
  Future<void> logFilterUsage({
    required String filterType,
    required String filterValue,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'filter_applied',
        parameters: {
          'filter_type': filterType,
          'filter_value': filterValue,
        },
      );
      debugPrint('Analytics: Filter - $filterType: $filterValue');
    } catch (e) {
      debugPrint('Error logging filter usage: $e');
    }
  }

  // ==================== Rating & Review Events ====================

  /// Log review submission
  Future<void> logReviewSubmission({
    required String restaurantId,
    required double rating,
    required bool hasPhoto,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'review_submitted',
        parameters: {
          'restaurant_id': restaurantId,
          'rating': rating,
          'has_photo': hasPhoto,
        },
      );
      debugPrint('Analytics: Review submitted - $rating stars');
    } catch (e) {
      debugPrint('Error logging review submission: $e');
    }
  }

  // ==================== Favorites Events ====================

  /// Log add to favorites
  Future<void> logAddToFavorites({
    required String restaurantId,
    required String restaurantName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'add_to_favorites',
        parameters: {
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
        },
      );
      debugPrint('Analytics: Added to favorites - $restaurantName');
    } catch (e) {
      debugPrint('Error logging add to favorites: $e');
    }
  }

  /// Log remove from favorites
  Future<void> logRemoveFromFavorites({
    required String restaurantId,
    required String restaurantName,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'remove_from_favorites',
        parameters: {
          'restaurant_id': restaurantId,
          'restaurant_name': restaurantName,
        },
      );
      debugPrint('Analytics: Removed from favorites - $restaurantName');
    } catch (e) {
      debugPrint('Error logging remove from favorites: $e');
    }
  }

  // ==================== Engagement Events ====================

  /// Log share
  Future<void> logShare({
    required String contentType,
    required String itemId,
    required String method,
  }) async {
    try {
      await _analytics.logShare(
        contentType: contentType,
        itemId: itemId,
        method: method,
      );
      debugPrint('Analytics: Share - $contentType via $method');
    } catch (e) {
      debugPrint('Error logging share: $e');
    }
  }

  /// Log tutorial completion
  Future<void> logTutorialComplete() async {
    try {
      await _analytics.logTutorialComplete();
      debugPrint('Analytics: Tutorial completed');
    } catch (e) {
      debugPrint('Error logging tutorial complete: $e');
    }
  }

  // ==================== Error Tracking ====================

  /// Log error
  Future<void> logError({
    required String errorCode,
    required String errorMessage,
    String? screen,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'error_occurred',
        parameters: {
          'error_code': errorCode,
          'error_message': errorMessage,
          if (screen != null) 'screen': screen,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      debugPrint('Analytics: Error - $errorCode: $errorMessage');
    } catch (e) {
      debugPrint('Error logging error: $e');
    }
  }

  // ==================== Custom Events ====================

  /// Log custom event
  Future<void> logCustomEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      debugPrint('Analytics: Custom event - $name');
    } catch (e) {
      debugPrint('Error logging custom event: $e');
    }
  }
}
