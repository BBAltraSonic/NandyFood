import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize({void Function(String? payload)? onNotificationTap}) async {
    // Initialize timezone data
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        onNotificationTap?.call(payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  // Background tap handler (must be a top-level or static function)
  static void notificationTapBackground(NotificationResponse response) {
    // For now we simply log or no-op; routing is handled when app resumes via onNotificationTap
    // You can extend this to persist payload for retrieval on cold start
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

    if (secondsDelay != null && secondsDelay > 0) {
      // Schedule notification for later
      await _notifications.zonedSchedule(
        id,
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
    } else {
      // Show notification immediately
      await _notifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
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
        body = 'Your order from $restaurantName has been delivered. Enjoy your meal!';
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
      payload: RoutePayloads.order(orderId),
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
      payload: actionUrl ?? RoutePaths.promotions,
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
      payload: RoutePayloads.order(orderId),
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
    var isGranted = true;

    // Android permission request is handled at the OS/app level; the plugin
    // may not expose a request method on all versions. Skip explicit request.

    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
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

    return isGranted;
  }

  // Enhanced notification features for Phase 8.3

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      AppLogger.info('Notification $id cancelled successfully');
    } catch (e) {
      AppLogger.error('Failed to cancel notification $id: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      AppLogger.info('All notifications cancelled successfully');
    } catch (e) {
      AppLogger.error('Failed to cancel all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      AppLogger.error('Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Show notification with action buttons (Android only)
  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nandyfood_channel',
      'NandyFood Notifications',
      channelDescription: 'Notifications for NandyFood app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view_order',
          'View Order',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'track_delivery',
          'Track Delivery',
          showsUserInterface: true,
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Show rich notification with big picture
  Future<void> showRichNotification({
    required int id,
    required String title,
    required String body,
    String? largeIcon,
    String? bigPicture,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nandyfood_channel',
      'NandyFood Notifications',
      channelDescription: 'Notifications for NandyFood app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      largeIcon: largeIcon != null ? FilePathAndroidBitmap(largeIcon) : null,
      styleInformation: bigPicture != null
          ? BigPictureStyleInformation(
              FilePathAndroidBitmap(bigPicture),
              contentTitle: title,
              htmlFormatContentTitle: true,
              summaryText: body,
              htmlFormatSummaryText: true,
            )
          : null,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Show notification with progress indicator
  Future<void> showProgressNotification({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    bool showProgress = true,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'nandyfood_channel',
      'NandyFood Notifications',
      channelDescription: 'Notifications for NandyFood app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      onlyAlertOnce: true,
      showProgress: showProgress,
      maxProgress: maxProgress,
      progress: progress,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notifications.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  /// Verify deep link payload format
  bool isValidDeepLinkPayload(String? payload) {
    if (payload == null || payload.isEmpty) return false;

    // Order tracking payload: "order:<order_id>"
    if (payload.startsWith('order:') && payload.length > 6) {
      return RegExp(r'^order:[a-zA-Z0-9_-]+$').hasMatch(payload);
    }

    // Restaurant payload: "restaurant:<restaurant_id>"
    if (payload.startsWith('restaurant:') && payload.length > 11) {
      return RegExp(r'^restaurant:[a-zA-Z0-9_-]+$').hasMatch(payload);
    }

    // Promotions payload: "promotion:<promotion_id>"
    if (payload.startsWith('promotion:') && payload.length > 10) {
      return RegExp(r'^promotion:[a-zA-Z0-9_-]+$').hasMatch(payload);
    }

    // Profile payload: "profile"
    if (payload == 'profile') return true;

    // Orders list payload: "orders"
    if (payload == 'orders') return true;

    return false;
  }

  /// Extract route information from payload
  Map<String, String>? extractRouteFromPayload(String? payload) {
    if (!isValidDeepLinkPayload(payload)) return null;

    if (payload!.startsWith('order:')) {
      final orderId = payload.substring(6);
      return {
        'route': '/order/track/$orderId',
        'id': orderId,
        'type': 'order',
      };
    }

    if (payload.startsWith('restaurant:')) {
      final restaurantId = payload.substring(11);
      return {
        'route': '/restaurant/$restaurantId',
        'id': restaurantId,
        'type': 'restaurant',
      };
    }

    if (payload.startsWith('promotion:')) {
      final promotionId = payload.substring(10);
      return {
        'route': '/promotion/$promotionId',
        'id': promotionId,
        'type': 'promotion',
      };
    }

    if (payload == 'profile') {
      return {
        'route': '/profile',
        'type': 'profile',
      };
    }

    if (payload == 'orders') {
      return {
        'route': '/orders/history',
        'type': 'orders',
      };
    }

    return null;
  }

  /// Get notification channel information
  Future<List<AndroidNotificationChannel>> getNotificationChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final channels = await androidImplementation.getNotificationChannels();
      return channels ?? [];
    }

    return [];
  }

  /// Create notification channels for different notification types
  Future<void> createNotificationChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Order updates channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'order_updates',
          'Order Updates',
          description: 'Notifications about your order status',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      // Promotions channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'promotions',
          'Promotions & Offers',
          description: 'Special offers and promotions',
          importance: Importance.low,
          enableVibration: false,
        ),
      );

      // Delivery updates channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'delivery_updates',
          'Delivery Updates',
          description: 'Real-time delivery tracking updates',
          importance: Importance.high,
          enableVibration: true,
        ),
      );
    }
  }
}