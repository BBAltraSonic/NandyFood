import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';
import 'package:food_delivery_app/shared/widgets/order_card_widget.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

class DeliveryStatusScreen extends ConsumerStatefulWidget {
  const DeliveryStatusScreen({super.key});

  @override
  ConsumerState<DeliveryStatusScreen> createState() =>
      _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState extends ConsumerState<DeliveryStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.sageBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Status',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track your orders in real-time',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.oliveGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'History'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildActiveOrdersTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Order> _activeOrders = const [];
  List<Order> _orderHistory = const [];
  bool _loading = true;
  String? _error;

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (!DatabaseService().isInitialized) return;
      final user = DatabaseService().client.auth.currentUser;
      if (user == null) return;

      final data = await DatabaseService().getUserOrders(user.id);
      final orders = data.map((e) => Order.fromJson(e)).toList();
      final active = orders.where((o) => o.status != OrderStatus.delivered && o.status != OrderStatus.cancelled).toList();
      final history = orders.where((o) => o.status == OrderStatus.delivered || o.status == OrderStatus.cancelled).toList();

      setState(() {
        _activeOrders = active;
        _orderHistory = history;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Widget _buildActiveOrdersTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final activeOrders = _activeOrders;

    if (activeOrders.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'No Active Deliveries',
        message: 'You don\'t have any orders in progress',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) {
        final order = activeOrders[index];
        return OrderCardWidget(
          order: order,
          restaurantName: null,
          onTap: () {
            context.push('/order/track', extra: order);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final orderHistory = _orderHistory;

    if (orderHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No Order History',
        message: 'Your past orders will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        return OrderCardWidget(
          order: order,
          restaurantName: null,
          onTap: () {
            context.push('/order/track', extra: order);
          },
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.warmCream,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: AppTheme.oliveGreen.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                context.go('/home');
              },
              child: const Text('Start Ordering'),
            ),
          ],
        ),
      ),
    );
  }
}
