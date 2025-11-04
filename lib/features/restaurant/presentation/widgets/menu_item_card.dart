import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/dish_customization_modal.dart';
import 'package:food_delivery_app/features/favourites/presentation/providers/favourites_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class MenuItemCard extends ConsumerWidget {
  final MenuItem menuItem;
  final VoidCallback? onAddToCart;

  const MenuItemCard({Key? key, required this.menuItem, this.onAddToCart})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isFavourite = ref.watch(
      isMenuItemFavouriteProvider(menuItem.id),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          onTap: () => showDishCustomizationModal(
            context: context,
            menuItem: menuItem,
            ref: ref,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with overlay
              Stack(
                children: [
                  // Large food image placeholder
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(BorderRadiusTokens.xl),
                        topRight: Radius.circular(BorderRadiusTokens.xl),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BrandColors.primary.withValues(alpha: 0.6),
                          BrandColors.primaryLight.withValues(alpha: 0.4),
                          BrandColors.accent.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_dining,
                        size: 60,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                  // Gradient overlay for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(BorderRadiusTokens.xl),
                          topRight: Radius.circular(BorderRadiusTokens.xl),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.3),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      elevation: 3,
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
                                backgroundColor: BrandColors.primary,
                                action: SnackBarAction(
                                  label: 'Undo',
                                  textColor: Colors.white,
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
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavourite ? Icons.favorite : Icons.favorite_border,
                            color: isFavourite ? Colors.black54 : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Price badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: BrandColors.accent,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '\$${menuItem.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Preparation time badge
                  if (menuItem.preparationTime != null)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${menuItem.preparationTime} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name
                    Text(
                      menuItem.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Description
                    if (menuItem.description != null && menuItem.description!.isNotEmpty) ...[
                      Text(
                        menuItem.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Dietary restrictions badges with enhanced icons
                    if (menuItem.dietaryRestrictions?.isNotEmpty == true) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: menuItem.dietaryRestrictions!.map<Widget>((
                          restriction,
                        ) {
                          return _buildDietaryBadge(context, restriction);
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Quick add section
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => showDishCustomizationModal(
                              context: context,
                              menuItem: menuItem,
                              ref: ref,
                            ),
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            label: const Text('Add to Cart'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrandColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Quick add button
                        Container(
                          decoration: BoxDecoration(
                            color: BrandColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
                            border: Border.all(color: BrandColors.secondary),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Quick add without customization
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${menuItem.name} added to cart!'),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: BrandColors.secondary,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.add,
                              color: BrandColors.secondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDietaryBadge(BuildContext context, String restriction) {
    final theme = Theme.of(context);
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    switch (restriction.toLowerCase()) {
      case 'vegetarian':
        badgeColor = BrandColors.secondary;
        badgeIcon = Icons.eco;
        badgeText = 'Veg';
        break;
      case 'vegan':
        badgeColor = BrandColors.secondaryDark;
        badgeIcon = Icons.spa;
        badgeText = 'Vegan';
        break;
      case 'gluten-free':
        badgeColor = Colors.black87;
        badgeIcon = Icons.grain;
        badgeText = 'GF';
        break;
      case 'dairy-free':
        badgeColor = Colors.lightBlue;
        badgeIcon = Icons.no_food;
        badgeText = 'DF';
        break;
      case 'nut-free':
        badgeColor = Colors.black87;
        badgeIcon = Icons.egg;
        badgeText = 'NF';
        break;
      case 'spicy':
        badgeColor = BrandColors.primary;
        badgeIcon = Icons.local_fire_department;
        badgeText = 'Spicy';
        break;
      default:
        badgeColor = Colors.grey;
        badgeIcon = Icons.info;
        badgeText = restriction;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w600,
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