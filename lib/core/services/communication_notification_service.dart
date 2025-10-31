import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:food_delivery_app/shared/models/order_conversation.dart';
import 'package:food_delivery_app/shared/models/order_message.dart';
import 'package:food_delivery_app/shared/models/order_call.dart';
import 'package:food_delivery_app/core/services/notification_service.dart';
import 'package:food_delivery_app/core/services/order_chat_service.dart';
import 'package:food_delivery_app/core/services/order_calling_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Provider for CommunicationNotificationService
final communicationNotificationServiceProvider = Provider<CommunicationNotificationService>((ref) {
  final notificationService = NotificationService();
  final chatService = ref.read(orderChatServiceProvider);
  final callingService = ref.read(orderCallingServiceProvider);
  final supabase = Supabase.instance.client;

  return CommunicationNotificationService(
    notificationService: notificationService,
    chatService: chatService,
    callingService: callingService,
    supabase: supabase,
  );
});

/// Service for handling communication-specific notifications
class CommunicationNotificationService {
  CommunicationNotificationService({
    required this.notificationService,
    required this.chatService,
    required this.callingService,
    required this.supabase,
  });

  final NotificationService notificationService;
  final OrderChatService chatService;
  final OrderCallingService callingService;
  final SupabaseClient supabase;

  final Map<String, Timer> _notificationTimers = {};
  final Map<String, bool> _hasNotifiedUnread = {};

  /// Initialize communication notifications
  Future<void> initialize() async {
    try {
      // Initialize notification channels
      await notificationService.createNotificationChannels();

      // Set up message event listeners
      await _setupMessageListeners();

      // Set up call event listeners
      await _setupCallListeners();

      AppLogger.info('Communication notifications initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize communication notifications: $e');
    }
  }

  /// Set up message event listeners
  Future<void> _setupMessageListeners() async {
    // Listen for new messages in conversations the user is part of
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) return;

    // Subscribe to new messages
    final channel = supabase.channel('communication_messages:${currentUser.id}');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_messages',
          callback: (payload) {
            _handleNewMessage(payload.newRecord);
          },
        )
        .subscribe();

    AppLogger.info('Message listeners set up for user: ${currentUser.id}');
  }

  /// Set up call event listeners
  Future<void> _setupCallListeners() async {
    // Listen to calling service events
    callingService.callEvents.listen((event) {
      _handleCallEvent(event);
    });

    AppLogger.info('Call listeners set up');
  }

  /// Handle new message event
  void _handleNewMessage(Map<String, dynamic> messageData) async {
    try {
      final message = OrderMessage.fromJson(messageData);
      final currentUser = supabase.auth.currentUser;

      // Don't notify for own messages
      if (message.senderId == currentUser?.id) return;

      // Don't notify if user is already in the chat
      // This would require tracking active UI state - for now we'll always notify

      // Get conversation details for context
      final conversation = await _getConversation(message.conversationId);
      if (conversation == null) return;

      // Get sender name
      final senderName = message.senderName ?? 'Unknown';

      // Send notification
      await notificationService.showNewMessageNotification(
        orderId: message.orderId,
        senderName: senderName,
        message: message,
        conversationId: message.conversationId,
      );

      // Schedule unread summary notification if applicable
      _scheduleUnreadSummary(conversation);

      AppLogger.info('New message notification sent: ${message.id}');
    } catch (e) {
      AppLogger.error('Error handling new message notification: $e');
    }
  }

  /// Handle call event
  void _handleCallEvent(dynamic event) async {
    try {
      // This would come from the OrderCallingService
      // For now, we'll handle the basic call events

      if (event is! Map<String, dynamic>) return;

      final eventType = event['type'] as String?;
      final callData = event['call'] as Map<String, dynamic>?;

      if (callData == null) return;

      final call = OrderCall.fromJson(callData);
      final currentUser = supabase.auth.currentUser;

      // Don't notify for calls initiated by current user
      if (call.initiatorId == currentUser?.id && eventType == 'outgoing') return;

      // Get conversation details
      final conversation = await _getConversation(call.conversationId);
      if (conversation == null) return;

      // Get caller/receiver name
      final callerName = call.isFromCurrentUser
          ? call.receiverName ?? 'Unknown'
          : call.initiatorName ?? 'Unknown';

      switch (eventType) {
        case 'incoming':
          await notificationService.showIncomingCallNotification(
            orderId: call.orderId,
            callerName: callerName,
            call: call,
            conversationId: call.conversationId,
          );
          break;

        case 'missed':
          // Cancel incoming call notification
          await notificationService.cancelCallNotification(call.id);

          await notificationService.showMissedCallNotification(
            orderId: call.orderId,
            callerName: callerName,
            call: call,
            conversationId: call.conversationId,
          );
          break;

        case 'connected':
          // Cancel incoming call notification when call is answered
          await notificationService.cancelCallNotification(call.id);
          break;

        case 'ended':
          // Cancel any active call notifications
          await notificationService.cancelCallNotification(call.id);

          await notificationService.showCallEndedNotification(
            orderId: call.orderId,
            callerName: callerName,
            call: call,
            conversationId: call.conversationId,
          );
          break;

        default:
          break;
      }

      AppLogger.info('Call notification sent: $eventType for call ${call.id}');
    } catch (e) {
      AppLogger.error('Error handling call notification: $e');
    }
  }

  /// Get conversation details
  Future<OrderConversation?> _getConversation(String conversationId) async {
    try {
      final conversationData = await supabase
          .from('order_conversations')
          .select('*')
          .eq('id', conversationId)
          .maybeSingle();

      return conversationData != null ? OrderConversation.fromJson(conversationData) : null;
    } catch (e) {
      AppLogger.error('Failed to get conversation: $e');
      return null;
    }
  }

  /// Schedule unread messages summary notification
  void _scheduleUnreadSummary(OrderConversation conversation) {
    final conversationKey = conversation.id;

    // Cancel existing timer for this conversation
    _notificationTimers[conversationKey]?.cancel();

    // Schedule new timer to show summary after 5 minutes
    _notificationTimers[conversationKey] = Timer(const Duration(minutes: 5), () async {
      try {
        final unreadCount = await chatService.getUnreadCount(conversation.id);

        if (unreadCount > 0 && !_hasNotifiedUnread[conversationKey]) {
          await notificationService.showUnreadMessagesSummaryNotification(
            orderId: conversation.orderId,
            restaurantName: conversation.restaurantName ?? 'Restaurant',
            unreadCount: unreadCount,
            conversationId: conversation.id,
          );

          _hasNotifiedUnread[conversationKey] = true;

          // Reset flag after user interaction (would need UI integration)
          Timer(const Duration(minutes: 30), () {
            _hasNotifiedUnread[conversationKey] = false;
          });
        }
      } catch (e) {
        AppLogger.error('Error sending unread summary: $e');
      }
    });
  }

  /// Cancel unread summary for a conversation
  void cancelUnreadSummary(String conversationId) {
    _notificationTimers[conversationId]?.cancel();
    _notificationTimers.remove(conversationId);
    _hasNotifiedUnread[conversationId] = false;
  }

  /// Send notification for order status change with communication context
  Future<void> sendOrderStatusNotification({
    required String orderId,
    required String status,
    required String restaurantName,
    bool enableChatReminder = false,
    int? estimatedMinutes,
  }) async {
    // Send standard order status notification
    await notificationService.showOrderStatusNotification(
      orderId: orderId,
      status: status,
      restaurantName: restaurantName,
      estimatedMinutes: estimatedMinutes,
    );

    // If chat reminder is enabled and status is preparing, remind user they can chat
    if (enableChatReminder && status.toLowerCase() == 'preparing') {
      // Schedule a gentle reminder after 2 minutes
      Timer(const Duration(minutes: 2), () async {
        await notificationService.showNotification(
          id: 'chat_reminder_$orderId'.hashCode,
          title: 'Need to chat about your order?',
          body: 'You can message $restaurantName directly from your order tracking screen.',
          payload: 'order_chat://$orderId',
        );
      });
    }
  }

  /// Dispose the service
  void dispose() {
    // Cancel all timers
    for (final timer in _notificationTimers.values) {
      timer.cancel();
    }
    _notificationTimers.clear();
    _hasNotifiedUnread.clear();
  }
}