import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/core/utils/accessibility_utils.dart';

class AccessibleOrderTrackingWidget extends StatelessWidget {
  final Order order;
  final VoidCallback? onCallDriver;
  final VoidCallback? onCancelOrder;

  const AccessibleOrderTrackingWidget({
    super.key,
    required this.order,
    this.onCallDriver,
    this.onCancelOrder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label:
          'Order tracking for order ${order.id}, '
          'Status: ${_getStatusText(order.status)}, '
          'Total: \$${order.totalAmount.toStringAsFixed(2)}',
      focusable: true,
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Accessibility.accessibleHeading(
                        'Order #${order.id.substring(0, 8)}',
                        level: 3,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Placed on ${_formatDateTime(order.placedAt)}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(order.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Progress tracker
              _buildProgressTracker(context),

              const SizedBox(height: 24),

              // Order details
              _buildOrderDetails(context),

              const SizedBox(height: 24),

              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressTracker(BuildContext context) {
    final steps = [
      StepProgress(
        title: 'Order Placed',
        isCompleted: _isStepCompleted(OrderStatus.placed, order.status),
        isActive: order.status == OrderStatus.placed,
      ),
      StepProgress(
        title: 'Confirmed',
        isCompleted: _isStepCompleted(OrderStatus.confirmed, order.status),
        isActive: order.status == OrderStatus.confirmed,
      ),
      StepProgress(
        title: 'Preparing',
        isCompleted: _isStepCompleted(OrderStatus.preparing, order.status),
        isActive: order.status == OrderStatus.preparing,
      ),
      StepProgress(
        title: 'Ready for Pickup',
        isCompleted: _isStepCompleted(
          OrderStatus.ready_for_pickup,
          order.status,
        ),
        isActive: order.status == OrderStatus.ready_for_pickup,
      ),
    ];

    return Column(
      children: [
        Accessibility.accessibleHeading('Order Progress', level: 4),
        const SizedBox(height: 16),
        ...steps.asMap().entries.expand((entry) {
          final index = entry.key;
          final step = entry.value;
          return [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? Colors.green
                        : (step.isActive
                              ? Colors.orange
                              : Colors.grey.shade300),
                  ),
                  child: step.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: step.isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: step.isCompleted || step.isActive
                          ? Colors.black
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            if (index < steps.length - 1)
              Container(
                width: 2,
                height: 20,
                margin: const EdgeInsets.only(left: 15),
                color: steps[index].isCompleted
                    ? Colors.green
                    : Colors.grey.shade300,
              ),
          ];
        }).toList(),
      ],
    );
  }

  Widget _buildOrderDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Accessibility.accessibleHeading('Order Details', level: 4),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount:'),
                  Text('\$${order.totalAmount.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pickup Address:'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.pickupAddress['street'] ?? 'Not specified',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method:'),
                  Text(order.paymentMethod),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (onCancelOrder != null &&
            (order.status == OrderStatus.placed ||
                order.status == OrderStatus.confirmed))
          Accessibility.accessibleButton(
            child: const Text('Cancel Order'),
            onPressed: onCancelOrder!,
            semanticsLabel: 'Cancel order',
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
      ],
    );
  }

  bool _isStepCompleted(OrderStatus stepStatus, OrderStatus currentStatus) {
    final statusOrder = [
      OrderStatus.placed,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready_for_pickup,
    ];

    final stepIndex = statusOrder.indexOf(stepStatus);
    final currentIndex = statusOrder.indexOf(currentStatus);

    return stepIndex <= currentIndex;
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed:
        return Colors.orange;
      case OrderStatus.preparing:
      case OrderStatus.ready_for_pickup:
        return Colors.blue;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready_for_pickup:
        return 'Ready for Pickup';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

class StepProgress {
  final String title;
  final bool isCompleted;
  final bool isActive;

  StepProgress({
    required this.title,
    required this.isCompleted,
    required this.isActive,
  });
}
