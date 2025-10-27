import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';

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
}