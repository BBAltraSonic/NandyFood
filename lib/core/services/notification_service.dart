import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Top-level function for handling background FCM messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('Handling background FCM message: ${message.messageId}');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  bool _timezoneInitialized = false;
  String? _fcmToken;

  // Navigation key for routing from notifications
  static GlobalKey<NavigatorState>? _navigatorKey;
  static GoRouter? _router;

  String? get fcmToken => _fcmToken;

  /// Set the navigation key for routing
  static void setNavigationContext({
    GlobalKey<NavigatorState>? navigatorKey,
    GoRouter? router,
  }) {
    _navigatorKey = navigatorKey;
    _router = router;
    debugPrint('Navigation context set for NotificationService');
  }

  int _normalizeId(int id) => id & 0x7fffffff;

  Future<void> _safeOperation(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException catch (e) {
      debugPrint('Notification plugin missing: $e');
    } catch (e) {
      debugPrint('Error handling notification operation: $e');
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    WidgetsFlutterBinding.ensureInitialized();

    if (!_timezoneInitialized) {
      tz.initializeTimeZones();
      _timezoneInitialized = true;
    }

    // Only initialize local notifications on supported platforms (Android/iOS)
    if (Platform.isAndroid || Platform.isIOS) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _safeOperation(() async {
        await _notifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: _onNotificationTapped,
        );
      });

      // Initialize FCM (only on mobile platforms)
      await _initializeFCM();
    } else {
      debugPrint('Local notifications not supported on this platform (${Platform.operatingSystem})');
    }

    _isInitialized = true;
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFCM() async {
    try {
      // Request FCM permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM permission granted');

        // Get FCM token
        await _getFCMToken();

        // Configure foreground notification presentation
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Set up FCM message handlers
        _setupFCMHandlers();

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      // For iOS, ensure APNs token is available
      if (Platform.isIOS) {
        final apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('Waiting for APNs token...');
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }

      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // TODO: Send token to backend
      await _sendTokenToBackend(_fcmToken);
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Handle FCM token refresh
  void _onTokenRefresh(String token) {
    _fcmToken = token;
    debugPrint('FCM Token refreshed: $token');
    _sendTokenToBackend(token);
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String? token) async {
    if (token == null) return;

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('No user logged in, FCM token not stored');
        return;
      }

      // Get package info for app version
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // Get device name
      final deviceName = await _getDeviceName();

      // Store token in Supabase user_devices table
      await supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'device_name': deviceName,
        'app_version': appVersion,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');

      debugPrint('FCM token registered: Device=$deviceName, Version=$appVersion, Platform=${Platform.isIOS ? 'iOS' : 'Android'}');

      debugPrint('FCM token stored in database for user: $userId');
    } catch (e) {
      debugPrint('Error sending FCM token to backend: $e');
    }
  }

  /// Get device name
  Future<String> _getDeviceName() async {
    try {
      if (Platform.isIOS) {
        return 'iOS Device';
      } else if (Platform.isAndroid) {
        return 'Android Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      return 'Unknown Device';
    }
  }

  /// Set up FCM message handlers
  void _setupFCMHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps (background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (terminated)
    _checkInitialMessage();
  }

  /// Handle FCM message in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground FCM message: ${message.messageId}');

    if (message.notification != null) {
      // Show local notification
      await showNotification(
        id: message.hashCode,
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap from background
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    _navigateFromNotification(message.data);
  }

  /// Check for initial message when app was terminated
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from notification: ${initialMessage.messageId}');
      _navigateFromNotification(initialMessage.data);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      // Parse payload and navigate
      _handlePayload(response.payload!);
    }
  }

  /// Handle notification payload
  void _handlePayload(String payload) {
    debugPrint('Handling notification payload: $payload');

    if (payload.startsWith('order:')) {
      final orderId = payload.replaceFirst('order:', '');
      _navigateToRoute('/order/tracking/$orderId');
    } else if (payload.startsWith('restaurant:')) {
      final restaurantId = payload.replaceFirst('restaurant:', '');
      _navigateToRoute('/restaurant/$restaurantId');
    } else if (payload.startsWith('chat:')) {
      final chatId = payload.replaceFirst('chat:', '');
      _navigateToRoute('/chat/$chatId');
    } else if (payload.startsWith('promo:')) {
      final promoId = payload.replaceFirst('promo:', '');
      _navigateToRoute('/promo/$promoId');
    } else {
      // Default to home if payload format is unknown
      _navigateToRoute('/home');
    }
  }

  /// Navigate based on notification data (FCM remote message)
  void _navigateFromNotification(Map<String, dynamic> data) {
    debugPrint('Navigating from notification data: $data');

    final type = data['type'] as String?;

    switch (type) {
      case 'order_update':
      case 'order_status':
        final orderId = data['order_id'] as String?;
        if (orderId != null) {
          _navigateToRoute('/order/tracking/$orderId');
        }
        break;

      case 'new_order':
        // For restaurant owners - navigate to orders screen
        _navigateToRoute('/restaurant/orders');
        break;

      case 'restaurant_update':
        final restaurantId = data['restaurant_id'] as String?;
        if (restaurantId != null) {
          _navigateToRoute('/restaurant/$restaurantId');
        }
        break;

      case 'promotion':
      case 'promo':
        final promoId = data['promo_id'] as String?;
        if (promoId != null) {
          _navigateToRoute('/promo/$promoId');
        } else {
          _navigateToRoute('/home');
        }
        break;

      case 'driver_nearby':
      case 'delivery_update':
        final orderId = data['order_id'] as String?;
        if (orderId != null) {
          _navigateToRoute('/order/tracking/$orderId');
        }
        break;

      default:
        // Unknown type - navigate to home
        _navigateToRoute('/home');
    }
  }

  /// Navigate to a specific route
  void _navigateToRoute(String route) {
    debugPrint('Attempting to navigate to: $route');

    // Try using GoRouter first (preferred)
    if (_router != null) {
      try {
        _router!.go(route);
        debugPrint('Navigation successful via GoRouter: $route');
        return;
      } catch (e) {
        debugPrint('GoRouter navigation failed: $e');
      }
    }

    // Fallback to Navigator if GoRouter is not available
    if (_navigatorKey?.currentState != null) {
      try {
        _navigatorKey!.currentState!.pushNamed(route);
        debugPrint('Navigation successful via Navigator: $route');
      } catch (e) {
        debugPrint('Navigator navigation failed: $e');
      }
    } else {
      debugPrint('No navigation context available. Route: $route');
      debugPrint('Please call NotificationService.setNavigationContext() in main.dart');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    int? secondsDelay,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
          'food_delivery_channel',
          'Food Delivery Notifications',
          channelDescription: 'Notifications for food delivery updates',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'New notification',
          playSound: true,
          enableVibration: true,
        );

    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await initialize();

    final notificationId = _normalizeId(id);

    if (secondsDelay != null && secondsDelay > 0) {
      // Schedule notification for later
      await _safeOperation(() async {
        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tz.TZDateTime.from(
            DateTime.now().add(Duration(seconds: secondsDelay)),
            tz.local,
          ),
          platformChannelSpecifics,
          payload: payload,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      });
    } else {
      // Show notification immediately
      await _safeOperation(() async {
        await _notifications.show(
          notificationId,
          title,
          body,
          platformChannelSpecifics,
          payload: payload,
        );
      });
    }
  }

  // Show order status notifications
  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
    required String restaurantName,
  }) async {
    String title;
    String body;

    switch (status.toLowerCase()) {
      case 'confirmed':
        title = 'Order Confirmed!';
        body = 'Your order from $restaurantName has been confirmed.';
        break;
      case 'preparing':
        title = 'Order Preparing';
        body = 'Your order from $restaurantName is being prepared.';
        break;
      case 'ready_for_pickup':
        title = 'Order Ready';
        body = 'Your order from $restaurantName is ready for pickup.';
        break;
      case 'out_for_delivery':
        title = 'On the Way!';
        body = 'Your order from $restaurantName is out for delivery.';
        break;
      case 'delivered':
        title = 'Order Delivered!';
        body =
            'Your order from $restaurantName has been delivered. Enjoy your meal!';
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order from $restaurantName has been cancelled.';
        break;
      default:
        title = 'Order Update';
        body = 'Update for your order from $restaurantName: $status';
        break;
    }

    await showNotification(
      id: orderId.hashCode,
      title: title,
      body: body,
      payload: 'order:$orderId',
    );
  }

  // Show promotional notifications
  Future<void> showPromotionalNotification({
    required String title,
    required String body,
    String? actionUrl,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: actionUrl ?? 'promotions',
    );
  }

  // Show delivery driver notifications
  Future<void> showDeliveryNotification({
    required String orderId,
    String? driverName,
    String? vehicleInfo,
  }) async {
    String title = 'Driver Update';
    String body = driverName != null
        ? 'Your driver $driverName is on the way with your order'
        : 'Your order is on the way';

    if (vehicleInfo != null) {
      body += ' in a $vehicleInfo';
    }

    body += '. Expect delivery soon!';

    await showNotification(
      id: orderId.hashCode + 1000,
      title: title,
      body: body,
      payload: 'order:$orderId',
    );
  }

  // Show general app notifications
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      body: body,
      payload: payload,
    );
  }

  // Request notification permissions (for iOS)
  Future<bool> requestPermissions() async {
    await initialize();
    var isGranted = true;

    await _safeOperation(() async {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final result = await androidImplementation
            .requestNotificationsPermission();
        if (result != null) {
          isGranted = isGranted && result;
        }
      }

      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImplementation != null) {
        final result = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (result != null) {
          isGranted = isGranted && result;
        }
      }
    });

    return isGranted;
  }

  /// Subscribe to FCM topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from FCM topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteFCMToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  // ========================================
  // Restaurant-Specific Notifications
  // ========================================

  /// Subscribe to restaurant notifications
  Future<void> subscribeToRestaurantNotifications(String restaurantId) async {
    await subscribeToTopic('restaurant_$restaurantId');
    await subscribeToTopic('restaurant_${restaurantId}_orders');
  }

  /// Unsubscribe from restaurant notifications
  Future<void> unsubscribeFromRestaurantNotifications(String restaurantId) async {
    await unsubscribeFromTopic('restaurant_$restaurantId');
    await unsubscribeFromTopic('restaurant_${restaurantId}_orders');
  }

  /// Show new order notification for restaurant owners
  Future<void> showNewOrderNotification({
    required String orderId,
    required String customerName,
    required double orderTotal,
    int? itemCount,
  }) async {
    String title = 'New Order Received!';
    String body = 'Order from $customerName';

    if (itemCount != null) {
      body += ' - $itemCount item${itemCount > 1 ? "s" : ""}';
    }

    body += ' - \$${orderTotal.toStringAsFixed(2)}';

    await showNotification(
      id: orderId.hashCode,
      title: title,
      body: body,
      payload: 'restaurant_order:$orderId',
    );
  }

  /// Show order cancellation notification for restaurants
  Future<void> showOrderCancellationNotification({
    required String orderId,
    required String customerName,
    String? reason,
  }) async {
    String title = 'Order Cancelled';
    String body = 'Order from $customerName has been cancelled';

    if (reason != null && reason.isNotEmpty) {
      body += ' - Reason: $reason';
    }

    await showNotification(
      id: orderId.hashCode + 2000,
      title: title,
      body: body,
      payload: 'restaurant_order:$orderId',
    );
  }

  /// Show customer message notification
  Future<void> showCustomerMessageNotification({
    required String orderId,
    required String customerName,
    required String message,
  }) async {
    await showNotification(
      id: orderId.hashCode + 3000,
      title: 'Message from $customerName',
      body: message,
      payload: 'restaurant_order:$orderId',
    );
  }

  /// Show daily summary notification for restaurant
  Future<void> showRestaurantDailySummaryNotification({
    required int totalOrders,
    required double totalRevenue,
    int? completedOrders,
  }) async {
    String title = "Today's Performance";
    String body = '$totalOrders order${totalOrders != 1 ? "s" : ""}, '
        '\$${totalRevenue.toStringAsFixed(2)} revenue';

    if (completedOrders != null) {
      body += ' ($completedOrders completed)';
    }

    await showNotification(
      id: DateTime.now().day.hashCode + 5000,
      title: title,
      body: body,
      payload: 'restaurant_analytics',
    );
  }

  /// Show order ready for pickup notification (internal use)
  Future<void> showOrderReadyReminderNotification({
    required String orderId,
    int delayMinutes = 5,
  }) async {
    await showNotification(
      id: orderId.hashCode + 4000,
      title: 'Order Ready',
      body: 'Order is ready for pickup. Notify driver!',
      payload: 'restaurant_order:$orderId',
      secondsDelay: delayMinutes * 60,
    );
  }

  /// Show low stock alert for restaurant
  Future<void> showLowStockAlert({
    required String itemName,
    String? currentStock,
  }) async {
    String body = 'Low stock alert for $itemName';

    if (currentStock != null) {
      body += ' - Current stock: $currentStock';
    }

    await showNotification(
      id: itemName.hashCode + 6000,
      title: 'Low Stock Alert',
      body: body,
      payload: 'restaurant_inventory',
    );
  }

  /// Show restaurant verification status notification
  Future<void> showRestaurantVerificationNotification({
    required String status,
    String? message,
  }) async {
    String title;
    String body;

    switch (status.toLowerCase()) {
      case 'approved':
        title = 'Restaurant Approved!';
        body = message ?? 'Your restaurant has been verified and approved.';
        break;
      case 'rejected':
        title = 'Verification Rejected';
        body = message ?? 'Your restaurant verification was rejected. Please review and resubmit.';
        break;
      case 'pending':
        title = 'Verification Pending';
        body = message ?? 'Your restaurant is under review.';
        break;
      default:
        title = 'Verification Update';
        body = message ?? 'Your restaurant verification status has been updated.';
    }

    await showNotification(
      id: 7000,
      title: title,
      body: body,
      payload: 'restaurant_verification',
    );
  }

  /// Show staff invitation notification
  Future<void> showStaffInvitationNotification({
    required String restaurantName,
    required String role,
  }) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: 'Restaurant Staff Invitation',
      body: 'You\'ve been invited to join $restaurantName as $role',
      payload: 'restaurant_staff_invitation',
    );
  }
}
