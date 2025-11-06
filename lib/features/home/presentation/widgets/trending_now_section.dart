import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/home/presentation/widgets/dish_card_compact.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class TrendingNowSection extends ConsumerWidget {
  const TrendingNowSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final restaurantState = ref.watch(restaurantProvider);

    // Get trending items (simulated for now)
    final trendingItems = _getTrendingItems(restaurantState);

    if (trendingItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and see all
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.orange.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trending Now',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NeutralColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Popular this week',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NeutralColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all trending items
                },
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Horizontal list of trending items
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: trendingItems.length,
              itemBuilder: (context, index) {
                final item = trendingItems[index];
                final restaurant = _getRestaurantForItem(item.restaurantId, restaurantState.restaurants);

                if (restaurant == null) return const SizedBox.shrink();

                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildTrendingCard(context, item, restaurant, theme, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCard(BuildContext context, MenuItem item, Restaurant restaurant, ThemeData theme, int index) {
    return Container(
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(
          color: Colors.red.shade100,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with trending badge
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(BorderRadiusTokens.lg),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          BrandColors.primary.withValues(alpha: 0.1),
                          BrandColors.primary.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: item.imageUrl?.isNotEmpty ?? false
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: NeutralColors.surface,
                                child: Icon(
                                  Icons.restaurant_outlined,
                                  size: 40,
                                  color: NeutralColors.textSecondary,
                                ),
                              );
                            },
                          )
                        : Icon(
                            Icons.restaurant_outlined,
                            size: 40,
                            color: NeutralColors.textSecondary,
                          ),
                  ),
                ),
                // Trending badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.orange.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'HOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Favorite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: ShadowTokens.shadowSm,
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NeutralColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.price.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 10,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${(500 - index * 50)}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<MenuItem> _getTrendingItems(RestaurantState restaurantState) {
    // Simulate trending items by taking some popular items
    final allItems = restaurantState.popularItems.isEmpty
        ? restaurantState.menuItems.where((item) => item.isAvailable).take(10).toList()
        : restaurantState.popularItems.take(10).toList();

    // Sort by some trending logic (for demo purposes, just take first 5)
    return allItems.take(5).toList();
  }

  Restaurant? _getRestaurantForItem(String restaurantId, List<Restaurant> restaurants) {
    try {
      return restaurants.firstWhere((r) => r.id == restaurantId);
    } catch (e) {
      return null;
    }
  }
}