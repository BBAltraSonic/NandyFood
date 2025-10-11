import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/order.dart';

class OrderTrackingWidget extends StatelessWidget {
  final Order order;
  final VoidCallback? onCancelOrder;

  const OrderTrackingWidget({
    super.key,
    required this.order,
    this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Placed on ${_formatDateTime(order.placedAt)}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Order status timeline
            _buildStatusTimeline(order.status),
            const SizedBox(height: 16),
            
            // Action buttons
            if (order.status == OrderStatus.placed || order.status == OrderStatus.preparing)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: onCancelOrder,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Cancel Order'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Build status timeline
  Widget _buildStatusTimeline(OrderStatus status) {
    final steps = [
      {'title': 'Order Placed', 'status': OrderStatus.placed},
      {'title': 'Preparing', 'status': OrderStatus.preparing},
      {'title': 'Out for Delivery', 'status': OrderStatus.out_for_delivery},
      {'title': 'Delivered', 'status': OrderStatus.delivered},
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final stepStatus = step['status'] as OrderStatus;
        final isCompleted = _isStepCompleted(status, stepStatus);
        final isCurrent = status == stepStatus;
        
        return Column(
          children: [
            Row(
              children: [
                // Status indicator
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.deepOrange 
                        : (isCurrent ? Colors.orange : Colors.grey.shade300),
                    shape: BoxShape.circle,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 16),
                // Step title
                Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? Colors.deepOrange : Colors.black,
                  ),
                ),
              ],
            ),
            // Connector line (except for last step)
            if (index < steps.length - 1)
              Container(
                height: 30,
                padding: const EdgeInsets.only(left: 15),
                child: VerticalDivider(
                  color: isCompleted ? Colors.deepOrange : Colors.grey.shade300,
                  width: 2,
                  thickness: 2,
                ),
              ),
          ],
        );
      }),
    );
  }

  /// Check if step is completed based on current order status
  bool _isStepCompleted(OrderStatus currentStatus, OrderStatus stepStatus) {
    final statusOrder = [
      OrderStatus.placed,
      OrderStatus.preparing,
      OrderStatus.out_for_delivery,
      OrderStatus.delivered,
      OrderStatus.cancelled,
    ];
    
    final currentIndex = statusOrder.indexOf(currentStatus);
    final stepIndex = statusOrder.indexOf(stepStatus);
    
    return stepIndex <= currentIndex;
  }

  /// Format datetime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}