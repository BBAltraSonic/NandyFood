import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/home/presentation/providers/home_restaurant_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class FeaturedRestaurantsSection extends ConsumerWidget {
  const FeaturedRestaurantsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(homeRestaurantProvider);
    final featuredRestaurants = ref.watch(featuredRestaurantsProvider);
    final isLoading = ref.watch(isLoadingRestaurantsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[600]!, Colors.amber[400]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Featured Restaurants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NeutralColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Handpicked by our team for you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all featured restaurants
                },
                child: Text(
                  'See all',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Loading state
        if (isLoading)
          Container(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 4,
              itemBuilder: (context, index) {
                return _buildLoadingCard(theme);
              },
            ),
          )
        // Error state
        else if (state.errorMessage != null)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red[400],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load featured restaurants',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(homeRestaurantProvider.notifier).refresh();
                    },
                    child: Text(
                      'Retry',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          )
        // Empty state
        else if (featuredRestaurants.isEmpty)
          Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_border,
                    color: Colors.grey[400],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No featured restaurants available',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Check back later for curated selections',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        // Success state
        else
          Container(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: featuredRestaurants.length,
              itemBuilder: (context, index) {
                return _buildFeaturedRestaurantCard(
                  context,
                  theme,
                  featuredRestaurants[index],
                  index,
                  state.userPreferences,
                );
              },
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer loading effect
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber[300]!,
                  Colors.amber[200]!,
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 32,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedRestaurantCard(
    BuildContext context,
    ThemeData theme,
    Restaurant restaurant,
    int index,
    Map<String, dynamic> userPreferences,
  ) {
    // Determine promotional badge based on user preferences and restaurant features
    String promotionalBadge = _getPromotionalBadge(restaurant, userPreferences, index);

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant image with badges
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber[600]!.withOpacity(0.8),
                  Colors.amber[400]!.withOpacity(0.6),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                // Restaurant image or placeholder
                if (restaurant.coverImageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      restaurant.coverImageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(restaurant.name);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      },
                    ),
                  )
                else
                  _buildImagePlaceholder(restaurant.name),

                // Featured badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber[600]!,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Promotional badge
                if (promotionalBadge.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        promotionalBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Personalized indicator
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: BrandColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 10,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'For You',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Restaurant info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name
                  Text(
                    restaurant.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: NeutralColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Cuisine type
                  Text(
                    restaurant.cuisineType,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NeutralColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Rating and delivery time
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: NeutralColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${restaurant.estimatedDeliveryTime} min',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NeutralColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Delivery fee and distance (if location available)
                  Row(
                    children: [
                      Text(
                        restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                            ? '\$${restaurant.deliveryFee!.toStringAsFixed(2)}'
                            : 'Free',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                              ? NeutralColors.textSecondary
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (restaurant.deliveryFee != null && restaurant.deliveryFee! > 0) ...[
                        const Spacer(),
                        Text(
                          '• ${restaurant.deliveryRadius.toStringAsFixed(1)}km',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: NeutralColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Order button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to restaurant details
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Order Now',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(String restaurantName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dining,
            size: 48,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(height: 4),
          Text(
            restaurantName.length > 15
                ? '${restaurantName.substring(0, 15)}...'
                : restaurantName,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getPromotionalBadge(Restaurant restaurant, Map<String, dynamic> userPreferences, int index) {
    final userFavoriteCuisines = userPreferences['favorite_cuisines'] as List<String>? ?? [];
    final userPriceRange = userPreferences['price_range'] as String? ?? 'all';

    // Check if restaurant matches user preferences
    if (userFavoriteCuisines.contains(restaurant.cuisineType)) {
      return 'YOUR FAVE';
    }

    // Price-based promotions
    if (userPriceRange == 'budget' && restaurant.deliveryFee == 0) {
      return 'FREE DELIVERY';
    } else if (userPriceRange == 'premium' && restaurant.deliveryFee != null && restaurant.deliveryFee! > 3.0) {
      return 'PREMIUM';
    }

    // Day-based promotions
    final dayOfWeek = DateTime.now().weekday;
    if (dayOfWeek == DateTime.friday) {
      return 'FRIDAY DEAL';
    } else if (dayOfWeek == DateTime.saturday || dayOfWeek == DateTime.sunday) {
      return 'WEEKEND';
    }

    // Index-based promotions
    switch (index % 4) {
      case 0:
        return '20% OFF';
      case 1:
        return 'Free Delivery';
      case 2:
        return 'Special Menu';
      case 3:
        return 'New';
      default:
        return '20% OFF';
    }
  }
}