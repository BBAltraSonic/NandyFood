// This file runs all tests in the application
import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'unit/services/auth_service_test.dart' as auth_service_test;
import 'unit/services/database_service_test.dart' as database_service_test;
import 'unit/services/payment_service_test.dart' as payment_service_test;
import 'unit/services/location_service_test.dart' as location_service_test;
import 'unit/services/notification_service_test.dart'
    as notification_service_test;
import 'unit/services/storage_service_test.dart' as storage_service_test;
import 'unit/services/delivery_tracking_service_test.dart'
    as delivery_tracking_service_test;

import 'widget/screens/login_screen_test.dart' as login_screen_test;
import 'widget/screens/signup_screen_test.dart' as signup_screen_test;
import 'widget/screens/home_screen_test.dart' as home_screen_test;
import 'widget/screens/restaurant_list_screen_test.dart'
    as restaurant_list_screen_test;
import 'widget/screens/restaurant_detail_screen_test.dart'
    as restaurant_detail_screen_test;
import 'widget/screens/menu_screen_test.dart' as menu_screen_test;
import 'widget/screens/cart_screen_test.dart' as cart_screen_test;
import 'widget/screens/checkout_screen_test.dart' as checkout_screen_test;
import 'widget/screens/order_tracking_screen_test.dart'
    as order_tracking_screen_test;
import 'widget/screens/order_history_screen_test.dart'
    as order_history_screen_test;
import 'widget/screens/profile_screen_test.dart' as profile_screen_test;
import 'widget/screens/settings_screen_test.dart' as settings_screen_test;

import 'integration/user_auth_flow_test.dart' as user_auth_flow_test;
import 'integration/place_order_flow_test.dart' as place_order_flow_test;
import 'integration/order_tracking_flow_test.dart' as order_tracking_flow_test;
import 'integration/payment_processing_flow_test.dart'
    as payment_processing_flow_test;
import 'integration/restaurant_browsing_flow_test.dart'
    as restaurant_browsing_flow_test;
import 'integration/profile_management_flow_test.dart'
    as profile_management_flow_test;
import 'integration/notification_handling_flow_test.dart'
    as notification_handling_flow_test;

void main() {
  group('All Tests Suite', () {
    // Run unit tests
    group('Unit Tests', () {
      auth_service_test.main();
      database_service_test.main();
      payment_service_test.main();
      location_service_test.main();
      notification_service_test.main();
      storage_service_test.main();
      delivery_tracking_service_test.main();
    });

    // Run widget tests
    group('Widget Tests', () {
      login_screen_test.main();
      signup_screen_test.main();
      home_screen_test.main();
      restaurant_list_screen_test.main();
      restaurant_detail_screen_test.main();
      menu_screen_test.main();
      cart_screen_test.main();
      checkout_screen_test.main();
      order_tracking_screen_test.main();
      order_history_screen_test.main();
      profile_screen_test.main();
      settings_screen_test.main();
    });

    // Run integration tests
    group('Integration Tests', () {
      user_auth_flow_test.main();
      place_order_flow_test.main();
      order_tracking_flow_test.main();
      payment_processing_flow_test.main();
      restaurant_browsing_flow_test.main();
      profile_management_flow_test.main();
      notification_handling_flow_test.main();
    });
  });
}
