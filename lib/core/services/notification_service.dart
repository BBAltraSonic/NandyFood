import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/order_message.dart';
import 'package:food_delivery_app/shared/models/order_call.dart';
import 'package:food_delivery_app/shared/models/support_ticket.dart';

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
    int? estimatedMinutes,
  }) async {
    String title;
    String body;

    switch (status.toLowerCase()) {
      case 'confirmed':
        title = 'Order Confirmed!';
        body = 'Your order from $restaurantName has been confirmed and will start preparing soon.';
        break;
      case 'preparing':
        title = 'Order Preparing';
        if (estimatedMinutes != null && estimatedMinutes > 0) {
          body = 'Your order from $restaurantName is being prepared. Estimated time: $estimatedMinutes minutes.';
        } else {
          body = 'Your order from $restaurantName is being prepared.';
        }
        break;
      case 'ready_for_pickup':
        title = 'Order Ready for Pickup! 🎉';
        body = 'Your order from $restaurantName is ready! You can pick it up now.';
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

  // Show preparation progress notifications
  Future<void> showPreparationProgressNotification({
    required String orderId,
    required String restaurantName,
    required int remainingMinutes,
    int totalMinutes = 15,
  }) async {
    final progress = ((totalMinutes - remainingMinutes) / totalMinutes * 100).round();

    await showProgressNotification(
      id: orderId.hashCode + 2000,
      title: 'Order Preparing',
      body: '$remainingMinutes minutes remaining',
      progress: progress,
      maxProgress: 100,
      payload: RoutePayloads.order(orderId),
    );
  }

  // Show pickup ready notification with actions
  Future<void> showPickupReadyNotification({
    required String orderId,
    required String restaurantName,
    required String pickupAddress,
  }) async {
    await showNotificationWithActions(
      id: orderId.hashCode + 3000,
      title: 'Order Ready for Pickup! 🎉',
      body: 'Your order from $restaurantName is ready at $pickupAddress',
      payload: RoutePayloads.order(orderId),
    );
  }

  // Show preparation time estimate updates
  Future<void> showPreparationTimeUpdate({
    required String orderId,
    required String restaurantName,
    required int newEstimatedMinutes,
  }) async {
    await showNotification(
      id: orderId.hashCode + 4000,
      title: 'Preparation Time Update',
      body: 'Your order from $restaurantName will be ready in approximately $newEstimatedMinutes minutes',
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

  // Show support ticket notifications
  Future<void> showSupportTicketCreated({
    required String ticketId,
    required String subject,
  }) async {
    await showNotification(
      id: ticketId.hashCode + 5000,
      title: 'Support Ticket Created',
      body: 'Your support ticket "$subject" has been created successfully',
      payload: '/support/ticket/$ticketId',
    );
  }

  Future<void> showSupportTicketStatusUpdate({
    required String ticketId,
    required String subject,
    required SupportTicketStatus newStatus,
  }) async {
    String statusMessage;
    switch (newStatus) {
      case SupportTicketStatus.inProgress:
        statusMessage = 'is now being reviewed by our support team';
        break;
      case SupportTicketStatus.waitingOnCustomer:
        statusMessage = 'requires your response';
        break;
      case SupportTicketStatus.resolved:
        statusMessage = 'has been resolved';
        break;
      case SupportTicketStatus.closed:
        statusMessage = 'has been closed';
        break;
      default:
        statusMessage = 'status has been updated';
    }

    await showNotification(
      id: ticketId.hashCode + 6000,
      title: 'Support Ticket Update',
      body: 'Your ticket "$subject" $statusMessage',
      payload: '/support/ticket/$ticketId',
    );
  }

  Future<void> showSupportMessageReceived({
    required String ticketId,
    required String subject,
    required String message,
    bool isFromSupport = true,
  }) async {
    final sender = isFromSupport ? 'Support Team' : 'You';
    await showNotification(
      id: ticketId.hashCode + 7000,
      title: 'New Support Message',
      body: '$sender: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      payload: '/support/ticket/$ticketId',
    );
  }

  Future<void> showSupportTicketAssigned({
    required String ticketId,
    required String subject,
    required String assignedToName,
  }) async {
    await showNotification(
      id: ticketId.hashCode + 8000,
      title: 'Support Ticket Assigned',
      body: 'Your ticket "$subject" has been assigned to $assignedToName',
      payload: '/support/ticket/$ticketId',
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
          'track_preparation',
          'Track Preparation',
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

  // Show new message notification
  Future<void> showNewMessageNotification({
    required String orderId,
    required String senderName,
    required OrderMessage message,
    String? conversationId,
  }) async {
    String title;
    String body;
    String notificationType;

    switch (message.messageType) {
      case MessageType.text:
        title = 'New message from $senderName';
        body = message.content.length > 50
            ? '${message.content.substring(0, 50)}...'
            : message.content;
        notificationType = 'text_message';
        break;
      case MessageType.image:
        title = 'New image from $senderName';
        body = '📷 Image shared';
        notificationType = 'image_message';
        break;
      case MessageType.voice:
        title = 'New voice message from $senderName';
        body = '🎙️ Voice message (${message.getFormattedVoiceDuration()})';
        notificationType = 'voice_message';
        break;
      case MessageType.file:
        title = 'New file from $senderName';
        body = '📎 ${message.fileName ?? 'File shared'}';
        notificationType = 'file_message';
        break;
      case MessageType.callStarted:
        title = 'Call started';
        body = '📞 Call with $senderName has started';
        notificationType = 'call_started';
        break;
      case MessageType.callEnded:
        title = 'Call ended';
        body = '📞 Call with $senderName has ended';
        notificationType = 'call_ended';
        break;
      default:
        title = 'New message';
        body = message.getDisplayText();
        notificationType = 'message';
        break;
    }

    await showNotification(
      id: 'message_${message.id}'.hashCode,
      title: title,
      body: body,
      payload: 'order_chat://$orderId${conversationId != null ? '?conversation=$conversationId' : ''}',
    );

    AppLogger.info('Message notification sent: $title');
  }

  // Show incoming call notification
  Future<void> showIncomingCallNotification({
    required String orderId,
    required String callerName,
    required OrderCall call,
    String? conversationId,
  }) async {
    final title = 'Incoming ${call.isVideoCall ? 'Video' : 'Voice'} Call';
    final body = '${call.isVideoCall ? '📹' : '📞'} $callerName is calling...';

    // Use high priority notification for calls
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Incoming call',
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
    );

    DarwinNotificationDetails iOSPlatformChannelSpecifics =
        const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'INCOMING_CALL',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _notifications.show(
      'call_${call.id}'.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: 'incoming_call://$orderId?callId=${call.id}${conversationId != null ? '&conversation=$conversationId' : ''}',
    );

    AppLogger.info('Incoming call notification sent: $title');
  }

  // Show missed call notification
  Future<void> showMissedCallNotification({
    required String orderId,
    required String callerName,
    required OrderCall call,
    String? conversationId,
  }) async {
    final title = 'Missed ${call.isVideoCall ? 'Video' : 'Voice'} Call';
    final body = '${call.isVideoCall ? '📹' : '📞'} You missed a call from $callerName';

    await showNotification(
      id: 'missed_call_${call.id}'.hashCode,
      title: title,
      body: body,
      payload: 'missed_call://$orderId?callId=${call.id}${conversationId != null ? '&conversation=$conversationId' : ''}',
    );

    AppLogger.info('Missed call notification sent: $title');
  }

  // Show call ended notification
  Future<void> showCallEndedNotification({
    required String orderId,
    required String callerName,
    required OrderCall call,
    String? conversationId,
  }) async {
    final title = 'Call Ended';
    final duration = call.getFormattedDuration();
    final body = '${call.isVideoCall ? '📹' : '📞'} Call with $callerName ended ($duration)';

    await showNotification(
      id: 'call_ended_${call.id}'.hashCode,
      title: title,
      body: body,
      payload: 'order_chat://$orderId${conversationId != null ? '?conversation=$conversationId' : ''}',
    );

    AppLogger.info('Call ended notification sent: $title');
  }

  // Show unread messages summary notification
  Future<void> showUnreadMessagesSummaryNotification({
    required String orderId,
    required String restaurantName,
    required int unreadCount,
    String? conversationId,
  }) async {
    if (unreadCount <= 0) return;

    final title = '$unreadCount unread message${unreadCount > 1 ? 's' : ''}';
    final body = 'From $restaurantName - Tap to open chat';

    await showNotification(
      id: 'unread_summary_$orderId'.hashCode,
      title: title,
      body: body,
      payload: 'order_chat://$orderId${conversationId != null ? '?conversation=$conversationId' : ''}',
    );

    AppLogger.info('Unread messages summary notification sent: $title');
  }

  // Cancel call notification
  Future<void> cancelCallNotification(String callId) async {
    await _notifications.cancel('call_$callId'.hashCode);
    AppLogger.info('Call notification cancelled: $callId');
  }

  // Cancel message notification
  Future<void> cancelMessageNotification(String messageId) async {
    await _notifications.cancel('message_$messageId'.hashCode);
    AppLogger.info('Message notification cancelled: $messageId');
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

      // Preparation updates channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'preparation_updates',
          'Preparation Updates',
          description: 'Real-time order preparation updates',
          importance: Importance.high,
          enableVibration: true,
        ),
      );

      // Chat messages channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          description: 'Messages from restaurant staff and customers',
          importance: Importance.high,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Incoming calls channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'incoming_calls',
          'Incoming Calls',
          description: 'Incoming voice and video calls',
          importance: Importance.max,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Communication updates channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          'communication_updates',
          'Communication Updates',
          description: 'Call status and communication notifications',
          importance: Importance.defaultImportance,
          enableVibration: false,
        ),
      );
    }
  }

  /// Dispose notification service and clean up resources
  Future<void> dispose() async {
    try {
      // Cancel all pending notifications
      await cancelAllNotifications();

      // Re-initialize with null settings to clean up resources
      await _notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings(''),
          iOS: DarwinInitializationSettings(),
        ),
      );

      AppLogger.info('NotificationService disposed successfully');
    } catch (e) {
      AppLogger.error('Failed to dispose NotificationService: $e');
    }
  }
}