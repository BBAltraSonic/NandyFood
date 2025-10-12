import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/realtime_service.dart';

/// Order status enum
enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready,
  pickedUp,
  onTheWay,
  nearby,
  delivered,
  cancelled,
}

/// Extension for OrderStatus
extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.onTheWay:
        return 'On the Way';
      case OrderStatus.nearby:
        return 'Driver Nearby';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get description {
    switch (this) {
      case OrderStatus.placed:
        return 'Your order has been placed successfully';
      case OrderStatus.confirmed:
        return 'Restaurant confirmed your order';
      case OrderStatus.preparing:
        return 'Your food is being prepared';
      case OrderStatus.ready:
        return 'Your order is ready for pickup';
      case OrderStatus.pickedUp:
        return 'Driver picked up your order';
      case OrderStatus.onTheWay:
        return 'Your order is on the way';
      case OrderStatus.nearby:
        return 'Driver is less than 1 km away';
      case OrderStatus.delivered:
        return 'Your order has been delivered. Enjoy!';
      case OrderStatus.cancelled:
        return 'Order was cancelled';
    }
  }

  int get stepNumber {
    switch (this) {
      case OrderStatus.placed:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.pickedUp:
        return 4;
      case OrderStatus.onTheWay:
        return 5;
      case OrderStatus.nearby:
        return 6;
      case OrderStatus.delivered:
        return 7;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return OrderStatus.placed;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
      case 'ready_for_pickup':
        return OrderStatus.ready;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'on_the_way':
      case 'out_for_delivery':
        return OrderStatus.onTheWay;
      case 'nearby':
        return OrderStatus.nearby;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.placed;
    }
  }
}

/// Order tracking state
class OrderTrackingState {
  const OrderTrackingState({
    required this.orderId,
    required this.status,
    this.statusHistory = const [],
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverRating,
    this.vehicleType,
    this.vehicleNumber,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.lastUpdated,
    this.error,
    this.isLoading = false,
  });

  final String orderId;
  final OrderStatus status;
  final List<OrderStatusUpdate> statusHistory;
  final String? driverId;
  final String? driverName;
  final String? driverPhone;
  final double? driverRating;
  final String? vehicleType;
  final String? vehicleNumber;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final DateTime? lastUpdated;
  final String? error;
  final bool isLoading;

  OrderTrackingState copyWith({
    String? orderId,
    OrderStatus? status,
    List<OrderStatusUpdate>? statusHistory,
    String? driverId,
    String? driverName,
    String? driverPhone,
    double? driverRating,
    String? vehicleType,
    String? vehicleNumber,
    DateTime? estimatedDeliveryTime,
    DateTime? actualDeliveryTime,
    DateTime? lastUpdated,
    String? error,
    bool? isLoading,
  }) {
    return OrderTrackingState(
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverRating: driverRating ?? this.driverRating,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Status update entry
class OrderStatusUpdate {
  const OrderStatusUpdate({
    required this.status,
    required this.timestamp,
    this.note,
  });

  final OrderStatus status;
  final DateTime timestamp;
  final String? note;
}

/// Order tracking provider
class OrderTrackingNotifier extends StateNotifier<OrderTrackingState> {
  OrderTrackingNotifier({
    required this.orderId,
    required this.realtimeService,
    required this.notificationService,
    required OrderStatus initialStatus,
  }) : super(OrderTrackingState(
          orderId: orderId,
          status: initialStatus,
          isLoading: true,
        )) {
    _initialize();
  }

  final String orderId;
  final RealtimeService realtimeService;
  final NotificationService notificationService;
  
  StreamSubscription<Map<String, dynamic>>? _orderSubscription;
  StreamSubscription<Map<String, dynamic>>? _deliverySubscription;

  /// Initialize tracking
  Future<void> _initialize() async {
    try {
      // Subscribe to order updates
      _orderSubscription = realtimeService.subscribeToOrder(orderId).listen(
        _handleOrderUpdate,
        onError: _handleError,
      );

      // Subscribe to delivery updates
      _deliverySubscription = realtimeService.subscribeToDelivery(orderId).listen(
        _handleDeliveryUpdate,
        onError: _handleError,
      );

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error initializing order tracking: $e');
      state = state.copyWith(
        error: 'Failed to start tracking',
        isLoading: false,
      );
    }
  }

  /// Handle order updates
  void _handleOrderUpdate(Map<String, dynamic> data) {
    try {
      final statusStr = data['status'] as String?;
      if (statusStr == null) return;

      final newStatus = OrderStatusExtension.fromString(statusStr);
      final previousStatus = state.status;

      // Only update if status changed
      if (newStatus != previousStatus) {
        final statusUpdate = OrderStatusUpdate(
          status: newStatus,
          timestamp: DateTime.now(),
        );

        final updatedHistory = [...state.statusHistory, statusUpdate];

        state = state.copyWith(
          status: newStatus,
          statusHistory: updatedHistory,
          lastUpdated: DateTime.now(),
          error: null,
        );

        // Show notification for status change
        _showStatusNotification(newStatus);

        debugPrint('Order status updated: ${newStatus.displayName}');
      }

      // Update estimated delivery time
      if (data['estimated_delivery_time'] != null) {
        final etaStr = data['estimated_delivery_time'] as String;
        state = state.copyWith(
          estimatedDeliveryTime: DateTime.parse(etaStr),
        );
      }

      // Update actual delivery time
      if (data['delivered_at'] != null && newStatus == OrderStatus.delivered) {
        final deliveredAtStr = data['delivered_at'] as String;
        state = state.copyWith(
          actualDeliveryTime: DateTime.parse(deliveredAtStr),
        );
      }
    } catch (e) {
      debugPrint('Error handling order update: $e');
    }
  }

  /// Handle delivery updates
  void _handleDeliveryUpdate(Map<String, dynamic> data) {
    try {
      state = state.copyWith(
        driverId: data['driver_id'] as String?,
        driverName: data['driver_name'] as String?,
        driverPhone: data['driver_phone'] as String?,
        driverRating: (data['driver_rating'] as num?)?.toDouble(),
        vehicleType: data['vehicle_type'] as String?,
        vehicleNumber: data['vehicle_number'] as String?,
        lastUpdated: DateTime.now(),
      );

      debugPrint('Delivery info updated: ${state.driverName}');
    } catch (e) {
      debugPrint('Error handling delivery update: $e');
    }
  }

  /// Handle errors
  void _handleError(Object error) {
    debugPrint('Order tracking error: $error');
    state = state.copyWith(
      error: 'Connection error. Retrying...',
    );

    // Retry connection after delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _initialize();
      }
    });
  }

  /// Show notification for status change
  Future<void> _showStatusNotification(OrderStatus status) async {
    String title;
    String body;

    switch (status) {
      case OrderStatus.confirmed:
        title = '✅ Order Confirmed';
        body = 'Your order has been confirmed by the restaurant';
        break;
      case OrderStatus.preparing:
        title = '👨‍🍳 Preparing Your Food';
        body = 'The restaurant is preparing your order';
        break;
      case OrderStatus.ready:
        title = '✨ Order Ready';
        body = 'Your order is ready for pickup';
        break;
      case OrderStatus.pickedUp:
        title = '🚗 Picked Up';
        body = 'Driver has picked up your order';
        break;
      case OrderStatus.onTheWay:
        title = '🛵 On the Way';
        body = 'Your order is on the way!';
        break;
      case OrderStatus.nearby:
        title = '📍 Driver Nearby';
        body = 'Your driver is less than 1 km away';
        break;
      case OrderStatus.delivered:
        title = '🎉 Delivered!';
        body = 'Your order has been delivered. Enjoy your meal!';
        break;
      default:
        return;
    }

    await notificationService.showNotification(
      id: orderId.hashCode,
      title: title,
      body: body,
      payload: 'order:$orderId',
    );
  }

  /// Cancel order
  Future<bool> cancelOrder(String reason) async {
    try {
      // TODO: Call API to cancel order
      // await supabase.from('orders').update({
      //   'status': 'cancelled',
      //   'cancellation_reason': reason,
      //   'cancelled_at': DateTime.now().toIso8601String(),
      // }).eq('id', orderId);

      state = state.copyWith(status: OrderStatus.cancelled);
      
      await notificationService.showNotification(
        id: orderId.hashCode,
        title: 'Order Cancelled',
        body: 'Your order has been cancelled',
        payload: 'order:$orderId',
      );

      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      state = state.copyWith(error: 'Failed to cancel order');
      return false;
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _deliverySubscription?.cancel();
    super.dispose();
  }
}

/// Provider family for order tracking
final orderTrackingProvider = StateNotifierProvider.family<
    OrderTrackingNotifier,
    OrderTrackingState,
    String>(
  (ref, orderId) {
    final realtimeService = ref.watch(realtimeServiceProvider);
    final notificationService = NotificationService();

    return OrderTrackingNotifier(
      orderId: orderId,
      realtimeService: realtimeService,
      notificationService: notificationService,
      initialStatus: OrderStatus.placed,
    );
  },
);
