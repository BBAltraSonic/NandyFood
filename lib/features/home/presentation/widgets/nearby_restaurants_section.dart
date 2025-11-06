import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/home/presentation/providers/home_restaurant_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/core/utils/location_utils.dart';
import 'package:geolocator/geolocator.dart';

class NearbyRestaurantsSection extends ConsumerWidget {
  const NearbyRestaurantsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(homeRestaurantProvider);
    final nearbyRestaurants = ref.watch(nearbyRestaurantsProvider);
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
                    colors: [Colors.green[600]!, Colors.green[400]!],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
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
                      'Nearby Restaurants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NeutralColors.textPrimary,
                      ),
                    ),
                    Text(
                      state.hasLocationPermission
                          ? state.userLocation != null
                              ? 'Restaurants near your current location'
                              : 'Getting your location...'
                          : 'Enable location for nearby restaurants',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Location status indicator
              if (state.isLocationLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primary),
                    ),
                  ),
                )
              else if (state.hasLocationPermission && state.userLocation != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        size: 12,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextButton(
                  onPressed: () {
                    ref.read(homeRestaurantProvider.notifier).retryLocationPermission();
                  },
                  child: Text(
                    'Enable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: BrandColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (state.lastUpdated != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Updated ${_formatTime(state.lastUpdated!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: NeutralColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Loading state
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: List.generate(3, (index) => _buildLoadingCard(theme, index)),
            ),
          )
        // Location permission denied
        else if (!state.hasLocationPermission)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 48,
                  color: Colors.orange[600],
                ),
                const SizedBox(height: 12),
                Text(
                  'Location Access Required',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enable location services to see restaurants near you',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(homeRestaurantProvider.notifier).retryLocationPermission();
                  },
                  icon: const Icon(Icons.location_on),
                  label: const Text('Enable Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          )
        // No nearby restaurants
        else if (nearbyRestaurants.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_searching_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'No Nearby Restaurants',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try expanding your search area or check back later',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        // Nearby restaurants list
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nearbyRestaurants.length,
              itemBuilder: (context, index) {
                final restaurant = nearbyRestaurants[index];
                final distance = LocationUtils.calculateDistance(
                  state.userLocation!.latitude,
                  state.userLocation!.longitude,
                  restaurant.latitude ?? 0.0,
                  restaurant.longitude ?? 0.0,
                );
                return _buildNearbyRestaurantCard(context, theme, restaurant, distance, index);
              },
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeData theme, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Shimmer loading for restaurant image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[200]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(width: 12),

            // Shimmer loading for restaurant info
            Expanded(
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
                  Row(
                    children: [
                      Container(
                        height: 12,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 12,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 12,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
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
                ],
              ),
            ),

            // Arrow placeholder
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyRestaurantCard(
    BuildContext context,
    ThemeData theme,
    Restaurant restaurant,
    double distance,
    int index,
  ) {
    final isOpenNow = _isRestaurantOpen(restaurant.openingHours);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to restaurant details
            // TODO: Implement navigation
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Restaurant image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.green[600]!.withOpacity(0.8),
                        Colors.green[400]!.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Restaurant image or placeholder
                      if (restaurant.coverImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            restaurant.coverImageUrl!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildImagePlaceholder();
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        _buildImagePlaceholder(),

                      // Distance badge
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            LocationUtils.formatDistance(distance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Restaurant info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant name and status
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              restaurant.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: NeutralColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOpenNow ? Colors.green[100] : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpenNow ? 'Open' : 'Closed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOpenNow ? Colors.green[700] : Colors.red[700],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Distance, rating, and delivery time
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: BrandColors.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            LocationUtils.formatDistance(distance),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: BrandColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
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

                      const SizedBox(height: 4),

                      // Cuisine type and delivery fee
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              restaurant.cuisineType,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: NeutralColors.textSecondary,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: NeutralColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                                ? '\$${restaurant.deliveryFee!.toStringAsFixed(2)} delivery'
                                : 'Free delivery',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                                  ? NeutralColors.textSecondary
                                  : Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: NeutralColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Center(
      child: Icon(
        Icons.restaurant,
        size: 28,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  
  // Check if restaurant is currently open
  bool _isRestaurantOpen(Map<String, dynamic> openingHours) {
    try {
      final now = DateTime.now();
      final currentDay = now.weekday; // 1 = Monday, 7 = Sunday
      final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Get opening hours for current day
      final dayKey = _getDayKey(currentDay);
      final dayHours = openingHours[dayKey] as Map<String, dynamic>?;

      if (dayHours == null) return false;

      final isOpen = dayHours['is_open'] as bool? ?? false;
      if (!isOpen) return false;

      final openTime = dayHours['open_time'] as String?;
      final closeTime = dayHours['close_time'] as String?;

      if (openTime == null || closeTime == null) return false;

      // Simple time comparison (you may want to enhance this for complex scenarios)
      return currentTime >= openTime && currentTime <= closeTime;
    } catch (e) {
      return false; // Assume closed if there's an error
    }
  }

  // Get day key for opening hours
  String _getDayKey(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  // Format time for display
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}