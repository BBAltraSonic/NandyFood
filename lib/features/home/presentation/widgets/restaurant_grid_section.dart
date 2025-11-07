import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/home/presentation/providers/home_restaurant_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/core/utils/location_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Restaurant Grid Section with vertical two-column infinite scroll
class RestaurantGridSection extends ConsumerStatefulWidget {
  const RestaurantGridSection({super.key});

  @override
  ConsumerState<RestaurantGridSection> createState() => _RestaurantGridSectionState();
}

class _RestaurantGridSectionState extends ConsumerState<RestaurantGridSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Load initial grid data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeRestaurantProvider.notifier).loadGridRestaurants();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreRestaurants();
    }
  }

  void _loadMoreRestaurants() {
    final notifier = ref.read(homeRestaurantProvider.notifier);
    if (notifier.hasMoreGridRestaurants && !notifier.isGridLoading) {
      notifier.loadMoreGridRestaurants();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(homeRestaurantProvider);
    final gridRestaurants = state.gridRestaurants;
    final isGridLoading = state.isGridLoading;
    final hasMoreGridRestaurants = state.hasMoreGridRestaurants;

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
                    colors: [BrandColors.primary, BrandColors.primary.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.grid_view,
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
                      'All Restaurants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NeutralColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Discover amazing restaurants near you',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isGridLoading)
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
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Restaurant Grid
        if (gridRestaurants.isEmpty && isGridLoading)
          _buildLoadingGrid()
        else if (gridRestaurants.isEmpty)
          _buildEmptyState()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate optimal aspect ratio based on screen width
                final screenWidth = constraints.maxWidth;
                final optimalHeight = (screenWidth / 2 - 6) * 1.2; // Responsive height
                final aspectRatio = (screenWidth / 2 - 6) / optimalHeight;

                return GridView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: aspectRatio.clamp(0.6, 0.9), // Dynamic aspect ratio
                  ),
                  itemCount: gridRestaurants.length + (hasMoreGridRestaurants ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= gridRestaurants.length) {
                      return _buildLoadingCard();
                    }
                    return _buildRestaurantCard(gridRestaurants[index], index);
                  },
                );
              },
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate optimal aspect ratio based on screen width
          final screenWidth = constraints.maxWidth;
          final optimalHeight = (screenWidth / 2 - 6) * 1.2; // Responsive height
          final aspectRatio = (screenWidth / 2 - 6) / optimalHeight;

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: aspectRatio.clamp(0.6, 0.9), // Dynamic aspect ratio
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildLoadingCard(),
          );
        },
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shimmer for image
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey[300]!, Colors.grey[200]!],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
            ),
          ),
          // Shimmer for content
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 10,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        height: 8,
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 8,
                        width: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
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

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'No Restaurants Found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for restaurants in your area',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant, int index) {
    final theme = Theme.of(context);
    final state = ref.watch(homeRestaurantProvider);
    final distance = state.userLocation != null
        ? LocationUtils.calculateDistance(
            state.userLocation!.latitude,
            state.userLocation!.longitude,
            restaurant.latitude ?? 0.0,
            restaurant.longitude ?? 0.0,
          )
        : null;
    final isOpenNow = _isRestaurantOpen(restaurant.openingHours);

    return Container(
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
            // TODO: Navigate to restaurant details
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant image
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            BrandColors.primary.withOpacity(0.8),
                            BrandColors.primary.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: restaurant.coverImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: restaurant.coverImageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 32,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Center(
                                  child: Icon(
                                    Icons.restaurant,
                                    size: 32,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.restaurant,
                                  size: 32,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                      ),
                    ),
                    // Status badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isOpenNow ? Colors.green[600] : Colors.red[600],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpenNow ? 'Open' : 'Closed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Distance badge (if available)
                    if (distance != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
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
              // Restaurant info
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Restaurant name
                      Text(
                        restaurant.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
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
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Rating and delivery time
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 10,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            restaurant.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.schedule,
                            size: 10,
                            color: NeutralColors.textSecondary,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${restaurant.estimatedDeliveryTime} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: NeutralColors.textSecondary,
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Delivery fee
                      Text(
                        restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                            ? '\$${restaurant.deliveryFee!.toStringAsFixed(2)} delivery'
                            : 'Free delivery',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: restaurant.deliveryFee != null && restaurant.deliveryFee! > 0
                              ? NeutralColors.textSecondary
                              : Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

      // Convert time strings to minutes for proper comparison
      final currentMinutes = _timeToMinutes(currentTime);
      final openMinutes = _timeToMinutes(openTime);
      final closeMinutes = _timeToMinutes(closeTime);

      return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
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

  /// Convert time string "HH:MM" to minutes since midnight
  int _timeToMinutes(String? timeStr) {
    if (timeStr == null) return 0;

    final parts = timeStr.split(':');
    if (parts.length != 2) return 0;

    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (e) {
      return 0;
    }
  }
}