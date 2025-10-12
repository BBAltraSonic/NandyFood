import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// Subscribe to delivery updates for a specific order
  Stream<Map<String, dynamic>> subscribeToDelivery(String orderId) {
    final channelName = 'delivery:$orderId';

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
          table: 'deliveries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'order_id',
            value: orderId,
          ),
          callback: (payload) {
            debugPrint('Delivery update received: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to delivery: $orderId');

    return controller.stream;
  }

  /// Subscribe to driver location updates
  Stream<Map<String, dynamic>> subscribeToDriverLocation(String driverId) {
    final channelName = 'driver_location:$driverId';

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
          table: 'driver_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'driver_id',
            value: driverId,
          ),
          callback: (payload) {
            debugPrint('Driver location update: ${payload.newRecord}');
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
            }
          },
        )
        .subscribe();

    _channels[channelName] = channel;

    debugPrint('Subscribed to driver location: $driverId');

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
  RealtimeChannelStates? getChannelStatus(String channelName) {
    return _channels[channelName]?.status;
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
