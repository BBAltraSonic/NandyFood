import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/dish_customization_modal.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/features/favourites/presentation/providers/favourites_provider.dart';
import 'package:go_router/go_router.dart';

class CompactDishCard extends ConsumerWidget {
  final MenuItem menuItem;
  final Restaurant restaurant;
  final double? distance;
  final VoidCallback? onQuickPickup;

  const CompactDishCard({
    super.key,
    required this.menuItem,
    required this.restaurant,
    this.distance,
    this.onQuickPickup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isFavourite = ref.watch(
      isMenuItemFavouriteProvider(menuItem.id),
    );

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        onTap: () => showDishCustomizationModal(
          context: context,
          menuItem: menuItem,
          ref: ref,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BorderRadiusTokens.lg),
                topRight: Radius.circular(BorderRadiusTokens.lg),
              ),
              child: Stack(
                children: [
                  // Dish image
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          BrandColors.primary.withValues(alpha: 0.6),
                          BrandColors.primaryLight.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                    child: menuItem.imageUrl?.isNotEmpty == true
                        ? CachedNetworkImage(
                            imageUrl: menuItem.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Icon(
                                Icons.local_dining,
                                size: 40,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(
                                Icons.local_dining,
                                size: 40,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.local_dining,
                              size: 40,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                  ),

                  // Gradient overlay for text readability
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.4),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
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
                                backgroundColor: BrandColors.primary,
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            isFavourite ? Icons.favorite : Icons.favorite_border,
                            color: isFavourite ? Colors.red : Colors.grey[600],
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Price badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: BrandColors.accent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\$${menuItem.price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Preparation time badge
                  if (menuItem.preparationTime > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${menuItem.preparationTime}m',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Restaurant name
                  Text(
                    restaurant.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: BrandColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Dish name
                  Text(
                    menuItem.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Distance and quick pickup row
                  Row(
                    children: [
                      // Distance indicator
                      if (distance != null) ...[
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: NeutralColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${distance!.toStringAsFixed(1)} mi',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NeutralColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                      ] else ...[
                        const Spacer(),
                      ],

                      // Quick pickup button
                      Container(
                        decoration: BoxDecoration(
                          color: BrandColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BrandColors.secondary),
                        ),
                        child: InkWell(
                          onTap: onQuickPickup ?? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${menuItem.name} ready for pickup!'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: BrandColors.secondary,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.shopping_bag,
                                  size: 14,
                                  color: BrandColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Pickup',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: BrandColors.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
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