import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:food_delivery_app/features/admin/presentation/providers/admin_stats_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Admin Analytics Screen for platform-wide analytics and reporting
class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30d'; // 7d, 30d, 90d, 1y

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
    final analyticsState = ref.watch(adminAnalyticsProvider);
    final statsState = ref.watch(adminStatsProvider);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('Platform Analytics'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          PopupMenuButton<String>(
            onSelected: (period) {
              setState(() {
                _selectedPeriod = period;
              });
              ref.refresh(adminAnalyticsProvider);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: '7d',
                child: Text('Last 7 Days'),
              ),
              const PopupMenuItem(
                value: '30d',
                child: Text('Last 30 Days'),
              ),
              const PopupMenuItem(
                value: '90d',
                child: Text('Last 90 Days'),
              ),
              const PopupMenuItem(
                value: '1y',
                child: Text('Last Year'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: NeutralColors.gray300),
                borderRadius: BorderRadiusTokens.borderRadiusMd,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getPeriodDisplayText(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(adminAnalyticsProvider);
              ref.refresh(adminStatsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Revenue'),
                Tab(text: 'Orders'),
                Tab(text: 'Users'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(analyticsState, statsState),
                _buildRevenueTab(analyticsState),
                _buildOrdersTab(analyticsState),
                _buildUsersTab(analyticsState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AsyncValue<Map<String, dynamic>> analyticsState, AsyncValue<Map<String, dynamic>> statsState) {
    return analyticsState.when(
      data: (analytics) => statsState.when(
        data: (stats) => _buildOverviewContent(analytics, stats),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => _buildErrorView(error),
      ),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => _buildErrorView(error),
    );
  }

  Widget _buildOverviewContent(Map<String, dynamic> analytics, Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          _buildKeyMetricsSection(analytics, stats),
          const SizedBox(height: 24),

          // Revenue Chart
          _buildRevenueChart(analytics),
          const SizedBox(height: 24),

          // Growth Indicators
          _buildGrowthIndicators(analytics),
          const SizedBox(height: 24),

          // Top Restaurants
          _buildTopRestaurantsSection(analytics),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivitySection(analytics),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection(Map<String, dynamic> analytics, Map<String, dynamic> stats) {
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
              'Total Revenue',
              'R${(analytics['monthlyRevenue'] as int? ?? 0).toString()}',
              Icons.attach_money,
              Colors.green,
              analytics['monthlyGrowth']?['revenue'] ?? '+0%',
            ),
            _buildMetricCard(
              'Total Orders',
              '${analytics['totalOrders'] ?? 0}',
              Icons.shopping_cart,
              Colors.blue,
              analytics['monthlyGrowth']?['orders'] ?? '+0%',
            ),
            _buildMetricCard(
              'Active Users',
              '${stats['activeUsers'] ?? 0}',
              Icons.people,
              Colors.orange,
              analytics['monthlyGrowth']?['users'] ?? '+0%',
            ),
            _buildMetricCard(
              'Restaurants',
              '${stats['totalRestaurants'] ?? 0}',
              Icons.store,
              Colors.purple,
              analytics['monthlyGrowth']?['restaurants'] ?? '+0%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String growth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
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
                  borderRadius: BorderRadiusTokens.borderRadiusMd,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
                ),
                child: Text(
                  growth,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
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

  Widget _buildRevenueChart(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: NeutralColors.gray200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: NeutralColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'R${value.toInt()}',
                          style: TextStyle(
                            color: NeutralColors.textSecondary,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateRevenueSpots(),
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        BrandColors.primary.withValues(alpha: 0.8),
                        BrandColors.primary.withValues(alpha: 0.2),
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          BrandColors.primary.withValues(alpha: 0.3),
                          BrandColors.primary.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 10000,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthIndicators(Map<String, dynamic> analytics) {
    final growth = analytics['monthlyGrowth'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Growth',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildGrowthItem(
                  'Revenue',
                  growth['revenue'] ?? '+0%',
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildGrowthItem(
                  'Orders',
                  growth['orders'] ?? '+0%',
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildGrowthItem(
                  'Users',
                  growth['users'] ?? '+0%',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildGrowthItem(
                  'Restaurants',
                  growth['restaurants'] ?? '+0%',
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthItem(String label, String growth, Color color) {
    final isPositive = growth.startsWith('+');

    return Column(
      children: [
        Icon(
          isPositive ? Icons.trending_up : Icons.trending_down,
          color: isPositive ? color : SemanticColors.error,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          growth,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isPositive ? color : SemanticColors.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: NeutralColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTopRestaurantsSection(Map<String, dynamic> analytics) {
    final topRestaurants = analytics['topRestaurants'] as List? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Restaurants by Revenue',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (topRestaurants.isEmpty)
            Text(
              'No restaurant data available',
              style: TextStyle(
                color: NeutralColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Column(
              children: topRestaurants.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final restaurant = entry.value;
                final restaurantData = restaurant['restaurants'] as Map<String, dynamic>?;
                final name = restaurantData?['name'] as String? ?? 'Unknown Restaurant';
                final revenue = (restaurant['total_amount'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getRankColor(index),
                          borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'R${revenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey;
      case 2:
        return Colors.brown;
      default:
        return BrandColors.primary;
    }
  }

  Widget _buildRecentActivitySection(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'New order placed',
            '2 minutes ago',
            Icons.shopping_cart,
            SemanticColors.success,
          ),
          const Divider(),
          _buildActivityItem(
            'New restaurant registered',
            '15 minutes ago',
            Icons.store,
            BrandColors.primary,
          ),
          const Divider(),
          _buildActivityItem(
            'User support request',
            '1 hour ago',
            Icons.support_agent,
            SemanticColors.warning,
          ),
          const Divider(),
          _buildActivityItem(
            'Payment received',
            '2 hours ago',
            Icons.payment,
            SemanticColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
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
      trailing: Text(
        time,
        style: TextStyle(
          fontSize: 12,
          color: NeutralColors.textSecondary,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildRevenueTab(AsyncValue<Map<String, dynamic>> analyticsState) {
    return analyticsState.when(
      data: (analytics) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildRevenueMetrics(analytics),
            const SizedBox(height: 24),
            _buildRevenueBreakdownChart(analytics),
            const SizedBox(height: 24),
            _buildRevenueTable(analytics),
          ],
        ),
      ),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => _buildErrorView(error),
    );
  }

  Widget _buildOrdersTab(AsyncValue<Map<String, dynamic>> analyticsState) {
    return analyticsState.when(
      data: (analytics) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildOrderStatusChart(analytics),
            const SizedBox(height: 24),
            _buildOrderMetrics(analytics),
          ],
        ),
      ),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => _buildErrorView(error),
    );
  }

  Widget _buildUsersTab(AsyncValue<Map<String, dynamic>> analyticsState) {
    return analyticsState.when(
      data: (analytics) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserMetrics(analytics),
            const SizedBox(height: 24),
            _buildUserGrowthChart(analytics),
          ],
        ),
      ),
      loading: () => const LoadingIndicator(),
      error: (error, stack) => _buildErrorView(error),
    );
  }

  Widget _buildRevenueMetrics(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('Total Revenue', 'R${analytics['monthlyRevenue'] ?? 0}'),
              ),
              Expanded(
                child: _buildMetricTile('Avg Order Value', 'R${analytics['averageOrderValue'] ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownChart(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Breakdown',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: _generatePieSections(),
                centerSpaceRadius: 60,
                sectionsSpace: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTable(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Add table widget here
          Text(
            'Detailed revenue table coming soon',
            style: TextStyle(
              color: NeutralColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChart(Map<String, dynamic> analytics) {
    final statusBreakdown = analytics['orderStatusBreakdown'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Status Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: NeutralColors.gray800,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final status = statusBreakdown.keys.elementAt(group.x.toInt());
                      final value = statusBreakdown[status] ?? 0;
                      return BarTooltipItem(
                        '$status: $value',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < statusBreakdown.keys.length) {
                          final status = statusBreakdown.keys.elementAt(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              status.toString().substring(0, 3).toUpperCase(),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: statusBreakdown.entries.map((entry) {
                  return BarChartGroupData(
                    x: statusBreakdown.keys.toList().indexOf(entry.key),
                    barRods: [
                      BarChartRodData(
                        toY: (entry.value as int? ?? 0).toDouble(),
                        color: _getStatusColor(entry.key as String),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMetrics(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('Total Orders', '${analytics['totalOrders'] ?? 0}'),
              ),
              Expanded(
                child: _buildMetricTile('Avg Order Value', 'R${analytics['averageOrderValue'] ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserMetrics(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile('New Users', '${analytics['newUsers'] ?? 0}'),
              ),
              Expanded(
                child: _buildMetricTile('New Restaurants', '${analytics['newRestaurants'] ?? 0}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserGrowthChart(Map<String, dynamic> analytics) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Growth Trend',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: NeutralColors.textSecondary,
                              fontSize: 12,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateUserGrowthSpots(),
                    isCurved: true,
                    color: BrandColors.secondary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: BrandColors.secondary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                  ),
                ],
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: BrandColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: NeutralColors.textSecondary,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateRevenueSpots() {
    // Generate sample data for the past 7 days
    return [
      const FlSpot(0, 3000),
      const FlSpot(1, 4500),
      const FlSpot(2, 5200),
      const FlSpot(3, 4800),
      const FlSpot(4, 6100),
      const FlSpot(5, 7500),
      const FlSpot(6, 8200),
    ];
  }

  List<FlSpot> _generateUserGrowthSpots() {
    // Generate sample user growth data
    return [
      const FlSpot(0, 20),
      const FlSpot(1, 35),
      const FlSpot(2, 28),
      const FlSpot(3, 42),
      const FlSpot(4, 38),
      const FlSpot(5, 55),
      const FlSpot(6, 48),
    ];
  }

  List<PieChartSectionData> _generatePieSections() {
    return [
      PieChartSectionData(
        color: BrandColors.primary,
        value: 35,
        title: '35%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: BrandColors.secondary,
        value: 25,
        title: '25%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: BrandColors.accent,
        value: 20,
        title: '20%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: NeutralColors.gray400,
        value: 20,
        title: '20%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  String _getPeriodDisplayText() {
    switch (_selectedPeriod) {
      case '7d':
        return 'Last 7 Days';
      case '30d':
        return 'Last 30 Days';
      case '90d':
        return 'Last 90 Days';
      case '1y':
        return 'Last Year';
      default:
        return 'Last 30 Days';
    }
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: SemanticColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
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
                ref.refresh(adminAnalyticsProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready_for_pickup':
        return Colors.teal;
      case 'out_for_delivery':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}