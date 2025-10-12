import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/menu_item_card.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/popular_items_section.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/reviews_section.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/operating_hours_widget.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';
import 'package:food_delivery_app/shared/widgets/floating_cart_button.dart';

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
        // Hero image with parallax effect
        _buildParallaxHeroImage(context, restaurantState),

        // Sticky menu categories header
        _buildStickyCategories(),

        // Restaurant info section
        _buildRestaurantInfo(restaurantState),

        // Popular items section
        if (restaurantState.popularItems.isNotEmpty)
          SliverToBoxAdapter(
            key: _categoryKeys[0],
            child: PopularItemsSection(
              popularItems: restaurantState.popularItems,
              onAddToCart: (menuItem) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${menuItem.name} added to cart')),
                );
              },
            ),
          ),

        // Menu items by category
        ..._buildMenuItemsByCategory(restaurantState, context),

        // Reviews Section
        if (restaurantState.totalReviews > 0 ||
            restaurantState.reviews.isNotEmpty)
          SliverToBoxAdapter(
            child: ReviewsSection(
              restaurantId: widget.restaurantId,
              overallRating: restaurantState.selectedRestaurant?.rating ?? 0.0,
              ratingBreakdown: restaurantState.ratingBreakdown,
              initialReviews: restaurantState.reviews,
              totalReviews: restaurantState.totalReviews,
              onLoadMore: (offset) => ref
                  .read(restaurantProvider.notifier)
                  .loadMoreReviews(widget.restaurantId, offset),
            ),
          ),
      ],
    );
  }

  Widget _buildParallaxHeroImage(BuildContext context, RestaurantState restaurantState) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: false,
      floating: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero image with tag
            Hero(
              tag: 'restaurant_${widget.restaurantId}',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.deepOrange.shade400,
                      Colors.deepOrange.shade700,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 80,
                  color: Colors.white24,
                ),
              ),
            ),
            // Gradient overlay for text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
            // Restaurant logo positioned at bottom
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 40,
                  color: Colors.deepOrange,
                ),
              ),
            ),
            // Restaurant name overlay
            Positioned(
              left: 108,
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurantState.selectedRestaurant?.name ?? widget.restaurant?.name ?? 'Restaurant',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 10, color: Colors.black54)],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurantState.selectedRestaurant?.rating ?? widget.restaurant?.rating ?? 0.0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurantState.selectedRestaurant?.estimatedDeliveryTime ?? widget.restaurant?.estimatedDeliveryTime ?? 30} min',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
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
      delegate: _StickyHeaderDelegate(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _menuCategories.length,
                  itemBuilder: (context, index) {
                    final isSelected =
                        _selectedCategory == _menuCategories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_menuCategories[index]),
                        selected: isSelected,
                        onSelected: (_) => _scrollToCategory(index),
                        selectedColor: Colors.deepOrange,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo(RestaurantState restaurantState) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantState.selectedRestaurant?.cuisineType ?? widget.restaurant?.cuisineType ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '2.5 km away',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.deepOrange),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 16,
                        color: Colors.deepOrange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Free delivery',
                        style: TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ((restaurantState.selectedRestaurant?.description ?? widget.restaurant?.description) != null) ...[
              const SizedBox(height: 12),
              Text(
                restaurantState.selectedRestaurant?.description ?? widget.restaurant?.description ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Operating Hours
            if ((restaurantState.selectedRestaurant?.openingHours ?? widget.restaurant?.openingHours) != null)
              OperatingHoursWidget(
                hoursData: restaurantState.selectedRestaurant?.openingHours ?? widget.restaurant!.openingHours,
              ),
            const SizedBox(height: 16),
            const Divider(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItemsByCategory(
    RestaurantState restaurantState,
    BuildContext context,
  ) {
    final List<Widget> widgets = [];

    // Group menu items by category
    final Map<String, List> itemsByCategory = {};
    for (var item in restaurantState.menuItems) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }

    // Skip the first category (Popular) as it's already shown
    for (int i = 1; i < _menuCategories.length; i++) {
      final category = _menuCategories[i];
      final items = itemsByCategory[category] ?? [];

      if (items.isNotEmpty) {
        // Category header
        widgets.add(
          SliverToBoxAdapter(
            key: _categoryKeys[i],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );

        // Category items
        widgets.add(
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final menuItem = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: MenuItemCard(
                  menuItem: menuItem,
                  onAddToCart: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${menuItem.name} added to cart')),
                    );
                  },
                ),
              );
            }, childCount: items.length),
          ),
        );
      }
    }

    return widgets;
  }
}

// Custom delegate for sticky header
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyHeaderDelegate({required this.child});

  @override
  double get minExtent => 61;

  @override
  double get maxExtent => 61;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickyHeaderDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
