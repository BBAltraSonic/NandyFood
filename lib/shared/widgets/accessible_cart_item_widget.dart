import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';
import 'package:food_delivery_app/core/utils/accessibility_utils.dart';

class AccessibleCartItemWidget extends StatelessWidget {
  final OrderItem orderItem;
  final String itemName;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;
  final bool showControls;

  const AccessibleCartItemWidget({
    super.key,
    required this.orderItem,
    required this.itemName,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
    this.showControls = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label:
          '$itemName, '
          'Quantity: ${orderItem.quantity}, '
          'Price: \$${(orderItem.unitPrice * orderItem.quantity).toStringAsFixed(2)}'
          '${orderItem.specialInstructions != null ? ', Special instructions: ${orderItem.specialInstructions}' : ''}',
      focusable: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Accessibility.accessibleHeading(
                      itemName,
                      level: 4,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Customizations
                    if (orderItem.customizations != null &&
                        orderItem.customizations!.isNotEmpty) ...[
                      Text(
                        _formatCustomizations(orderItem.customizations!),
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Special instructions
                    if (orderItem.specialInstructions != null) ...[
                      Text(
                        'Note: ${orderItem.specialInstructions}',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    // Price
                    Text(
                      '\$${(orderItem.unitPrice * orderItem.quantity).toStringAsFixed(2)}',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity controls
              if (showControls) ...[
                Row(
                  children: [
                    // Decrement button
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: onDecrement,
                      tooltip: 'Decrease quantity',
                    ),

                    // Quantity display
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '${orderItem.quantity}',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Increment button
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: onIncrement,
                      tooltip: 'Increase quantity',
                    ),
                  ],
                ),

                // Remove button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onRemove,
                  tooltip: 'Remove item',
                ),
              ] else ...[
                // Quantity display without controls
                Text('Qty: ${orderItem.quantity}', style: textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Format customizations for display
  String _formatCustomizations(Map<String, dynamic> customizations) {
    final entries = customizations.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
    return 'Customizations: $entries';
  }
}
