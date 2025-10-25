import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/favourites_provider.dart';
import '../../../../shared/widgets/restaurant_card_widget.dart';
import '../../../../shared/widgets/menu_item_card_widget.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/loading_indicator.dart';

/// Favourites screen showing user's favorite restaurants and menu items
class FavouritesScreen extends ConsumerStatefulWidget {
  const FavouritesScreen({super.key});

  @override
  ConsumerState<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends ConsumerState<FavouritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshFavourites() async {
    await ref.read(favouritesProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favouritesProvider);
    final restaurantFavourites = state.restaurantFavourites;
    final menuItemFavourites = state.menuItemFavourites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
        actions: [
          if (state.favourites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all favorites',
              onPressed: () => _showClearConfirmation(context),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Restaurants',
              icon: Badge(
                label: Text('${restaurantFavourites.length}'),
                isLabelVisible: restaurantFavourites.isNotEmpty,
                child: const Icon(Icons.restaurant),
              ),
            ),
            Tab(
              text: 'Menu Items',
              icon: Badge(
                label: Text('${menuItemFavourites.length}'),
                isLabelVisible: menuItemFavourites.isNotEmpty,
                child: const Icon(Icons.fastfood),
              ),
            ),
          ],
        ),
      ),
      body: state.isLoading && state.favourites.isEmpty
          ? const LoadingIndicator()
          : TabBarView(
              controller: _tabController,
              children: [
                _RestaurantFavouritesTab(
                  favourites: restaurantFavourites,
                  onRefresh: _refreshFavourites,
                ),
                _MenuItemFavouritesTab(
                  favourites: menuItemFavourites,
                  onRefresh: _refreshFavourites,
                ),
              ],
            ),
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites?'),
        content: const Text(
          'Are you sure you want to remove all favorites? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(favouritesProvider.notifier)
                  .clearAllFavourites();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All favorites cleared'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

/// Restaurant favourites tab
class _RestaurantFavouritesTab extends ConsumerWidget {
  const _RestaurantFavouritesTab({
    required this.favourites,
    required this.onRefresh,
  });

  final List<FavouriteItem> favourites;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (favourites.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.favorite_border,
        title: 'No Favorite Restaurants',
        message:
            'Start adding restaurants to your favorites to see them here',
        actionText: 'Explore Restaurants',
        onAction: () {
          context.push('/restaurants');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favourites.length,
        itemBuilder: (context, index) {
          final favourite = favourites[index];
          final restaurant = favourite.restaurant;

          if (restaurant == null) {
            return const SizedBox.shrink();
          }

          return Dismissible(
            key: Key(favourite.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 32,
              ),
            ),
            confirmDismiss: (direction) async {
              return await _showRemoveConfirmation(
                context,
                restaurant.name,
              );
            },
            onDismissed: (direction) {
              ref
                  .read(favouritesProvider.notifier)
                  .removeRestaurantFavourite(restaurant.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${restaurant.name} removed from favorites'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref
                          .read(favouritesProvider.notifier)
                          .addRestaurantFavourite(restaurant.id);
                    },
                  ),
                ),
              );
            },
            child: RestaurantCardWidget(
              restaurant: restaurant,
              onTap: () {
                context.push('/restaurant/${restaurant.id}', extra: restaurant);
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showRemoveConfirmation(
    BuildContext context,
    String restaurantName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites?'),
        content: Text('Remove $restaurantName from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Menu item favourites tab
class _MenuItemFavouritesTab extends ConsumerWidget {
  const _MenuItemFavouritesTab({
    required this.favourites,
    required this.onRefresh,
  });

  final List<FavouriteItem> favourites;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (favourites.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.fastfood_outlined,
        title: 'No Favorite Menu Items',
        message: 'Start adding menu items to your favorites to see them here',
        actionText: 'Explore Menu',
        onAction: () {
          context.push('/restaurants');
        },
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favourites.length,
        itemBuilder: (context, index) {
          final favourite = favourites[index];
          final menuItem = favourite.menuItem;

          if (menuItem == null) {
            return const SizedBox.shrink();
          }

          return Dismissible(
            key: Key(favourite.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 32,
              ),
            ),
            confirmDismiss: (direction) async {
              return await _showRemoveConfirmation(
                context,
                menuItem.name,
              );
            },
            onDismissed: (direction) {
              ref
                  .read(favouritesProvider.notifier)
                  .removeMenuItemFavourite(menuItem.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${menuItem.name} removed from favorites'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      ref
                          .read(favouritesProvider.notifier)
                          .addMenuItemFavourite(menuItem.id);
                    },
                  ),
                ),
              );
            },
            child: MenuItemCardWidget(
              menuItem: menuItem,
              onTap: () {
                // Navigate to menu item detail or add to cart
              },
            ),
          );
        },
      ),
    );
  }

  Future<bool?> _showRemoveConfirmation(
    BuildContext context,
    String itemName,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites?'),
        content: Text('Remove $itemName from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
