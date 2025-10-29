import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/restaurant_card.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';
import 'package:food_delivery_app/shared/widgets/empty_state_widget.dart';
import 'package:food_delivery_app/shared/widgets/skeleton_loading.dart';
import 'package:food_delivery_app/shared/widgets/advanced_filter_sheet.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final TextEditingController _searchController = TextEditingController();
  RestaurantFilters _currentFilters = const RestaurantFilters();
  String _searchQuery = '';
  bool _isFilterSheetOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantState = ref.watch(restaurantProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar with Search
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: BrandColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [BrandColors.primary, BrandColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              title: _buildSearchBar(context, theme),
              titlePadding: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 16,
              ),
            ),
            actions: [
              // Filter button with badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: _showFilterSheet,
                  ),
                  if (_currentFilters.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: BrandColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Quick Filter Chips
          SliverToBoxAdapter(
            child: _buildQuickFilters(theme, restaurantState),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Results Summary
          SliverToBoxAdapter(
            child: _buildResultsSummary(theme, restaurantState),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Restaurant List
          if (restaurantState.isLoading)
            const SliverToBoxAdapter(
              child: SkeletonList(
                skeletonCard: RestaurantCardSkeleton(),
                itemCount: 5,
              ),
            )
          else if (restaurantState.errorMessage != null)
            SliverToBoxAdapter(
              child: ErrorMessageWidget(
                message: restaurantState.errorMessage!,
                onRetry: () =>
                    ref.read(restaurantProvider.notifier).loadRestaurants(),
              ),
            )
          else
            _buildRestaurantList(restaurantState, context, ref),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search restaurants, cuisines...',
          hintStyle: TextStyle(
            color: NeutralColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: BrandColors.primary,
            size: 24,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
          // Debounced search
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_searchQuery == value) {
              // Apply search filter
              _applySearchFilter(value);
            }
          });
        },
      ),
    );
  }

  Widget _buildQuickFilters(ThemeData theme, dynamic restaurantState) {
    final quickFilters = [
      {'id': 'top_rated', 'label': '⭐ Top Rated', 'icon': Icons.star_rounded},
      {'id': 'fast_delivery', 'label': '🚀 Fast Delivery', 'icon': Icons.speed_rounded},
      {'id': 'budget_friendly', 'label': '💰 Budget Friendly', 'icon': Icons.savings_rounded},
      {'id': 'new', 'label': '✨ New', 'icon': Icons.new_releases_rounded},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickFilters.length,
        itemBuilder: (context, index) {
          final filter = quickFilters[index];
          final isSelected = _currentFilters.sortBy == filter['id'];

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : BrandColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : BrandColors.primary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  if (isSelected) {
                    _currentFilters = _currentFilters.copyWith(sortBy: null);
                  } else {
                    _currentFilters = _currentFilters.copyWith(
                      sortBy: filter['id'] as String,
                    );
                  }
                });
                _applyFilters();
              },
              backgroundColor: NeutralColors.surface,
              selectedColor: BrandColors.primary,
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: BrandColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultsSummary(ThemeData theme, dynamic restaurantState) {
    final filteredRestaurants = _getFilteredRestaurants(restaurantState);
    final hasActiveFilters = _currentFilters.hasActiveFilters || _searchQuery.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Text(
            hasActiveFilters
                ? '${filteredRestaurants.length} restaurants found'
                : 'All Restaurants',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (hasActiveFilters)
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear_rounded, size: 18),
              label: const Text('Clear all'),
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList(restaurantState, BuildContext context, WidgetRef ref) {
    final restaurants = _getFilteredRestaurants(restaurantState);

    if (restaurants.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyStateWidget.noRestaurants(
          onRefresh: () {
            ref.read(restaurantProvider.notifier).loadRestaurants();
          },
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final restaurant = restaurants[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RestaurantCard(
                restaurant: restaurant,
                onTap: () {
                  context.push('/restaurant/${restaurant.id}');
                },
              ),
            );
          },
          childCount: restaurants.length,
        ),
      ),
    );
  }

  List<dynamic> _getFilteredRestaurants(dynamic restaurantState) {
    List<dynamic> restaurants = restaurantState.restaurants;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      restaurants = restaurants.where((restaurant) {
        return restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            restaurant.cuisineType.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply dietary restriction filters
    if (_currentFilters.dietaryRestrictions.isNotEmpty) {
      restaurants = restaurants.where((restaurant) {
        return _currentFilters.dietaryRestrictions.any((restriction) =>
            restaurant.dietaryOptions.contains(restriction));
      }).toList();
    }

    // Apply rating filter
    if (_currentFilters.minRating != null) {
      restaurants = restaurants.where((restaurant) =>
          restaurant.rating >= _currentFilters.minRating!).toList();
    }

    // Apply sorting
    switch (_currentFilters.sortBy) {
      case 'top_rated':
        restaurants.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'fast_delivery':
        restaurants.sort((a, b) => a.estimatedDeliveryTime.compareTo(b.estimatedDeliveryTime));
        break;
      case 'popular':
        // Sort by some popularity metric - for now, keep rating as proxy
        restaurants.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        // Keep recommended order
        break;
    }

    return restaurants;
  }

  void _showFilterSheet() {
    setState(() {
      _isFilterSheetOpen = true;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdvancedFilterSheet(
        initialFilters: _currentFilters,
        onApply: (filters) {
          setState(() {
            _currentFilters = filters;
            _isFilterSheetOpen = false;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    ).then((_) {
      setState(() {
        _isFilterSheetOpen = false;
      });
    });
  }

  void _applySearchFilter(String query) {
    // Search filtering is handled in _getFilteredRestaurants
    setState(() {});
  }

  void _applyFilters() {
    // Filter application is handled in _getFilteredRestaurants
    setState(() {});
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilters = const RestaurantFilters();
      _searchQuery = '';
      _searchController.clear();
    });
  }
}