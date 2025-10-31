import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:food_delivery_app/shared/models/order_conversation.dart';
import 'package:food_delivery_app/shared/models/order_message.dart';
import 'package:food_delivery_app/shared/models/order_call.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/core/services/storage_service.dart';

/// Provider for StorageService
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for OrderChatService
final orderChatServiceProvider = Provider<OrderChatService>((ref) {
  final supabase = Supabase.instance.client;
  final storageService = ref.watch(storageServiceProvider);
  return OrderChatService(supabase, storageService);
});

/// Service for managing order-specific real-time communication
class OrderChatService {
  OrderChatService(this._supabase, this._storageService);

  final SupabaseClient _supabase;
  final StorageService _storageService;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};
  final Map<String, StreamController<List<OrderMessage>>> _messageControllers = {};
  final Uuid _uuid = const Uuid();

  /// Initialize chat service for current user
  Future<void> initialize() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.info('OrderChatService initialized for user: ${currentUser.id}');
    } catch (e) {
      AppLogger.error('Failed to initialize OrderChatService: $e');
      rethrow;
    }
  }

  /// Get or create conversation for an order
  Future<OrderConversation> getOrCreateConversation(String orderId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if conversation already exists
      final existingConversation = await _supabase
          .from('order_conversations')
          .select('*')
          .eq('order_id', orderId)
          .maybeSingle();

      if (existingConversation != null) {
        return OrderConversation.fromJson(existingConversation);
      }

      // Get order details to determine participants
      final orderData = await _supabase
          .from('orders')
          .select('''
            id,
            customer_id,
            restaurants!inner(
              id,
              owner_id,
              name
            )
          ''')
          .eq('id', orderId)
          .single();

      // Create new conversation
      final conversationData = {
        'id': _uuid.v4(),
        'order_id': orderId,
        'restaurant_id': orderData['restaurants']['id'],
        'customer_id': orderData['customer_id'],
        'title': 'Order #$orderId',
        'status': 'active',
        'metadata': {
          'created_by': currentUser.id,
          'created_at': DateTime.now().toIso8601String(),
        },
      };

      final newConversation = await _supabase
          .from('order_conversations')
          .insert(conversationData)
          .select('''
            *,
            restaurants!inner(
              name
            ),
            user_profiles!customer_id(
              full_name
            )
          ''')
          .single();

      return OrderConversation.fromJson(newConversation);
    } catch (e) {
      AppLogger.error('Failed to get or create conversation for order $orderId: $e');
      rethrow;
    }
  }

  /// Subscribe to messages in a conversation
  Stream<List<OrderMessage>> subscribeToMessages(String conversationId) {
    final streamKey = 'messages:$conversationId';

    // Return existing stream if already subscribed
    if (_messageControllers.containsKey(streamKey)) {
      return _messageControllers[streamKey]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<List<OrderMessage>>.broadcast(
      onCancel: () => _unsubscribeFromMessages(streamKey),
    );
    _messageControllers[streamKey] = controller;

    // Create and configure channel
    final channel = _supabase.channel(streamKey);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            _handleNewMessage(conversationId, payload.newRecord);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'order_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            _handleMessageUpdate(conversationId, payload.newRecord);
          },
        )
        .subscribe();

    _channels[streamKey] = channel;

    // Load initial messages
    _loadInitialMessages(conversationId, controller);

    return controller.stream;
  }

  /// Load initial messages for a conversation
  Future<void> _loadInitialMessages(String conversationId, StreamController<List<OrderMessage>> controller) async {
    try {
      final messagesData = await _supabase
          .from('order_messages')
          .select('''
            *,
            user_profiles!sender_id(
              full_name,
              avatar_url
            )
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      final messages = messagesData.map((data) {
        // Add isFromMe field
        final currentUser = _supabase.auth.currentUser;
        data['is_from_me'] = data['sender_id'] == currentUser?.id;

        // Add sender info from joined user profile
        if (data['user_profiles'] != null) {
          data['sender_name'] = data['user_profiles']['full_name'];
          data['sender_avatar'] = data['user_profiles']['avatar_url'];
        }

        return OrderMessage.fromJson(data);
      }).toList();

      if (!controller.isClosed) {
        controller.add(messages);
      }
    } catch (e) {
      AppLogger.error('Failed to load initial messages: $e');
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  /// Handle new message from realtime subscription
  void _handleNewMessage(String conversationId, Map<String, dynamic> messageData) {
    final streamKey = 'messages:$conversationId';
    final controller = _messageControllers[streamKey];

    if (controller != null && !controller.isClosed) {
      // Add sender info and isFromMe field
      final currentUser = _supabase.auth.currentUser;
      messageData['is_from_me'] = messageData['sender_id'] == currentUser?.id;

      final message = OrderMessage.fromJson(messageData);

      // Get current messages list and add new message
      // Note: In a real implementation, you'd want to maintain a local cache
      // For now, we'll trigger a refresh
      _loadInitialMessages(conversationId, controller);
    }
  }

  /// Handle message update from realtime subscription
  void _handleMessageUpdate(String conversationId, Map<String, dynamic> messageData) {
    final streamKey = 'messages:$conversationId';
    final controller = _messageControllers[streamKey];

    if (controller != null && !controller.isClosed) {
      // Refresh messages to get updated state
      _loadInitialMessages(conversationId, controller);
    }
  }

  /// Send a text message
  Future<OrderMessage> sendTextMessage(String conversationId, String content) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final messageData = {
        'id': _uuid.v4(),
        'conversation_id': conversationId,
        'order_id': await _getOrderIdFromConversation(conversationId),
        'sender_id': currentUser.id,
        'content': content.trim(),
        'message_type': 'text',
        'status': 'sent',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'metadata': <String, dynamic>{},
      };

      final newMessage = await _supabase
          .from('order_messages')
          .insert(messageData)
          .select('''
            *,
            user_profiles!sender_id(
              full_name,
              avatar_url
            )
          ''')
          .single();

      // Update conversation last activity
      await _updateConversationActivity(conversationId);

      return OrderMessage.fromJson(newMessage);
    } catch (e) {
      AppLogger.error('Failed to send text message: $e');
      rethrow;
    }
  }

  /// Send an image message
  Future<OrderMessage> sendImageMessage(String conversationId, File imageFile) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload image to storage
      final fileName = '${_uuid.v4()}.jpg';
      final filePath = 'chat_images/$conversationId';
      final fileUrl = await _storageService.uploadFile(
        bucketName: 'chat-files',
        filePath: filePath,
        fileName: fileName,
        fileData: imageFile,
      );

      final messageData = {
        'id': _uuid.v4(),
        'conversation_id': conversationId,
        'order_id': await _getOrderIdFromConversation(conversationId),
        'sender_id': currentUser.id,
        'content': '📷 Image',
        'message_type': 'image',
        'status': 'sent',
        'file_url': fileUrl,
        'file_type': 'image',
        'file_size': await imageFile.length(),
        'file_name': imageFile.path.split('/').last,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'metadata': <String, dynamic>{
          'original_name': imageFile.path.split('/').last,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      };

      final newMessage = await _supabase
          .from('order_messages')
          .insert(messageData)
          .select('''
            *,
            user_profiles!sender_id(
              full_name,
              avatar_url
            )
          ''')
          .single();

      // Update conversation last activity
      await _updateConversationActivity(conversationId);

      return OrderMessage.fromJson(newMessage);
    } catch (e) {
      AppLogger.error('Failed to send image message: $e');
      rethrow;
    }
  }

  /// Send a voice message
  Future<OrderMessage> sendVoiceMessage(
    String conversationId,
    File voiceFile,
    int duration,
    List<double> waveform,
  ) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Upload voice file to storage
      final fileName = '${_uuid.v4()}.m4a';
      final filePath = 'voice_messages/$conversationId';
      final fileUrl = await _storageService.uploadFile(
        bucketName: 'chat-files',
        filePath: filePath,
        fileName: fileName,
        fileData: voiceFile,
      );

      final messageData = {
        'id': _uuid.v4(),
        'conversation_id': conversationId,
        'order_id': await _getOrderIdFromConversation(conversationId),
        'sender_id': currentUser.id,
        'content': '🎙️ Voice message',
        'message_type': 'voice',
        'status': 'sent',
        'file_url': fileUrl,
        'file_type': 'audio/m4a',
        'file_size': await voiceFile.length(),
        'file_name': voiceFile.path.split('/').last,
        'voice_duration': duration,
        'voice_waveform': waveform,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'metadata': {
          'original_name': voiceFile.path.split('/').last,
          'duration': duration,
          'waveform_points': waveform.length,
          'uploaded_at': DateTime.now().toIso8601String(),
        },
      };

      final newMessage = await _supabase
          .from('order_messages')
          .insert(messageData)
          .select('''
            *,
            user_profiles!sender_id(
              full_name,
              avatar_url
            )
          ''')
          .single();

      // Update conversation last activity
      await _updateConversationActivity(conversationId);

      return OrderMessage.fromJson(newMessage);
    } catch (e) {
      AppLogger.error('Failed to send voice message: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId, List<String> messageIds) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabase
          .from('order_messages')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
  .filter('id', 'in', messageIds)
          .neq('sender_id', currentUser.id); // Only mark messages from others as read
    } catch (e) {
      AppLogger.error('Failed to mark messages as read: $e');
      rethrow;
    }
  }

  /// Get unread message count for a conversation
  Future<int> getUnreadCount(String conversationId) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return 0;
      }

      final count = await _supabase
          .from('order_messages')
          .count()
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUser.id)
          .filter('read_at', 'is', null);

      return count;
    } catch (e) {
      AppLogger.error('Failed to get unread count: $e');
      return 0;
    }
  }

  /// Update conversation activity
  Future<void> _updateConversationActivity(String conversationId) async {
    try {
      await _supabase
          .from('order_conversations')
          .update({
            'last_message_at': DateTime.now().toIso8601String(),
            'last_activity_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);
    } catch (e) {
      AppLogger.error('Failed to update conversation activity: $e');
    }
  }

  /// Get order ID from conversation
  Future<String> _getOrderIdFromConversation(String conversationId) async {
    final conversation = await _supabase
        .from('order_conversations')
        .select('order_id')
        .eq('id', conversationId)
        .single();

    return conversation['order_id'];
  }

  /// Unsubscribe from messages
  void _unsubscribeFromMessages(String streamKey) {
    final channel = _channels[streamKey];
    if (channel != null) {
      _supabase.removeChannel(channel);
      _channels.remove(streamKey);
    }

    final controller = _messageControllers[streamKey];
    if (controller != null && !controller.isClosed) {
      controller.close();
      _messageControllers.remove(streamKey);
    }
  }

  /// Unsubscribe from all subscriptions
  void unsubscribeAll() {
    for (final channel in _channels.values) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();

    for (final controller in _messageControllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _messageControllers.clear();

    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }

  /// Dispose the service
  void dispose() {
    unsubscribeAll();
  }
}