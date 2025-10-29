import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../shared/models/order.dart';
import '../providers/delivery_orders_provider.dart';

/// Delivery status screen with active and history tabs
class DeliveryStatusScreen extends ConsumerStatefulWidget {
  const DeliveryStatusScreen({super.key});

  @override
  ConsumerState<DeliveryStatusScreen> createState() => _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends ConsumerState<DeliveryStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _historyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _historyScrollController.addListener(_onHistoryScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historyScrollController.dispose();
    super.dispose();
  }

  void _onHistoryScroll() {
    if (_historyScrollController.position.pixels >=
        _historyScrollController.position.maxScrollExtent - 200) {
      // Load more when near bottom
      ref.read(deliveryOrdersProvider.notifier).loadMoreHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryState = ref.watch(deliveryOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Active'),
                  if (deliveryState.activeOrders.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${deliveryState.activeOrders.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrdersTab(deliveryState),
          _buildHistoryTab(deliveryState),
        ],
      ),
    );
  }

  Widget _buildActiveOrdersTab(DeliveryOrdersState state) {
    if (state.isLoadingActive) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorWidget(state.error!, () {
        ref.read(deliveryOrdersProvider.notifier).refreshActiveOrders();
      });
    }

    if (!state.hasActiveOrders) {
      return _buildEmptyState(
        icon: Icons.delivery_dining,
        title: 'No Active Deliveries',
        message: 'Your active orders will appear here',
        actionLabel: 'Browse Restaurants',
        onAction: () => context.go('/home'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(deliveryOrdersProvider.notifier).refreshActiveOrders();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.activeOrders.length,
        itemBuilder: (context, index) {
          final order = state.activeOrders[index];
          return _buildActiveOrderCard(order);
        },
      ),
    );
  }

  Widget _buildHistoryTab(DeliveryOrdersState state) {
    if (state.isLoadingHistory && state.historyOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.historyOrders.isEmpty) {
      return _buildErrorWidget(state.error!, () {
        ref.read(deliveryOrdersProvider.notifier).refreshHistoryOrders();
      });
    }

    if (!state.hasHistoryOrders) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Order History',
        message: 'Your completed and cancelled orders will appear here',
        actionLabel: 'Order Now',
        onAction: () => context.go('/home'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(deliveryOrdersProvider.notifier).refreshHistoryOrders();
      },
      child: ListView.builder(
        controller: _historyScrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.historyOrders.length + (state.isLoadingHistory ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.historyOrders.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final order = state.historyOrders[index];
          return _buildHistoryOrderCard(order);
        },
      ),
    );
  }

  Widget _buildActiveOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/order/tracking/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildStatusIndicator(order.status?.name ?? 'unknown'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.restaurantName ?? 'Restaurant',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatStatus(order.status?.name ?? 'unknown'),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getStatusColor(order.status?.name ?? 'unknown'),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.receipt_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatOrderTime(order.createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (order.status == OrderStatus.placed || order.status == OrderStatus.confirmed)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _showCancelOrderDialog(order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Order'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryOrderCard(Order order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/order/tracking/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDelivered ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isDelivered ? Icons.check_circle : Icons.cancel,
                      color: isDelivered ? Colors.green : Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.restaurantName ?? 'Restaurant',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDelivered ? 'Delivered' : 'Cancelled',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDelivered ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatHistoryDate(order.updatedAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _handleReorder(order.id),
                    child: const Text('Reorder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getStatusIcon(status),
        color: _getStatusColor(status),
        size: 24,
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing Your Food';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'picked_up':
        return 'Picked Up';
      case 'out_for_delivery':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready_for_pickup':
        return Colors.indigo;
      case 'picked_up':
        return Colors.teal;
      case 'out_for_delivery':
        return Colors.green;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready_for_pickup':
        return Icons.shopping_bag;
      case 'picked_up':
        return Icons.directions_bike;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _formatOrderTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(time);
    }
  }

  String _formatHistoryDate(DateTime date) {
    return DateFormat('MMM d, yyyy • h:mm a').format(date);
  }

  void _showCancelOrderDialog(String orderId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this order?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
                hintText: 'Tell us why you\'re cancelling',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Order'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(deliveryOrdersProvider.notifier)
                  .cancelOrder(orderId, reasonController.text);

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Order cancelled successfully'
                        : 'Failed to cancel order',
                  ),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _handleReorder(String orderId) async {
    AppLogger.info('Reordering from order: $orderId');

    final newOrderId = await ref
        .read(deliveryOrdersProvider.notifier)
        .reorder(orderId);

    if (!mounted) return;

    if (newOrderId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order added to cart successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      context.push('/order/tracking/$newOrderId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reorder'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
