import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:intl/intl.dart';

class PendingOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onViewDetails;

  const PendingOrderCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status.name).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${order.id.substring(0, 8)}',
                      style: TextStyle(
                        color: _getStatusColor(order.status.name),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('HH:mm').format(order.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Customer Order',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.restaurant_rounded,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${order.items.length} items',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.attach_money_rounded,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (order.status.name == 'pending' && (onAccept != null || onReject != null)) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onReject != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: const BorderSide(color: Colors.black87),
                          ),
                        ),
                      ),
                    if (onAccept != null && onReject != null) const SizedBox(width: 12),
                    if (onAccept != null)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onAccept,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.black87;
      case 'confirmed':
      case 'preparing':
        return Colors.black87;
      case 'ready':
        return Colors.black87;
      case 'completed':
        return Colors.black87;
      case 'cancelled':
      case 'rejected':
        return Colors.black87;
      default:
        return Colors.grey;
    }
  }
}
