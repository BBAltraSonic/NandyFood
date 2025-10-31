import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/shared/models/order_conversation.dart';
import 'package:food_delivery_app/shared/models/order_message.dart';
import 'package:food_delivery_app/shared/models/order_call.dart';

/// Provider for RealtimeService
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(Supabase.instance.client);
});

/// Service for managing Supabase real-time subscriptions
class RealtimeService {
  RealtimeService(this._supabase);

  final SupabaseClient _supabase;
  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController<Map<String, dynamic>>> _controllers = {};

  /// Subscribe to order updates for a specific order
  Stream<Map<String, dynamic>> subscribeToOrder(String orderId) {
    final channelName = 'order:$orderId';

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    // Create and configure channel
    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            debugPrint('Order update received: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to order: $orderId');

    return controller.stream;
  }

  /// Subscribe to preparation tracking view for a specific restaurant
  Stream<Map<String, dynamic>> subscribeToPreparationTracking(String restaurantId) {
    final channelName = 'preparation_tracking:$restaurantId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'preparation_tracking_view',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) {
            debugPrint('Preparation tracking update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to preparation tracking: $restaurantId');

    return controller.stream;
  }

  /// Subscribe to preparation updates for a specific order
  Stream<Map<String, dynamic>> subscribeToOrderPreparation(String orderId) {
    final channelName = 'order_preparation:$orderId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: orderId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            // Only notify about preparation-related status changes
            if (['confirmed', 'preparing', 'ready_for_pickup'].contains(record['status'])) {
              debugPrint('Order preparation update: $record');
              if (!controller.isClosed) {
                controller.add(record);
              }
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to order preparation: $orderId');

    return controller.stream;
  }

  /// Subscribe to all orders for a user
  Stream<Map<String, dynamic>> subscribeToUserOrders(String userId) {
    final channelName = 'user_orders:$userId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('User order update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to user orders: $userId');

    return controller.stream;
  }

  /// Subscribe to all orders for a restaurant
  Stream<Map<String, dynamic>> subscribeToRestaurantOrders(String restaurantId) {
    final channelName = 'restaurant_orders:$restaurantId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'restaurant_id',
            value: restaurantId,
          ),
          callback: (payload) {
            debugPrint('Restaurant order update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to restaurant orders: $restaurantId');

    return controller.stream;
  }

  /// Subscribe to restaurant availability changes
  Stream<Map<String, dynamic>> subscribeToRestaurant(String restaurantId) {
    final channelName = 'restaurant:$restaurantId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'restaurants',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: restaurantId,
          ),
          callback: (payload) {
            debugPrint('Restaurant update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to restaurant: $restaurantId');

    return controller.stream;
  }

  /// Subscribe to presence channel (for online/offline status)
  Stream<Map<String, dynamic>> subscribeToPresence(String channelId) {
    final channelName = 'presence:$channelId';

    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    final channel = _supabase.channel(channelName);

    channel
        .onPresenceSync((payload) {
          debugPrint('Presence sync: $payload');
          if (!controller.isClosed) {
            controller.add({'type': 'sync', 'data': payload});
          }
        })
        .onPresenceJoin((payload) {
          debugPrint('Presence join: $payload');
          if (!controller.isClosed) {
            controller.add({'type': 'join', 'data': payload});
          }
        })
        .onPresenceLeave((payload) {
          debugPrint('Presence leave: $payload');
          if (!controller.isClosed) {
            controller.add({'type': 'leave', 'data': payload});
          }
        })
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to presence: $channelId');

    return controller.stream;
  }

  /// Subscribe to order conversations for a specific order
  Stream<OrderConversation> subscribeToOrderConversation(String orderId) {
    final channelName = 'conversation:$orderId';

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      // Cast the stream to the expected type
      return _controllers[channelName]!.stream
          .map((data) => OrderConversation.fromJson(data));
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    // Create and configure channel
    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_conversations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            debugPrint('Conversation update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to conversation for order: $orderId');

    return controller.stream
        .map((data) => OrderConversation.fromJson(data));
  }

  /// Subscribe to messages in a specific conversation
  Stream<OrderMessage> subscribeToConversationMessages(String conversationId) {
    final channelName = 'messages:$conversationId';

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream
          .map((data) => OrderMessage.fromJson(data));
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    // Create and configure channel
    final channel = _supabase.channel(channelName);

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
            debugPrint('New message: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
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
            debugPrint('Message update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to messages for conversation: $conversationId');

    return controller.stream
        .map((data) => OrderMessage.fromJson(data));
  }

  /// Subscribe to calls for a specific user
  Stream<OrderCall> subscribeToUserCalls(String userId) {
    final channelName = 'user_calls:$userId';

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream
          .map((data) => OrderCall.fromJson(data));
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    // Create and configure channel
    final channel = _supabase.channel(channelName);

    // Listen for calls where user is either initiator or receiver
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Incoming call: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'order_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('Call update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_calls',
          callback: (payload) {
            final callData = payload.newRecord;
            // Filter for calls initiated by this user
            if (callData['initiator_id'] == userId) {
              debugPrint('Outgoing call: $callData');
              if (!controller.isClosed) {
                controller.add(callData);
              }
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to calls for user: $userId');

    return controller.stream
        .map((data) => OrderCall.fromJson(data));
  }

  /// Subscribe to calls for a specific conversation
  Stream<OrderCall> subscribeToConversationCalls(String conversationId) {
    final channelName = 'conversation_calls:$conversationId';

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream
          .map((data) => OrderCall.fromJson(data));
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    // Create and configure channel
    final channel = _supabase.channel(channelName);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'order_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            debugPrint('Conversation call update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to calls for conversation: $conversationId');

    return controller.stream
        .map((data) => OrderCall.fromJson(data));
  }

  /// Subscribe to communication activity for a user
  Stream<Map<String, dynamic>> subscribeToUserCommunicationActivity(String userId) {
    final channelName = 'user_communication:$userId';

    // Return existing stream if already subscribed
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream;
    }

    // Create new stream controller
    final controller = StreamController<Map<String, dynamic>>.broadcast(
      onCancel: () => _unsubscribe(channelName),
    );
    _controllers[channelName] = controller;

    // Create and configure channel
    final channel = _supabase.channel(channelName);

    // Listen to conversations where user is participant
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'order_conversations',
          callback: (payload) {
            final conversationData = payload.newRecord;
            // Filter for conversations where this user is customer or restaurant staff
            if (conversationData['customer_id'] == userId || conversationData['restaurant_id'] == userId) {
              debugPrint('Conversation activity: $conversationData');
              if (!controller.isClosed) {
                controller.add({
                  'type': 'conversation_update',
                  'data': conversationData,
                });
              }
            }
          },
        )
        // Listen to new messages in conversations user participates in
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_messages',
          callback: (payload) {
            // Filter client-side for conversations user participates in
            final messageData = payload.newRecord;
            final conversationId = messageData['conversation_id'] as String?;

            if (conversationId != null) {
              _checkConversationParticipation(conversationId, userId).then((isParticipant) {
                if (isParticipant && !controller.isClosed) {
                  controller.add({
                    'type': 'new_message',
                    'data': messageData,
                  });
                }
              });
            }
          },
        )
        // Listen to calls where user is participant
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'order_calls',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint('User call activity: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add({
                'type': 'incoming_call',
                'data': payload.newRecord,
              });
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to communication activity for user: $userId');

    return controller.stream;
  }

  /// Check if user participates in a conversation
  Future<bool> _checkConversationParticipation(String conversationId, String userId) async {
    try {
      final result = await _supabase
          .from('order_conversations')
          .select('customer_id, restaurant_id')
          .eq('id', conversationId)
          .maybeSingle();

      if (result == null) return false;

      return result['customer_id'] == userId || result['restaurant_id'] == userId;
    } catch (e) {
      debugPrint('Error checking conversation participation: $e');
      return false;
    }
  }

  /// Broadcast message to a channel
  Future<void> broadcast({
    required String channelId,
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final channel = _channels['broadcast:$channelId'] ??
          _supabase.channel('broadcast:$channelId');

      await channel.sendBroadcastMessage(
        event: event,
        payload: payload,
      );

      debugPrint('Broadcast sent to $channelId: $event');
    } catch (e) {
      debugPrint('Error broadcasting message: $e');
    }
  }

  /// Unsubscribe from a channel
  Future<void> _unsubscribe(String channelName) async {
    try {
      final channel = _channels[channelName];
      if (channel != null) {
        await channel.unsubscribe();
        _channels.remove(channelName);
        debugPrint('Unsubscribed from: $channelName');
      }

      final controller = _controllers[channelName];
      if (controller != null) {
        await controller.close();
        _controllers.remove(channelName);
      }
    } catch (e) {
      debugPrint('Error unsubscribing from $channelName: $e');
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    final channelNames = _channels.keys.toList();
    for (final channelName in channelNames) {
      await _unsubscribe(channelName);
    }
    debugPrint('Unsubscribed from all channels');
  }

  /// Check channel status
  String? getChannelStatus(String channelName) {
    // RealtimeChannel doesn't expose status in current version
    // Return simple presence indicator instead
    return _channels.containsKey(channelName) ? 'subscribed' : null;
  }

  /// Get all active channels
  List<String> getActiveChannels() {
    return _channels.keys.toList();
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await unsubscribeAll();
  }
}
