import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/features/favourites/presentation/providers/favourites_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class RestaurantCard extends ConsumerWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({Key? key, required this.restaurant, this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isFavourite = ref.watch(
      isRestaurantFavouriteProvider(restaurant.id),
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      height: 220,
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: 'restaurant_${restaurant.id}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                boxShadow: ShadowTokens.foodCardShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image with gradient
                    _buildBackgroundImage(context, restaurant),

                    // Gradient overlay for text readability
                    _buildGradientOverlay(theme),

                    // Content overlay
                    _buildContent(context, restaurant),

                    // Favorite button
                    _buildFavoriteButton(context, ref, authState, isFavourite),

                    // Top restaurant badge
                    if (restaurant.rating >= 4.5)
                      _buildTopBadge(theme),

                    // Rating badge
                    _buildRatingBadge(context, restaurant),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(BuildContext context, Restaurant restaurant) {
    final theme = Theme.of(context);

    // Gradient background placeholder - replace with actual images when available
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.primary.withValues(alpha: 0.8),
            BrandColors.primaryLight.withValues(alpha: 0.6),
            BrandColors.secondary.withValues(alpha: 0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );

    // Future implementation with actual images:
    /*
    return CachedNetworkImage(
      imageUrl: restaurant.coverImageUrl ?? '',
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandColors.primary.withValues(alpha: 0.3),
              BrandColors.secondary.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandColors.primary.withValues(alpha: 0.8),
              BrandColors.secondary.withValues(alpha: 0.4),
            ],
          ),
        ),
        child: const Icon(
          Icons.restaurant,
          size: 80,
          color: Colors.white54,
        ),
      ),
    );
    */
  }

  Widget _buildGradientOverlay(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.6),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Restaurant restaurant) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Restaurant name
          Text(
            restaurant.name.isNotEmpty ? restaurant.name : 'Restaurant',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Cuisine and delivery info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  restaurant.cuisineType.isNotEmpty ? restaurant.cuisineType : 'Food',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                '${restaurant.estimatedDeliveryTime} min',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 4),
              Text(
                'Distance', // TODO: Calculate actual distance from user location
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),

          // Optional description
          if (restaurant.description != null && restaurant.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              restaurant.description!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoriteButton(
    BuildContext context,
    WidgetRef ref,
    dynamic authState,
    bool isFavourite,
  ) {
    return Positioned(
      top: 12,
      right: 12,
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            // Check authentication
            if (!authState.isAuthenticated || authState.user == null) {
              _showLoginDialog(context);
              return;
            }

            await ref
                .read(favouritesProvider.notifier)
                .toggleRestaurantFavourite(restaurant.id);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavourite
                        ? '${restaurant.name} removed from favorites'
                        : '${restaurant.name} added to favorites',
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: BrandColors.primary,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              isFavourite ? Icons.favorite : Icons.favorite_border,
              color: isFavourite ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBadge(ThemeData theme) {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [BrandColors.secondary, BrandColors.secondaryDark],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              'Top',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge(BuildContext context, Restaurant restaurant) {
    final theme = Theme.of(context);

    // Validate rating before using it
    String ratingText;
    try {
      if (restaurant.rating.isNaN || restaurant.rating.isInfinite || restaurant.rating < 0) {
        ratingText = 'N/A';
      } else {
        ratingText = restaurant.rating.toStringAsFixed(1);
      }
    } catch (e) {
      ratingText = 'N/A';
    }

    return Positioned(
      bottom: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: BrandColors.accent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              ratingText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text(
          'Please login to add restaurants to your favorites.',
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