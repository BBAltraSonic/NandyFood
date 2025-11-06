import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/providers/restaurant_dashboard_provider.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/widgets/pending_order_card.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/widgets/restaurant_tools_grid.dart';
import 'package:food_delivery_app/shared/widgets/restaurant_role_indicator.dart';
import 'package:food_delivery_app/shared/widgets/restaurant_smart_shortcuts.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Enhanced restaurant home screen with smart tool organization
class RestaurantHomeScreen extends ConsumerStatefulWidget {
  const RestaurantHomeScreen({super.key});

  @override
  ConsumerState<RestaurantHomeScreen> createState() =>
      _RestaurantHomeScreenState();
}

class _RestaurantHomeScreenState extends ConsumerState<RestaurantHomeScreen> {
  String? _restaurantId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurantData();
  }

  Future<void> _loadRestaurantData() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) return;

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);

      if (restaurants.isNotEmpty) {
        setState(() {
          _restaurantId = restaurants.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _restaurantId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dashboardState =
        ref.watch(restaurantDashboardProvider(_restaurantId!));
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.watch(staffDataProvider);

    return Scaffold(
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
                : _buildHomeContent(dashboardState, isOwner, staffData),
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

  Widget _buildHomeContent(dashboardState, bool isOwner, staffData) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(isOwner, staffData),
          const SizedBox(height: 24),

          // Restaurant Status Toggle
          _buildRestaurantStatusCard(dashboardState),
          const SizedBox(height: 24),

          // Key Metrics
          _buildKeyMetricsSection(dashboardState),
          const SizedBox(height: 24),

          // Priority Actions based on role
          _buildPriorityActionsSection(isOwner, staffData),
          const SizedBox(height: 24),

          // Pending Orders (if any)
          if (dashboardState.pendingOrders.isNotEmpty) ...[
            _buildPendingOrdersSection(dashboardState),
            const SizedBox(height: 24),
          ],

          // Today's Overview
          _buildTodayOverviewSection(dashboardState),
          const SizedBox(height: 24),

          // Smart Shortcuts
          RestaurantSmartShortcuts(),
          const SizedBox(height: 24),

          // Quick Access Tools
          QuickAccessTools(),
          const SizedBox(height: 24),

          // All Tools Grid
          RestaurantToolsGrid(
            showCategories: true,
            showSearch: true,
            crossAxisCount: 3,
            childAspectRatio: 1.2,
          ),
          const SizedBox(height: 24),

          // Recent Activity
          RecentActivityWidget(),
          if (dashboardState.recentOrders.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildRecentActivitySection(dashboardState),
          ],
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(bool isOwner, staffData) {
    final dashboardState = ref.watch(restaurantDashboardProvider(_restaurantId!));
    final restaurant = dashboardState.restaurant;
    final hour = DateTime.now().hour;
    String greeting = 'Good ';

    if (hour < 12) {
      greeting += 'Morning';
    } else if (hour < 17) {
      greeting += 'Afternoon';
    } else {
      greeting += 'Evening';
    }

    String roleSpecificGreeting = isOwner
        ? 'Owner'
        : staffData?.role ?? 'Team Member';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlack,
            AppTheme.primaryBlack.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $roleSpecificGreeting! 👋',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant?.name ?? 'Your Restaurant',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.store_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantStatusCard(dashboardState) {
    final isAccepting = dashboardState.restaurant?.isActive ?? false;

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
            isAccepting ? Icons.storefront_rounded : Icons.store_mall_directory_rounded,
            color: isAccepting ? Colors.green : Colors.orange,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAccepting ? 'Restaurant is Open' : 'Restaurant is Closed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isAccepting ? Colors.green.shade800 : Colors.orange.shade800,
                      ),
                ),
                Text(
                  isAccepting
                      ? 'Accepting new orders from customers'
                      : 'Not accepting new orders',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isAccepting ? Colors.green.shade600 : Colors.orange.shade600,
                      ),
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
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection(dashboardState) {
    final metrics = dashboardState.metrics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Performance",
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
          childAspectRatio: 1.4,
          children: [
            DashboardStatCard(
              title: "Orders",
              value: metrics?.todayOrders.toString() ?? '0',
              icon: Icons.receipt_long_rounded,
              color: Colors.blue,
              subtitle: 'Today',
              onTap: () => context.push(RoutePaths.restaurantOrders),
            ),
            DashboardStatCard(
              title: "Revenue",
              value: '\$${(metrics?.todayRevenue ?? 0).toStringAsFixed(0)}',
              icon: Icons.attach_money_rounded,
              color: Colors.green,
              subtitle: 'Today',
              onTap: () => context.push(RoutePaths.restaurantAnalytics),
            ),
            DashboardStatCard(
              title: 'Pending',
              value: (metrics?.pendingOrders ?? 0).toString(),
              icon: Icons.pending_actions_rounded,
              color: Colors.orange,
              subtitle: 'Orders',
              onTap: () => context.push('${RoutePaths.restaurantOrders}?status=pending'),
            ),
            DashboardStatCard(
              title: 'Avg Order',
              value: '\$${(metrics?.avgOrderValue ?? 0).toStringAsFixed(0)}',
              icon: Icons.trending_up_rounded,
              color: Colors.purple,
              subtitle: 'Value',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityActionsSection(bool isOwner, staffData) {
    String sectionTitle;
    List<Map<String, dynamic>> actions;

    if (isOwner) {
      sectionTitle = 'Owner Actions';
      actions = [
        {
          'icon': Icons.list_alt_rounded,
          'label': 'Manage Orders',
          'color': Colors.blue,
          'route': RoutePaths.restaurantOrders,
        },
        {
          'icon': Icons.restaurant_menu_rounded,
          'label': 'Edit Menu',
          'color': Colors.orange,
          'route': RoutePaths.restaurantMenu,
        },
        {
          'icon': Icons.people_rounded,
          'label': 'Staff Management',
          'color': Colors.purple,
          'route': '/restaurant/staff',
        },
        {
          'icon': Icons.analytics_rounded,
          'label': 'View Analytics',
          'color': Colors.green,
          'route': RoutePaths.restaurantAnalytics,
        },
      ];
    } else {
      final role = staffData?.role?.toLowerCase();
      sectionTitle = '${staffData?.role ?? 'Staff'} Actions';

      switch (role) {
        case 'chef':
          actions = [
            {
              'icon': Icons.restaurant_rounded,
              'label': 'Kitchen Display',
              'color': Colors.orange,
              'route': '/restaurant/kitchen',
            },
            {
              'icon': Icons.restaurant_menu_rounded,
              'label': 'Menu Items',
              'color': Colors.green,
              'route': RoutePaths.restaurantMenu,
            },
          ];
          break;
        case 'cashier':
          actions = [
            {
              'icon': Icons.list_alt_rounded,
              'label': 'Orders',
              'color': Colors.blue,
              'route': RoutePaths.restaurantOrders,
            },
            {
              'icon': Icons.point_of_sale_rounded,
              'label': 'Payments',
              'color': Colors.green,
              'route': '/restaurant/payments',
            },
          ];
          break;
        case 'server':
          actions = [
            {
              'icon': Icons.list_alt_rounded,
              'label': 'Active Orders',
              'color': Colors.blue,
              'route': RoutePaths.restaurantOrders,
            },
            {
              'icon': Icons.room_service_rounded,
              'label': 'Service',
              'color': Colors.purple,
              'route': '/restaurant/service',
            },
          ];
          break;
        default:
          actions = [
            {
              'icon': Icons.list_alt_rounded,
              'label': 'View Orders',
              'color': Colors.blue,
              'route': RoutePaths.restaurantOrders,
            },
          ];
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionTitle,
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
          childAspectRatio: 1.3,
          children: actions.map((action) {
            return _buildActionCard(
              action['label'],
              action['icon'],
              action['color'],
              () => context.push(action['route']),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionCard(
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
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

  Widget _buildPendingOrdersSection(dashboardState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ...dashboardState.pendingOrders.take(3).map((order) {
          return PendingOrderCard(
            order: order,
            onAccept: () => _acceptOrder(order.id),
            onReject: () => _rejectOrder(order.id),
            onViewDetails: () {
              // TODO: Navigate to order details
            },
          );
        }),
      ],
    );
  }

  Widget _buildTodayOverviewSection(dashboardState) {
    final metrics = dashboardState.metrics;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Overview",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  'Peak Hour',
                  metrics?.peakHour ?? '12-1 PM',
                  Icons.access_time_rounded,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Popular Item',
                  metrics?.popularItem ?? 'Loading...',
                  Icons.star_rounded,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewItem(
                  'Completion Rate',
                  '${metrics?.completionRate ?? 0}%',
                  Icons.check_circle_rounded,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildOverviewItem(
                  'Avg Prep Time',
                  '${metrics?.avgPrepTime ?? 0} min',
                  Icons.timer_rounded,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickToolsSection(bool isOwner) {
    final List<Map<String, dynamic>> tools = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'Add Menu Item',
        'color': Colors.green,
        'route': '${RoutePaths.restaurantMenu}/add',
      },
      {
        'icon': Icons.local_offer_outlined,
        'label': 'Create Promotion',
        'color': Colors.red,
        'route': '/restaurant/promotions/create',
      },
      {
        'icon': Icons.inventory_2_outlined,
        'label': 'Inventory',
        'color': Colors.brown,
        'route': '/restaurant/inventory',
      },
    ];

    if (isOwner) {
      tools.addAll([
        {
          'icon': Icons.bar_chart_outlined,
          'label': 'Reports',
          'color': Colors.indigo,
          'route': '/restaurant/reports',
        },
        {
          'icon': Icons.settings_outlined,
          'label': 'Settings',
          'color': Colors.grey,
          'route': RoutePaths.restaurantSettings,
        },
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Tools',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: tools.map((tool) {
            return _buildQuickToolChip(
              tool['label'],
              tool['icon'],
              tool['color'],
              () => context.push(tool['route']),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickToolChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(dashboardState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...dashboardState.recentOrders.take(5).map((order) {
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
              subtitle: Text('${order.status.name} • ${_formatTime(order.createdAt)}'),
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
    );
  }

  // Helper methods
  Future<void> _acceptOrder(String orderId) async {
    // TODO: Implement accept order logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order accepted'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _rejectOrder(String orderId) async {
    // TODO: Implement reject order logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order rejected'),
        backgroundColor: Colors.orange,
      ),
    );
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

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
  }
}