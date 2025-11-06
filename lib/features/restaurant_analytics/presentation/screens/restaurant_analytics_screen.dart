import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Restaurant analytics screen with business insights
class RestaurantAnalyticsScreen extends ConsumerStatefulWidget {
  const RestaurantAnalyticsScreen({super.key});

  @override
  ConsumerState<RestaurantAnalyticsScreen> createState() =>
      _RestaurantAnalyticsScreenState();
}

class _RestaurantAnalyticsScreenState extends ConsumerState<RestaurantAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'Today';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            const Tab(text: 'Overview'),
            const Tab(text: 'Sales'),
            const Tab(text: 'Items'),
            if (isOwner) const Tab(text: 'Customers'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Today', child: Text('Today')),
              const PopupMenuItem(value: 'Week', child: Text('This Week')),
              const PopupMenuItem(value: 'Month', child: Text('This Month')),
              const PopupMenuItem(value: 'Year', child: Text('This Year')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Period: '),
                  Text(
                    _selectedPeriod,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _exportReports(),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildSalesTab(),
          _buildItemsTab(),
          if (isOwner) _buildCustomersTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDetailedReport(),
        icon: const Icon(Icons.analytics),
        label: const Text('Detailed Report'),
        backgroundColor: AppTheme.primaryBlack,
      ),
    );
  }

  String _getScreenTitle(UserRoleType role, staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return 'Business Analytics';
      case UserRoleType.restaurantStaff:
        final staffRole = staffData?.role?.toLowerCase();
        switch (staffRole) {
          case 'chef':
            return 'Kitchen Analytics';
          case 'cashier':
            return 'Sales Analytics';
          case 'manager':
            return 'Performance Analytics';
          default:
            return 'Analytics';
        }
      default:
        return 'Analytics';
    }
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics cards
          _buildKeyMetricsGrid(),
          const SizedBox(height: 24),

          // Revenue chart placeholder
          _buildRevenueChart(),
          const SizedBox(height: 24),

          // Quick insights
          _buildQuickInsights(),
          const SizedBox(height: 24),

          // Performance indicators
          _buildPerformanceIndicators(),
        ],
      ),
    );
  }

  Widget _buildSalesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSalesMetrics(),
          const SizedBox(height: 24),
          _buildSalesChart(),
          const SizedBox(height: 24),
          _buildPeakHoursAnalysis(),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopPerformingItems(),
          const SizedBox(height: 24),
          _buildItemCategoriesAnalysis(),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomerMetrics(),
          const SizedBox(height: 24),
          _buildCustomerRetention(),
          const SizedBox(height: 24),
          _buildTopCustomers(),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics - $_selectedPeriod',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            _buildMetricCard(
              'Total Revenue',
              '\$2,847',
              Icons.attach_money,
              Colors.green,
              '+12.5%',
              true,
            ),
            _buildMetricCard(
              'Total Orders',
              '156',
              Icons.receipt_long,
              Colors.blue,
              '+8.3%',
              true,
            ),
            _buildMetricCard(
              'Average Order',
              '\$18.25',
              Icons.trending_up,
              Colors.orange,
              '+2.1%',
              true,
            ),
            _buildMetricCard(
              'Customers',
              '89',
              Icons.people,
              Colors.purple,
              '+15.2%',
              true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    bool isPositive,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insert_chart, size: 48, color: Colors.grey),
                  Text('Revenue Chart'),
                  Text('(Chart integration needed)'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Insights',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            'Peak Hours',
            '12:00 PM - 2:00 PM',
            'Most orders during lunch rush',
            Icons.schedule,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Popular Item',
            'Classic Burger',
            'Sold 45 times today',
            Icons.star,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            'Customer Rating',
            '4.8/5.0',
            'Based on 23 reviews today',
            Icons.thumb_up,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, String description, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          description,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Indicators',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildPerformanceIndicator('Order Completion Rate', '94%', 0.94, Colors.green),
        const SizedBox(height: 12),
        _buildPerformanceIndicator('Average Prep Time', '18 min', 0.75, Colors.orange),
        const SizedBox(height: 12),
        _buildPerformanceIndicator('Customer Satisfaction', '4.8/5', 0.96, Colors.blue),
      ],
    );
  }

  Widget _buildPerformanceIndicator(String label, String value, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesMetrics() {
    // Placeholder for sales metrics
    return const Center(
      child: Text('Sales metrics coming soon...'),
    );
  }

  Widget _buildSalesChart() {
    // Placeholder for sales chart
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Text('Sales Chart')),
    );
  }

  Widget _buildPeakHoursAnalysis() {
    // Placeholder for peak hours analysis
    return const Center(
      child: Text('Peak hours analysis coming soon...'),
    );
  }

  Widget _buildTopPerformingItems() {
    // Placeholder for top performing items
    return const Center(
      child: Text('Top performing items coming soon...'),
    );
  }

  Widget _buildItemCategoriesAnalysis() {
    // Placeholder for item categories analysis
    return const Center(
      child: Text('Item categories analysis coming soon...'),
    );
  }

  Widget _buildCustomerMetrics() {
    // Placeholder for customer metrics
    return const Center(
      child: Text('Customer metrics coming soon...'),
    );
  }

  Widget _buildCustomerRetention() {
    // Placeholder for customer retention
    return const Center(
      child: Text('Customer retention analysis coming soon...'),
    );
  }

  Widget _buildTopCustomers() {
    // Placeholder for top customers
    return const Center(
      child: Text('Top customers coming soon...'),
    );
  }

  void _exportReports() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Reports'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose export format and date range'),
            SizedBox(height: 16),
            // Add format and date selection widgets
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting reports...')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDetailedReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detailed Report'),
        content: const Text('Generate comprehensive business report with all metrics and insights.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating detailed report...')),
              );
            },
            child: const Text('Generate'),
          ),
        ],
      ),
    );
  }
}