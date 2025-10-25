import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/dish_customization_modal.dart';
import 'package:food_delivery_app/features/favourites/presentation/providers/favourites_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';

class MenuItemCard extends ConsumerWidget {
  final MenuItem menuItem;
  final VoidCallback? onAddToCart;

  const MenuItemCard({Key? key, required this.menuItem, this.onAddToCart})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isFavourite = ref.watch(
      isMenuItemFavouriteProvider(menuItem.id),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Stack(
        children: [
          Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
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
                  child: const Icon(
                    Icons.local_dining,
                    size: 40,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),

                // Menu item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              menuItem.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '\$${menuItem.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Dietary restrictions badges
                      if (menuItem.dietaryRestrictions.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: menuItem.dietaryRestrictions.map<Widget>((
                            restriction,
                          ) {
                            Color badgeColor;
                            String badgeText;

                            switch (restriction.toLowerCase()) {
                              case 'vegetarian':
                                badgeColor = Colors.green;
                                badgeText = 'Veg';
                              case 'vegan':
                                badgeColor = Colors.green.shade700;
                                badgeText = 'Vegan';
                              case 'gluten-free':
                                badgeColor = Colors.blue;
                                badgeText = 'GF';
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
                                color: badgeColor.withValues(alpha: 0.1),
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

                      const SizedBox(height: 8),

                      Text(
                        menuItem.description ?? 'No description available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => showDishCustomizationModal(
                  context: context,
                  menuItem: menuItem,
                  ref: ref,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add to Cart'),
              ),
            ),
          ),
        ],
      ),

          // Favorite button
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.white.withValues(alpha: 0.9),
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  // Check authentication
                  if (!authState.isAuthenticated || authState.user == null) {
                    _showLoginPrompt(context);
                    return;
                  }

                  final success = await ref
                      .read(favouritesProvider.notifier)
                      .toggleMenuItemFavourite(menuItem.id);

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavourite
                              ? '${menuItem.name} removed from favorites'
                              : '${menuItem.name} added to favorites',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        action: SnackBarAction(
                          label: 'Undo',
                          onPressed: () {
                            ref
                                .read(favouritesProvider.notifier)
                                .toggleMenuItemFavourite(menuItem.id);
                          },
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    isFavourite ? Icons.favorite : Icons.favorite_border,
                    color: isFavourite ? Colors.red : Colors.grey[400],
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please login to add items to your favorites.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/auth/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
