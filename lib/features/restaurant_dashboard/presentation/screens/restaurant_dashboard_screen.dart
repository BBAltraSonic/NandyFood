import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';

import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/core/widgets/role_guard.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/providers/restaurant_dashboard_provider.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/widgets/pending_order_card.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/notifications_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/realtime_order_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/audio_notification_service.dart';
import 'dart:async';

class RestaurantDashboardScreen extends ConsumerStatefulWidget {
  const RestaurantDashboardScreen({super.key});

  @override
  ConsumerState<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState
    extends ConsumerState<RestaurantDashboardScreen> {
  String? _restaurantId;
  bool _isLoading = true;

  // Real-time services
  final _realtimeService = RealtimeOrderService();
  final _audioService = AudioNotificationService();
  StreamSubscription? _newOrderSubscription;
  StreamSubscription? _statusChangeSubscription;

  @override
  void initState() {
    super.initState();
    _loadRestaurantId();
  }

  @override
  void dispose() {
    _newOrderSubscription?.cancel();
    _statusChangeSubscription?.cancel();
    _realtimeService.unsubscribe();
    _realtimeService.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantId() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      if (mounted) {
        context.go(RoutePaths.authLogin);
      }
      return;
    }

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);

      if (restaurants.isEmpty) {
        if (mounted) {
          context.go(RoutePaths.restaurantRegister);
        }
        return;
      }

      setState(() {
        _restaurantId = restaurants.first;
        _isLoading = false;
      });

      // Subscribe to real-time orders
      _subscribeToOrders(restaurants.first);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading restaurant: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.go(RoutePaths.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RestaurantAccessGuard(
      checkVerification: true,
      redirectTo: '/home',
      child: Builder(
        builder: (context) {
          if (_isLoading || _restaurantId == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final dashboardState =
              ref.watch(restaurantDashboardProvider(_restaurantId!));

          return Scaffold(
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dashboard'),
                  if (dashboardState.restaurant != null)
                    Text(
                      dashboardState.restaurant!.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              actions: [
                Consumer(
                  builder: (context, ref, child) {
                    final notifications = ref.watch(notificationsProvider);
                    final unreadCount = ref.watch(notificationsProvider.notifier).unreadCount;

                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
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
                                unreadCount > 99 ? '99+' : unreadCount.toString(),
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
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    context.push('/restaurant/settings');
                  },
                ),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(restaurantDashboardProvider(_restaurantId!).notifier)
                    .loadDashboardData();
              },
              child: dashboardState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dashboardState.error != null
                      ? _buildErrorState(dashboardState.error!)
                      : _buildDashboardContent(dashboardState),
            ),
            bottomNavigationBar: _buildBottomNav(),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(restaurantDashboardProvider(_restaurantId!).notifier)
                  .loadDashboardData();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(RestaurantDashboardState state) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Status toggle
        _buildAcceptingOrdersToggle(state),
        const SizedBox(height: 24),

        // Stats cards
        _buildStatsGrid(state),
        const SizedBox(height: 24),

        // Pending orders section
        if (state.pendingOrders.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Orders',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  context.push(RoutePaths.restaurantOrders);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.pendingOrders.take(3).map((order) {
            return PendingOrderCard(
              order: order,
              onAccept: () => _acceptOrder(order.id),
              onReject: () => _rejectOrder(order.id),
              onViewDetails: () {
                // TODO: Navigate to order details
              },
            );
          }),
          const SizedBox(height: 24),
        ],

        // Quick actions
        _buildQuickActions(),
        const SizedBox(height: 24),

        // Owner-only features
        Consumer(
          builder: (context, ref, child) {
            final isOwner = ref.watch(isRestaurantOwnerProvider);

            if (isOwner) {
              return Column(
                children: [
                  _buildOwnerOnlyActions(),
                  const SizedBox(height: 24),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),

        // Recent activity
        if (state.recentOrders.isNotEmpty) ...[
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...state.recentOrders.take(5).map((order) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(order.status.name)
                      .withValues(alpha: 0.1),
                  child: Icon(
                    _getStatusIcon(order.status.name),
                    color: _getStatusColor(order.status.name),
                    size: 20,
                  ),
                ),
                title: Text('Order #${order.id.substring(0, 8)}'),
                subtitle: Text(order.status.name),
                trailing: Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildAcceptingOrdersToggle(RestaurantDashboardState state) {
    final isAccepting = state.restaurant?.isActive ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepting
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccepting ? Colors.green : Colors.orange,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isAccepting ? Icons.check_circle : Icons.pause_circle,
            color: isAccepting ? Colors.green : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAccepting ? 'Accepting Orders' : 'Not Accepting Orders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  isAccepting
                      ? 'Your restaurant is open'
                      : 'Your restaurant is closed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: isAccepting,
            onChanged: (value) {
              ref
                  .read(restaurantDashboardProvider(_restaurantId!).notifier)
                  .toggleAcceptingOrders();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(RestaurantDashboardState state) {
    final metrics = state.metrics;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: [
        DashboardStatCard(
          title: "Today's Orders",
          value: metrics?.todayOrders.toString() ?? '0',
          icon: Icons.receipt_long_rounded,
          color: Colors.blue,
          onTap: () => context.push(RoutePaths.restaurantOrders),
        ),
        DashboardStatCard(
          title: "Today's Revenue",
          value: '\$${(metrics?.todayRevenue ?? 0).toStringAsFixed(0)}',
          icon: Icons.attach_money_rounded,
          color: Colors.green,
          subtitle: metrics != null && metrics.todayOrders > 0
              ? 'Avg: \$${metrics.avgOrderValue.toStringAsFixed(2)}'
              : null,
        ),
        DashboardStatCard(
          title: 'Pending Orders',
          value: (metrics?.pendingOrders ?? 0).toString(),
          icon: Icons.pending_actions_rounded,
          color: Colors.orange,
          onTap: () => context.push('${RoutePaths.restaurantOrders}?status=pending'),
        ),
        DashboardStatCard(
          title: 'Active Items',
          value: (metrics?.activeMenuItems ?? 0).toString(),
          icon: Icons.restaurant_menu_rounded,
          color: Colors.purple,
          onTap: () => context.push(RoutePaths.restaurantMenu),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildQuickActionCard(
              'Orders',
              Icons.list_alt_rounded,
              Colors.blue,
              () => context.push(RoutePaths.restaurantOrders),
            ),
            _buildQuickActionCard(
              'Menu',
              Icons.restaurant_menu_rounded,
              Colors.orange,
              () => context.push(RoutePaths.restaurantMenu),
            ),
            _buildQuickActionCard(
              'Analytics',
              Icons.analytics_rounded,
              Colors.purple,
              () => context.push(RoutePaths.restaurantAnalytics),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOwnerOnlyActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Owner Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildQuickActionCard(
              'Restaurant Info',
              Icons.info_rounded,
              Colors.indigo,
              () => context.push('/restaurant/info'),
            ),
            _buildQuickActionCard(
              'Staff Management',
              Icons.people_rounded,
              Colors.teal,
              () => context.push('/restaurant/staff'),
            ),
            _buildQuickActionCard(
              'Financial Reports',
              Icons.attach_money_rounded,
              Colors.green,
              () => context.push('/restaurant/reports'),
            ),
            _buildQuickActionCard(
              'Promotions',
              Icons.local_offer_rounded,
              Colors.red,
              () => context.push('/restaurant/promotions'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            // Already on dashboard
            break;
          case 1:
            context.push(RoutePaths.restaurantOrders);
            break;
          case 2:
            context.push(RoutePaths.restaurantMenu);
            break;
          case 3:
            context.push(RoutePaths.restaurantAnalytics);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
      ],
    );
  }

  Future<void> _acceptOrder(String orderId) async {
    // Show prep time dialog
    final prepTime = await showDialog<int>(
      context: context,
      builder: (context) => _PrepTimeDialog(),
    );

    if (prepTime != null) {
      await ref
          .read(restaurantDashboardProvider(_restaurantId!).notifier)
          .acceptOrder(orderId, prepTime);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted'),
            backgroundColor: Colors.green,
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

    if (reason != null) {
      await ref
          .read(restaurantDashboardProvider(_restaurantId!).notifier)
          .rejectOrder(orderId, reason);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Subscribe to real-time order notifications
  void _subscribeToOrders(String restaurantId) {
    AppLogger.section('🔔 Setting up real-time notifications');

    // Subscribe to real-time channel
    _realtimeService.subscribeToRestaurantOrders(restaurantId);

    // Listen for new orders
    _newOrderSubscription = _realtimeService.newOrdersStream.listen(
      (order) {
        AppLogger.success('🆕 NEW ORDER: ${order.id}');

        // Add notification to notifications list
        final notification = RestaurantNotification(
          id: 'new_order_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
          title: 'New Order Received!',
          message: 'Order #${order.id.substring(0, 8)} for R${order.totalAmount.toStringAsFixed(2)}',
          type: NotificationType.newOrder,
          timestamp: DateTime.now(),
          data: {
            'orderId': order.id,
            'totalAmount': order.totalAmount,
            'customerName': order.customerName ?? 'Customer',
          },
          actionUrl: RoutePaths.restaurantOrders,
        );
        ref.read(notificationsProvider.notifier).addNotification(notification);

        // Play notification sound
        _audioService.playNewOrderSound();
        _audioService.vibrateForNewOrder();

        // Show in-app notification
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'New Order!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('R ${order.totalAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: Colors.white,
                onPressed: () {
                  context.push(RoutePaths.restaurantOrders);
                },
              ),
            ),
          );

          // Refresh dashboard
          ref
              .read(restaurantDashboardProvider(restaurantId).notifier)
              .loadDashboardData();
        }
      },
      onError: (error) {
        AppLogger.error('Error in new order stream: $error');
      },
    );

    // Listen for status changes
    _statusChangeSubscription = _realtimeService.orderStatusStream.listen(
      (order) {
        AppLogger.info('Order ${order.id} status changed to: ${order.status}');

        // Add notification for important status changes
        if (order.status.name == 'delivered' || order.status.name == 'cancelled') {
          final notification = RestaurantNotification(
            id: 'status_change_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
            title: 'Order ${order.status.name == 'delivered' ? 'Delivered' : 'Cancelled'}',
            message: 'Order #${order.id.substring(0, 8)} has been ${order.status.name}',
            type: NotificationType.orderStatusChange,
            timestamp: DateTime.now(),
            data: {
              'orderId': order.id,
              'status': order.status.name,
              'totalAmount': order.totalAmount,
            },
            actionUrl: RoutePaths.restaurantOrders,
          );
          ref.read(notificationsProvider.notifier).addNotification(notification);
        }

        // Play soft notification
        _audioService.playStatusChangeSound();

        // Refresh dashboard
        if (mounted) {
          ref
              .read(restaurantDashboardProvider(restaurantId).notifier)
              .loadDashboardData();
        }
      },
      onError: (error) {
        AppLogger.error('Error in status change stream: $error');
      },
    );

    AppLogger.success('✅ Real-time notifications configured');
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
