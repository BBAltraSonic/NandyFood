import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/order_conversation.dart';
import 'package:food_delivery_app/shared/models/order_call.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/notification_service.dart';
import 'package:food_delivery_app/core/services/order_chat_service.dart';
import 'package:food_delivery_app/core/services/order_calling_service.dart';
import 'package:food_delivery_app/shared/widgets/order_preparation_timeline_widget.dart';
import 'package:food_delivery_app/shared/widgets/order_chat_widget.dart';
import 'package:food_delivery_app/shared/widgets/order_call_widget.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderTrackingScreen({Key? key, this.order, this.orderId}) : super(key: key);

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notificationService = NotificationService();

  Order? _order;
  String? _loadError;
  RealtimeChannel? _orderChannel;
  StreamSubscription<Order>? _orderSubscription;
  Timer? _preparationTimer;
  int _remainingMinutes = 0;

  // Communication state
  OrderConversation? _conversation;
  bool _showChatModal = false;
  bool _showCallModal = false;
  OrderCall? _activeCall;
  int _unreadMessageCount = 0;
  StreamSubscription<CallEvent>? _callSubscription;

  @override
  void initState() {
    super.initState();
    _initializeOrderTracking();
  }

  void _initializeOrderTracking() {
    _order = widget.order;
    final orderId = widget.order?.id ?? widget.orderId;

    if (orderId != null && orderId.isNotEmpty) {
      // Set up real-time order tracking
      _setupOrderSubscription(orderId);

      // Initialize communication features
      _initializeCommunication(orderId);

      // If only an ID was provided, fetch the full order details
      if (_order == null) {
        _loadOrderById(orderId);
      } else {
        _startPreparationTracking();
      }
    }
  }

  void _setupOrderSubscription(String orderId) {
    _orderChannel = _supabase.channel('order_tracking_$orderId');

    _orderChannel?.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'orders',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: orderId,
      ),
      callback: (payload) {
        if (!mounted) return;
        _handleOrderUpdate(payload.newRecord);
      },
    ).subscribe();
  }

  void _handleOrderUpdate(Map<String, dynamic> orderData) {
    final updatedOrder = Order.fromJson(orderData);
    setState(() {
      _order = updatedOrder;
    });

    // Update remaining time based on status
    if (updatedOrder.status == OrderStatus.preparing) {
      _startPreparationTimer();
    } else if (updatedOrder.status == OrderStatus.ready_for_pickup) {
      _preparationTimer?.cancel();
      setState(() {
        _remainingMinutes = 0;
      });
    }

    // Show notification for status changes
    _notificationService.showOrderStatusNotification(
      orderId: updatedOrder.id,
      status: updatedOrder.status.name,
      restaurantName: updatedOrder.restaurantName ?? 'Restaurant',
      estimatedMinutes: _remainingMinutes,
    );
  }

  Future<void> _loadOrderById(String id) async {
    try {
      setState(() {
        _loadError = null;
      });
      final data = await DatabaseService().getOrder(id);
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _order = Order.fromJson(data);
          _loadError = null;
        });
        _startPreparationTracking();
      } else {
        setState(() {
          _loadError = 'We couldn\'t find this order.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load order. Please check your connection and try again.';
      });
    }
  }

  void _startPreparationTracking() {
    if (_order == null) return;

    if (_order!.status == OrderStatus.preparing) {
      _startPreparationTimer();
    } else if (_order!.status == OrderStatus.ready_for_pickup) {
      setState(() {
        _remainingMinutes = 0;
      });
    }
  }

  void _startPreparationTimer() {
    _preparationTimer?.cancel();

    if (_order?.preparationStartedAt != null) {
      final elapsed = DateTime.now().difference(_order!.preparationStartedAt!).inMinutes;
      _remainingMinutes = (_order!.estimatedPreparationTime - elapsed).clamp(0, _order!.estimatedPreparationTime);

      _preparationTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        setState(() {
          _remainingMinutes = (_remainingMinutes - 1).clamp(0, _order!.estimatedPreparationTime);
        });

        if (_remainingMinutes <= 0) {
          timer.cancel();
        }
      });
    } else {
      _remainingMinutes = _order?.estimatedPreparationTime ?? 15;
    }
  }

  /// Initialize communication features for the order
  Future<void> _initializeCommunication(String orderId) async {
    try {
      final chatService = ref.read(orderChatServiceProvider);
      final callingService = ref.read(orderCallingServiceProvider);

      // Initialize services
      await chatService.initialize();
      await callingService.initialize();

      // Get or create conversation
      _conversation = await chatService.getOrCreateConversation(orderId);

      // Set up call event listener
      _callSubscription = callingService.callEvents.listen((event) {
        if (!mounted) return;
        _handleCallEvent(event);
      });

      // Get unread message count
      _updateUnreadCount();

      AppLogger.info('Communication initialized for order: $orderId');
    } catch (e) {
      AppLogger.error('Failed to initialize communication: $e');
    }
  }

  /// Handle call events
  void _handleCallEvent(CallEvent event) {
    setState(() {
      switch (event.type) {
        case CallEventType.incoming:
          _activeCall = event.call;
          _showCallModal = true;
          break;
        case CallEventType.connected:
          _activeCall = event.call;
          break;
        case CallEventType.ended:
        case CallEventType.missed:
        case CallEventType.rejected:
          _activeCall = null;
          _showCallModal = false;
          break;
        default:
          break;
      }
    });
  }

  /// Update unread message count
  Future<void> _updateUnreadCount() async {
    if (_conversation == null) return;

    try {
      final chatService = ref.read(orderChatServiceProvider);
      final count = await chatService.getUnreadCount(_conversation!.id);
      if (mounted) {
        setState(() => _unreadMessageCount = count);
      }
    } catch (e) {
      AppLogger.error('Failed to update unread count: $e');
    }
  }

  /// Open chat modal
  void _openChat() {
    setState(() => _showChatModal = true);
    // Reset unread count when opening chat
    if (_unreadMessageCount > 0) {
      setState(() => _unreadMessageCount = 0);
    }
  }

  /// Close chat modal
  void _closeChat() {
    setState(() => _showChatModal = false);
    _updateUnreadCount();
  }

  /// Initiate voice call
  Future<void> _startVoiceCall() async {
    if (_conversation == null) return;

    try {
      final callingService = ref.read(orderCallingServiceProvider);
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Determine the other participant (restaurant staff)
      final receiverId = currentUser.id == _conversation!.customerId
          ? _conversation!.restaurantId
          : _conversation!.customerId;

      final call = await callingService.initiateCall(
        conversationId: _conversation!.id,
        orderId: _order!.id,
        receiverId: receiverId,
        callType: CallType.voice,
        isVideoCall: false,
      );

      setState(() {
        _activeCall = call;
        _showCallModal = true;
      });
    } catch (e) {
      AppLogger.error('Failed to start voice call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Initiate video call
  Future<void> _startVideoCall() async {
    if (_conversation == null) return;

    try {
      final callingService = ref.read(orderCallingServiceProvider);
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return;

      // Determine the other participant (restaurant staff)
      final receiverId = currentUser.id == _conversation!.customerId
          ? _conversation!.restaurantId
          : _conversation!.customerId;

      final call = await callingService.initiateCall(
        conversationId: _conversation!.id,
        orderId: _order!.id,
        receiverId: receiverId,
        callType: CallType.video,
        isVideoCall: true,
      );

      setState(() {
        _activeCall = call;
        _showCallModal = true;
      });
    } catch (e) {
      AppLogger.error('Failed to start video call: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start video call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _preparationTimer?.cancel();
    _orderChannel?.unsubscribe();
    _callSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Stack(
        children: [
          // Main content
          _order == null
              ? (_loadError != null
                  ? _buildLoadError(context)
                  : const Center(child: CircularProgressIndicator()))
              : _buildOrderTrackingContent(context),

          // Communication modals
          _buildCommunicationModals(),
        ],
      ),
      // Communication buttons
      floatingActionButton: _buildCommunicationButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  Widget _buildLoadError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_loadError ?? 'An error occurred', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    final id = widget.order?.id ?? widget.orderId;
                    if (id != null) {
                      _loadOrderById(id);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTrackingContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info header
            _buildOrderInfoCard(),
            const SizedBox(height: 16),

            // Preparation timeline
            _buildPreparationTimeline(),
            const SizedBox(height: 16),

            // Current status details
            _buildCurrentStatusCard(),
            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(),
            const SizedBox(height: 16),

            // Restaurant info
            _buildRestaurantInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order #',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  _order!.id.substring(0, 8).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '\$${_order!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                _buildStatusBadge(_order!.status),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case OrderStatus.placed:
        color = Colors.orange;
        icon = Icons.shopping_cart;
        text = 'Order Placed';
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        icon = Icons.check_circle;
        text = 'Confirmed';
        break;
      case OrderStatus.preparing:
        color = Colors.purple;
        icon = Icons.restaurant;
        text = 'Preparing';
        break;
      case OrderStatus.ready_for_pickup:
        color = Colors.green;
        icon = Icons.check;
        text = 'Ready for Pickup';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreparationTimeline() {
    return OrderPreparationTimelineWidget(
      order: _order!,
      remainingMinutes: _remainingMinutes,
    );
  }

  Widget _buildCurrentStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (_order!.status) {
      case OrderStatus.preparing:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your order is being prepared...',
              style: TextStyle(fontSize: 16),
            ),
            if (_remainingMinutes > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Estimated time: $_remainingMinutes minutes',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      case OrderStatus.ready_for_pickup:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your order is ready for pickup! 🎉',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Please visit the restaurant to collect your order.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      default:
        return Text(
          _order!.preparationStatusText,
          style: const TextStyle(fontSize: 16),
        );
    }
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_order!.status == OrderStatus.ready_for_pickup)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Show pickup instructions
                _showPickupInstructions();
              },
              icon: const Icon(Icons.info),
              label: const Text('Pickup Instructions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ),
        if (_order!.status == OrderStatus.preparing)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Request status update notification
                _requestStatusUpdate();
              },
              icon: const Icon(Icons.notifications),
              label: const Text('Notify me when ready'),
            ),
          ),
      ],
    );
  }

  Widget _buildRestaurantInfoCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restaurant Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.store, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _order!.restaurantName ?? 'Restaurant',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            if (_order!.pickupAddress.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _order!.pickupAddress['address'] ?? 'Pickup location',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPickupInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pickup Instructions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your order is ready for pickup!'),
            const SizedBox(height: 16),
            const Text('Please follow these steps:'),
            const SizedBox(height: 8),
            const Text('• Visit the restaurant counter'),
            const Text('• Provide your order number'),
            const Text('• Collect your order'),
            const SizedBox(height: 16),
            if (_order!.pickupInstructions?.isNotEmpty == true)
              Text('Special instructions: ${_order!.pickupInstructions}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _requestStatusUpdate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You will be notified when your order is ready'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Build communication buttons
  Widget _buildCommunicationButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Chat button
        FloatingActionButton(
          heroTag: "chat",
          onPressed: _openChat,
          backgroundColor: Colors.blue,
          child: Stack(
            children: [
              const Icon(Icons.chat, color: Colors.white),
              if (_unreadMessageCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Voice call button
        FloatingActionButton(
          heroTag: "voice_call",
          onPressed: _startVoiceCall,
          backgroundColor: Colors.green,
          mini: true,
          child: const Icon(Icons.call, color: Colors.white),
        ),
        const SizedBox(height: 8),
        // Video call button
        FloatingActionButton(
          heroTag: "video_call",
          onPressed: _startVideoCall,
          backgroundColor: Colors.purple,
          mini: true,
          child: const Icon(Icons.videocam, color: Colors.white),
        ),
      ],
    );
  }

  /// Build communication modals
  Widget _buildCommunicationModals() {
    return Stack(
      children: [
        // Chat modal
        if (_showChatModal && _conversation != null)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            bottom: 100,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: OrderChatWidget(
                orderId: _order!.id,
                conversationId: _conversation!.id,
                onClose: _closeChat,
                height: MediaQuery.of(context).size.height * 0.6,
              ),
            ),
          ),

        // Call modal
        if (_showCallModal && _activeCall != null)
          Container(
            color: Colors.black.withValues(alpha: 0.8),
            child: OrderCallWidget(
              call: _activeCall!,
              isVideoCall: _activeCall!.isVideoCall,
              onCallEnded: () {
                setState(() {
                  _showCallModal = false;
                  _activeCall = null;
                });
              },
            ),
          ),
      ],
    );
  }
}