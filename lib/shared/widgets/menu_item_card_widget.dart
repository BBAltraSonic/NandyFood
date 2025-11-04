import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

class MenuItemCardWidget extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const MenuItemCardWidget({
    super.key,
    required this.menuItem,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu item image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fastfood,
                  color: Colors.grey.shade600,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              // Menu item details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Menu item name
                    Text(
                      menuItem.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Menu item description
                    if (menuItem.description != null)
                      Text(
                        menuItem.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Price and dietary restrictions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${menuItem.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (menuItem.dietaryRestrictions?.isNotEmpty == true)
                          Row(
                            children: menuItem.dietaryRestrictions!.map((
                              restriction,
                            ) {
                              return Container(
                                margin: const EdgeInsets.only(left: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  restriction.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Add to cart button
              IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: onAddToCart,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
