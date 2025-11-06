import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:food_delivery_app/features/home/presentation/providers/dish_favorites_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Favorites Section Widget for Home Screen
class FavoritesSection extends ConsumerStatefulWidget {
  const FavoritesSection({super.key});

  @override
  ConsumerState<FavoritesSection> createState() => _FavoritesSectionState();
}

class _FavoritesSectionState extends ConsumerState<FavoritesSection> {
  @override
  void initState() {
    super.initState();
    // Initialize favorites when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncedDishFavoritesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesState = ref.watch(syncedDishFavoritesProvider);
    final theme = Theme.of(context);

    // Only show favorites section if user has favorites
    if (!favoritesState.isLoading && favoritesState.favoriteItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.favorite,
                color: BrandColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Favorite Dishes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: NeutralColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (!favoritesState.isLoading && favoritesState.favoriteItems.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full favorites screen
                    // context.push('/favorites');
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: BrandColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Loading State
        if (favoritesState.isLoading)
          SizedBox(
            height: 180,
            child: const Center(child: LoadingIndicator()),
          ),

        // Error State
        if (!favoritesState.isLoading && favoritesState.errorMessage != null)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade400,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load favorites',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(dishFavoritesProvider.notifier).refresh();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),

        // Favorites List
        if (!favoritesState.isLoading &&
            favoritesState.errorMessage == null &&
            favoritesState.favoriteItems.isNotEmpty)
          SizedBox(
            height: 200,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: favoritesState.favoriteItems.length,
              itemBuilder: (context, index) {
                final menuItem = favoritesState.favoriteItems[index];
                return _buildFavoriteCard(context, menuItem);
              },
            ),
          ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFavoriteCard(BuildContext context, MenuItem menuItem) {
    final theme = Theme.of(context);
    final isFavorite = ref.read(dishFavoritesProvider.notifier).isFavorite(menuItem.id);

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to restaurant/restaurantDetail screen
          if (menuItem.restaurantId != null) {
            context.push('/restaurant/${menuItem.restaurantId}');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with favorite button overlay
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      color: NeutralColors.surface,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: menuItem.imageUrl != null && menuItem.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: menuItem.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: NeutralColors.surface,
                                child: Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    color: NeutralColors.textSecondary,
                                    size: 32,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: NeutralColors.surface,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: NeutralColors.textSecondary,
                                    size: 32,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: NeutralColors.surface,
                              child: Center(
                                child: Icon(
                                  Icons.restaurant,
                                  color: NeutralColors.textSecondary,
                                  size: 32,
                                ),
                              ),
                            ),
                    ),
                  ),

                  // Favorite button overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          ref.read(dishFavoritesProvider.notifier).toggleFavorite(menuItem.id);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : NeutralColors.textSecondary,
                            size: 16,
                          ),
                        ),
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
  
                    // Menu item name
                    Text(
                      menuItem.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Price and info row
                    Row(
                      children: [
                        Text(
                          'R${menuItem.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: BrandColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (menuItem.isAvailable != null && !menuItem.isAvailable!)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Unavailable',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
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
      ),
    );
  }
}