import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/order_conversation.dart';
import 'package:food_delivery_app/shared/models/order_call.dart';
import 'package:food_delivery_app/core/services/order_chat_service.dart';
import 'package:food_delivery_app/core/services/order_calling_service.dart';
import 'package:food_delivery_app/shared/widgets/order_chat_widget.dart';
import 'package:food_delivery_app/shared/widgets/order_call_widget.dart';
import 'package:intl/intl.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

class RestaurantOrdersScreen extends ConsumerStatefulWidget {
  final String? initialStatus;

  const RestaurantOrdersScreen({
    super.key,
    this.initialStatus,
  });

  @override
  ConsumerState<RestaurantOrdersScreen> createState() =>
      _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState
    extends ConsumerState<RestaurantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _restaurantId;
  bool _isLoading = true;
  List<Order> _orders = [];
  String _currentStatus = 'pending';

  // Communication state
  final Map<String, OrderConversation> _conversations = {};
  final Map<String, int> _unreadCounts = {};
  bool _showChatModal = false;
  bool _showCallModal = false;
  OrderConversation? _selectedConversation;
  OrderCall? _activeCall;
  StreamSubscription<CallEvent>? _callSubscription;

  final _restaurantManagementService = RestaurantManagementService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadRestaurantAndOrders();
    _initializeCommunication();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _callSubscription?.cancel();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final statuses = ['pending', 'preparing', 'ready', 'completed', 'cancelled'];
      setState(() => _currentStatus = statuses[_tabController.index]);
      _loadOrders();
    }
  }

  Future<void> _loadRestaurantAndOrders() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);

      if (restaurants.isEmpty) return;

      setState(() {
        _restaurantId = restaurants.first;
      });

      await _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadOrders() async {
    if (_restaurantId == null) return;

    setState(() => _isLoading = true);

    try {
      final orders = await _restaurantManagementService.getRestaurantOrders(
        _restaurantId!,
        status: _currentStatus == 'all' ? null : _currentStatus,
      );

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Initialize communication features
  Future<void> _initializeCommunication() async {
    try {
      final chatService = ref.read(orderChatServiceProvider);
      final callingService = ref.read(orderCallingServiceProvider);

      // Initialize services
      await chatService.initialize();
      await callingService.initialize();

      // Set up call event listener
      _callSubscription = callingService.callEvents.listen((event) {
        if (!mounted) return;
        _handleCallEvent(event);
      });

      AppLogger.info('Communication initialized for restaurant dashboard');
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

  /// Get or create conversation for an order
  Future<OrderConversation?> _getConversationForOrder(String orderId) async {
    if (_conversations.containsKey(orderId)) {
      return _conversations[orderId];
    }

    try {
      final chatService = ref.read(orderChatServiceProvider);
      final conversation = await chatService.getOrCreateConversation(orderId);

      if (mounted) {
        setState(() {
          _conversations[orderId] = conversation;
        });
      }

      return conversation;
    } catch (e) {
      AppLogger.error('Failed to get conversation for order $orderId: $e');
      return null;
    }
  }

  /// Get unread message count for an order
  Future<int> _getUnreadCountForOrder(String orderId) async {
    if (_unreadCounts.containsKey(orderId)) {
      return _unreadCounts[orderId]!;
    }

    final conversation = await _getConversationForOrder(orderId);
    if (conversation == null) return 0;

    try {
      final chatService = ref.read(orderChatServiceProvider);
      final count = await chatService.getUnreadCount(conversation.id);

      if (mounted) {
        setState(() {
          _unreadCounts[orderId] = count;
        });
      }

      return count;
    } catch (e) {
      AppLogger.error('Failed to get unread count for order $orderId: $e');
      return 0;
    }
  }

  /// Open chat for an order
  Future<void> _openChatForOrder(Order order) async {
    final conversation = await _getConversationForOrder(order.id);
    if (conversation == null) return;

    setState(() {
      _selectedConversation = conversation;
      _showChatModal = true;
    });

    // Reset unread count when opening chat
    if (_unreadCounts[order.id] != null && _unreadCounts[order.id]! > 0) {
      setState(() {
        _unreadCounts[order.id] = 0;
      });
    }
  }

  /// Close chat modal
  void _closeChat() {
    setState(() {
      _showChatModal = false;
      _selectedConversation = null;
    });
  }

  /// Start voice call for an order
  Future<void> _startVoiceCallForOrder(Order order) async {
    final conversation = await _getConversationForOrder(order.id);
    if (conversation == null) return;

    try {
      final callingService = ref.read(orderCallingServiceProvider);
      final authState = ref.read(authStateProvider);
      final currentUser = authState.user;
      if (currentUser == null) return;

      final call = await callingService.initiateCall(
        conversationId: conversation.id,
        orderId: order.id,
        receiverId: conversation.customerId,
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

  /// Start video call for an order
  Future<void> _startVideoCallForOrder(Order order) async {
    final conversation = await _getConversationForOrder(order.id);
    if (conversation == null) return;

    try {
      final callingService = ref.read(orderCallingServiceProvider);
      final authState = ref.read(authStateProvider);
      final currentUser = authState.user;
      if (currentUser == null) return;

      final call = await callingService.initiateCall(
        conversationId: conversation.id,
        orderId: order.id,
        receiverId: conversation.customerId,
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

  /// Get stream of unread message count for an order
  Stream<int> _getUnreadMessageCountStream(String orderId) {
    // This would integrate with your chat service to get unread count
    // For now, return a stream that always emits 0
    return Stream.value(0);
  }

  /// Build communication indicators for an order
  Widget _buildCommunicationIndicators(Order order) {
    return StreamBuilder<int>(
      stream: _getUnreadMessageCountStream(order.id),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chat button with unread indicator
            InkWell(
              onTap: () => _openChatForOrder(order),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Icon(
                      Icons.chat_outlined,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Voice call button
            InkWell(
              onTap: () => _startVoiceCallForOrder(order),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.call_outlined,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Video call button
            InkWell(
              onTap: () => _startVideoCallForOrder(order),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.videocam_outlined,
                  color: Colors.purple.shade700,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build communication modals
  Widget _buildCommunicationModals() {
    return Stack(
      children: [
        // Chat modal
        if (_showChatModal && _selectedConversation != null)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            bottom: 100,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: OrderChatWidget(
                orderId: _selectedConversation!.orderId,
                conversationId: _selectedConversation!.id,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Preparing'),
            Tab(text: 'Ready'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: _orders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(_orders[index]);
                          },
                        ),
                ),

          // Communication modals
          _buildCommunicationModals(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_currentStatus) {
      case 'pending':
        message = 'No pending orders';
        icon = Icons.inbox_outlined;
        break;
      case 'preparing':
        message = 'No orders being prepared';
        icon = Icons.restaurant_outlined;
        break;
      case 'ready':
        message = 'No orders ready for pickup';
        icon = Icons.done_outline;
        break;
      case 'completed':
        message = 'No completed orders';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'No cancelled orders';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'No orders found';
        icon = Icons.receipt_long_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${order.id.substring(0, 8)}',
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              DateFormat('HH:mm').format(order.createdAt),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        trailing: const SizedBox(), // _buildCommunicationIndicators(order),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(Icons.restaurant_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text('${order.items.length} items'),
              const SizedBox(width: 16),
              Icon(Icons.attach_money_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                '\$${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Items',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                // TODO: Load order items separately
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Order items (to be loaded)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (order.notes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildOrderActions(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderActions(Order order) {
    switch (order.status.name) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejectOrder(order.id),
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(order.id),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Accept'),
              ),
            ),
          ],
        );

      case 'preparing':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markOrderReady(order.id),
            icon: const Icon(Icons.done_all),
            label: const Text('Mark as Ready'),
          ),
        );

      case 'ready':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _markOrderCompleted(order.id),
            icon: const Icon(Icons.check_circle),
            label: const Text('Mark as Completed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    final prepTime = await showDialog<int>(
      context: context,
      builder: (context) => _PrepTimeDialog(),
    );

    if (prepTime == null) return;

    try {
      await _restaurantManagementService.acceptOrder(orderId, prepTime);
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectOrder(String orderId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectReasonDialog(),
    );

    if (reason == null) return;

    try {
      await _restaurantManagementService.rejectOrder(orderId, reason);
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markOrderReady(String orderId) async {
    try {
      await _restaurantManagementService.updateOrderStatus(orderId, 'ready');
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as ready'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markOrderCompleted(String orderId) async {
    try {
      await _restaurantManagementService.updateOrderStatus(orderId, 'completed');
      await _loadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready_for_pickup:
        return Colors.purple;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

class _PrepTimeDialog extends StatefulWidget {
  @override
  State<_PrepTimeDialog> createState() => _PrepTimeDialogState();
}

class _PrepTimeDialogState extends State<_PrepTimeDialog> {
  int _prepTime = 20;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Preparation Time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_prepTime minutes',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Slider(
            value: _prepTime.toDouble(),
            min: 10,
            max: 60,
            divisions: 10,
            label: '$_prepTime min',
            onChanged: (value) {
              setState(() => _prepTime = value.toInt());
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _prepTime),
          child: const Text('Accept Order'),
        ),
      ],
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();

  final List<String> _reasons = [
    'Too busy',
    'Out of ingredients',
    'Kitchen closed',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Order'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ..._reasons.map((reason) {
            return RadioListTile<String>(
              title: Text(reason),
              value: reason,
              // ignore: deprecated_member_use
              groupValue: _selectedReason,
              // ignore: deprecated_member_use
              onChanged: (value) {
                setState(() => _selectedReason = value);
              },
            );
          }),
          if (_selectedReason == 'Other')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: TextField(
                controller: _customReasonController,
                decoration: const InputDecoration(
                  labelText: 'Please specify',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  final reason = _selectedReason == 'Other'
                      ? _customReasonController.text
                      : _selectedReason!;
                  Navigator.pop(context, reason);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }

  }
