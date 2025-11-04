import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/features/admin/presentation/providers/admin_stats_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Admin Orders Screen for managing all platform orders
class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  DateTimeRange? _dateRange;
  String? _selectedRestaurant;
  late TabController _tabController;

  final List<String> _orderStatuses = [
    'all',
    'pending',
    'confirmed',
    'preparing',
    'ready',
    'completed',
    'cancelled',
    'refunded',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _orderStatuses.length, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(adminOrdersProvider);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('Order Management'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(adminOrdersProvider);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportOrders,
            tooltip: 'Export Orders',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _orderStatuses.map((status) {
            return Tab(
              text: status.capitalizeFirst(),
            );
          }).toList(),
          onTap: (index) {
            setState(() {
              _selectedStatus = _orderStatuses[index];
            });
          },
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: ordersState.when(
              data: (orders) => _buildOrdersList(orders),
              loading: () => const LoadingIndicator(),
              error: (error, stack) => _buildErrorView(error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders by ID, customer, or restaurant...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadiusTokens.borderRadiusMd,
                borderSide: BorderSide(color: NeutralColors.gray300),
              ),
              filled: true,
              fillColor: NeutralColors.gray50,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: NeutralColors.gray300),
                      borderRadius: BorderRadiusTokens.borderRadiusMd,
                      color: NeutralColors.gray50,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, color: NeutralColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _dateRange != null
                                ? '${DateFormat('MMM dd').format(_dateRange!.start)} - ${DateFormat('MMM dd').format(_dateRange!.end)}'
                                : 'Select date range',
                            style: TextStyle(
                              color: _dateRange != null ? NeutralColors.textPrimary : NeutralColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_dateRange != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _dateRange = null;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Map<String, dynamic>> orders) {
    final filteredOrders = _filterOrders(orders);

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: NeutralColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: NeutralColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NeutralColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(adminOrdersProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredOrders.length,
        itemBuilder: (context, index) {
          final order = filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterOrders(List<Map<String, dynamic>> orders) {
    var filtered = orders.where((order) {
      final searchQuery = _searchController.text.toLowerCase();
      final orderId = (order['id'] as String? ?? '').toLowerCase();
      final customer = order['user_profiles'] as Map<String, dynamic>? ?? {};
      final customerName = (customer['full_name'] as String? ?? '').toLowerCase();
      final restaurant = order['restaurants'] as Map<String, dynamic>? ?? {};
      final restaurantName = (restaurant['name'] as String? ?? '').toLowerCase();

      final matchesSearch = orderId.contains(searchQuery) ||
                           customerName.contains(searchQuery) ||
                           restaurantName.contains(searchQuery);

      bool matchesStatus = true;
      if (_selectedStatus != 'all') {
        matchesStatus = (order['status'] as String? ?? '') == _selectedStatus;
      }

      bool matchesDateRange = true;
      if (_dateRange != null) {
        final orderDate = DateTime.parse(order['created_at'] as String? ?? DateTime.now().toIso8601String());
        matchesDateRange = !orderDate.isBefore(_dateRange!.start) && !orderDate.isAfter(_dateRange!.end);
      }

      bool matchesRestaurant = true;
      if (_selectedRestaurant != null) {
        matchesRestaurant = (order['restaurant_id'] as String? ?? '') == _selectedRestaurant;
      }

      return matchesSearch && matchesStatus && matchesDateRange && matchesRestaurant;
    }).toList();

    return filtered;
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
    final createdAt = DateTime.parse(order['created_at'] as String? ?? DateTime.now().toIso8601String());
    final customer = order['user_profiles'] as Map<String, dynamic>? ?? {};
    final customerName = customer['full_name'] as String? ?? 'Unknown Customer';
    final restaurant = order['restaurants'] as Map<String, dynamic>? ?? {};
    final restaurantName = restaurant['name'] as String? ?? 'Unknown Restaurant';
    final estimatedPrepTime = order['estimated_preparation_time'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(color: NeutralColors.gray200),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadiusTokens.borderRadiusMd,
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: NeutralColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurantName,
                          style: TextStyle(
                            fontSize: 14,
                            color: NeutralColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R${totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: NeutralColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customerName,
                      style: TextStyle(
                        fontSize: 14,
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: NeutralColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatOrderTime(createdAt),
                    style: TextStyle(
                      fontSize: 14,
                      color: NeutralColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (estimatedPrepTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: NeutralColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Est. prep time: $estimatedPrepTime min',
                      style: TextStyle(
                        fontSize: 14,
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      _handleOrderAction(value, order);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility),
                            const SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (status == 'pending')
                        PopupMenuItem(
                          value: 'confirm',
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: SemanticColors.success),
                              const SizedBox(width: 8),
                              Text('Confirm Order', style: TextStyle(color: SemanticColors.success)),
                            ],
                          ),
                        ),
                      if (status == 'confirmed')
                        PopupMenuItem(
                          value: 'prepare',
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant, color: BrandColors.primary),
                              const SizedBox(width: 8),
                              Text('Start Preparation'),
                            ],
                          ),
                        ),
                      if (status == 'preparing')
                        PopupMenuItem(
                          value: 'ready',
                          child: Row(
                            children: [
                              const Icon(Icons.done_all, color: SemanticColors.success),
                              const SizedBox(width: 8),
                              Text('Mark as Ready', style: TextStyle(color: SemanticColors.success)),
                            ],
                          ),
                        ),
                      if (status == 'ready')
                        PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              const Icon(Icons.task_alt, color: SemanticColors.success),
                              const SizedBox(width: 8),
                              Text('Complete Order', style: TextStyle(color: SemanticColors.success)),
                            ],
                          ),
                        ),
                      if (!['completed', 'cancelled', 'refunded'].contains(status))
                        PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: SemanticColors.error),
                              const SizedBox(width: 8),
                              Text('Cancel Order', style: TextStyle(color: SemanticColors.error)),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'contact',
                        child: Row(
                          children: [
                            const Icon(Icons.contact_support),
                            const SizedBox(width: 8),
                            Text('Contact Customer'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = _getStatusColor(status);
    final displayText = _getDisplayStatus(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return SemanticColors.info;
      case 'confirmed':
        return SemanticColors.infoDark;
      case 'preparing':
        return SemanticColors.warning;
      case 'ready':
        return SemanticColors.success;
      case 'completed':
        return SemanticColors.successDark;
      case 'cancelled':
        return SemanticColors.error;
      case 'refunded':
        return SemanticColors.warningDark;
      default:
        return NeutralColors.gray600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'completed':
        return Icons.task_alt;
      case 'cancelled':
        return Icons.cancel;
      case 'refunded':
        return Icons.refresh;
      default:
        return Icons.help_outline;
    }
  }

  String _getDisplayStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'refunded':
        return 'Refunded';
      default:
        return status.capitalizeFirst();
    }
  }

  String _formatOrderTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _orderStatuses.map((status) {
                    return FilterChip(
                      label: Text(status.capitalizeFirst()),
                      selected: _selectedStatus == status,
                      onSelected: (selected) {
                        setDialogState(() {
                          _selectedStatus = status;
                        });
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      backgroundColor: NeutralColors.gray100,
                      selectedColor: BrandColors.primary.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _selectedStatus == status ? BrandColors.primary : NeutralColors.textSecondary,
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: BrandColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  void _exportOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
        backgroundColor: SemanticColors.info,
      ),
    );
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    // TODO: Navigate to order details screen or show dialog
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order details for #$orderId'),
        action: SnackBarAction(
          label: 'View Full Details',
          onPressed: () {
            // TODO: Navigate to detailed order view
          },
        ),
      ),
    );
  }

  void _handleOrderAction(String action, Map<String, dynamic> order) {
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN';

    switch (action) {
      case 'view':
        _showOrderDetails(order);
        break;
      case 'confirm':
        _updateOrderStatus(order, 'confirmed');
        break;
      case 'prepare':
        _updateOrderStatus(order, 'preparing');
        break;
      case 'ready':
        _updateOrderStatus(order, 'ready');
        break;
      case 'complete':
        _updateOrderStatus(order, 'completed');
        break;
      case 'cancel':
        _showCancelOrderDialog(order);
        break;
      case 'contact':
        _contactCustomer(order);
        break;
    }
  }

  void _updateOrderStatus(Map<String, dynamic> order, String newStatus) {
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Order Status'),
        content: Text('Are you sure you want to update order #$orderId to ${newStatus.capitalizeFirst()}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual status update
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #$orderId status updated to ${newStatus.capitalizeFirst()}'),
                  backgroundColor: SemanticColors.success,
                ),
              );
              ref.refresh(adminOrdersProvider);
            },
            style: TextButton.styleFrom(foregroundColor: BrandColors.primary),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(Map<String, dynamic> order) {
    final orderId = order['id']?.toString().substring(0, 8).toUpperCase() ?? 'UNKNOWN';
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order #$orderId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter cancellation reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          TextButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                // TODO: Implement actual order cancellation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Order #$orderId cancelled'),
                    backgroundColor: SemanticColors.error,
                  ),
                );
                ref.refresh(adminOrdersProvider);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a cancellation reason'),
                    backgroundColor: SemanticColors.warning,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: SemanticColors.error),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _contactCustomer(Map<String, dynamic> order) {
    final customer = order['user_profiles'] as Map<String, dynamic>? ?? {};
    final customerName = customer['full_name'] as String? ?? 'Unknown Customer';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact $customerName functionality coming soon'),
        backgroundColor: SemanticColors.info,
      ),
    );
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
              'Failed to load orders',
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
                ref.refresh(adminOrdersProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}