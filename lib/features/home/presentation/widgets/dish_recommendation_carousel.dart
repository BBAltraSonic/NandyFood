import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final ScrollController _scrollController = ScrollController();
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    // Load recommendations when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dishRecommendationProvider.notifier).loadRecommendations();
    });

    // Setup scroll listener for infinite loading
    _scrollController.addListener(_onScroll);

    // Setup auto-scroll
    _setupAutoScroll();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final recommendationsState = ref.read(dishRecommendationProvider);
    final currentState = recommendationsState.value;

    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    // Trigger load more when we're near the end
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Load more at 80% of the list

    if (currentScroll >= threshold && !currentState.isLoadingMore) {
      ref.read(dishRecommendationProvider.notifier).loadMoreRecommendations();
    }
  }

  void _setupAutoScroll() {
    if (_isAutoScrolling) return;

    _isAutoScrolling = true;
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _scrollController.hasClients && _isAutoScrolling) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _scrollController.animateTo(
            maxScroll * 0.8, // Scroll to 80% of the list
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
          ).then((_) {
            // Reset to start after a delay
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                );
              }
            });
          });
        }
      }
      _isAutoScrolling = false;
      // Schedule next auto-scroll
      if (mounted) {
        _setupAutoScroll();
      }
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
                    _getTimeBasedTitle(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeBasedSubtitle(),
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

        // Horizontal list content
        recommendationsState.when(
          loading: () => _buildShimmerList(),
          error: (error, stackTrace) => _buildErrorWidget(error),
          data: (recommendationState) {
            if (recommendationState.recommendations.isEmpty) {
              return _buildEmptyState();
            }
            return _buildHorizontalList(recommendationState);
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalList(recommendationState) {
  return RepaintBoundary(
    child: Container(
      height: 260, // More accurate height matching actual card dimensions
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: recommendationState.recommendations.length + (recommendationState.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          // Show loading indicator at the end
          if (index == recommendationState.recommendations.length) {
            return _buildLoadingIndicator();
          }

          final menuItem = recommendationState.recommendations[index];
          final restaurant = _getRestaurantForMenuItem(menuItem.restaurantId);

          if (restaurant == null) {
            return const SizedBox.shrink();
          }

          return RepaintBoundary(
            key: ValueKey('dish_${menuItem.id}'),
            child: Container(
              width: 280,
              child: CompactDishCard(
                menuItem: menuItem,
                restaurant: restaurant,
                distance: _calculateDistance(restaurant),
                onQuickPickup: () {
                  _handleQuickPickup(menuItem, restaurant);
                },
              ),
            ),
          );
        },
      ),
    ),
  );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        border: Border.all(
          color: NeutralColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(BrandColors.primary),
            ),
            SizedBox(height: 8),
            Text(
              'Loading more...',
              style: TextStyle(
                color: NeutralColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 260, // Match the actual card height
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (context, index) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            return Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorWidget(Object error) {
    final theme = Theme.of(context);
    return Container(
      height: 260, // Match the actual card height
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
      height: 260, // Match the actual card height
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

  String _getTimeBasedTitle() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) {
      return 'Breakfast Recommendations';
    } else if (hour >= 11 && hour < 14) {
      return 'Lunch Specials';
    } else if (hour >= 14 && hour < 17) {
      return 'Afternoon Snacks';
    } else if (hour >= 17 && hour < 21) {
      return 'Dinner Favorites';
    } else {
      return 'Late Night Cravings';
    }
  }

  String _getTimeBasedSubtitle() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 11) {
      return 'Start your day with these delicious options';
    } else if (hour >= 11 && hour < 14) {
      return 'Quick and satisfying meals for lunch';
    } else if (hour >= 14 && hour < 17) {
      return 'Perfect afternoon pick-me-ups';
    } else if (hour >= 17 && hour < 21) {
      return 'Hearty meals for dinner time';
    } else {
      return 'Late night bites and comfort food';
    }
  }
}