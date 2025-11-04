import 'package:flutter/material.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/restaurant_card.dart';
import 'package:food_delivery_app/features/home/presentation/widgets/home_map_view_widget.dart';
import 'package:food_delivery_app/features/home/presentation/widgets/categories_horizontal_list.dart';
import 'package:food_delivery_app/features/home/presentation/widgets/order_again_section.dart';
import 'package:food_delivery_app/features/home/presentation/providers/map_view_provider.dart';
import 'package:food_delivery_app/core/services/location_service.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
    // Use Future.microtask to delay provider modification until after build
    Future.microtask(_loadRestaurants);
    _scrollController.addListener(_onScroll);

    // Initialize address with current location
    _initializeAddressWithLocation();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = 200.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      ref.read(restaurantProvider.notifier).loadMoreRestaurants();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(position.latitude, position.longitude);
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          // Default to New York if location fails
          _userLocation = const LatLng(40.7128, -74.0060);
        });
      }
    }
  }

  Future<void> _loadRestaurants() async {
    await ref.read(restaurantProvider.notifier).loadRestaurants();
  }

  // Initialize address with current location
  void _initializeAddressWithLocation() {
    // Start with a default placeholder
    _addressController.text = 'Enter your pickup address...';
  }

  // Update pickup address and save it
  void _updatePickupAddress(String address) {
    if (address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid pickup address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save the address (you can implement local storage or state management here)
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pickup address updated: $address'),
        backgroundColor: BrandColors.primary,
      ),
    );

    // You can also update the user location or other state variables here
    setState(() {
      // Update any state related to the pickup address
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurantState = ref.watch(restaurantProvider);
    final mapViewState = ref.watch(mapViewProvider);
    final theme = Theme.of(context);

    return Stack(
      children: [
        Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: mapViewState.isMapView
                ? _buildMapView(context, theme, restaurantState)
                : _buildListView(context, theme, restaurantState),
          ),
        ),
      ],
    );
  }

  Widget _buildListView(BuildContext context, ThemeData theme, restaurantState) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: [
            BrandColors.primary.withValues(alpha: 0.03),
            NeutralColors.background,
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Parallax Map Section (60% of screen)
            SliverPersistentHeader(
              pinned: false,
              floating: false,
              delegate: ParallaxMapDelegate(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                minHeight: 100,
                child: Stack(
                  children: [
                    // Full viewport map
                    Positioned.fill(
                      child: HomeMapViewWidget(
                        restaurants: restaurantState.restaurants.where((Restaurant r) => r.id.isNotEmpty).toList(),
                        userLocation: _userLocation,
                        height: double.infinity,
                        showRestaurantPreview: false,
                        showPickupMarkers: true,
                      ),
                    ),

                    // Floating header with location and user controls
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        child: _buildFloatingHeader(context, theme),
                      ),
                    ),

                    // Floating search bar overlapping from bottom of map
                    Positioned(
                      bottom: 20, // Position to overlap from bottom of map
                      left: 24,
                      right: 24,
                      child: _buildFloatingSearchBar(context, theme),
                    ),

                    // Gradient fade at bottom for smooth transition with search bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 120, // Increased height to cover search bar overlap area
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              NeutralColors.background.withValues(alpha: 0.6),
                              NeutralColors.background,
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar (moved to parallax map section)

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Promotional Banner (Updated for pickup focus)
            SliverToBoxAdapter(
              child: _buildPickupPromotionalBanner(theme),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Order Again Section (only visible if user has past orders)
            const SliverToBoxAdapter(child: OrderAgainSection()),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Categories Section
            SliverToBoxAdapter(
              child: _buildCategoriesSection(theme, restaurantState),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Nearby Pickup Spots Section (Updated from Popular Restaurants)
            SliverToBoxAdapter(
              child: _buildNearbyPickupSpotsSection(theme, restaurantState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(BuildContext context, ThemeData theme, restaurantState) {
    return Stack(
      children: [
        // Full-screen map
        Positioned.fill(
          child: HomeMapViewWidget(
            restaurants: restaurantState.restaurants.where((Restaurant r) => r.id.isNotEmpty).toList(),
            userLocation: _userLocation,
            height: double.infinity,
            showRestaurantPreview: true,
          ),
        ),

        // Integrated search bar at the top
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: _buildMapSearchBar(context, theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapSearchBar(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xxl),
        boxShadow: ShadowTokens.shadowMd,
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search restaurants, dishes, cuisines...',
          hintStyle: TextStyle(
            color: NeutralColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: BrandColors.primary,
              size: 24,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BrandColors.secondary, BrandColors.secondaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.list_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                ref.read(mapViewProvider.notifier).showListView();
              },
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        onTap: () => context.push('/search'),
        readOnly: true,
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Top navigation row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Location and greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: BrandColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _isLoadingLocation ? 'Current Location' : 'New York, NY',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: BrandColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Good ${_getTimeOfDay()}! 👋',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: NeutralColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What would you like to eat today?',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                children: [
                  // Restaurant Dashboard Button (if user is restaurant owner)
                  Consumer(
                    builder: (context, ref, _) {
                      final authState = ref.watch(authStateProvider);
                      if (authState.canAccessRestaurantDashboard) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: BrandColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: BrandColors.secondary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.store_rounded,
                                color: BrandColors.secondary,
                              ),
                              onPressed: () => context.push('/restaurant/dashboard'),
                              tooltip: 'Restaurant Dashboard',
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  // Profile button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [BrandColors.primary, BrandColors.primaryLight],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: ShadowTokens.primaryShadow,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person, color: Colors.white),
                      onPressed: () => context.push(RoutePaths.profile),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSearchBar(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: NeutralColors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xxl),
          boxShadow: ShadowTokens.shadowMd,
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search restaurants, dishes, cuisines...',
            hintStyle: TextStyle(
              color: NeutralColors.textSecondary,
              fontSize: 16,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.search_rounded,
                color: BrandColors.primary,
                size: 24,
              ),
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [BrandColors.secondary, BrandColors.secondaryLight],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                icon: Icon(
                  ref.watch(mapViewProvider).isMapView
                      ? Icons.list_rounded
                      : Icons.map_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  ref.read(mapViewProvider.notifier).toggleMapView();
                },
              ),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
          ),
          onTap: () => context.push('/search'),
          readOnly: true,
        ),
      ),
    );
  }

  Widget _buildPromotionalBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandColors.accent,
              BrandColors.accent.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          boxShadow: [
            BoxShadow(
              color: BrandColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Special Offer!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Get 20% off your first order',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ORDER NOW',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: BrandColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.local_offer_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection(ThemeData theme, RestaurantState restaurantState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to all categories
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
        ),
        const SizedBox(height: 16),
        CategoriesHorizontalList(
          selectedCategoryId: restaurantState.selectedCategory ?? 'all',
          onCategorySelected: (categoryId) {
            ref.read(restaurantProvider.notifier).filterByCategory(categoryId);
          },
        ),
      ],
    );
  }

  Widget _buildPopularRestaurantsSection(ThemeData theme, RestaurantState restaurantState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Restaurants',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/restaurants');
                },
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 20),

        // Restaurant List
        if (restaurantState.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (restaurantState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    restaurantState.errorMessage!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRestaurants,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        else if (restaurantState.restaurants.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No restaurants found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your filters or search criteria',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: restaurantState.restaurants.map((restaurant) {
                // Additional null safety check
                if (restaurant.id.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RestaurantCard(
                    restaurant: restaurant,
                    onTap: () {
                      if (restaurant.id.isNotEmpty) {
                        context.push('/restaurant/${restaurant.id}');
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // New widget: Floating search bar for map overlay
  Widget _buildFloatingSearchBar(BuildContext context, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.xxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search restaurants, dishes, cuisines...',
          hintStyle: TextStyle(
            color: NeutralColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.search_rounded,
              color: BrandColors.primary,
              size: 24,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BrandColors.secondary, BrandColors.secondaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              icon: Icon(
                Icons.list_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                ref.read(mapViewProvider.notifier).toggleMapView();
              },
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
        ),
        onTap: () => context.push('/search'),
        readOnly: true,
      ),
    );
  }

  // New widget: Floating header with address input and user controls
  Widget _buildFloatingHeader(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Address input field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: ShadowTokens.shadowMd,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: BrandColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pickup Address',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: BrandColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            hintText: 'Enter your pickup address...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: NeutralColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          onSubmitted: (value) {
                            _updatePickupAddress(value);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User avatar
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [BrandColors.primary, BrandColors.primaryLight],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: ShadowTokens.primaryShadow,
            ),
            child: IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () => context.push(RoutePaths.profile),
            ),
          ),
        ],
      ),
    );
  }

  // Updated widget: Pickup-focused promotional banner
  Widget _buildPickupPromotionalBanner(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BrandColors.secondary,
              BrandColors.secondary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          boxShadow: [
            BoxShadow(
              color: BrandColors.secondary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Quick Pickup Special!',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Skip the queue - Order ahead',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ORDER NOW',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: BrandColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated widget: Nearby pickup spots section
  Widget _buildNearbyPickupSpotsSection(ThemeData theme, RestaurantState restaurantState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nearby Pickup Spots',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.push('/restaurants');
                },
                child: Text(
                  'View all',
                  style: TextStyle(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const SizedBox(height: 20),

        // Restaurant List
        if (restaurantState.isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (restaurantState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    restaurantState.errorMessage!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRestaurants,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        else if (restaurantState.restaurants.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pickup spots found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try adjusting your location or search criteria',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: restaurantState.restaurants.map((restaurant) {
                // Additional null safety check
                if (restaurant.id.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RestaurantCard(
                    restaurant: restaurant,
                    onTap: () {
                      if (restaurant.id.isNotEmpty) {
                        context.push('/restaurant/${restaurant.id}');
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }


  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

}

// ParallaxMapDelegate for the parallax scrolling effect
class ParallaxMapDelegate extends SliverPersistentHeaderDelegate {
  final double maxHeight;
  final double minHeight;
  final Widget child;

  ParallaxMapDelegate({
    required this.maxHeight,
    required this.minHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / (maxExtent - minHeight);
    final scale = 1.0 + (progress * 0.5); // Zoom in slightly as scrolled

    return Transform.scale(
      scale: scale,
      child: OverflowBox(
        minHeight: maxHeight,
        maxHeight: maxHeight,
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return oldDelegate != this;
  }
}