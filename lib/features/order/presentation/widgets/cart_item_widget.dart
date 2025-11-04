import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

class CartItemWidget extends StatelessWidget {
  final OrderItem orderItem;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onRemove;

  const CartItemWidget({
    super.key,
    required this.orderItem,
    this.onIncrement,
    this.onDecrement,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu item image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.fastfood,
                color: Colors.grey.shade600,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            // Menu item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu item ID (placeholder for name)
                  Text(
                    orderItem.menuItemId,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Customizations
                  if (orderItem.customizations != null &&
                      orderItem.customizations!.isNotEmpty)
                    Text(
                      _formatCustomizations(orderItem.customizations!),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 4),
                  // Special instructions
                  if (orderItem.specialInstructions != null)
                    Text(
                      'Note: ${orderItem.specialInstructions}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(height: 8),
                  // Price
                  Text(
                    '\$${(orderItem.unitPrice * orderItem.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity controls
            Column(
              children: [
                // Increment button
                IconButton(icon: const Icon(Icons.add), onPressed: onIncrement),
                // Quantity display
                Text(
                  '${orderItem.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Decrement button
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: onDecrement,
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Remove button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black87),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  /// Format customizations for display
  String _formatCustomizations(Map<String, dynamic> customizations) {
    final List<String> parts = [];

    // Add size
    if (customizations['size'] != null) {
      parts.add('Size: ${customizations['size']}');
    }

    // Add toppings
    if (customizations['toppings'] != null &&
        (customizations['toppings'] as List).isNotEmpty) {
      final toppings = (customizations['toppings'] as List).join(', ');
      parts.add('Toppings: $toppings');
    }

    // Add spice level
    if (customizations['spiceLevel'] != null) {
      final spiceLevel = customizations['spiceLevel'] as int;
      String spiceLevelText;
      if (spiceLevel <= 1) {
        spiceLevelText = 'Mild';
      } else if (spiceLevel <= 2) {
        spiceLevelText = 'Medium';
      } else if (spiceLevel <= 3) {
        spiceLevelText = 'Spicy';
      } else if (spiceLevel <= 4) {
        spiceLevelText = 'Hot';
      } else {
        spiceLevelText = 'Extra Hot';
      }
      parts.add('Spice: $spiceLevelText');
    }

    return parts.join(' • ');
  }
}
