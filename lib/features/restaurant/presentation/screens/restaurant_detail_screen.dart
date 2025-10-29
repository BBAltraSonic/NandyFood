import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/menu_item_card.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/popular_items_section.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/reviews_section.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/operating_hours_widget.dart';
import 'package:food_delivery_app/features/favourites/presentation/providers/favourites_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';
import 'package:food_delivery_app/shared/widgets/floating_cart_button.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final Restaurant? restaurant;
  final String restaurantId;

  const RestaurantDetailScreen({
    super.key,
    this.restaurant,
    required this.restaurantId,
  });

  @override
  ConsumerState<RestaurantDetailScreen> createState() =>
      _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState
    extends ConsumerState<RestaurantDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _categoryKeys = [];
  String? _selectedCategory;
  final List<String> _menuCategories = [
    'Popular',
    'Appetizers',
    'Mains',
    'Desserts',
    'Drinks',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize keys for categories
    _categoryKeys.addAll(
      List.generate(_menuCategories.length, (_) => GlobalKey()),
    );
    _selectedCategory = _menuCategories.first;

    // Select this restaurant in the provider and load menu items
    Future.microtask(() {
      if (widget.restaurant != null) {
        ref.read(restaurantProvider.notifier).selectRestaurant(widget.restaurant!);
      }
      ref.read(restaurantProvider.notifier).loadMenuItems(widget.restaurantId);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCategory(int index) {
    if (_categoryKeys[index].currentContext != null) {
      setState(() {
        _selectedCategory = _menuCategories[index];
      });
      Scrollable.ensureVisible(
        _categoryKeys[index].currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantState = ref.watch(restaurantProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: NeutralColors.background,
          body: restaurantState.isLoading
              ? const LoadingIndicator()
              : restaurantState.errorMessage != null
              ? ErrorMessageWidget(
                  message: restaurantState.errorMessage!,
                  onRetry: () => ref
                      .read(restaurantProvider.notifier)
                      .loadMenuItems(widget.restaurantId),
                )
              : _buildRestaurantDetailContent(restaurantState, context),
        ),
        // Floating Cart Button
        const FloatingCartButton(),
      ],
    );
  }

  Widget _buildRestaurantDetailContent(
    RestaurantState restaurantState,
    BuildContext context,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Enhanced Hero image with parallax effect
        _buildEnhancedHeroImage(context, restaurantState),

        // Sticky menu categories header
        _buildStickyCategories(),

        // Enhanced Restaurant info section
        _buildEnhancedRestaurantInfo(restaurantState),

        // Popular items section
        if (restaurantState.popularItems.isNotEmpty)
          SliverToBoxAdapter(
            key: _categoryKeys[0],
            child: PopularItemsSection(
              popularItems: restaurantState.popularItems,
              onAddToCart: (menuItem) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${menuItem.name} added to cart'),
                    backgroundColor: BrandColors.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),

        // Menu items by category
        ..._buildMenuItemsByCategory(restaurantState, context),

        // Reviews Section
        SliverToBoxAdapter(
          child: ReviewsSection(
            restaurantId: widget.restaurantId,
            restaurantName: restaurantState.selectedRestaurant?.name ?? 'Restaurant',
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedHeroImage(BuildContext context, RestaurantState restaurantState) {
    final restaurant = restaurantState.selectedRestaurant ?? widget.restaurant;

    return SliverAppBar(
      expandedHeight: 380,
      pinned: false,
      floating: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        // Enhanced Favorite button
        Consumer(
          builder: (context, ref, child) {
            final authState = ref.watch(authStateProvider);
            final isFavourite = ref.watch(
              isRestaurantFavouriteProvider(widget.restaurantId),
            );
            final isLoading = ref.watch(favouritesProvider).isLoading;

            return Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                boxShadow: ShadowTokens.shadowMd,
              ),
              child: IconButton(
                icon: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: isFavourite ? Colors.red.shade400 : Colors.grey.shade600,
                  size: 24,
                ),
                onPressed: isLoading ? null : () async {
                  // Check authentication
                  if (!authState.isAuthenticated || authState.user == null) {
                    if (context.mounted) {
                      _showLoginDialog(context);
                    }
                    return;
                  }

                  final success = await ref
                      .read(favouritesProvider.notifier)
                      .toggleRestaurantFavourite(widget.restaurantId);

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isFavourite
                            ? 'Removed from favorites'
                            : 'Added to favorites',
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: BrandColors.primary,
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Enhanced Hero image with gradient background
            Hero(
              tag: 'restaurant_${widget.restaurantId}',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      BrandColors.primary,
                      BrandColors.primaryLight,
                      BrandColors.secondary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.restaurant,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),

            // Enhanced gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Restaurant information overlay
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant logo and name
                  Row(
                    children: [
                      // Enhanced logo
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: ShadowTokens.shadowLg,
                        ),
                        child: Icon(
                          Icons.restaurant,
                          size: 50,
                          color: BrandColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Restaurant name and rating
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant?.name ?? 'Restaurant',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 10, color: Colors.black54),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Rating and delivery info
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandColors.accent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${restaurant?.rating ?? 0.0}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${restaurant?.estimatedDeliveryTime ?? 30} min',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
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
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Cuisine type and delivery radius
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        restaurant?.cuisineType ?? 'Various Cuisines',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${restaurant?.deliveryRadius ?? 5} km',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyCategories() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        child: Container(
          decoration: BoxDecoration(
            color: NeutralColors.surface,
            boxShadow: ShadowTokens.shadowSm,
          ),
          child: Column(
            children: [
              // Category navigation
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _menuCategories.length,
                  itemBuilder: (context, index) {
                    final category = _menuCategories[index];
                    final isSelected = _selectedCategory == category;

                    return Container(
                      margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) => _scrollToCategory(index),
                        backgroundColor: NeutralColors.gray100,
                        selectedColor: BrandColors.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : NeutralColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? BrandColors.primary : NeutralColors.gray300,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRestaurantInfo(RestaurantState restaurantState) {
    final restaurant = restaurantState.selectedRestaurant ?? widget.restaurant;
    final theme = Theme.of(context);

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: NeutralColors.surface,
          borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
          boxShadow: ShadowTokens.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrandColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_rounded,
                    color: BrandColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'About this restaurant',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (restaurant?.description != null && restaurant!.description!.isNotEmpty) ...[
              Text(
                restaurant.description!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: NeutralColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Operating Hours
            OperatingHoursWidget(hoursData: widget.restaurant?.openingHours ?? {}),

            const SizedBox(height: 24),

            // Quick stats
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    Icons.star_rounded,
                    '${restaurant?.rating ?? 0.0}',
                    'Rating',
                    BrandColors.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    Icons.access_time_rounded,
                    '${restaurant?.estimatedDeliveryTime ?? 30} min',
                    'Delivery',
                    BrandColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStat(
                    Icons.delivery_dining_rounded,
                    '${restaurant?.deliveryRadius ?? 5} km',
                    'Radius',
                    BrandColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItemsByCategory(
    RestaurantState restaurantState,
    BuildContext context,
  ) {
    final menuItems = restaurantState.menuItems;
    final List<Widget> categorySections = [];

    for (int i = 1; i < _menuCategories.length; i++) {
      final category = _menuCategories[i];
      final categoryItems = menuItems.where((item) {
        // This would need proper categorization logic
        return item.category?.toLowerCase() == category.toLowerCase();
      }).toList();

      if (categoryItems.isNotEmpty) {
        categorySections.add(
          SliverToBoxAdapter(
            key: _categoryKeys[i],
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: BrandColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          color: BrandColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: NeutralColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...categoryItems.map((menuItem) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MenuItemCard(
                        menuItem: menuItem,
                        onAddToCart: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${menuItem.name} added to cart'),
                              backgroundColor: BrandColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        );
      }
    }

    return categorySections;
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
              context.push('/auth/login');
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SliverAppBarDelegate({required this.child});

  @override
  double get minExtent => 60;

  @override
  double get maxExtent => 60;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}