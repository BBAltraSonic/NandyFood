import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';
import 'package:food_delivery_app/shared/widgets/empty_state_widget.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock order history data
    final orders = [
      Order(
        id: 'order_12345678',
        userId: 'user_123',
        restaurantId: 'restaurant_123',
        deliveryAddress: {'street': '123 Main St', 'city': 'New York'},
        status: OrderStatus.delivered,
        totalAmount: 30.97,
        deliveryFee: 2.90,
        taxAmount: 2.45,
        paymentMethod: 'credit_card',
        paymentStatus: PaymentStatus.completed,
        placedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Order(
        id: 'order_87654321',
        userId: 'user_123',
        restaurantId: 'restaurant_456',
        deliveryAddress: {'street': '123 Main St', 'city': 'New York'},
        status: OrderStatus.delivered,
        totalAmount: 24.50,
        deliveryFee: 2.90,
        taxAmount: 1.95,
        paymentMethod: 'credit_card',
        paymentStatus: PaymentStatus.completed,
        placedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Order(
        id: 'order_1111111',
        userId: 'user_123',
        restaurantId: 'restaurant_789',
        deliveryAddress: {'street': '123 Main St', 'city': 'New York'},
        status: OrderStatus.delivered,
        totalAmount: 42.75,
        deliveryFee: 2.90,
        taxAmount: 3.40,
        paymentMethod: 'credit_card',
        paymentStatus: PaymentStatus.completed,
        placedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
      Order(
        id: 'order_2222222',
        userId: 'user_123',
        restaurantId: 'restaurant_101',
        deliveryAddress: {'street': '123 Main St', 'city': 'New York'},
        status: OrderStatus.cancelled,
        totalAmount: 18.25,
        deliveryFee: 2.90,
        taxAmount: 1.45,
        paymentMethod: 'credit_card',
        paymentStatus: PaymentStatus.completed,
        placedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Order History'), centerTitle: true),
      body: orders.isEmpty
          ? EmptyStateWidget.noOrders(
              onBrowse: () {
                Navigator.of(context).pushReplacementNamed('/home');
              },
            )
          : RefreshIndicator(
              onRefresh: () async {
                // In a real implementation, this would refresh the order history
                await Future.delayed(const Duration(seconds: 1));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refresh functionality coming soon')),
                );
              },
              child: ListView.builder(
                itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '\$${order.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order.placedAt),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(order.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(order.status),
                        ),
                      ),
                      child: Text(
                        _getStatusText(order.status),
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to order details screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order details functionality coming soon'),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.out_for_delivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime dateTime) {
    // Format as "Oct 12, 2023"
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}
