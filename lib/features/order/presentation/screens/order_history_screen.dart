import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/features/delivery/presentation/providers/delivery_orders_provider.dart';
import 'package:food_delivery_app/shared/widgets/order_history_item_widget.dart';
import 'package:food_delivery_app/shared/models/order.dart';

enum OrderFilter {
  all,
  active,
  completed,
  cancelled,
}

enum OrderSort {
  newest,
  oldest,
  highestAmount,
  lowestAmount,
}

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  OrderFilter _selectedFilter = OrderFilter.all;
  OrderSort _selectedSort = OrderSort.newest;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(deliveryOrdersProvider);
    final notifier = ref.read(deliveryOrdersProvider.notifier);

    // Filter orders based on selection
    final filteredOrders = _filterOrders(ordersState.historyOrders);

    // Sort orders based on selection
    final sortedOrders = _sortOrders(filteredOrders);

    if (!ordersState.isLoadingHistory && sortedOrders.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History'), centerTitle: true),
        body: _buildEmptyState(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        centerTitle: true,
        bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildTabBar(),
      ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          PopupMenuButton<OrderSort>(
            icon: const Icon(Icons.sort),
            onSelected: (OrderSort sort) {
              setState(() {
                _selectedSort = sort;
              });
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: OrderSort.newest,
                  child: ListTile(
                    leading: Icon(Icons.new_releases),
                    title: Text('Newest First'),
                  ),
                ),
                const PopupMenuItem(
                  value: OrderSort.oldest,
                  child: ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Oldest First'),
                  ),
                ),
                const PopupMenuItem(
                  value: OrderSort.highestAmount,
                  child: ListTile(
                    leading: Icon(Icons.arrow_upward),
                    title: Text('Highest Amount'),
                  ),
                ),
                const PopupMenuItem(
                  value: OrderSort.lowestAmount,
                  child: ListTile(
                    leading: Icon(Icons.arrow_downward),
                    title: Text('Lowest Amount'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await notifier.refreshHistoryOrders();
        },
        child: Column(
          children: [
            // Search bar (if search is active)
            if (_searchQuery.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Searching for: "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Summary stats
            _buildSummaryStats(sortedOrders),

            // Orders list
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 200 &&
                      !ordersState.isLoadingHistory) {
                    notifier.loadMoreHistory();
                  }
                  return false;
                },
                child: ListView.builder(
                  itemCount: sortedOrders.length + 1,
                  itemBuilder: (context, index) {
                    if (index < sortedOrders.length) {
                      final order = sortedOrders[index];
                      return _buildOrderItem(context, order, notifier);
                    }

                    // Footer: loading spinner or Load More button
                    if (ordersState.isLoadingHistory) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: OutlinedButton(
                          onPressed: () => notifier.loadMoreHistory(),
                          child: const Text('Load more'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No orders found matching "$_searchQuery"'
                  : 'No past orders yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                child: const Text('Clear search'),
              )
            else
              TextButton(
                onPressed: () => context.go(RoutePaths.home),
                child: const Text('Browse restaurants'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: OrderFilter.values.map((filter) {
            final isSelected = _selectedFilter == filter;
            final count = _getFilterCount(filter);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getFilterLabel(filter)),
                backgroundColor: isSelected
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade700,
                ),
                checkmarkColor: Theme.of(context).primaryColor,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryStats(List<Order> orders) {
    if (orders.isEmpty) return const SizedBox.shrink();

    final totalAmount = orders.fold<double>(
      0, (sum, order) => sum + order.totalAmount
    );
    final completedOrders = orders.where(
      (order) => order.status.name.toLowerCase() == 'delivered'
    ).length;
    final avgOrderValue = completedOrders > 0
        ? totalAmount / completedOrders
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Orders', orders.length.toString()),
              _buildStatItem('Completed', completedOrders.toString()),
              _buildStatItem('Total Spent', 'R${totalAmount.toStringAsFixed(0)}'),
            ],
          ),
          if (completedOrders > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 4),
            Text(
              'Average order value: R${avgOrderValue.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order, dynamic notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OrderHistoryItemWidget(
            order: order,
            onTap: () {
              // Navigate to unified order tracking
              context.push('${RoutePaths.orderTrack}?orderId=${order.id}');
            },
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status.name),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order.status.name.toLowerCase() == 'delivered')
                    TextButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                      label: const Text('Reorder', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final newOrderId = await notifier.reorder(order.id);
                        if (newOrderId != null && context.mounted) {
                          context.push('${RoutePaths.orderTrack}?orderId=$newOrderId');
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to reorder. Please try again.')),
                          );
                        }
                      },
                    ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      context.push('${RoutePaths.orderTrack}?orderId=${order.id}');
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFilterLabel(OrderFilter filter) {
    switch (filter) {
      case OrderFilter.all:
        return 'All';
      case OrderFilter.active:
        return 'Active';
      case OrderFilter.completed:
        return 'Completed';
      case OrderFilter.cancelled:
        return 'Cancelled';
    }
  }

  int _getFilterCount(OrderFilter filter) {
    final ordersState = ref.read(deliveryOrdersProvider);
    switch (filter) {
      case OrderFilter.all:
        return ordersState.historyOrders.length;
      case OrderFilter.active:
        return ordersState.historyOrders.where((order) =>
          ['placed', 'confirmed', 'preparing', 'ready', 'picked_up', 'on_the_way']
              .contains(order.status.name.toLowerCase())
        ).length;
      case OrderFilter.completed:
        return ordersState.historyOrders.where((order) =>
          order.status.name.toLowerCase() == 'delivered'
        ).length;
      case OrderFilter.cancelled:
        return ordersState.historyOrders.where((order) =>
          order.status.name.toLowerCase() == 'cancelled'
        ).length;
    }
  }

  List<Order> _filterOrders(List<Order> orders) {
    List<Order> filtered = List.from(orders);

    // Apply status filter
    switch (_selectedFilter) {
      case OrderFilter.active:
        filtered = filtered.where((order) =>
          ['placed', 'confirmed', 'preparing', 'ready', 'picked_up', 'on_the_way']
              .contains(order.status.name.toLowerCase())
        ).toList();
        break;
      case OrderFilter.completed:
        filtered = filtered.where((order) =>
          order.status.name.toLowerCase() == 'delivered'
        ).toList();
        break;
      case OrderFilter.cancelled:
        filtered = filtered.where((order) =>
          order.status.name.toLowerCase() == 'cancelled'
        ).toList();
        break;
      case OrderFilter.all:
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) =>
          order.restaurantName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false ||
          order.id.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    return filtered;
  }

  List<Order> _sortOrders(List<Order> orders) {
    List<Order> sorted = List.from(orders);

    switch (_selectedSort) {
      case OrderSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case OrderSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case OrderSort.highestAmount:
        sorted.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case OrderSort.lowestAmount:
        sorted.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
    }

    return sorted;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
      case 'ready':
        return Colors.orange;
      case 'picked_up':
      case 'on_the_way':
      case 'nearby':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Orders'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter restaurant name or order ID...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (value) {
            setState(() {
              _searchQuery = value;
            });
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
