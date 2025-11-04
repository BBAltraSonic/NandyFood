import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/features/admin/presentation/providers/admin_stats_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Admin Dashboard Screen for system-wide management
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final statsState = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(adminStatsProvider);
            },
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.push(RoutePaths.adminSettings);
                  break;
                case 'logout':
                  _handleLogout(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: statsState.when(
        data: (stats) => _buildDashboardContent(context, ref, stats),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => _buildErrorView(context, error),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> stats,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(adminStatsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            _buildWelcomeHeader(context, ref, stats),
            const SizedBox(height: 24),

            // Key Metrics Cards
            _buildMetricsSection(context, stats),
            const SizedBox(height: 24),

            // Quick Actions
            _buildQuickActionsSection(context),
            const SizedBox(height: 24),

            // Recent Activity
            _buildRecentActivitySection(context, stats),
            const SizedBox(height: 24),

            // System Health
            _buildSystemHealthSection(context, stats),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, WidgetRef ref, Map<String, dynamic> stats) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.userMetadata?['full_name'] ?? 'Admin';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BrandColors.primary, BrandColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShadowTokens.shadowMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $userName!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your food delivery platform',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatChip('Active Users', '${stats['activeUsers'] ?? 0}'),
              const SizedBox(width: 12),
              _buildStatChip('Online Restaurants', '${stats['activeRestaurants'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildMetricCard(
              context,
              'Today\'s Orders',
              '${stats['todayOrders'] ?? 0}',
              Icons.shopping_cart,
              Colors.green,
              '↑ 12% from yesterday',
            ),
            _buildMetricCard(
              context,
              'Today\'s Revenue',
              'R${stats['todayRevenue'] ?? 0}',
              Icons.attach_money,
              Colors.blue,
              '↑ 8% from yesterday',
            ),
            _buildMetricCard(
              context,
              'Total Users',
              '${stats['totalUsers'] ?? 0}',
              Icons.people,
              Colors.orange,
              '↑ 15% this month',
            ),
            _buildMetricCard(
              context,
              'Active Restaurants',
              '${stats['totalRestaurants'] ?? 0}',
              Icons.store,
              Colors.purple,
              '↑ 5% this week',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(color: NeutralColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: NeutralColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: NeutralColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildActionCard(
              context,
              'Users',
              Icons.people,
              Colors.blue,
              () => context.push(RoutePaths.adminUsers),
            ),
            _buildActionCard(
              context,
              'Restaurants',
              Icons.store,
              Colors.purple,
              () => context.push(RoutePaths.adminRestaurants),
            ),
            _buildActionCard(
              context,
              'Orders',
              Icons.shopping_cart,
              Colors.green,
              () => context.push(RoutePaths.adminOrders),
            ),
            _buildActionCard(
              context,
              'Analytics',
              Icons.analytics,
              Colors.orange,
              () => context.push(RoutePaths.adminAnalytics),
            ),
            _buildActionCard(
              context,
              'Support',
              Icons.support_agent,
              Colors.red,
              () => context.push(RoutePaths.adminSupport),
            ),
            _buildActionCard(
              context,
              'Settings',
              Icons.settings,
              Colors.grey,
              () => context.push(RoutePaths.adminSettings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NeutralColors.gray200),
          boxShadow: ShadowTokens.shadowSm,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                context.push(RoutePaths.adminOrders);
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ShadowTokens.shadowSm,
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'New order #12345',
                'Pizza Palace - R125.00',
                Icons.shopping_cart,
                Colors.green,
                '2 min ago',
              ),
              const Divider(),
              _buildActivityItem(
                'New restaurant registered',
                'Burger Barn - Johannesburg',
                Icons.store,
                Colors.purple,
                '15 min ago',
              ),
              const Divider(),
              _buildActivityItem(
                'User support request',
                'Order delivery issue',
                Icons.support_agent,
                Colors.orange,
                '1 hour ago',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String time,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: NeutralColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSystemHealthSection(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Health',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ShadowTokens.shadowSm,
          ),
          child: Column(
            children: [
              _buildHealthItem('Database', 'Connected', Colors.green),
              const Divider(),
              _buildHealthItem('API Server', 'Operational', Colors.green),
              const Divider(),
              _buildHealthItem('Payment Gateway', 'Operational', Colors.green),
              const Divider(),
              _buildHealthItem('Notifications', 'Operational', Colors.green),
              const Divider(),
              _buildHealthItem('Storage', '85% Used', Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthItem(String title, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh the data
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}