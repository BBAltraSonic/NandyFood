import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/core/utils/accessibility_utils.dart';

class AccessibleMenuItemCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback? onAddToCart;
  final bool isInCart;
  final int quantityInCart;

  const AccessibleMenuItemCard({
    super.key,
    required this.menuItem,
    this.onAddToCart,
    this.isInCart = false,
    this.quantityInCart = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      button: onAddToCart != null,
      label: '${menuItem.name}, '
          'Price: \$${menuItem.price.toStringAsFixed(2)}, '
          '${menuItem.description ?? 'No description'}'
          '${isInCart ? ', $quantityInCart in cart' : ''}',
      focusable: true,
      enabled: true,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: onAddToCart,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                      child: const Icon(
                        Icons.local_dining,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Menu item details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Menu item name
                          Accessibility.accessibleHeading(
                            menuItem.name,
                            level: 4,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Menu item description
                          if (menuItem.description != null)
                            Text(
                              menuItem.description!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 8),
                          
                          // Menu item price
                          Text(
                            '\$${menuItem.price.toStringAsFixed(2)}',
                            style: textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          // Dietary restrictions badges
                          if (menuItem.dietaryRestrictions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: menuItem.dietaryRestrictions.map((restriction) {
                                Color badgeColor;
                                String badgeText;
                                
                                switch (restriction.toLowerCase()) {
                                  case 'vegetarian':
                                    badgeColor = Colors.green;
                                    badgeText = 'Veg';
                                    break;
                                  case 'vegan':
                                    badgeColor = Colors.green.shade700;
                                    badgeText = 'Vegan';
                                    break;
                                  case 'gluten-free':
                                    badgeColor = Colors.blue;
                                    badgeText = 'GF';
                                    break;
                                  default:
                                    badgeColor = Colors.grey;
                                    badgeText = restriction;
                                }
                                
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: badgeColor),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Add to cart button or quantity indicator
                    if (isInCart)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$quantityInCart',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        onPressed: onAddToCart,
                        tooltip: 'Add ${menuItem.name} to cart',
                      ),
                  ],
                ),
                
                // Preparation time
                if (menuItem.preparationTime > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${menuItem.preparationTime} min prep time',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}