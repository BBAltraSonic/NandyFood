import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';
import 'package:food_delivery_app/shared/widgets/order_history_item_widget.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For now, using mock data - this would come from the provider in a real implementation
    final mockOrders = [
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
        items: [
          OrderItem(
            id: 'item_1',
            orderId: 'order_12345678',
            menuItemId: 'menu_1',
            quantity: 1,
            unitPrice: 12.99,
          ),
          OrderItem(
            id: 'item_2',
            orderId: 'order_12345678',
            menuItemId: 'menu_2',
            quantity: 1,
            unitPrice: 8.99,
          ),
          OrderItem(
            id: 'item_3',
            orderId: 'order_12345678',
            menuItemId: 'menu_3',
            quantity: 2,
            unitPrice: 4.49,
          ),
        ],
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
        items: [
          OrderItem(
            id: 'item_4',
            orderId: 'order_87654321',
            menuItemId: 'menu_4',
            quantity: 1,
            unitPrice: 15.99,
          ),
          OrderItem(
            id: 'item_5',
            orderId: 'order_87654321',
            menuItemId: 'menu_5',
            quantity: 1,
            unitPrice: 4.99,
          ),
          OrderItem(
            id: 'item_6',
            orderId: 'order_87654321',
            menuItemId: 'menu_6',
            quantity: 1,
            unitPrice: 3.52,
          ),
        ],
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
        items: [
          OrderItem(
            id: 'item_7',
            orderId: 'order_1111111',
            menuItemId: 'menu_7',
            quantity: 1,
            unitPrice: 16.99,
          ),
          OrderItem(
            id: 'item_8',
            orderId: 'order_1111111',
            menuItemId: 'menu_8',
            quantity: 1,
            unitPrice: 7.99,
          ),
          OrderItem(
            id: 'item_9',
            orderId: 'order_1111111',
            menuItemId: 'menu_9',
            quantity: 2,
            unitPrice: 2.99,
          ),
          OrderItem(
            id: 'item_10',
            orderId: 'order_1111111',
            menuItemId: 'menu_10',
            quantity: 1,
            unitPrice: 6.79,
          ),
        ],
        placedAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Order History'), centerTitle: true),
      body: _buildOrderHistoryContent(mockOrders, context),
    );
  }

  Widget _buildOrderHistoryContent(List<Order> orders, BuildContext context) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders yet', style: TextStyle(fontSize: 18)),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh order history
        await Future.delayed(const Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refresh functionality coming soon')),
        );
      },
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OrderHistoryItemWidget(
              order: orders[index],
              onTap: () {
                // TODO: Navigate to order details
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('View order details coming soon'),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
