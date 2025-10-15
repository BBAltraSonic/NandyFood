import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/providers/analytics_provider.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/widgets/sales_chart.dart';

/// Restaurant analytics dashboard screen
class RestaurantAnalyticsScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantAnalyticsScreen({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  ConsumerState<RestaurantAnalyticsScreen> createState() =>
      _RestaurantAnalyticsScreenState();
}

class _RestaurantAnalyticsScreenState
    extends ConsumerState<RestaurantAnalyticsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));

    // Load analytics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadDashboardAnalytics(
            widget.restaurantId,
            startDate: _startDate,
            endDate: _endDate,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref
                  .read(analyticsProvider.notifier)
                  .refresh(widget.restaurantId);
            },
          ),
        ],
      ),
      body: analyticsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : analyticsState.errorMessage != null
              ? _buildErrorState(analyticsState.errorMessage!)
              : analyticsState.dashboardAnalytics == null
                  ? const Center(child: Text('No analytics data available'))
                  : _buildAnalyticsContent(analyticsState.dashboardAnalytics!),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(analyticsProvider.notifier)
                  .refresh(widget.restaurantId);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent(analytics) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(analyticsProvider.notifier).refresh(widget.restaurantId);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range display
            _buildDateRangeCard(),
            const SizedBox(height: 16),

            // Key metrics
            _buildKeyMetrics(analytics),
            const SizedBox(height: 24),

            // Sales chart
            SalesChart(
              salesByDay: analytics.salesAnalytics.salesByDay,
              title: 'Sales Overview',
              lineColor: Colors.green,
            ),
            const SizedBox(height: 16),

            // Revenue pie chart
            RevenuePieChart(
              grossRevenue: analytics.revenueAnalytics.grossRevenue,
              platformFees: analytics.revenueAnalytics.platformFees,
              deliveryFees: analytics.revenueAnalytics.deliveryFees,
            ),
            const SizedBox(height: 16),

            // Customer metrics
            _buildCustomerMetrics(analytics.customerAnalytics),
            const SizedBox(height: 16),

            // Peak hours chart
            PeakHoursChart(
              peakHoursData: analytics.peakHours,
            ),
            const SizedBox(height: 16),

            // Top menu items
            _buildTopMenuItems(analytics.topItems),
            const SizedBox(height: 16),

            // Order status breakdown
            _buildOrderStatusBreakdown(analytics.orderStatusBreakdown),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showDateRangePicker(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetrics(analytics) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Total Sales',
            'R${analytics.salesAnalytics.totalSales.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Total Orders',
            analytics.salesAnalytics.totalOrders.toString(),
            Icons.shopping_bag,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerMetrics(customerAnalytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCustomerStat(
                  'Total',
                  customerAnalytics.totalCustomers.toString(),
                ),
                _buildCustomerStat(
                  'New',
                  customerAnalytics.newCustomers.toString(),
                ),
                _buildCustomerStat(
                  'Returning',
                  customerAnalytics.returningCustomers.toString(),
                ),
                _buildCustomerStat(
                  'Repeat Rate',
                  '${(customerAnalytics.repeatRate * 100).toStringAsFixed(1)}%',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTopMenuItems(List topItems) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Menu Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (topItems.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No menu item data available'),
                ),
              )
            else
              ...topItems.take(5).map((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text('${topItems.indexOf(item) + 1}'),
                  ),
                  title: Text(item.itemName),
                  subtitle: Text('${item.totalOrders} orders'),
                  trailing: Text(
                    'R${item.totalRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusBreakdown(orderStatusBreakdown) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Pending', orderStatusBreakdown.pending, Colors.orange),
            _buildStatusRow('Confirmed', orderStatusBreakdown.confirmed, Colors.blue),
            _buildStatusRow('Preparing', orderStatusBreakdown.preparing, Colors.purple),
            _buildStatusRow('Delivered', orderStatusBreakdown.delivered, Colors.green),
            _buildStatusRow('Cancelled', orderStatusBreakdown.cancelled, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate!,
        end: _endDate!,
      ),
    );

    if (picked != null && mounted) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      ref.read(analyticsProvider.notifier).updateDateRange(
            widget.restaurantId,
            picked.start,
            picked.end,
          );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
