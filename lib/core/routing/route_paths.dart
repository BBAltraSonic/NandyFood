import 'package:flutter/foundation.dart';

/// Centralized route paths and helpers for building parameterized routes
class RoutePaths {
  // Auth & entry
  static const String splash = '/';
  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';

  // Home
  static const String home = '/home';

  // Profile
  static const String profile = '/profile';
  static const String profileAddresses = '/profile/addresses';
  static const String profilePaymentMethods = '/profile/payment-methods';
  static const String profileAddPayment = '/profile/add-payment';

  // Order
  static const String orderCart = '/order/cart';
  static const String orderTrack = '/order/track'; // expects Order via extra
  static const String orderTrackByIdPattern = '/order/track/:id';
  static String orderTrackWithId(String id) => '$orderTrack/$id';
  static const String orderHistory = '/order/history';

  // Restaurant
  static const String restaurantByIdPattern = '/restaurant/:id';
  static String restaurant(String id) => '/restaurant/$id';
  static const String restaurantRegister = '/restaurant/register';
  static const String restaurantDashboard = '/restaurant/dashboard';
  static const String restaurantOrders = '/restaurant/orders';
  static const String restaurantMenu = '/restaurant/menu';
  static const String restaurantAnalytics = '/restaurant/analytics';
  static const String restaurantSettings = '/restaurant/settings';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminRestaurants = '/admin/restaurants';
  static const String adminOrders = '/admin/orders';
  static const String adminAnalytics = '/admin/analytics';
  static const String adminSettings = '/admin/settings';
  static const String adminSupport = '/admin/support';

  // Promotions
  static const String promotions = '/promotions';
  static const String promoByIdPattern = '/promo/:id';
  static String promo(String id) => '/promo/$id';
}

/// Notification payload helpers to avoid scattering string formats
class RoutePayloads {
  static String order(String id) => 'order:$id';
  static String promo(String id) => 'promo:$id';
  static const String promotions = RoutePaths.promotions;
}

