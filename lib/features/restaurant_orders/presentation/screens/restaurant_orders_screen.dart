import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/features/restaurant_orders/providers/restaurant_orders_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Restaurant orders screen with role-specific functionality
class RestaurantOrdersScreen extends ConsumerStatefulWidget {
  const RestaurantOrdersScreen({super.key});

  @override
  ConsumerState<RestaurantOrdersScreen> createState() =>
      _RestaurantOrdersScreenState();
}

class _RestaurantOrdersScreenState extends ConsumerState<RestaurantOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _restaurantId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRestaurantData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantData() async {
    // TODO: Load restaurant data
    setState(() {
      _restaurantId = 'mock_restaurant_id';
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.watch(staffDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle(userRole ?? UserRoleType.consumer, staffData)),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Pending'),
            const Tab(text: 'Preparing'),
            const Tab(text: 'Ready'),
            if (isOwner) const Tab(text: 'History'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.analytics),
              onPressed: () => context.push(RoutePaths.restaurantAnalytics),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList('pending'),
          _buildOrdersList('preparing'),
          _buildOrdersList('ready'),
          if (isOwner) _buildOrdersList('completed'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showQuickActions(),
        icon: const Icon(Icons.bolt),
        label: const Text('Quick Actions'),
        backgroundColor: AppTheme.primaryBlack,
      ),
    );
  }

  String _getScreenTitle(UserRoleType role, staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return 'Orders Management';
      case UserRoleType.restaurantStaff:
        final staffRole = staffData?.role?.toLowerCase();
        switch (staffRole) {
          case 'chef':
            return 'Kitchen Orders';
          case 'cashier':
            return 'Order Processing';
          case 'server':
            return 'Service Orders';
          default:
            return 'Orders';
        }
      default:
        return 'Orders';
    }
  }

  Widget _buildOrdersList(String status) {
    return Column(
      children: [
        // Status header with stats
        Container(
          padding: const EdgeInsets.all(16),
          color: _getStatusColor(status).withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${status.toUpperCase()} ORDERS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                    Text(
                      _getStatusDescription(status),
                      style: TextStyle(
                        color: _getStatusColor(status).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '0', // TODO: Get actual count
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Orders list
        Expanded(
          child: _buildOrdersGrid(status),
        ),
      ],
    );
  }

  Widget _buildOrdersGrid(String status) {
    // TODO: Implement actual orders grid with real data
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Mock data
      itemBuilder: (context, index) {
        return _buildOrderCard(status, index);
      },
    );
  }

  Widget _buildOrderCard(String status, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status).withOpacity(0.1),
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
          ),
        ),
        title: Text('Order #${1000 + index}'),
        subtitle: Text('Customer • ${_formatTime(DateTime.now().subtract(Duration(minutes: index * 15)))}'),
        trailing: Text(
          '\$${(25.99 + index * 3).toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order details
                _buildOrderDetails(),
                const SizedBox(height: 16),
                // Action buttons based on status and role
                _buildOrderActions(status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Items:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Mock order items
        _buildOrderItem('Burger Deluxe', 2, '\$18.99'),
        _buildOrderItem('French Fries', 1, '\$4.99'),
        _buildOrderItem('Soft Drink', 2, '\$5.98'),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              '\$29.96',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItem(String name, int quantity, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$quantity x $name'),
          Text(price),
        ],
      ),
    );
  }

  Widget _buildOrderActions(String status) {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;

    switch (status) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _rejectOrder(),
                icon: const Icon(Icons.close),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _acceptOrder(),
                icon: const Icon(Icons.check),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        );
      case 'preparing':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markReady(),
                icon: const Icon(Icons.done_all),
                label: const Text('Mark Ready'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            if (isOwner) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _updatePrepTime(),
                  icon: const Icon(Icons.timer),
                  label: const Text('Update Time'),
                ),
              ),
            ],
          ],
        );
      case 'ready':
        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markCompleted(),
                icon: const Icon(Icons.delivery_dining),
                label: const Text('Mark Delivered'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _contactCustomer(),
                icon: const Icon(Icons.phone),
                label: const Text('Contact'),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Awaiting restaurant confirmation';
      case 'preparing':
        return 'Currently being prepared';
      case 'ready':
        return 'Ready for pickup/delivery';
      case 'completed':
        return 'Order fulfilled';
      default:
        return 'Unknown status';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Today'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Apply filter
              },
            ),
            ListTile(
              title: const Text('This Week'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Apply filter
              },
            ),
            ListTile(
              title: const Text('This Month'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Apply filter
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print Orders'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Print orders
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Orders'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Export orders
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Order Notifications'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Notification settings
              },
            ),
          ],
        ),
      ),
    );
  }

  void _acceptOrder() {
    // TODO: Implement accept order logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order accepted'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectOrder() {
    // TODO: Implement reject order logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order rejected'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _markReady() {
    // TODO: Implement mark ready logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order marked as ready'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _markCompleted() {
    // TODO: Implement mark completed logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order marked as delivered'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _updatePrepTime() {
    // TODO: Implement update prep time
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Preparation Time'),
        content: const TextField(
          decoration: InputDecoration(
            labelText: 'Preparation time (minutes)',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _contactCustomer() {
    // TODO: Implement contact customer
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contacting customer...')),
    );
  }
}