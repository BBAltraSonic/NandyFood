import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:food_delivery_app/features/home/presentation/providers/dish_recommendation_provider.dart';
import 'package:food_delivery_app/features/home/presentation/widgets/dish_card_compact.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:shimmer/shimmer.dart';

class DishRecommendationCarousel extends ConsumerStatefulWidget {
  const DishRecommendationCarousel({super.key});

  @override
  ConsumerState<DishRecommendationCarousel> createState() => _DishRecommendationCarouselState();
}

class _DishRecommendationCarouselState extends ConsumerState<DishRecommendationCarousel> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load recommendations when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dishRecommendationProvider.notifier).loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recommendationsState = ref.watch(dishRecommendationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommended for Pickup',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Popular dishes from nearby restaurants',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: NeutralColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Refresh button
              Container(
                decoration: BoxDecoration(
                  color: BrandColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BrandColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: BrandColors.primary,
                    size: 20,
                  ),
                  onPressed: () {
                    ref.read(dishRecommendationProvider.notifier).refresh();
                  },
                  tooltip: 'Refresh recommendations',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Carousel content
        recommendationsState.when(
          loading: () => _buildShimmerCarousel(),
          error: (error, stackTrace) => _buildErrorWidget(error),
          data: (recommendations) {
            if (recommendations.isEmpty) {
              return _buildEmptyState();
            }
            return _buildCarousel(recommendations);
          },
        ),

        // Carousel indicator
        if (recommendationsState.hasValue && recommendationsState.value!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: recommendationsState.value!.asMap().entries.map<Widget>((entry) {
              final isActive = _currentIndex == entry.key;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? BrandColors.primary
                      : BrandColors.primary.withValues(alpha: 0.3),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildCarousel(List recommendations) {
    return CarouselSlider.builder(
      carouselController: _carouselController,
      options: CarouselOptions(
        height: 280,
        viewportFraction: 0.85,
        enlargeCenterPage: true,
        enableInfiniteScroll: recommendations.length > 1,
        autoPlay: recommendations.length > 1,
        autoPlayInterval: const Duration(seconds: 8),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index, realIndex) {
        final menuItem = recommendations[index];
        final restaurant = _getRestaurantForMenuItem(menuItem.restaurantId);

        if (restaurant == null) {
          return const SizedBox.shrink();
        }

        return CompactDishCard(
          menuItem: menuItem,
          restaurant: restaurant,
          distance: _calculateDistance(restaurant),
          onQuickPickup: () {
            _handleQuickPickup(menuItem, restaurant);
          },
        );
      },
    );
  }

  Widget _buildShimmerCarousel() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: CarouselSlider.builder(
        options: CarouselOptions(
          height: 280,
          viewportFraction: 0.85,
          enableInfiniteScroll: false,
        ),
        itemCount: 3,
        itemBuilder: (context, index, realIndex) {
          return Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    final theme = Theme.of(context);
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load recommendations',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(dishRecommendationProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: NeutralColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 48,
              color: NeutralColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations available',
              style: theme.textTheme.titleMedium?.copyWith(
                color: NeutralColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new dishes',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: NeutralColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Restaurant? _getRestaurantForMenuItem(String restaurantId) {
    try {
      final restaurantState = ref.read(restaurantProvider);
      return restaurantState.restaurants
          .where((r) => r.id == restaurantId)
          .firstOrNull;
    } catch (e) {
      return null;
    }
  }

  double? _calculateDistance(Restaurant restaurant) {
    // TODO: Implement actual distance calculation using user location
    // For now, return a mock distance
    return (restaurant.id.hashCode % 50) / 10.0 + 0.5; // 0.5 to 5.5 miles
  }

  void _handleQuickPickup(dynamic menuItem, Restaurant restaurant) {
    // TODO: Implement actual quick pickup logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${menuItem.name} from ${restaurant.name} ready for pickup!'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: BrandColors.secondary,
      ),
    );
  }
}